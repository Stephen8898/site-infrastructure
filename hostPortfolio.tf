terraform {

  backend "s3" {
    bucket = "s3-state-tf-portfolio-infra-12312"
    region = "us-east-1"
    key    = "portfolio-infrastructure/terraform.tfstate"
  }
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
  bucket = var.domain_name

  tags = {
    Name       = "Portfolio site bucket"
    Enviroment = "dev-test"
  }
}

resource "aws_s3_bucket_website_configuration" "host" {
  bucket = aws_s3_bucket.portfolio.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "error.html"
  }
}

resource "aws_s3_bucket_public_access_block" "bucket_access" {
  bucket = aws_s3_bucket.portfolio.id

  block_public_acls   = false
  block_public_policy = false
}

resource "aws_s3_bucket_policy" "bucket_policy" {
  bucket = aws_s3_bucket.portfolio.id

  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "PublicReadGetObject",
        "Effect" : "Allow",
        "Principal" : "*",
        "Action" : [
          "s3:GetObject"
        ],
        "Resource" : [
          "${aws_s3_bucket.portfolio.arn}/*"
        ]
      }
    ]
  })
}
resource "aws_s3_object" "file" {
  for_each     = fileset(path.module, "content/**/*.{html,css,js}")
  bucket       = aws_s3_bucket.portfolio.id
  key          = replace(each.value, "/^content//", "")
  source       = each.value
  content_type = lookup(local.content_types, regex("\\.[^.]+$", each.value), null)
  source_hash  = filemd5(each.value)
}

resource "aws_s3_bucket_lifecycle_configuration" "portfolio_bucket_Lifecycle" {
  bucket = aws_s3_bucket.portfolio.id
  rule {
    id = "Transition Objects to IA after 30 days"
    filter {}

    status = "Enabled"

    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }
  }
}

resource "aws_cloudfront_distribution" "distribution" {
  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"

  origin {
    domain_name = aws_s3_bucket_website_configuration.host.website_endpoint
    origin_id   = aws_s3_bucket.portfolio.bucket_regional_domain_name

    custom_origin_config {
      http_port                = 80
      https_port               = 443
      origin_keepalive_timeout = 5
      origin_protocol_policy   = "http-only"
      origin_read_timeout      = 30
      origin_ssl_protocols     = ["TLSv1.2"]
    }
  }

  aliases = [var.domain_name]

  viewer_certificate { acm_certificate_arn = var.certificate_arn }

  restrictions {
    geo_restriction {
      restriction_type = "none"
      locations        = []
    }
  }

  default_cache_behavior {
    cache_policy_id        = "658327ea-f89d-4fab-a63d-7e88639e58f6"
    viewer_protocol_policy = "redirect-to-https"
    target_origin_id       = aws_s3_bucket.portfolio.bucket_regional_domain_name
    cached_methods         = ["GET", "HEAD"]
    allowed_methods        = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
  }
  price_class = "PriceClass_100"
}

resource "aws_route53_record" "portfolio-site" {
  zone_id = var.zone_id
  name    = var.sub_domain_name
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.distribution.domain_name
    zone_id                = aws_cloudfront_distribution.distribution.hosted_zone_id
    evaluate_target_health = false
  }
}

output "s3_bucket_endpoint" {
  value = aws_s3_bucket_website_configuration.host.website_endpoint
}

output "route53_domain" {
  value = aws_route53_record.portfolio-site.fqdn
}

output "cdn_domain" {
  value = aws_cloudfront_distribution.distribution.domain_name
}
