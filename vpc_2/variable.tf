variable "aws_region" {
	default = "ap-south-1"
}

variable "vpc_cidr" {
	default = "10.20.0.0/16"
}

variable "subnets_cidr" {
	type = "list"
	default = ["10.20.1.0/24", "10.20.2.0/24"]
}

variable "azs" {
	type = "list"
	default = ["ap-south-1a", "ap-south-1b"]
}

variable "amiid" {
  default = "ami-04b2519c83e2a7ea5"
}

variable "instance_type" {
  default = "t2.micro"
}
variable "number_instances" {
  default = "1"
}
variable "key" {
default = "jmsth21t"
}
