# Generated by Terragrunt. Sig: nIlQXj57tbuaRZEa
terraform {
  backend "s3" {
    encrypt        = true
    key            = "internetgateway/terraform.tfstate"
    region         = "eu-west-2"
    bucket         = "tf-alfresco-dev-remote-state"
    dynamodb_table = "tf-alfresco-dev-lock-table"
  }
}
