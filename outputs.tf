output cert_arn {
  description = "ACM certificate ARN."
  value       = "${aws_acm_certificate.cert.arn}"
}

output domain_name {
  description = "API Gateway custom domain."
  value       = "${aws_api_gateway_domain_name.custom_domain.domain_name}"
}

output lambda_function_arn {
  description = "Lambda function ARN."
  value       = "${aws_lambda_function.lambda.arn}"
}

output lambda_function_name {
  description = "Lambda function name."
  value       = "${aws_lambda_function.lambda.function_name}"
}

output s3_bucket {
  description = "S3 bucket."
  value       = "${aws_s3_bucket.bucket.bucket}"
}
