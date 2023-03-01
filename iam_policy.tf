resource "aws_iam_policy" "webapps3" {
  name        = "WebAppS3"
  path        = "/"
  description = "IAM Policy for S3 bucket"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid    = "WebAppS3BucketPolicy"
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:DeleteObject"
        ]
        Resource = [
          "arn:aws:s3:::${aws_s3_bucket.main_s3_bucket.id}",
          "arn:aws:s3:::${aws_s3_bucket.main_s3_bucket.id}/*"
        ]
      }
    ]
  })
}

resource "aws_iam_role" "ec2-csye6225" {
  name        = "EC2-CSYE6225"
  description = "IAM Role for EC2 service"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })

  tags = {
    "Name" = "EC2-CSYE6225"
  }
}

resource "aws_iam_policy_attachment" "policy-attachment" {
  name       = "S3PolicyAttachment"
  roles      = ["${aws_iam_role.ec2-csye6225.name}"]
  policy_arn = aws_iam_policy.webapps3.arn
}