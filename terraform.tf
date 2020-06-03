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
    App   = local.app
    Repo  = local.repo
    Build = var.BUILD
  }
}

data aws_iam_policy_document assume_role {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

data aws_secretsmanager_secret secret {
  name = local.app
}

data aws_iam_policy_document secret {
  statement {
    sid       = "GetSecretValue"
    actions   = ["secretsmanager:GetSecretValue"]
    resources = [data.aws_secretsmanager_secret.secret.arn]
  }
}

resource aws_acm_certificate cert {
  domain_name               = local.domain_name
  subject_alternative_names = ["*.${local.domain_name}"]
  validation_method         = "DNS"
  tags                      = local.tags
}

resource aws_api_gateway_deployment api {
  depends_on = [
    aws_api_gateway_integration.root_get,
    aws_api_gateway_integration.proxy_get,
  ]
  rest_api_id = aws_api_gateway_rest_api.api.id
  stage_name  = "production"
}

resource aws_api_gateway_domain_name custom_domain {
  domain_name     = local.domain_name
  certificate_arn = aws_acm_certificate.cert.arn
}

resource aws_api_gateway_integration proxy_get {
  content_handling        = "CONVERT_TO_TEXT"
  http_method             = aws_api_gateway_method.proxy_get.http_method
  integration_http_method = "POST"
  resource_id             = aws_api_gateway_resource.proxy.id
  rest_api_id             = aws_api_gateway_rest_api.api.id
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.lambda.invoke_arn
}

resource aws_api_gateway_integration root_get {
  content_handling        = "CONVERT_TO_TEXT"
  http_method             = aws_api_gateway_method.root_get.http_method
  integration_http_method = "POST"
  resource_id             = aws_api_gateway_rest_api.api.root_resource_id
  rest_api_id             = aws_api_gateway_rest_api.api.id
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.lambda.invoke_arn
}

resource aws_api_gateway_method proxy_get {
  authorization = "NONE"
  http_method   = "GET"
  resource_id   = aws_api_gateway_resource.proxy.id
  rest_api_id   = aws_api_gateway_rest_api.api.id
}

resource aws_api_gateway_method root_get {
  authorization = "NONE"
  http_method   = "GET"
  resource_id   = aws_api_gateway_rest_api.api.root_resource_id
  rest_api_id   = aws_api_gateway_rest_api.api.id
}

resource aws_api_gateway_resource proxy {
  parent_id   = aws_api_gateway_rest_api.api.root_resource_id
  path_part   = "{proxy+}"
  rest_api_id = aws_api_gateway_rest_api.api.id
}

resource aws_api_gateway_rest_api api {
  description = "Boston TWC website"
  name        = "website"

  endpoint_configuration {
    types = ["EDGE"]
  }
}

resource aws_cloudwatch_log_group logs {
  name              = "/aws/lambda/${aws_lambda_function.lambda.function_name}"
  retention_in_days = 30
  tags              = local.tags
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
      AWS_SECRET = data.aws_secretsmanager_secret.secret.name
      S3_BUCKET  = aws_s3_bucket.bucket.bucket
    }
  }
}

resource aws_lambda_permission invoke {
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda.arn
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.api.execution_arn}/*/*/*"
}

resource aws_s3_bucket bucket {
  acl    = "private"
  bucket = aws_api_gateway_domain_name.custom_domain.domain_name
  tags   = local.tags

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
}

output cert_arn {
  description = "ACM certificate ARN"
  value       = aws_acm_certificate.cert.arn
}

output domain_name {
  description = "API Gateway custom domain"
  value       = aws_api_gateway_domain_name.custom_domain.domain_name
}

output lambda_function_arn {
  description = "Lambda function ARN"
  value       = aws_lambda_function.lambda.arn
}

output lambda_function_name {
  description = "Lambda function name"
  value       = aws_lambda_function.lambda.function_name
}

output s3_bucket {
  description = "S3 bucket"
  value       = aws_s3_bucket.bucket.bucket
}

variable BUILD {
  description = "Build name"
}
