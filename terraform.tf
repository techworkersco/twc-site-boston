terraform {
  backend "s3" {
    bucket = "twc-boston-us-east-1"
    key    = "terraform/website.tfstate"
    region = "us-east-1"
  }

  required_version = "~> 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"

  default_tags {
    tags = local.tags
  }
}

locals {
  app         = "website"
  domain_name = "boston.techworkerscoalition.org"
  repo        = "https://github.com/techworkersco/twc-site-boston"

  tags = {
    App  = local.app
    Repo = local.repo
  }
}

###########
#   DNS   #
###########

resource "aws_acm_certificate" "cert" {
  domain_name               = local.domain_name
  subject_alternative_names = ["*.${local.domain_name}"]
  validation_method         = "DNS"
}

resource "aws_route53_zone" "zone" {
  name = local.domain_name
}

resource "aws_route53_record" "a" {
  name    = aws_apigatewayv2_domain_name.api.domain_name
  type    = "A"
  zone_id = aws_route53_zone.zone.id

  alias {
    evaluate_target_health = true
    name                   = aws_apigatewayv2_domain_name.api.domain_name_configuration.0.target_domain_name
    zone_id                = aws_apigatewayv2_domain_name.api.domain_name_configuration.0.hosted_zone_id
  }
}

###################
#   API GATEWAY   #
###################

resource "aws_apigatewayv2_api" "api" {
  description   = "Boston TWC website"
  name          = "website"
  protocol_type = "HTTP"
}

resource "aws_apigatewayv2_api_mapping" "api" {
  api_id      = aws_apigatewayv2_api.api.id
  domain_name = aws_apigatewayv2_domain_name.api.id
  stage       = aws_apigatewayv2_stage.api.id
}

resource "aws_apigatewayv2_domain_name" "api" {
  domain_name = local.domain_name

  domain_name_configuration {
    certificate_arn = aws_acm_certificate.cert.arn
    endpoint_type   = "REGIONAL"
    security_policy = "TLS_1_2"
  }
}

resource "aws_apigatewayv2_integration" "api" {
  api_id             = aws_apigatewayv2_api.api.id
  description        = "Boston TWC website"
  integration_method = "POST"
  integration_type   = "AWS_PROXY"
  integration_uri    = aws_lambda_function.lambda.invoke_arn
}

resource "aws_apigatewayv2_route" "api" {
  for_each           = toset(["GET /", "GET /{proxy+}"])
  api_id             = aws_apigatewayv2_api.api.id
  route_key          = each.key
  authorization_type = "NONE"
  target             = "integrations/${aws_apigatewayv2_integration.api.id}"
}

resource "aws_apigatewayv2_stage" "api" {
  api_id      = aws_apigatewayv2_api.api.id
  auto_deploy = true
  name        = "$default"

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api.arn

    format = jsonencode({
      httpMethod     = "$context.httpMethod"
      ip             = "$context.identity.sourceIp"
      protocol       = "$context.protocol"
      requestId      = "$context.requestId"
      requestTime    = "$context.requestTime"
      responseLength = "$context.responseLength"
      routeKey       = "$context.routeKey"
      status         = "$context.status"
    })
  }

  lifecycle {
    ignore_changes = [deployment_id]
  }
}

############
#   LOGS   #
############

resource "aws_cloudwatch_log_group" "api" {
  name              = "/aws/apigatewayv2/${aws_apigatewayv2_api.api.name}"
  retention_in_days = 30
}

resource "aws_cloudwatch_log_group" "lambda" {
  name              = "/aws/lambda/${aws_lambda_function.lambda.function_name}"
  retention_in_days = 30
}

##############
#   LAMBDA   #
##############

resource "aws_iam_role" "lambda" {
  name                = "${local.app}-lambda"
  managed_policy_arns = ["arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"]

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid       = "AssumeLambda"
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
    }]
  })
}

resource "aws_lambda_function" "lambda" {
  description      = "Boston TWC Website"
  filename         = "${path.module}/package.zip"
  function_name    = "website"
  handler          = "index.handler"
  memory_size      = 2048
  role             = aws_iam_role.lambda.arn
  runtime          = "nodejs18.x"
  source_code_hash = filebase64sha256("${path.module}/package.zip")
  timeout          = 30

  environment {
    variables = {
      GOOGLE_API_KEY     = var.GOOGLE_API_KEY
      GOOGLE_CALENDAR_ID = var.GOOGLE_CALENDAR_ID
    }
  }
}

resource "aws_lambda_permission" "lambda" {
  for_each      = toset(["GET/", "GET/*"])
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda.arn
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.api.execution_arn}/${aws_apigatewayv2_stage.api.name}/${each.value}"
}

##########
#   S3   #
##########

resource "aws_s3_bucket" "bucket" {
  bucket = "twc-boston-us-east-1"
}

resource "aws_s3_bucket_public_access_block" "bucket" {
  bucket = aws_s3_bucket.bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

#################
#   VARIABLES   #
#################

variable "GOOGLE_API_KEY" {
  description = "Google API key"
  type        = string
}

variable "GOOGLE_CALENDAR_ID" {
  description = "Google Calendar ID"
  type        = string
  default     = "uqr1emskpd1iochp7r1v8v0nl8@group.calendar.google.com"
}

###############
#   OUTPUTS   #
###############

output "url" {
  description = "Boston TWC website URL"
  value       = "https://boston.techworkerscoalition.org/"
}

output "name_servers" {
  description = "boston.techworkerscoalition.org nameservers"
  value       = [for x in aws_route53_zone.zone.name_servers : x]
}
