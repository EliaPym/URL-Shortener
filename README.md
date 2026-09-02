# Serverless URL Shortener

![Terraform](https://img.shields.io/badge/Terraform-AWS%20Provider%20~%3E5.0-844FBA?logo=terraform&logoColor=white)
![Python](https://img.shields.io/badge/Python-3.11-3776AB?logo=python&logoColor=white)
![AWS Lambda](https://img.shields.io/badge/AWS-Lambda-FF9900?logo=awslambda&logoColor=white)
![GitHub License](https://img.shields.io/github/license/EliaPym/URL-Shortener)

A basic serverless URL shortener template built on AWS - Lambda, API Gateway, Dynamo, S3, and Cloudfront provisioning - deployed entirely through Terraform.

## Table of Contents

- [Features](#features)
- [Tech Stack](#tech-stack)
- [Architecture](#architecture)
- [Project Structure](#project-structure)
- [Getting Started](#getting-started)
  - [Prerequisites](#prerequisites)
  - [Deployment](#deployment)
- [API Reference](#api-reference)
- [Roadmap](#roadmap)
- [Known Limitations / Bugs](#known-limitations--bugs)
- [Contributing](#contributing)
- [License](#license)

## Features

## Tech Stack

| Layer          | Technology                                                                 |
|----------------|----------------------------------------------------------------------------|
| **IAC**        | Terraform (`~> 5.0` AWS provider)                                          |
| **Compute**    | AWS Lambda (Python 3.11)                                                   |
| **API**        | API Gateway (HTTP API v2)                                                  |
| **Database**   | DynamoDB (on-demand - `PAY_PER_REQUEST`)                                   |
| **Edge / DNS** | Cloudfront, Route 53, ACM                                                  |
| **Backend**    | FastAPI + Mangum                                                           |
| **AWS SDK**    | Boto3 (bundled with Lambda Python 3.11 runtime - not a project dependancy) |

## Architecture

```mermaid
graph TD
Placeholder
```

## Project Structure

```bash
.
├── .gitignore
├── LICENSE
├── README.md
├── infrastructure/
│   ├── main.tf
│   ├── variables.tf
│   ├── storage.tf
│   ├── compute.tf
│   ├── api.tf
│   ├── edge.tf
│   ├── dns.tf
│   ├── outputs.tf
│   └── .terraform
│       └── terraform.tfstate
└── backend/
    ├── lambda_function.py
    ├── requirements.txt
    └── build/                        # Created during deployment - see below, not committed
```

## Configuration

All project-specific settings are in `./infrastructure/variables.tf`

| Variable       | Purpose                                                      | Default in this repo    |
|----------------|--------------------------------------------------------------|-------------------------|
| `aws_region`   | Region for Lambda, DynamoDB, and API Gateway custom domains  | `eu-west-2`             |
| `project_name` | Applied as a project tag on tagged resources                 | `URL_Shortener_Project` |
| `main_url`     | "Long" domain - serves the S3/CloudFront frontend            | `i-linked.org`          |
| `short_url`    | "Short domain - mapped directly to API Gateway for redirects | `i-l.ink`               |
| `api_url`      | Included as a SAN on the short-domain certificate            | `api.i-l.ink`           |

> The repo's default `aws_region` is `eu-west-2` (London). CloudFront and its certificates are always deployed globally in `us-east-1` regardless of this setting. This is an AWS requirement, not something this variable controls.

**Also update `./backend/lambda_function.py`.** Not currently tied to the `short_url` in `variables.tf` but is required to be the same. The line that builds the response is hardcoded to `https://i-l.ink/`:

```bash
short_url: str = "https://i-l.ink/"
```

## Getting Started

### Prerequisites

An **Active AWS Account** and the **AWS CLI v2** configured with credentials that can create IAM roles, Lambda functions, API Gateway APIs, DynamoDB tables, S3 buckets, CloudFront distributions, Route 53 zones, and ACM certificates.

- **Terraform:** `v1.5.0+`
- **Python:** `v3.11.X`
- **pip:** `v23.0+`
- **AWS CLI:** `v2.X`

   ```bash
   aws configure   # or: aws sso login --profile your-profile
   ```

- **WSL** (*for Windows users only - needed for installation of Linux version of Python libraries*)
- **Two registered domain names**
  - Main/long domain (e.g. `example-domain.com`)
  - Short domain (e.g. `exmpl.co`)
- **Registrar Admin Access**

### Deployment

Deployment happens in two Terraform passes, because the stack creates its own Route 53 hosted zones - and ACM's DNS validation, plus the final redirect record, cannot succeed until your registrar is actually delegating to those zones.

1. Clone the repo and set your AWS credentials

   ```bash
   git clone https://github.com/EliaPym/URL-Shortener.git
   cd <repo>
   aws configure
   ```

2. Update `./infrastructure/variables.tf` with the following: (see [Configuration](#configuration))
   - **Preferred deployment region:** `aws_region`
   - **Project name:** `project_name`
   - **Main URL (frontend):** `main_url`
   - **Short URL:** `short_url`
   - **API URL:** `api_url` (*must be in the form of* `prefix.<short-url>.<tld>`)
3. Update the hardcoded domain `short_url` in `./backend/lambda_function.py`.
4. Create the Route 53 zones and point the registrar's nameservers at them. Deployment requires this to be completed first.

   ```bash
   cd infrastructure
   terraform init
   terraform apply -target=aws_route53_zone.url_shortener_dns -target=aws_route53_zone.api_shortener_dns
   ```

5. Build the Lambda deployment package

   ```bash
   cd ../backend

   pip install \
   --platform manylinux2014_x86_64 \
   --implementation cp \
   --python-version 3.11 \
   --only-binary=:all: \
   --upgrade \
   --target=build \
   -r requirements.txt

   cp lambda_function.py build/
   ```

   > [!NOTE]
   > Run this inside **WSL** if you're on Windows - MacOS and Linux can run it natively. There are issues with pip not installing the correct Linux binaries on Windows despite declaring `--platform manylinux2014_x86_64` so WSL is recommended.

6. Deploy the rest of the stack

   ```bash
   cd ../infrastructure
   terraform apply
   ```

7. Grab the endpoints

   ```bash
   terraform output
   ```

## API Reference

All routes are served through a single catch-all Lambda integration. FastAPI handles routing internally.

| Method | Path            | Description                                                                             |
|--------|-----------------|-----------------------------------------------------------------------------------------|
| `GET`  | `/`             | Health/welcome message                                                                  |
| `GET`  | `/{short_code}` | 301 redirect to stored original URL, returns 404 if `short_code` isn't found            |
| `POST` | `/Shorten`      | Creates or reuses the short link. Body: `{"long_url": "...", "custom_url": "optional"}` |

### Creating a short link

```bash
curl -X POST "https://i-l.ink/Shorten" \                             # Replace with your short domain
  -H "Content-Type: application/json" \
  -d '{"long_url": "https://example.com/some/very/long/path"}'

# → { "short_url": "https://i-l.ink/a1b2c3" }
```

### With custom alias

```bash
curl -X POST "https://i-l.ink/Shorten" \                             # Replace with your short domain
  -H "Content-Type: application/json" \
  -d '{"long_url": "https://example.com", "custom_url": "foobar"}'

# → { "short_url": "https://i-l.ink/foobar" }
```

### Follow a short link

```bash
curl -I "https://i-l.ink/a1b2c3"
# → HTTP/2 301
# → location: https://example.com/some/very/long/path
```

## Roadmap

## Known Limitations / Bugs

## Contributing

Contributions, issues, and feature requests are welcome.

1. Fork the project
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

Distributed under the MIT License. See [LICENSE](LICENSE) for details.

---

**Elia Pym |** [elia.pym@e-p.dev](mailto:elia.pym@e-p.dev) **|** [LinkedIn](https://linkedin.com/in/EliaPym) **|** [GitHub](https://github.com/EliaPym)
