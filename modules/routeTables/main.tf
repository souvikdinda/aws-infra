# Route Table for Public Subnet
resource "aws_route_table" "public" {
  vpc_id = "${var.vpc_id}"

  route {
    cidr_block = "${var.publicroutetablecidr}"
    gateway_id = "${var.igw_id}"
  }

  tags = {
    Name = "Public Route Table"
  }
}

# Route Table for Private Subnet
resource "aws_route_table" "private" {
  vpc_id = "${var.vpc_id}"

  tags = {
    Name = "Private Route Table"
  }
}

module "route-table-association" {
  source = "./routeTableAssociation"
  public_subnet_id = "${var.public_subnet_id}"
  private_subnet_id = "${var.private_subnet_id}"
  public_route_table_id = "${aws_route_table.public.id}"
  private_route_table_id = "${aws_route_table.private.id}"
}

