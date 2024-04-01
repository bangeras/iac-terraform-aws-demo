variable "aws_region" {
  type        = string
  description = "AWS Region"
}

variable "env" {
  type        = string
  description = "Deployment environment"
}

## Networking
variable "vpc_suffix" {
  type        = string
  description = "Suffix name tag used for naming all VPC resources"
}

variable "vpc_cidr" {
  type        = string
  description = "CIDR block of the vpc"
}

variable "public_subnets_cidr" {
  type        = list(string)
  description = "Public Subnet CIDR values"
}

variable "private_subnets_cidr" {
  type        = list(string)
  description = "Private Subnet CIDR values"
}

## EC2
variable "ec2_ami" {
  type        = string
  description = "EC2 Instance AMI"
}

variable "ec2_instance_type" {
  type        = string
  description = "EC2 Instance Type"
}

variable "ec2_instance_count" {
  type        = number
  description = "EC2 Instance Count"
}

locals {
  availability_zones = ["${var.aws_region}a", "${var.aws_region}b"]
  public_subnets     = ["${var.vpc_suffix}-subnet-public1-${var.aws_region}a", "${var.vpc_suffix}-subnet-public2-${var.aws_region}b"]
  private_subnets    = ["${var.vpc_suffix}-subnet-private1-${var.aws_region}a", "${var.vpc_suffix}-subnet-private2-${var.aws_region}b"]
}


