output "alb_dns_name" {
  value       = aws_lb.main.dns_name
  description = "Application Load Balancer'ın internet adresi"
}