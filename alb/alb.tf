provider "aws" {
region = "ap-south-1"
}
# This is a single-line comment.
resource "aws_instance" "base" {
ami = "ami-04b2519c83e2a7ea5"
instance_type = "t2.micro"
count  = 2
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
   Name = "jmsth21_9pm${count.index}"
}
}

resource "aws_key_pair" "keypair" {
  key_name   = "jmsth219pm"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDL0+znf/BJn4/QXO/oAtkHhjAWgLfRFgF3FkSS27nBKq3sH/gb9DzMpOqkrvd1vzX0UWdRBIASQCeeQh3GoXoHANIhDGDtlhXEHrySQTk3F9xOs/B9yzJ6C1bnb5ApY2LO0Xh5NbOMmzyVZ+WiKtKhcY+x9KPTXu18sL0Ax2jFeXXD5ZkF1ro47Er+pHMAD6gKftv2SQHTaDQanynYOvrCOjwTg+WYT68tqX4ZF6Yf99IfZtPuavL3zn6gJEgPjwGMhpXnNW0hIHDDvq4FPHy4JTd4ONqtSmIjl6bTX40PgBFzRf6/jt6g/UgT9gvpx4hDye7yMMT77xQtDmO3xNlD ec2-user@ip-172-31-12-66"
}
resource "aws_eip" "myeip" {
  count = length(aws_instance.base)
  vpc = true
  instance = "${element(aws_instance.base.*.id,count.index)}"
  
   tags = {
    Name = "eip-jmsth21_9pm${count.index + 1}"
  }
 }
resource "aws_default_vpc" "default" {
  tags = {
    Name = "Default VPC"
  }
}
resource "aws_security_group" "allow_ports" {
  name        = "alb"
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
data "aws_subnet_ids" "subnet" {
  vpc_id = "${aws_default_vpc.default.id}"

}
resource "aws_lb_target_group" "my-target-group" {
  health_check {
    interval            = 10
    path                = "/"
    protocol            = "HTTP"
    timeout             = 5
    healthy_threshold   = 5
    unhealthy_threshold = 2
  }

  name        = "my-test-tg"
  port        = 80
  protocol    = "HTTP"
  target_type = "instance"
  vpc_id      = "${aws_default_vpc.default.id}"
}

resource "aws_lb" "my-aws-alb" {
  name     = "jmsth-test-alb"
  internal = false
  security_groups = [
    "${aws_security_group.allow_ports.id}",
  ]

  subnets = data.aws_subnet_ids.subnet.ids
  tags = {
    Name = "jmsth-test-alb"
  }

  ip_address_type    = "ipv4"
  load_balancer_type = "application"
}

resource "aws_lb_listener" "jmsth-test-alb-listner" {
  
 load_balancer_arn = aws_lb.my-aws-alb.arn
      port                = 80
      protocol            = "HTTP"
      default_action {
        target_group_arn = "${aws_lb_target_group.my-target-group.arn}"
        type             = "forward"
      }
}
resource "aws_alb_target_group_attachment" "ec2_attach" {
  count = length(aws_instance.base)
  target_group_arn = aws_lb_target_group.my-target-group.arn
  target_id = aws_instance.base[count.index].id
}
