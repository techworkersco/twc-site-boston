provider archive {
  version = "~> 1.1"
}

provider aws {
  version    = "~> 1.39"
  access_key = "${var.aws_access_key_id}"
  secret_key = "${var.aws_secret_access_key}"
  region     = "${var.aws_region}"
}

data "aws_caller_identity" "current" {
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

resource aws_acm_certificate cert {
  domain_name               = "boston.techworkerscoalition.org"
  subject_alternative_names = ["*.boston.techworkerscoalition.org"]
  validation_method         = "DNS"
}

resource aws_api_gateway_deployment api {
  depends_on  = [
    "aws_api_gateway_integration.root_get",
    "aws_api_gateway_integration.proxy_get",
  ]
  rest_api_id = "${aws_api_gateway_rest_api.api.id}"
  stage_name  = "production"
}

resource aws_api_gateway_domain_name custom_domain {
  domain_name     = "boston.techworkerscoalition.org"
  certificate_arn = "${aws_acm_certificate.cert.arn}"
}

resource aws_api_gateway_integration proxy_get {
  content_handling        = "CONVERT_TO_TEXT"
  http_method             = "${aws_api_gateway_method.proxy_get.http_method}"
  integration_http_method = "POST"
  resource_id             = "${aws_api_gateway_resource.proxy.id}"
  rest_api_id             = "${aws_api_gateway_rest_api.api.id}"
  type                    = "AWS_PROXY"
  uri                     = "${aws_lambda_function.lambda.invoke_arn}"
}

resource aws_api_gateway_integration root_get {
  content_handling        = "CONVERT_TO_TEXT"
  http_method             = "${aws_api_gateway_method.root_get.http_method}"
  integration_http_method = "POST"
  resource_id             = "${aws_api_gateway_rest_api.api.root_resource_id}"
  rest_api_id             = "${aws_api_gateway_rest_api.api.id}"
  type                    = "AWS_PROXY"
  uri                     = "${aws_lambda_function.lambda.invoke_arn}"
}

resource aws_api_gateway_method proxy_get {
  authorization = "NONE"
  http_method   = "GET"
  resource_id   = "${aws_api_gateway_resource.proxy.id}"
  rest_api_id   = "${aws_api_gateway_rest_api.api.id}"
}

resource aws_api_gateway_method root_get {
  authorization = "NONE"
  http_method   = "GET"
  resource_id   = "${aws_api_gateway_rest_api.api.root_resource_id}"
  rest_api_id   = "${aws_api_gateway_rest_api.api.id}"
}

resource aws_api_gateway_resource proxy {
  parent_id   = "${aws_api_gateway_rest_api.api.root_resource_id}"
  path_part   = "{proxy+}"
  rest_api_id = "${aws_api_gateway_rest_api.api.id}"
}

resource aws_api_gateway_rest_api api {
  description            = "Boston TWC website"
  name                   = "website"

  endpoint_configuration {
    types = ["EDGE"]
  }
}

resource aws_lambda_function lambda {
  description   = "Boston TWC Website"
  function_name = "website"
  handler       = "lambda.handler"
  role          = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/AWSLambdaBasicExecution"
  runtime       = "nodejs8.10"
  s3_bucket     = "${var.s3_bucket}"
  s3_key        = "${var.s3_key}"
}

resource aws_lambda_permission invoke {
  action        = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.lambda.arn}"
  principal     = "apigateway.amazonaws.com"
  statement_id  = "AllowAPIGatewayInvoke"
  source_arn    = "${aws_api_gateway_rest_api.api.execution_arn}/*/*/*"
}

resource aws_s3_bucket bucket {
  acl    = "private"
  bucket = "boston.techworkerscoalition.org"

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
}
