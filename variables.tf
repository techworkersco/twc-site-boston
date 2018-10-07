variable aws_access_key_id {
  description = "AWS access key ID."
}

variable aws_secret_access_key {
  description = "AWS secret access key."
}

variable aws_region {
  description = "AWS region."
  default     = "us-east-1"
}

variable s3_bucket {
  description = "S3 bucket for Lambda package."
}

variable s3_key {
  description = "S3 key for Lambda package."
}
