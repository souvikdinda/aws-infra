resource "aws_subnet" "private-subnets" {
    vpc_id = "${var.vpc_id}"
    availability_zone = "${var.availability_zone}"
    cidr_block = "${cidrsubnet(var.cidr, 8, (var.index*2 + 1) )}"

    tags = {
        Name = "private-subnet-${var.index + 1}"
    }
}

resource "aws_subnet" "public-subnets" {
    vpc_id = "${var.vpc_id}"
    availability_zone = "${var.availability_zone}"
    cidr_block = "${cidrsubnet(var.cidr, 8, (var.index*2+2))}"
    map_public_ip_on_launch = true
    tags = {
        Name = "public-subnet-${var.index + 1}"
    }
}

output "public-subnets-id" {
  value = "${aws_subnet.public-subnets.id}"
}

output "private-subnets-id" {
  value = "${aws_subnet.private-subnets.id}"
}