output "api_gateway_endpoint" {
    description = "Public URL of backend"
    value = aws_apigatewayv2_api.url_shortener_api.api_endpoint
}

output "frontend_s3_bucket_name" {
    description = "Name of S3 bucket for hosting frontend"
    value = aws_s3_bucket.url_shortener_frontend.id
}

output "frontend_s3_website_url" {
    description = "URL of S3 bucket for frontend"
    value = aws_s3_bucket_website_configuration.url_shortener_frontend.website_endpoint
}