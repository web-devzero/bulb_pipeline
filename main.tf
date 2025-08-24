provider "aws" {
  region     = "us-east-1"
}

resource "aws_s3_bucket" "artifact_bucket" {
  bucket = "basxy-pipelinerole-artifact-bucket"

  tags = {
    Name        = "basxy-pipelinerole-artifact-bucket"
    Environment = "Dev"
  }
}