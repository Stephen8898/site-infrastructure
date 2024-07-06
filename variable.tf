variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}
variable "bucket_name" {
  description = "Name of S3 bucket"
  type        = string
}

variable "domain_name" {
  description = "Domain name for hosted zone"
  type        = string
}

variable "zone_id" {
  description = "The Route 53 hosted zone ID."
  type        = string
}

