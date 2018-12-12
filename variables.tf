variable "region" {
  description = "The AWS region."
}

variable "business_unit" {
  description = "The name of our business unit, i.e. development."
}

variable "role_arn" {
  description = "arn to use for terraform"
}

variable "environment_identifier" {
  description = "resource label or name"
}

variable "remote_state_bucket_name" {
  description = "Terraform remote state bucket name"
}

variable "tags" {
  description = "Standard tags map"
  type        = "map"
}
