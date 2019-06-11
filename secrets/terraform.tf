terraform {
  backend s3 {
    bucket  = "boston.techworkerscoalition.org"
    key     = "terraform/website-secrets.tfstate"
    region  = "us-east-1"
    profile = "twc"
  }

  required_version = ">= 0.12.0"

  required_providers {
    aws = "~> 2.7"
  }
}

provider aws {
  region  = "us-east-1"
  version = "~> 2.7"
}

locals {
  secret = {
    GOOGLE_API_KEY     = var.google_api_key
    GOOGLE_CALENDAR_ID = var.google_calendar_id
  }

  tags = {
    App     = "boston.techworkerscoalition.org"
    Repo    = var.repo
    Release = var.release
  }
}

data aws_kms_key key {
  key_id = var.kms_key_alias
}

resource aws_secretsmanager_secret secret {
  description = var.secret_description
  name        = var.secret_name
  kms_key_id  = data.aws_kms_key.key.id
  tags        = local.tags
}

resource aws_secretsmanager_secret_version version {
  secret_id     = aws_secretsmanager_secret.secret.id
  secret_string = jsonencode(local.secret)
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
  default     = "https://github.com/techworkersco/twc-site-boston"
}

variable secret_description {
  description = "SecretsManager secret description."
  default     = "boston.techworkerscoalition.org secrets"
}

variable secret_name {
  description = "SecretsManager secret name."
  default     = "website"
}

output secret_arn {
  description = "SecretsManager secret ARN."
  value       = "${aws_secretsmanager_secret.secret.arn}"
}

output secret_name {
  description = "SecretsManager secret name."
  value       = "${aws_secretsmanager_secret.secret.name}"
}
