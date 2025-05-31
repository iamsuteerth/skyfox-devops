package main

import (
	"context"
	"fmt"
	"io"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"
)

func main() {
	var err error
	defer func() {
		if err != nil {
			fmt.Println(err.Error())
			os.Exit(1)
		}
	}()
	ctx, sigCxl := signal.NotifyContext(context.Background(), syscall.SIGINT, syscall.SIGTERM)
	defer sigCxl()
	req, err := http.NewRequestWithContext(ctx, http.MethodGet, "http://localhost:13133", nil)
	if err != nil {
		err = fmt.Errorf("failed to create request: %w", err)
		return
	}
	http.DefaultClient.Timeout = time.Second
	res, err := http.DefaultClient.Do(req)
	if err != nil {
		err = fmt.Errorf("failed to do request: %w", err)
		return
	}
	defer func() { _ = res.Body.Close() }()

	resBody, err := io.ReadAll(res.Body)
	if err != nil {
		err = fmt.Errorf("failed to read response body: %w", err)
		return
	}

	if res.StatusCode != http.StatusOK {
		err = fmt.Errorf("unexpected server status [%d]: %s", res.StatusCode, string(resBody))
		return
	}

	fmt.Println("HEALTHY")
}