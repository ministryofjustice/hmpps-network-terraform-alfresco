terraform {
  # The configuration for this backend will be filled in by Terragrunt
  # When creating comment out this bit, as terragrunt will try and create the s3 bucket and cause issues.
  # After bucket is create rename terraform.tfstate: mv terraform.tfstate terraform.tfstate1
  # Remember to comment out assume role line when running terraform
  # Below will build for dev environment
  # Run command: terraform plan -var-file env_configs/common.tfvars -var-file env_configs/dev.tfvars
  backend "s3" {}
}

provider "aws" {
  region  = "${var.region}"
  version = "~> 1.16"

  # # Comment out when using terraform only
  # assume_role {
  #   role_arn = "${var.role_arn}"
  # }
}

resource "aws_kms_key" "remote_state" {
  description             = "This key is used to encrypt ${var.remote_state_bucket_name} bucket"
  deletion_window_in_days = 10
  tags                    = "${merge(var.tags, map("Name", "${var.remote_state_bucket_name}-kms-key"))}"
}

resource "aws_kms_alias" "remote_state" {
  name          = "alias/${var.remote_state_bucket_name}-kms-key"
  target_key_id = "${aws_kms_key.remote_state.key_id}"
}

module "remote_state" {
  source                   = "git::https://github.com/ministryofjustice/hmpps-terraform-modules.git?ref=pre-shared-vpc//modules//remote_state"
  remote_state_bucket_name = "${var.remote_state_bucket_name}"
  kms_key_arn              = "${aws_kms_key.remote_state.arn}"
  tags                     = "${var.tags}"
}

module "dynamodb-table" {
  source     = "git::https://github.com/ministryofjustice/hmpps-terraform-modules.git?ref=pre-shared-vpc//modules//dynamodb-tables"
  table_name = "${var.environment_identifier}-lock-table"
  tags       = "${var.tags}"
  hash_key   = "LockID"
}
