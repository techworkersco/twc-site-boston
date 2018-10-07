terraform {
  backend s3 {
    bucket = "terraform.boston.techworkerscoalition.org"
    key    = "website.tfstate"
    region = "us-east-1"
  }
}
