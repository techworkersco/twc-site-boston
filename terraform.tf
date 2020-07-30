terraform {
  backend s3 {
    bucket = "boston.techworkerscoalition.org"
    key    = "terraform/website.tfstate"
    region = "us-east-1"
  }

  required_version = "~> 0.12"

  required_providers {
    aws = "~> 2.7"
  }
}

provider aws {
  version = "~> 2.7"
  region  = "us-east-1"
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

# DNS

resource aws_acm_certificate cert {
  domain_name               = local.domain_name
  subject_alternative_names = ["*.${local.domain_name}"]
  validation_method         = "DNS"
  tags                      = local.tags
}

resource aws_route53_zone zone {
  name = local.domain_name
}

resource aws_route53_record a {
  name    = aws_apigatewayv2_domain_name.domain.domain_name
  type    = "A"
  zone_id = aws_route53_zone.zone.id

  alias {
    evaluate_target_health = true
    name                   = aws_apigatewayv2_domain_name.domain.domain_name_configuration.0.target_domain_name
    zone_id                = aws_apigatewayv2_domain_name.domain.domain_name_configuration.0.hosted_zone_id
  }
}

# API GATEWAY :: DOMAIN

resource aws_apigatewayv2_domain_name domain {
  domain_name = local.domain_name
  tags        = local.tags

  domain_name_configuration {
    certificate_arn = aws_acm_certificate.cert.arn
    endpoint_type   = "REGIONAL"
    security_policy = "TLS_1_2"
  }
}

resource aws_apigatewayv2_api_mapping domain {
  api_id      = aws_apigatewayv2_api.http_api.id
  domain_name = aws_apigatewayv2_domain_name.domain.id
  stage       = aws_apigatewayv2_stage.default.id
}

# API GATEWAY :: HTTP API

resource aws_apigatewayv2_api http_api {
  description   = "Boston TWC website"
  name          = "website"
  protocol_type = "HTTP"
  tags          = local.tags
}

resource aws_apigatewayv2_stage default {
  api_id      = aws_apigatewayv2_api.http_api.id
  auto_deploy = true
  name        = "$default"
  tags        = local.tags

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_logs.arn

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

resource aws_cloudwatch_log_group api_logs {
  name              = "/aws/apigatewayv2/${aws_apigatewayv2_api.http_api.name}"
  retention_in_days = 30
  tags              = local.tags
}

# API GATEWAY :: HTTP INTEGRATIONS

resource aws_apigatewayv2_integration proxy {
  api_id               = aws_apigatewayv2_api.http_api.id
  connection_type      = "INTERNET"
  description          = "Lambda example"
  integration_method   = "POST"
  integration_type     = "AWS_PROXY"
  integration_uri      = aws_lambda_function.lambda.invoke_arn
  passthrough_behavior = "WHEN_NO_MATCH"
  timeout_milliseconds = 3000

  lifecycle {
    ignore_changes = [passthrough_behavior]
  }
}

# API GATEWAY :: HTTP ROUTES

resource aws_apigatewayv2_route get_root {
  api_id             = aws_apigatewayv2_api.http_api.id
  route_key          = "GET /"
  authorization_type = "NONE"
  target             = "integrations/${aws_apigatewayv2_integration.proxy.id}"
}

resource aws_apigatewayv2_route get_proxy {
  api_id             = aws_apigatewayv2_api.http_api.id
  route_key          = "GET /{proxy+}"
  authorization_type = "NONE"
  target             = "integrations/${aws_apigatewayv2_integration.proxy.id}"
}

# LOGS

resource aws_cloudwatch_log_group logs {
  name              = "/aws/lambda/${aws_lambda_function.lambda.function_name}"
  retention_in_days = 30
  tags              = local.tags
}

# IAM

data aws_iam_policy_document assume_role {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

data aws_iam_policy_document secret {
  statement {
    sid       = "GetSecretValue"
    actions   = ["secretsmanager:GetSecretValue"]
    resources = [aws_secretsmanager_secret.secret.arn]
  }
}

resource aws_iam_role role {
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
  name               = local.app
}

resource aws_iam_role_policy inline {
  policy = data.aws_iam_policy_document.secret.json
  role   = aws_iam_role.role.id
}

resource aws_iam_role_policy_attachment basic {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  role       = aws_iam_role.role.name
}

# LAMBDA

resource aws_lambda_function lambda {
  description      = "Boston TWC Website"
  filename         = "${path.module}/package.zip"
  function_name    = "website"
  handler          = "index.handler"
  memory_size      = 2048
  role             = aws_iam_role.role.arn
  runtime          = "nodejs12.x"
  source_code_hash = filebase64sha256("${path.module}/package.zip")
  tags             = local.tags
  timeout          = 30

  environment {
    variables = {
      AWS_SECRET = aws_secretsmanager_secret.secret.name
      S3_BUCKET  = aws_s3_bucket.bucket.bucket
    }
  }
}

resource aws_lambda_permission invoke {
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda.arn
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.http_api.execution_arn}/*/*/*"
}

# S3

resource aws_s3_bucket bucket {
  acl    = "private"
  bucket = local.domain_name
  tags   = local.tags

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
}

# SECRETS

data aws_kms_key kms_key {
  key_id = "alias/aws/secretsmanager"
}

resource aws_secretsmanager_secret secret {
  description = "${local.app} secrets"
  name        = local.app
  kms_key_id  = data.aws_kms_key.kms_key.id
  tags        = local.tags
}

# OUTPUTS

output url {
  value = "https://boston.techworkerscoalition.org/"
}
