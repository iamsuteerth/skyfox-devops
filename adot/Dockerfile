FROM golang:1.23.2 AS builder

ENV GOOS=linux \
    GOARCH=arm64 \
    CGO_ENABLED=0
    
WORKDIR /go/src
COPY . .
RUN go build -o healthchecker ./main.go

FROM public.ecr.aws/aws-observability/aws-otel-collector:latest

COPY --chmod=755 --from=builder /go/src/healthchecker /bin/healthchecker

CMD ["/awscollector"]