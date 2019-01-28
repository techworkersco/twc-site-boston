variable aws_access_key_id {
  description = "AWS access key ID."
  default     = ""
}

variable aws_secret_access_key {
  description = "AWS secret access key."
  default     = ""
}

variable aws_profile {
  description = "AWS profile name."
  default     = ""
}

variable aws_region {
  description = "AWS region."
  default     = "us-east-1"
}

variable release {
  description = "Release tag."
}

variable repo {
  description = "Project repository."
  default     = "https://github.com/techworkersco/twc-site-boston.git"
}

variable s3_bucket {
  description = "S3 bucket for Lambda package."
  default     = "boston.techworkerscoalition.org"
}

variable s3_key {
  description = "S3 key for Lambda package."
  default     = "website/package.zip"
}
