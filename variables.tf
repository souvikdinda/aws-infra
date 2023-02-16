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