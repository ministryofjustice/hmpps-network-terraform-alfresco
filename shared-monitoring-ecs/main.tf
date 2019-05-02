terraform {
  # The configuration for this backend will be filled in by Terragrunt
  backend "s3" {}
}

provider "aws" {
  region  = "${var.region}"
  version = "~> 1.16"
}

####################################################
# DATA SOURCE MODULES FROM OTHER TERRAFORM BACKENDS
####################################################

#-------------------------------------------------------------
### Getting the current running account id
#-------------------------------------------------------------
data "aws_caller_identity" "current" {}

#-------------------------------------------------------------
### Getting the common details
#-------------------------------------------------------------
data "terraform_remote_state" "vpc" {
  backend = "s3"

  config {
    bucket = "${var.remote_state_bucket_name}"
    key    = "vpc/terraform.tfstate"
    region = "${var.region}"
  }
}

# #-------------------------------------------------------------
# ### Getting the efs details
# #-------------------------------------------------------------
# data "terraform_remote_state" "efs" {
#   backend = "s3"

#   config {
#     bucket = "${var.remote_state_bucket_name}"
#     key    = "alfresco/efs/terraform.tfstate"
#     region = "${var.region}"
#   }
# }

#-------------------------------------------------------------
### Getting the security groups details
#-------------------------------------------------------------
data "terraform_remote_state" "security-groups" {
  backend = "s3"

  config {
    bucket = "${var.remote_state_bucket_name}"
    key    = "security-groups/terraform.tfstate"
    region = "${var.region}"
  }
}

#-------------------------------------------------------------
### Getting the latest amazon ami
#-------------------------------------------------------------

data "aws_ami" "ecs_ami" {
  most_recent = true

  filter {
    name   = "name"
    values = ["HMPPS ECS Centos master*"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  owners = ["${data.terraform_remote_state.vpc.vpc_account_id}", "895523100917"] # MOJ
}

#-------------------------------------------------------------
### Getting ACM Cert
#-------------------------------------------------------------
data "aws_acm_certificate" "cert" {
  domain      = "*.${data.terraform_remote_state.vpc.public_zone_name}"
  types       = ["AMAZON_ISSUED"]
  most_recent = true
}

####################################################
# Locals
####################################################

locals {
  ami_id                       = "${data.aws_ami.ecs_ami.id}"
  application                  = "elasticsearch"
  cidr_block                   = "${data.terraform_remote_state.vpc.vpc_cidr_block}"
  vpc_id                       = "${data.terraform_remote_state.vpc.vpc_id}"
  account_id                   = "${data.terraform_remote_state.vpc.vpc_account_id}"
  sg_bastion_in_id             = "${data.terraform_remote_state.security-groups.sg_ssh_bastion_in_id}"
  environment_identifier       = "${var.environment_identifier}"
  short_environment_identifier = "${var.short_environment_identifier}"
  lb_security_groups           = ["${data.terraform_remote_state.security-groups.sg_monitoring_elb}"]
  common_name                  = "${local.short_environment_identifier}-elk"
  certificate_arn              = "${data.aws_acm_certificate.cert.arn}"
  environment                  = "${var.environment_type}"
  image_url                    = "${var.es_image_url}"
  allowed_cidr_block           = ["${data.terraform_remote_state.vpc.vpc_cidr_block}"]
  internal_domain              = "${data.terraform_remote_state.vpc.private_zone_name}"
  private_zone_id              = "${data.terraform_remote_state.vpc.private_zone_id}"
  external_domain              = "${data.terraform_remote_state.vpc.public_zone_name}"
  public_zone_id               = "${data.terraform_remote_state.vpc.public_zone_id}"
  containerport                = 9200
  service_desired_count        = "${var.es_service_desired_count}"
  region                       = "${var.region}"

  private_subnet_ids = [
    "${data.terraform_remote_state.vpc.vpc_private-subnet-az1}",
    "${data.terraform_remote_state.vpc.vpc_private-subnet-az2}",
    "${data.terraform_remote_state.vpc.vpc_private-subnet-az3}",
  ]

  tags = "${data.terraform_remote_state.vpc.tags}"
}

# locals {
#   allowed_cidr_block           = ["${data.terraform_remote_state.vpc.vpc_cidr_block}"]
#   internal_domain              = "${data.terraform_remote_state.vpc.internal_domain}"
#   external_domain              = "${data.terraform_remote_state.vpc.external_domain}"
#   environment_identifier       = "${data.terraform_remote_state.vpc.environment_identifier}"
#   short_environment_identifier = "${data.terraform_remote_state.vpc.short_environment_identifier}"
#   region                       = "${var.region}"
#   alfresco_app_name            = "${data.terraform_remote_state.vpc.alfresco_app_name}"
#   environment                  = "${data.terraform_remote_state.vpc.environment}"
#   instance_profile             = "${data.terraform_remote_state.iam.iam_instance_ecs_es_profile_name}"
#   access_logs_bucket           = "${data.terraform_remote_state.vpc.common_s3_lb_logs_bucket}"
#   ssh_deployer_key             = "${data.terraform_remote_state.vpc.common_ssh_deployer_key}"
#   s3bucket_kms_id              = "${data.terraform_remote_state.s3bucket.s3bucket_kms_id}"
#   s3bucket                     = "${data.terraform_remote_state.s3bucket.s3bucket}"
#   app_hostnames                = "${data.terraform_remote_state.vpc.app_hostnames}"
#   bastion_inventory            = "${var.bastion_inventory}"
#   application                  = "elasticsearch"
#   image_version                = "latest"
#   config-bucket                = "${data.terraform_remote_state.vpc.common_s3-config-bucket}"
#   public_subnet_ids            = ["${data.terraform_remote_state.vpc.public_subnet_ids}"]
#   ecs_service_role             = "${data.terraform_remote_state.iam.iam_service_ecs_es_role_arn}"
#   ecs_instance_role            = "${data.terraform_remote_state.iam.iam_instance_ecs_es_role_arn}"


#   instance_security_groups = [
#     bastion_in_sg_id    = "${data.terraform_remote_state.security-groups.sg_ssh_bastion_in_id} 
#     "${data.terraform_remote_state.security-groups.security_groups_sg_efs_sg_id}",
#     "${data.terraform_remote_state.vpc.common_sg_outbound_id}",
#     "${data.terraform_remote_state.vpc.monitoring_server_client_sg_id}",
#   ]
# }
