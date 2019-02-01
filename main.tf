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
  ]

  tags {
    App     = "boston.techworkerscoalition.org"
    Repo    = "${var.repo}"
    Release = "${var.release}"
  }
}

data archive_file package {
  output_path = "${path.module}/dist/package.zip"
  source_dir  = "${path.module}/build"
  type        = "zip"
}

data aws_iam_role role {
  name = "AWSLambdaBasicExecution"
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
  memory_size      = 512
  role             = "${data.aws_iam_role.role.arn}"
  runtime          = "nodejs8.10"
  source_code_hash = "${data.archive_file.package.output_base64sha256}"
  tags             = "${local.tags}"

  environment {
    variables {
      GOOGLE_API_KEY     = "${var.google_api_key}"
      GOOGLE_CALENDAR_ID = "${var.google_calendar_id}"
      HOST               = "${var.host}"
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
  bucket = "${var.s3_bucket}"
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
