terraform {
  backend "s3" {
    bucket = "bassy-terraform-state-bucket99"
    key    = "state/terraform.tfstate"
    region = "us-east-1"
    dynamodb_table = "terraform-state-locks"
  }
}