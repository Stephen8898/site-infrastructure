variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}
variable "sub_domain_name" {
  description = "Sub domain name for hosted zone"
  type        = string
}

variable "domain_name" {
  description = "Sustom domain name"
  type        = string
}

variable "zone_id" {
  description = "The Route 53 hosted zone ID."
  type        = string
}

variable "certificate_arn" {
  description = "ARN for custom Certificate"
  type        = string
}
