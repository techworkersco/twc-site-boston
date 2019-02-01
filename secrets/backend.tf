terraform {
  backend s3 {
    bucket  = "boston.techworkerscoalition.org"
    key     = "terraform/website-secrets.tfstate"
    region  = "us-east-1"
    profile = "twc"
  }
}
