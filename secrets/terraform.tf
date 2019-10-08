terraform {
  backend s3 {
    bucket  = "boston.techworkerscoalition.org"
    key     = "terraform/website-secrets.tfstate"
    region  = "us-east-1"
    profile = "twc"
  }

  required_version = ">= 0.12.0"
}

provider aws {
  region  = "us-east-1"
  version = "~> 2.7"
}

locals {
  app  = "website"
  repo = "https://github.com/techworkersco/twc-site-boston"

  google_api_key     = var.google_api_key
  google_calendar_id = var.google_calendar_id

  secret = {
    GOOGLE_API_KEY     = local.google_api_key
    GOOGLE_CALENDAR_ID = local.google_calendar_id
  }

  tags = {
    App     = local.app
    Repo    = local.repo
    Release = var.release
  }
}

data aws_kms_key key {
  key_id = var.kms_key_alias
}

resource aws_secretsmanager_secret secret {
  description = "${local.app} secrets"
  name        = local.app
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

variable release {
  description = "Release tag."
}

output secret_arn {
  description = "SecretsManager secret ARN."
  value       = aws_secretsmanager_secret.secret.arn
}

output secret_name {
  description = "SecretsManager secret name."
  value       = aws_secretsmanager_secret.secret.name
}
