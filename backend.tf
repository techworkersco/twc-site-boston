terraform {
  backend s3 {
    bucket  = "boston.techworkerscoalition.org"
    key     = "website/terraform.tfstate"
    region  = "us-east-1"
    profile = "twc"
  }
}
