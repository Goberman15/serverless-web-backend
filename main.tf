terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~>5.29.0"
    }
  }

  backend "s3" {
    bucket         = "remote-state-tf-1523"
    key            = "project/serverless-web-backend"
    region         = "ap-southeast-1"
    dynamodb_table = "tf-locks-table"
    encrypt        = true
  }
}

data "aws_caller_identity" "me" {

}
