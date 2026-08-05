resource "aws_apigatewayv2_domain_name" "short_link_domain" {
  domain_name = var.short_url

  domain_name_configuration {
    certificate_arn = aws_acm_certificate_validation.api_shortener_dns.certificate_arn
    endpoint_type   = "REGIONAL"
    security_policy = "TLS_1_2"
  }
}

resource "aws_apigatewayv2_api_mapping" "short_link_mapping" {
  api_id      = aws_apigatewayv2_api.url_shortener_api.id
  domain_name = aws_apigatewayv2_domain_name.short_link_domain.id
  stage       = aws_apigatewayv2_stage.default_stage.id
}

resource "aws_apigatewayv2_api" "url_shortener_api" {
  name          = "url_shortener_api"
  protocol_type = "HTTP"

  tags = {
    Environment = "Production"
    Project     = var.project_name
  }
}

resource "aws_apigatewayv2_integration" "lambda_integration" {
  api_id             = aws_apigatewayv2_api.url_shortener_api.id
  integration_type   = "AWS_PROXY"
  integration_method = "POST"
  integration_uri    = aws_lambda_function.url_shortener_lambda.invoke_arn
}

resource "aws_apigatewayv2_route" "default_route" {
  api_id    = aws_apigatewayv2_api.url_shortener_api.id
  route_key = "ANY /{proxy+}"
  target    = "integrations/${aws_apigatewayv2_integration.lambda_integration.id}"
}

resource "aws_apigatewayv2_stage" "default_stage" {
  api_id      = aws_apigatewayv2_api.url_shortener_api.id
  name        = "$default"
  auto_deploy = true
}

resource "aws_lambda_permission" "api_gw_invoke" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.url_shortener_lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.url_shortener_api.execution_arn}/*/*"
}
