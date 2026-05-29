resource "aws_dynamodb_table" "url-shortener-mappings" {
    name            = "URLMappings"
    billing_mode    = "PAY_PER_REQUEST"
    hash_key        = "ShortURL"
    range_key       = "LongURL"

    attribute {
        name = "ShortURL"
        type = "S"
    }

    attribute {
        name = "LongURL"
        type = "S"
    }

    ttl {
        enabled = false
    }

    server_side_encryption {
        enabled = false
    }
}

resource "aws_s3_bucket_website_configuration" "url-shortener-website" {
    bucket = "url-shortener-website-bucket"

    index_document {
        suffix = "index.html"
    }

    error_document {
        key = "404.html"
    }
}