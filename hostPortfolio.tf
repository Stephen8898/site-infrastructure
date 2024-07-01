terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

resource "aws_s3_bucket" "portfolio" {
  bucket = var.bucket_name

  tags = {
    Name       = "Portfolio site bucket"
    Enviroment = "dev-test"
  }
}

resource "aws_route53_record" "portfolio-site" {
  zone_id = var.zone_id
  name    = var.domain_name
  type    = "CNAME"
  ttl     = 60
  records = [aws_s3_bucket.portfolio.website_domain]
}

output "s3_bucket_endpoint" {
  value = aws_s3_bucket.portfolio.website_domain
}
