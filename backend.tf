terraform {
  backend s3 {
    bucket  = "boston.techworkerscoalition.org"
    key     = "terraform/website.tfstate"
    region  = "us-east-1"
    profile = "twc"
  }
}
