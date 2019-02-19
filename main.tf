provider archive {
  version = "~> 1.1"
}

provider aws {
  access_key = "${var.aws_access_key_id}"
  profile    = "${var.aws_profile}"
  region     = "${var.aws_region}"
  secret_key = "${var.aws_secret_access_key}"
  version    = "~> 1.50"
}

locals {
  assets = [
    "assets/event-2018-10-28.png",
    "assets/event-2018-12-09.png",
    "assets/event-2018-12-11.png",
    "assets/event-2019-02-24.png",
  ]

  tags {
    App     = "${var.app}"
    Repo    = "${var.repo}"
    Release = "${var.release}"
  }
}

data archive_file package {
  output_path = "${path.module}/dist/package.zip"
  source_dir  = "${path.module}/build"
  type        = "zip"
}

data aws_secretsmanager_secret secret {
  name = "${var.app}"
}

data aws_iam_policy_document secret {
  statement {
    sid       = "GetSecretValue"
    actions   = ["secretsmanager:GetSecretValue"]
    resources = ["${data.aws_secretsmanager_secret.secret.arn}"]
  }
}

module role {
  source          = "amancevice/lambda-basic-execution-role/aws"
  version         = "0.0.2"
  name            = "${var.app}"
  inline_policies = ["${data.aws_iam_policy_document.secret.json}"]
}

resource aws_acm_certificate cert {
  domain_name               = "boston.techworkerscoalition.org"
  subject_alternative_names = ["*.boston.techworkerscoalition.org"]
  validation_method         = "DNS"
  tags                      = "${local.tags}"
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
  description = "Boston TWC website"
  name        = "website"

  endpoint_configuration {
    types = ["EDGE"]
  }
}

resource aws_cloudwatch_log_group logs {
  name              = "/aws/lambda/${aws_lambda_function.lambda.function_name}"
  retention_in_days = 30
  tags              = "${local.tags}"
}

resource aws_lambda_function lambda {
  description      = "Boston TWC Website"
  filename         = "${data.archive_file.package.output_path}"
  function_name    = "website"
  handler          = "lambda.handler"
  memory_size      = 2048
  role             = "${module.role.role_arn}"
  runtime          = "nodejs8.10"
  source_code_hash = "${data.archive_file.package.output_base64sha256}"
  tags             = "${local.tags}"
  timeout          = 30

  environment {
    variables {
      AWS_SECRET = "${data.aws_secretsmanager_secret.secret.name}"
    }
  }
}

resource aws_lambda_permission invoke {
  action        = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.lambda.arn}"
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.api.execution_arn}/*/*/*"
}

resource aws_s3_bucket bucket {
  acl    = "private"
  bucket = "${aws_api_gateway_domain_name.custom_domain.domain_name}"
  tags   = "${local.tags}"

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
}

resource aws_s3_bucket_object assets {
  count        = "${length(local.assets)}"
  acl          = "public-read"
  bucket       = "${aws_s3_bucket.bucket.bucket}"
  content_type = "image/png"
  etag         = "${md5(file("${element(local.assets, count.index)}"))}"
  key          = "website/${element(local.assets, count.index)}"
  source       = "${element(local.assets, count.index)}"
  tags         = "${local.tags}"
}
