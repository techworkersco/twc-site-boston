output secret_arn {
  description = "SecretsManager secret ARN."
  value       = "${aws_secretsmanager_secret.secret.arn}"
}

output secret_name {
  description = "SecretsManager secret name."
  value       = "${aws_secretsmanager_secret.secret.name}"
}
