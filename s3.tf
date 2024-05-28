variable "bucket_name" {}
variable "iam_user" {}
variable "region" {}
variable "Environment" {}

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region  = var.region
}

resource "aws_s3_bucket" "buckt_logs" {

   bucket = var.bucket_name
   force_destroy = true
   acl = "private"
   tags = {
    Name        = "bucket"
    Environment = "var.Environment"
  }

}


resource "aws_s3_bucket_versioning" "versioning" {
  bucket = aws_s3_bucket.buckt_logs.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_ownership_controls" "enforced" {
  bucket = aws_s3_bucket.buckt_logs.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}
  

data "aws_iam_user" "iam_user" {
  user_name = var.iam_user
}


resource "aws_s3_object" "logs_directory" {
  bucket = aws_s3_bucket.buckt_logs.bucket
  key    = "logs/"
}

data "aws_iam_policy_document" "logs_upload_policy" {
  statement {
     sid  = "111"
     effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = [data.aws_iam_user.iam_user.arn]
    }

    actions = [
    "s3:PutObject"
    ]

    resources = [
      "${aws_s3_bucket.buckt_logs.arn}/logs/*"
    ]
  }
}

resource "aws_s3_bucket_policy" "policy" {
    bucket = aws_s3_bucket.buckt_logs.id
    policy = data.aws_iam_policy_document.logs_upload_policy.json
 }
