output "external_alb_arn" {
  description = "ARN of the external Application Load Balancer"
  value       = aws_lb.external.arn
}

output "external_alb_dns_name" {
  description = "DNS name of the external Application Load Balancer"
  value       = aws_lb.external.dns_name
}

output "external_alb_zone_id" {
  description = "Zone ID of the external Application Load Balancer"
  value       = aws_lb.external.zone_id
}

output "external_alb_url" {
  description = "URL of the external Application Load Balancer"
  value       = "http://${aws_lb.external.dns_name}"
}

output "internal_alb_arn" {
  description = "ARN of the internal Application Load Balancer"
  value       = aws_lb.internal.arn
}

output "internal_alb_dns_name" {
  description = "DNS name of the internal Application Load Balancer"
  value       = aws_lb.internal.dns_name
}

output "internal_alb_url" {
  description = "URL of the internal Application Load Balancer"
  value       = "http://${aws_lb.internal.dns_name}"
}

output "backend_target_group_arn" {
  description = "ARN of the backend target group"
  value       = aws_lb_target_group.backend.arn
}

output "payment_target_group_arn" {
  description = "ARN of the payment target group"
  value       = aws_lb_target_group.payment.arn
}

output "movie_target_group_arn" {
  description = "ARN of the movie target group"
  value       = aws_lb_target_group.movie.arn
}

output "backend_environment_variables" {
  description = "Environment variables for backend service configuration"
  value = {
    MOVIE_SERVICE_URL    = "http://${aws_lb.internal.dns_name}/movie-service"
    PAYMENT_GATEWAY_URL = "http://${aws_lb.internal.dns_name}/payment-service"
  }
}
