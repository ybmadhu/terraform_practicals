variable "no-of-instances" {
    default = 1
 }
variable "region" {
  description = "AWS region for hosting our your network"
  default = "ap-south-1"
}
variable "public_key_path" {
  description = "mykey file path"
  default = "/home/ec2-user/terraform_practicals/base/jmsth21t.pem"
}
variable "key_name" {
  description = "Key name for SSHing into EC2"
  default = "jmsth21t"
}
variable "amiid" {
  description = "Base ami to launch the instances"
  default = "ami-04b2519c83e2a7ea5"
}
