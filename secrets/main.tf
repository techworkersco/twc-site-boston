provider aws {
  access_key = "${var.aws_access_key_id}"
  secret_key = "${var.aws_secret_access_key}"
  profile    = "${var.aws_profile}"
  region     = "${var.aws_region}"
  version    = "~> 1.57"
}

locals {
  secret {
    GOOGLE_API_KEY     = "${var.google_api_key}"
    GOOGLE_CALENDAR_ID = "${var.google_calendar_id}"
  }

  tags {
    App     = "chapter-auth"
    Repo    = "${var.repo}"
    Release = "${var.release}"
  }
}

data aws_kms_key key {
  key_id = "${var.kms_key_alias}"
}

resource aws_secretsmanager_secret secret {
  description = "${var.secret_description}"
  name        = "${var.secret_name}"
  kms_key_id  = "${data.aws_kms_key.key.id}"
  tags        = "${local.tags}"
}

resource aws_secretsmanager_secret_version version {
  secret_id     = "${aws_secretsmanager_secret.secret.id}"
  secret_string = "${jsonencode(local.secret)}"
}
