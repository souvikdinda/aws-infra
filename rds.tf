resource "aws_kms_key" "rds_encryption_key" {
  description             = "KMS key for RDS instance"
  enable_key_rotation     = false

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "Enable IAM User Permissions"
        Effect    = "Allow"
        Principal = { AWS = "*" }
        Action    = "kms:*"
        Resource  = "*"
      },
      {
        Sid       = "Allow usage of the key for RDS"
        Effect    = "Allow"
        Principal = {
          AWS = ["arn:aws:iam::${local.aws_account_id}:root"]
        }
        Action    = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ]
        Resource = "*"
      }
    ]
  })
}

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
  storage_encrypted = true
  kms_key_id = aws_kms_key.rds_encryption_key.arn
}
