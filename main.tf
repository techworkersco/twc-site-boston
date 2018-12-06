provider archive {
  version = "~> 1.1"
}

provider aws {
  version    = "~> 1.50"
  access_key = "${var.aws_access_key_id}"
  secret_key = "${var.aws_secret_access_key}"
  profile    = "${var.aws_profile}"
  region     = "${var.aws_region}"
}

locals {
  package = "website-${var.version}.zip"
  assets = [
    "assets/event-2018-10-28.png",
    "assets/event-2018-12-09.png",
    "assets/event-2018-12-11.png",
  ]
}

data archive_file package {
  output_path = "${path.module}/dist/${local.package}"
  source_dir  = "${path.module}/src"
  type        = "zip"
}

data aws_caller_identity current {
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

resource aws_cloudwatch_log_group logs {
  name              = "/aws/lambda/${aws_lambda_function.lambda.function_name}"
  retention_in_days = 30
}

resource aws_lambda_function lambda {
  description       = "Boston TWC Website"
  function_name     = "website"
  handler           = "lambda.handler"
  memory_size       = 512
  role              = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/AWSLambdaBasicExecution"
  runtime           = "nodejs8.10"
  s3_bucket         = "${aws_s3_bucket_object.package.bucket}"
  s3_key            = "${aws_s3_bucket_object.package.key}"
  s3_object_version = "${aws_s3_bucket_object.package.version_id}"
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
  bucket = "${var.s3_bucket}"

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
}

resource aws_s3_bucket_object package {
  bucket       = "${aws_s3_bucket.bucket.bucket}"
  content_type = "application/zip"
  etag         = "${data.archive_file.package.output_md5}"
  key          = "website/${local.package}"
  source       = "${data.archive_file.package.output_path}"
}

resource aws_s3_bucket_object assets {
  count        = "${length(local.assets)}"
  acl          = "public-read"
  bucket       = "${aws_s3_bucket.bucket.bucket}"
  content_type = "image/png"
  etag         = "${md5(file("${element(local.assets, count.index)}"))}"
  key          = "website/${element(local.assets, count.index)}"
  source       = "${element(local.assets, count.index)}"
}
