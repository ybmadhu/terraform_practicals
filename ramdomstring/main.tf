provider "aws" {
  region = "ap-south-1"
}
resource "random_string" "string" {
  length = 8
}

output "o" {
  value = "${random_string.string.result}"
}
provider "random" {}

resource "random_id" "s3-suffix" {
  byte_length = 5
}
resource "aws_s3_bucket" "bucket" {
  bucket = "my-tf-test-bucket-${random_id.s3-suffix.dec}"
  acl    = "private"

  tags = {
    Name        = "My bucket"
    Environment = "Dev"
  }
}
