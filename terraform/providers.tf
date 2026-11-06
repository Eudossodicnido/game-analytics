terraform {
  required_version = "~>1.16"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~>6.0"
    }
  }
  backend "s3" {
    bucket       = "tfstate-649473075374-eu-central-1-an"
    key          = "game-analytics/prod/terraform.tfstate"
    region       = "eu-central-1"
    use_lockfile = true

    assume_role = {
      role_arn = "arn:aws:iam::649473075374:role/game-analytics-terraform-role"
    }
  }
}

provider "aws" {
  region = "eu-central-1"

  assume_role {
    role_arn = "arn:aws:iam::649473075374:role/game-analytics-terraform-role"
  }
}

