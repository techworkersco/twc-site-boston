variable aws_access_key_id {
  description = "AWS access key ID."
  default     = ""
}

variable aws_profile {
  description = "AWS profile."
  default     = ""
}

variable aws_region {
  description = "AWS region."
  default     = "us-east-2"
}

variable aws_secret_access_key {
  description = "AWS secret access key."
  default     = ""
}

variable kms_key_alias {
  description = "KMS key alias."
  default     = "alias/aws/secretsmanager"
}

variable google_api_key {
  description = "Google API key."
}

variable google_calendar_id {
  description = "Google Calendar ID."
}

variable host {
  description = "Host name."
  default     = "https://boston.techworkerscoalition.org/"
}

variable release {
  description = "Release tag."
}

variable repo {
  description = "Project repository."
  default     = "https://github.com/techworkersco/twc-site-boston.git"
}

variable secret_description {
  description = "SecretsManager secret description."
  default     = "boston.techworkerscoalition.org secrets"
}

variable secret_name {
  description = "SecretsManager secret name."
  default     = "website"
}
