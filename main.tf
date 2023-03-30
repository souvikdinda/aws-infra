# Creating VPC
resource "aws_vpc" "main_vpc" {
  cidr_block       = var.cidr
  instance_tenancy = "default"

  tags = {
    "Name" = "Main-VPC"
  }
}

# Creating Subnets via modules
module "subnets" {
  source = "./modules/subnets"
  count  = min(length(data.aws_availability_zones.azs.names), 3)

  vpc_id            = aws_vpc.main_vpc.id
  availability_zone = element(data.aws_availability_zones.azs.names, count.index)
  index             = count.index

}

# Creating Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main_vpc.id

  tags = {
    Name = "Internet Gateway"
  }
}

module "routeTables" {
  source               = "./modules/routeTables"
  vpc_id               = aws_vpc.main_vpc.id
  publicroutetablecidr = var.publicroutetablecidr
  igw_id               = aws_internet_gateway.igw.id
  public_subnet_id     = module.subnets.*.public-subnets-id
  private_subnet_id    = module.subnets.*.private-subnets-id
}

# Creating key pair to enable ssh connection to ec2 instance
resource "aws_key_pair" "ec2" {
  key_name   = "connection-key"
  public_key = file("~/.ssh/ec2.pub")
}

# Creating security group for VPC
resource "aws_security_group" "application" {
  vpc_id = aws_vpc.main_vpc.id
  name   = "application"

  ingress {
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    from_port        = 8080
    to_port          = 8080
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    cidr_blocks      = ["0.0.0.0/0"]
    from_port        = 0
    ipv6_cidr_blocks = ["::/0"]
    protocol         = -1
    to_port          = 0
  }

  tags = {
    "Name" = "application"
  }
}

# DB security group
resource "aws_security_group" "database" {
  name   = "database"
  vpc_id = aws_vpc.main_vpc.id

  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.application.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]

  }

  tags = {
    "Name" = "database"
  }
}

# Creating ec2 instance for latest ami available
resource "aws_instance" "my_ec2_instance" {
  ami = data.aws_ami.my-node-ami.id
  # ami                     = "ami-0dfcb1ef8550277af"
  instance_type           = var.configuration.ec2_instance.instance_type
  disable_api_termination = false
  root_block_device {
    volume_size           = var.configuration.ec2_instance.volume_size
    volume_type           = var.configuration.ec2_instance.volume_type
    delete_on_termination = true
  }
  subnet_id            = module.subnets[0].public-subnets-id
  security_groups      = ["${aws_security_group.application.id}"]
  key_name             = aws_key_pair.ec2.key_name
  iam_instance_profile = aws_iam_instance_profile.ec2-profile.name

  user_data = <<EOF
  #!/bin/bash

  echo "==================================="
  echo "Creating .env file to webapp"
  echo "==================================="
  touch /home/ec2-user/webapp/.env
  echo -e "PORT=8080\nDB_HOSTNAME=${aws_db_instance.app_db.address}\nDB_PORT=3306\nDB_USERNAME=${var.db_username}\nDB_PASSWORD=\"${var.db_password}\"\nDB_DBNAME=${var.configuration.database.db_name}\nAWS_BUCKET_NAME=${aws_s3_bucket.main_s3_bucket.bucket}\nAWS_BUCKET_REGION=${var.region}\nENVIRONMENT=production\nMETRICS_HOSTNAME=localhost\nMETRICS_PORT=8125" > /home/ec2-user/webapp/.env

  echo "==================================="
  echo "Chaning application ownership"
  echo "==================================="
  sudo chmod -R 755 /home/ec2-user/webapp

  echo "================================="
  echo "Configuring cloudwatch"
  echo "================================="
  sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
  -a fetch-config \
  -m ec2 \
  -c file:/home/ec2-user/webapp/api/cloudwatch/config.json \
  -s

  EOF

  tags = {
    "Name" = "Application Server"
  }
}

resource "aws_route53_record" "route53-record" {
  zone_id = var.hosted_zone_id
  name    = var.hosted_zone_name
  type    = "A"
  ttl     = 60

  records = [aws_instance.my_ec2_instance.public_ip]
}