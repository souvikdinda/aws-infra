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
  most_recent = true
  owners      = ["377562592179"]

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

variable "configuration" {
  description = "Configuration Settings"
  type        = map(any)
  default = {
    "database" = {
      allocated_storage   = 20
      engine              = "mysql"
      instance_class      = "db.t3.micro"
      db_name             = "csye6225"
      skip_final_snapshot = true
    },
    "ec2_instance" = {
      instance_type = "t2.micro"
      volume_size   = 50
      volume_type   = "gp2"
    }
  }
}

variable "db_username" {
  type    = string
  default = "csye6225"
}

variable "db_password" {
  type    = string
  default = "Passw0rd#123"
}

variable "hosted_zone_id" {
  type    = string
  default = "Z056114913N7ZVZ9CPNAB"
}

variable "hosted_zone_name" {
  type    = string
  default = "dev.souvikdinda.me"
}