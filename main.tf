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



# # Route Table for Public Subnet
# resource "aws_route_table" "public" {
#   vpc_id = "${aws_vpc.main_vpc.id}"

#   route {
#     cidr_block = "${var.publicroutetablecidr}"
#     gateway_id = "${aws_internet_gateway.igw.id}"
#   }

#   tags = {
#     Name = "Public Route Table"
#   }
# }

# # Association between Public Subnet and Public Route Table
# resource "aws_route_table_association" "public" {
#     count = "${min(length(data.aws_availability_zones.azs.names),3)}"
#     subnet_id      = "${element(module.subnets.*.public-subnets-id, count.index)}"
#     route_table_id = "${aws_route_table.public.id}"
# }

# # Route Table for Private Subnet
# resource "aws_route_table" "private" {
#   vpc_id = "${aws_vpc.main_vpc.id}"

#   tags = {
#     Name = "Private Route Table"
#   }
# }

# # Association between Private Subnet and Priavte Route Table
# resource "aws_route_table_association" "private" {
#     count = "${min(length(data.aws_availability_zones.azs.names),3)}"
#     subnet_id      = "${element(module.subnets.*.private-subnets-id, count.index)}"
#     route_table_id = "${aws_route_table.private.id}"
# }

