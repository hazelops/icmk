variable "env" {}
variable "aws_profile" {}
variable "aws_region" {}
variable "ssh_public_key" {}
variable "ec2_key_pair_name" {
  default = "nutcorp"
}
variable "root_domain_name" {
  default = "nutcorp.net"
}
