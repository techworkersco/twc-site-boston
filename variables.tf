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

variable app {
  description = "App name."
  default     = "website"
}

variable release {
  description = "Release tag."
}

variable repo {
  description = "Project repository."
  default     = "https://github.com/techworkersco/twc-site-boston.git"
}
