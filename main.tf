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

resource "aws_cloudwatch_log_group" "csye6225" {
  name = "csye6225"
  lifecycle {
    prevent_destroy = false
  }
}

resource "aws_route53_record" "route53-record" {
  zone_id = data.aws_route53_zone.zone_name.zone_id
  name    = data.aws_route53_zone.zone_name.name
  type    = "A"

  alias {
    name                   = aws_lb.applicationLoadBalancer.dns_name
    zone_id                = aws_lb.applicationLoadBalancer.zone_id
    evaluate_target_health = true
  }

}