terraform {
  required_version = "~> 0.10.0"
}

# S3 buckets
provider "aws" {
  version = "= 1.1"
  alias  = "virginia"
  region = "us-east-2"
}

provider "random" {}

data "aws_caller_identity" "creds" {}
output "aws_account_id" {
  value = "${data.aws_caller_identity.creds.account_id}"
}
