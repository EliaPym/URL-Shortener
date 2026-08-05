resource "aws_acm_certificate" "url_shortener_dns" {
  domain_name       = var.main_url
  validation_method = "DNS"
  provider          = aws.us_east_1

  subject_alternative_names = [format("www.%s", var.main_url)]
}

resource "aws_acm_certificate" "api_shortener_dns" {
  domain_name       = var.short_url
  validation_method = "DNS"

  subject_alternative_names = [var.api_url]
}

resource "aws_route53_zone" "url_shortener_dns" {
  name = var.main_url
}

resource "aws_route53_zone" "api_shortener_dns" {
  name = var.short_url
}

resource "aws_route53_record" "url_shortener_dns" {
  for_each = {
    for dvo in aws_acm_certificate.url_shortener_dns.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      type   = dvo.resource_record_type
      record = dvo.resource_record_value
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = aws_route53_zone.url_shortener_dns.zone_id
}

resource "aws_route53_record" "api_shortener_dns" {
  for_each = {
    for dvo in aws_acm_certificate.api_shortener_dns.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      type   = dvo.resource_record_type
      record = dvo.resource_record_value
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = aws_route53_zone.api_shortener_dns.zone_id
}

resource "aws_acm_certificate_validation" "url_shortener_dns" {
  provider                = aws.us_east_1
  certificate_arn         = aws_acm_certificate.url_shortener_dns.arn
  validation_record_fqdns = [for record in aws_route53_record.url_shortener_dns : record.fqdn]
}

resource "aws_acm_certificate_validation" "api_shortener_dns" {
  certificate_arn         = aws_acm_certificate.api_shortener_dns.arn
  validation_record_fqdns = [for record in aws_route53_record.api_shortener_dns : record.fqdn]
}
