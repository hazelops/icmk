provider "aws" {
  profile = var.aws_profile
  region  = var.aws_region
}

resource "aws_key_pair" "root" {
  key_name = var.ec2_key_pair_name
  public_key = var.ssh_public_key
}

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "${var.env}-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["us-east-1a"]
  private_subnets = ["10.0.1.0/24"]
  public_subnets  = ["10.0.101.0/24"]

  enable_nat_gateway = true

  tags = {
    Terraform = "true"
    Environment = var.env
  }
}

data "aws_route53_zone" "root" {
  name         = "${var.root_domain_name}."
  private_zone = false
}

module "bastion" {
  source = "hazelops/ec2-bastion/aws"
  version = "~> 1.0"
  env = var.env
  vpc_id = module.vpc.vpc_id
  zone_id = data.aws_route53_zone.root.zone_id
  public_subnets = module.vpc.public_subnets
  ec2_key_pair_name = var.ec2_key_pair_name
  ssh_forward_rules = [
    "LocalForward 222 127.0.0.1:22"
  ]
}

output "cmd" {
  description = "Map of useful commands"
  value = {
    tunnel = module.bastion.cmd
  }
}

output "ssh_forward_config" {
  value = module.bastion.ssh_config
}
