resource "aws_db_parameter_group" "db_parameters" {
  name        = "mysql"
  description = "Parameter group for RDS instance"
  family      = "mysql8.0"
  lifecycle {
    create_before_destroy = true
  }
  tags = {
    Name = "RDS Paramater Group"
  }
}

resource "aws_db_subnet_group" "db_subnet" {
  name       = "rds-subnet-group"
  subnet_ids = ["${module.subnets[0].private-subnets-id}", "${module.subnets[1].private-subnets-id}"]
}

resource "aws_db_instance" "app_db" {
  identifier             = "csye6225"
  engine                 = var.configuration.database.engine
  instance_class         = var.configuration.database.instance_class
  multi_az               = false
  db_name                = var.configuration.database.db_name
  username               = var.db_username
  password               = var.db_password
  allocated_storage      = var.configuration.database.allocated_storage
  apply_immediately      = true
  db_subnet_group_name   = aws_db_subnet_group.db_subnet.id
  publicly_accessible    = false
  parameter_group_name   = aws_db_parameter_group.db_parameters.id
  vpc_security_group_ids = ["${aws_security_group.database.id}"]
  skip_final_snapshot    = true
}
