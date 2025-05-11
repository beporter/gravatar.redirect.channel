output "lambda_url" {
  value = aws_apigatewayv2_api.lambda_api.api_endpoint
}

output "website_url" {
  value = "http://${var.site_domain_name}"
}

output "route53_name_servers" {
  description = "The Route 53 NS records for the hosted zone"
  value       = data.aws_route53_zone.main.name_servers
}
