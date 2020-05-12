provider "aws" {
region = "ap-south-1"
}
# This is a single-line comment.
resource "aws_instance" "base" {
ami = "ami-04b2519c83e2a7ea5"
instance_type = "t2.micro"
key_name = "${aws_key_pair.keypair.key_name}"
vpc_security_group_ids = [aws_security_group.allow_ports.id]
user_data= <<-EOF
             #!/bin/bash
              yum install httpd -y
              echo "hey i am $(hostname -f)" > /var/www/html/index.html
              service httpd start
              chkconfig httpd on
EOF
tags = {
   Name = "jmsth21"
}
}

resource "aws_key_pair" "keypair" {
  key_name   = "jmsth21t"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDL0+znf/BJn4/QXO/oAtkHhjAWgLfRFgF3FkSS27nBKq3sH/gb9DzMpOqkrvd1vzX0UWdRBIASQCeeQh3GoXoHANIhDGDtlhXEHrySQTk3F9xOs/B9yzJ6C1bnb5ApY2LO0Xh5NbOMmzyVZ+WiKtKhcY+x9KPTXu18sL0Ax2jFeXXD5ZkF1ro47Er+pHMAD6gKftv2SQHTaDQanynYOvrCOjwTg+WYT68tqX4ZF6Yf99IfZtPuavL3zn6gJEgPjwGMhpXnNW0hIHDDvq4FPHy4JTd4ONqtSmIjl6bTX40PgBFzRf6/jt6g/UgT9gvpx4hDye7yMMT77xQtDmO3xNlD ec2-user@ip-172-31-12-66"
}
resource "aws_eip" "myeip" {
  vpc = true
  instance = "${aws_instance.base.id}"
}
resource "aws_default_vpc" "default" {
  tags = {
    Name = "Default VPC"
  }
}
resource "aws_security_group" "allow_ports" {
  name        = "allow_ports1"
  description = "Allow inbound traffic"
  vpc_id      = "${aws_default_vpc.default.id}"
  ingress {
    description = "http from VPC"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "tomcat port from VPC"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
}

  ingress {
    description = "TLS from VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow_ports"
  }
}

resource "aws_s3_bucket" "bucket" {
  bucket = "jmsth21-bucket"
  acl    = "public-read"
  website {
    index_document = "index.html"
    error_document = "error.html"
    }
  versioning {
    enabled = true
  }
  tags = {
    Name        = "My bucket"
    Environment = "Dev"
  }
}

resource "aws_s3_bucket_object" "test" {
  for_each = fileset(path.module, "*.html")
  bucket = aws_s3_bucket.bucket.bucket
  key    = each.value
  source = "${path.module}/${each.value}"
}

output "fileset-results" {
  value = fileset(path.module, "*.html")
}

resource "aws_s3_bucket_policy" "default" {
  bucket = aws_s3_bucket.bucket.id
  policy = data.aws_iam_policy_document.default.json
}

data "aws_iam_policy_document" "default" {
  statement {
    actions = ["s3:GetObject"]

    resources = ["${aws_s3_bucket.bucket.arn}/*"]

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
  }
}
