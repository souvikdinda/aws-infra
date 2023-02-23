# Creating VPC
resource "aws_vpc" "main_vpc" {
  cidr_block = "${var.cidr}"
  instance_tenancy = "default"

  tags = {
    "Name" = "Main-VPC"
  }
}

# Creating Subnets via modules
module "subnets" {
  source = "./modules/subnets"
  count = "${min(length(data.aws_availability_zones.azs.names),3)}"

  vpc_id = "${aws_vpc.main_vpc.id}"
  availability_zone = "${element(data.aws_availability_zones.azs.names, count.index)}"
  index = "${count.index}"
  
}

# Creating Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = "${aws_vpc.main_vpc.id}"

  tags = {
    Name = "Internet Gateway"
  }
}

module "routeTables" {
  source = "./modules/routeTables"
  vpc_id = "${aws_vpc.main_vpc.id}"
  publicroutetablecidr = "${var.publicroutetablecidr}"
  igw_id = "${aws_internet_gateway.igw.id}"
  public_subnet_id = "${module.subnets.*.public-subnets-id}"
  private_subnet_id = "${module.subnets.*.private-subnets-id}"
}

# Creating key pair to enable ssh connection to ec2 instance
resource "aws_key_pair" "ec2" {
  key_name   = "connection-key"
  public_key = "${file("~/.ssh/ec2.pub")}"
}

# Creating security group for VPC
resource "aws_security_group" "application" {
  vpc_id = "${aws_vpc.main_vpc.id}"

  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = [ "0.0.0.0/0" ]
    ipv6_cidr_blocks = [ "::/0" ]
  }

  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = [ "0.0.0.0/0" ]
    ipv6_cidr_blocks = [ "::/0" ]
  }

  ingress {
    from_port = 443
    to_port = 443
    protocol = "tcp"
    cidr_blocks = [ "0.0.0.0/0" ]
    ipv6_cidr_blocks = [ "::/0" ]
  }

  ingress {
    from_port = 8080
    to_port = 8080
    protocol = "tcp"
    cidr_blocks = [ "0.0.0.0/0" ]
    ipv6_cidr_blocks = [ "::/0" ]
  }

  egress {
    cidr_blocks = [ "0.0.0.0/0" ]
    from_port = 0
    ipv6_cidr_blocks = [ "::/0" ]
    protocol = -1
    to_port = 0
  }

  tags = {
    "Name" = "application"
  }
}

# Creating ec2 instance for latest ami available
resource "aws_instance" "my_ec2_instance" {
  ami = "${data.aws_ami.my-node-ami.id}"
  instance_type = "t2.micro"
  disable_api_termination = false
  root_block_device {
    volume_size = 50
    volume_type = "gp2"
    delete_on_termination = true
  }
  subnet_id = "${module.subnets[0].public-subnets-id}"
  security_groups = ["${aws_security_group.application.id}"]
  key_name = "${aws_key_pair.ec2.key_name}"
  tags = {
    "Name" = "Application Server"
  }
}