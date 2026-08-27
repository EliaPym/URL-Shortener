# Serverless URL Shortener

A basic serverless URL shortener template built on AWS.

## Project Structure

```
.
├── infrastructure/       # Terraform configuration
│   ├── main.tf            # AWS provider + us-east-1 alias for the CloudFront certificate
│   ├── variables.tf       # Region, project name, domain inputs
│   ├── storage.tf         # DynamoDB table + frontend S3 bucket
│   ├── compute.tf         # Lambda function, IAM role and policy
│   ├── api.tf              # HTTP API, routes, Lambda integration, custom domain
│   ├── edge.tf              # CloudFront distribution
│   ├── dns.tf                # ACM certificates, Route 53 zones and records
│   └── outputs.tf            # Values printed after deploy
└── backend/                   # FastAPI application
    ├── lambda_function.py      # Routes + Mangum handler
    ├── requirements.txt        # Runtime dependencies
    └── build/                   # Created during deployment — see below, not committed
```

## Prerequisites

- **Terraform** `v1.5.0+`
- **Python** `v3.11.X`
- **pip** `v23.0+`
- **AWS CLI** `v2.X`
- **WSL** (*for Windows users only*)

### AWS

- **Active AWS Account** with billing enabled
- **IAM Privileges**
  - AWS Lambda
  - IAM Roles/Policies
  - API Gateway (HTTP API v2)
  - S3 bucket
  - DynamoDB
  - Route 53
  - AWS Certificate Manager
  - CloudFront

### Domain Names

- **Two registered domain names**
  - Main/long domain
  - Short domain
- **Registrar Admin Access**
