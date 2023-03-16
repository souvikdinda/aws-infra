resource "random_id" "s3_bucket_name" {
  byte_length = 10
}

resource "aws_s3_bucket" "main_s3_bucket" {
  bucket        = "app-bucket-${random_id.s3_bucket_name.hex}"
  force_destroy = true

  tags = {
    "Name" = "s3_bucket"
  }
}

resource "aws_s3_bucket_public_access_block" "s3-public-access" {
  bucket = aws_s3_bucket.main_s3_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_acl" "main_s3_bucket_acl" {
  bucket = aws_s3_bucket.main_s3_bucket.id
  acl    = "private"
}

resource "aws_s3_bucket_server_side_encryption_configuration" "s3_bucket_encryption" {
  bucket = aws_s3_bucket.main_s3_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "aws:kms"
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "s3_bucket_lifecycle" {
  bucket = aws_s3_bucket.main_s3_bucket.id

  rule {
    id     = "rule-1"
    status = "Enabled"
    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }
    transition {
      days          = 60
      storage_class = "GLACIER"
    }
  }
}