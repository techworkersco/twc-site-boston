terraform {
  required_version = "~> 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.7"
    }
  }
}

provider "aws" { region = "us-east-1" }

variable "GOOGLE_API_KEY" { description = "Google API key" }
variable "GOOGLE_CALENDAR_ID" { description = "Google Calendar ID" }

data "aws_secretsmanager_secret" "secret" { name = "website" }

resource "aws_secretsmanager_secret_version" "version" {
  secret_id = data.aws_secretsmanager_secret.secret.id

  secret_string = jsonencode({
    GOOGLE_API_KEY     = var.GOOGLE_API_KEY
    GOOGLE_CALENDAR_ID = var.GOOGLE_CALENDAR_ID
  })
}
