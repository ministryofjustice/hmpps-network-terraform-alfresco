terraform {
  # The configuration for this backend will be filled in by Terragrunt
  backend "s3" {}
}

provider "aws" {
  region  = "${var.region}"
  version = "~> 1.16"
}

#-------------------------------------------------------------
### Getting the current running account id
#-------------------------------------------------------------
data "aws_caller_identity" "current" {}
