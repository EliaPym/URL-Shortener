resource "aws_dynamodb_table" "url_shortener_mappings" {
  name         = "URL_Mappings"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "ShortURL"

  attribute {
    name = "ShortURL"
    type = "S"
  }

  ttl {
    enabled = false
  }

  server_side_encryption {
    enabled = false
  }

  tags = {
    Environment = "Production"
    Project     = var.project_name
  }
}

resource "random_uuid" "bucket_suffix" {
}

resource "aws_s3_bucket" "url_shortener_frontend" {
  bucket = "url-shortener-frontend-${random_uuid.bucket_suffix.result}"
}

resource "aws_s3_bucket_website_configuration" "url_shortener_frontend" {
  bucket = aws_s3_bucket.url_shortener_frontend.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "404.html"
  }
}

resource "aws_s3_object" "frontend_config" {
  bucket       = aws_s3_bucket.url_shortener_frontend.id
  key          = "config.js"
  content      = "const API_URL = \"https://${var.api_url}\";"
  content_type = "text/javascript"
}

resource "aws_s3_bucket_public_access_block" "url_shortener_frontend" {
  bucket = aws_s3_bucket.url_shortener_frontend.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_policy" "url_shortener_frontend" {
  bucket = aws_s3_bucket.url_shortener_frontend.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.url_shortener_frontend.arn}/*"
      }
    ]
  })

  depends_on = [aws_s3_bucket_public_access_block.url_shortener_frontend]
}

locals {
  frontend_dir = "${path.module}/../frontend"
  mime_types = {
    html = "text/html"
    css  = "text/css"
    js   = "text/javascript"
  }
}

resource "aws_s3_object" "frontend_files" {
  for_each = setsubtract(fileset(local.frontend_dir, "**"), ["config.js"])

  bucket       = aws_s3_bucket.url_shortener_frontend.id
  key          = each.value
  source       = "${local.frontend_dir}/${each.value}"
  etag         = filemd5("${local.frontend_dir}/${each.value}")
  content_type = lookup(local.mime_types, regex("\\.([^.]*)$", each.value), "application/octet-stream")
}
