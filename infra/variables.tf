variable "project_name" {
  description = "The name of your project, which will be used to prefix many AWS resources"
}

variable "aws_region" {
  description = "Target AWS region to deploy to"
}

variable "s3_bucket_name" {
  description = "S3 bucket that contains the website content"
}

variable "top_level_domain" {
  description = "Top-level domain"
}

variable "website_domain" {
  description = "Fully qualified domain name for the website"
}

variable "contact_email" {
  description = "Reply-to address for outbound emails"
}
