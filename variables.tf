variable "cidr" {
  default = "10.0.0.0/16"
}

variable "region" {
  default = "us-east-1"
}

data "aws_availability_zones" "azs" {
  state = "available"
}

variable "publicroutetablecidr" {
  default = "0.0.0.0/0"
}

data "aws_ami" "my-node-ami" {
  most_recent      = true
  owners           = ["377562592179"]

  filter {
    name   = "name"
    values = ["NodeApp_*"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}