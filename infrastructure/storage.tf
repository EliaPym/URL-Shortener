resource "aws_dynamodb_table" "url-shortener-mappings" {
    name            = "URLMappings"
    billing_mode    = "PAY_PER_REQUEST"
    hash_key        = "ShortURL"
    range_key       = "LongURL"
    read_capacity   = 20
    write_capacity  = 20

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