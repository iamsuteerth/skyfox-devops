output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "IDs of the private subnets"
  value       = aws_subnet.private[*].id
}

output "internet_gateway_id" {
  description = "ID of the Internet Gateway"
  value       = aws_internet_gateway.main.id
}

output "vpc_cidr_block" {
  description = "CIDR block of the VPC"
  value       = aws_vpc.main.cidr_block
}

output "alb_security_group_id" {
  description = "ID of the ALB security group"
  value       = aws_security_group.alb.id
}

output "backend_security_group_id" {
  description = "ID of the backend security group"
  value       = aws_security_group.backend.id
}

output "payment_security_group_id" {
  description = "ID of the payment security group"
  value       = aws_security_group.payment.id
}

output "movie_security_group_id" {
  description = "ID of the movie security group"
  value       = aws_security_group.movie.id
}

output "ecs_instance_security_group_id" {
  description = "ID of the ECS instance security group"
  value       = aws_security_group.ecs_instance.id
}