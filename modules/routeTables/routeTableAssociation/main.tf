# Association between Public Subnet and Public Route Table
resource "aws_route_table_association" "public" {
    count = "${length(var.public_subnet_id)}"
    subnet_id      = "${element(var.public_subnet_id.*, count.index)}"
    route_table_id = "${var.public_route_table_id}"
}

# Association between Private Subnet and Priavte Route Table
resource "aws_route_table_association" "private" {
    count = "${length(var.private_subnet_id)}"
    subnet_id      = "${element(var.private_subnet_id.*, count.index)}"
    route_table_id = "${var.private_route_table_id}"
}