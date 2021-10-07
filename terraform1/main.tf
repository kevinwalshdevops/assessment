terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}

provider "aws" {
  region = var.region
}

data "aws_canonical_user_id" "current_user" {}

resource "aws_s3_bucket" "bucket_1" {
  bucket = var.bucket_1
  acl    = "log-delivery-write"


   tags = {
    Name        = var.bucket_1_name
    Environment = var.environment_1
  }
}

resource "aws_s3_bucket" "bucket_2" {
  bucket = var.bucket_2

  website {
    index_document = "index.html"
    error_document = "error.html"

    routing_rules = <<EOF
[{
    "Condition": {
        "KeyPrefixEquals": "docs/"
    },
    "Redirect": {
        "ReplaceKeyPrefixWith": "documents/"
    }
}]
EOF
  }
  logging {
    target_bucket = aws_s3_bucket.bucket_1.id
    target_prefix = "log/"
  }

  tags = {
    Name        = var.bucket_2_name
    Environment = var.environment_2
  }
}