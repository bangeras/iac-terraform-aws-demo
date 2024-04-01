env             = "dev"
aws_region      = "ap-south-1"

## Networking
vpc_suffix      = "svb"
vpc_cidr        = "10.0.0.0/16"
public_subnets_cidr = ["10.0.0.0/20", "10.0.16.0/20"]
private_subnets_cidr = ["10.0.128.0/20", "10.0.144.0/20"]


## Compute
ec2_ami = "ami-00952f27cf14db9cd"
ec2_instance_type = "t3.micro"
ec2_instance_count = 2
