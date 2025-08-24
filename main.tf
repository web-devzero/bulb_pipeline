provider "aws" {
  region     = "us-east-1"
}

resource "aws_s3_bucket" "basxy_test_bucket" {
  bucket = "basxy-test-bucket"

  tags = {
    Name        = "basxy-test-bucket"
    Environment = "Dev"
  }
}