# Creating key pair to enable ssh connection to ec2 instance
resource "aws_key_pair" "ec2" {
  key_name   = "connection-key"
  public_key = file("~/.ssh/ec2.pub")
}

resource "aws_kms_key" "ebs_encryption_key" {
  description             = "KMS key for EBS instance"
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
      }
    ]
  })
}

resource "aws_launch_template" "asg_launch_template" {
  name_prefix = "asg_launch_config"
  # image_id = data.aws_ami.my-node-ami.id
  image_id = "ami-0f7d2d40f81acc547"
  instance_type = var.configuration.ec2_instance.instance_type
  key_name = aws_key_pair.ec2.key_name
  
  iam_instance_profile {
    name = aws_iam_instance_profile.ec2-profile.name
  }

  network_interfaces {
    associate_public_ip_address = true
    security_groups = ["${aws_security_group.application.id}"]
  }

  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      delete_on_termination = true
      encrypted = true
      volume_size = var.configuration.ec2_instance.volume_size
      volume_type = var.configuration.ec2_instance.volume_type
      kms_key_id = aws_kms_key.ebs_encryption_key.arn
    }
  }

  user_data = base64encode(join("\n",[
    "#!/bin/bash",
    "touch /home/ec2-user/webapp/.env",
    "echo -e \"PORT=8080\\nDB_HOSTNAME=${aws_db_instance.app_db.address}\\nDB_PORT=3306\\nDB_USERNAME=${var.db_username}\\nDB_PASSWORD=\\\"${var.db_password}\\\"\\nDB_DBNAME=${var.configuration.database.db_name}\\nAWS_BUCKET_NAME=${aws_s3_bucket.main_s3_bucket.bucket}\\nAWS_BUCKET_REGION=${var.region}\\nENVIRONMENT=production\\nMETRICS_HOSTNAME=localhost\\nMETRICS_PORT=8125\" > /home/ec2-user/webapp/.env",
    "sudo chmod -R 755 /home/ec2-user/webapp",
    "sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -c file:/home/ec2-user/webapp/api/cloudwatch/config.json -s"
  ]))
    
  

  lifecycle {
    create_before_destroy = true
  }
}

# resource "aws_launch_configuration" "asg_launch_config" {
#   name_prefix                 = "asg_launch_config"
#   # image_id                    = "ami-0f7d2d40f81acc547"
#   image_id = data.aws_ami.my-node-ami.id
#   instance_type               = var.configuration.ec2_instance.instance_type
#   key_name                    = aws_key_pair.ec2.key_name
#   iam_instance_profile        = aws_iam_instance_profile.ec2-profile.name
#   associate_public_ip_address = true
#   security_groups             = ["${aws_security_group.application.id}"]
#   root_block_device {
#     volume_size           = var.configuration.ec2_instance.volume_size
#     volume_type           = var.configuration.ec2_instance.volume_type
#     delete_on_termination = true
#     encrypted = true
#   }

#   user_data = <<EOF
#     #!/bin/bash

#     echo "==================================="
#     echo "Creating .env file to webapp"
#     echo "==================================="
#     touch /home/ec2-user/webapp/.env
#     echo -e "PORT=8080\nDB_HOSTNAME=${aws_db_instance.app_db.address}\nDB_PORT=3306\nDB_USERNAME=${var.db_username}\nDB_PASSWORD=\"${var.db_password}\"\nDB_DBNAME=${var.configuration.database.db_name}\nAWS_BUCKET_NAME=${aws_s3_bucket.main_s3_bucket.bucket}\nAWS_BUCKET_REGION=${var.region}\nENVIRONMENT=production\nMETRICS_HOSTNAME=localhost\nMETRICS_PORT=8125" > /home/ec2-user/webapp/.env

#     echo "==================================="
#     echo "Chaning application ownership"
#     echo "==================================="
#     sudo chmod -R 755 /home/ec2-user/webapp

#     echo "================================="
#     echo "Configuring cloudwatch"
#     echo "================================="
#     sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
#     -a fetch-config \
#     -m ec2 \
#     -c file:/home/ec2-user/webapp/api/cloudwatch/config.json \
#     -s
#   EOF

#   lifecycle {
#     create_before_destroy = true
#   }
# }

# Creating Autoscaling group
resource "aws_autoscaling_group" "autoscaling_group" {
  name                      = "autoscaling_group"
  min_size                  = 1
  max_size                  = 3
  desired_capacity          = 1
  health_check_grace_period = 60
  health_check_type         = "EC2"
  force_delete              = true
  target_group_arns         = [aws_lb_target_group.lb_target_group.arn]
  vpc_zone_identifier       = [module.subnets[0].public-subnets-id, module.subnets[1].public-subnets-id, module.subnets[2].public-subnets-id]
  launch_template {
    id = aws_launch_template.asg_launch_template.id
    version = "$Latest"
  }
  # launch_configuration = aws_launch_configuration.asg_launch_config.name
  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 90
      instance_warmup = 60
    }
  }


  lifecycle {
    create_before_destroy = true
  }


  tag {
    key                 = "Name"
    value               = "Autoscaling group"
    propagate_at_launch = true
  }
}

resource "aws_autoscaling_policy" "scale_up" {
  name                   = "scaling_up"
  autoscaling_group_name = aws_autoscaling_group.autoscaling_group.name
  adjustment_type        = "ChangeInCapacity"
  scaling_adjustment     = 1
  cooldown               = 60
  policy_type            = "SimpleScaling"

}

resource "aws_cloudwatch_metric_alarm" "scaling_up_alarm" {
  alarm_name          = "scaling_up_alarm"
  alarm_description   = "Scaling up alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "60"
  statistic           = "Average"
  threshold           = "5"
  actions_enabled     = true
  alarm_actions       = [aws_autoscaling_policy.scale_up.arn]

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.autoscaling_group.name
  }

}

resource "aws_autoscaling_policy" "scale_down" {
  name                   = "scaling_down"
  autoscaling_group_name = aws_autoscaling_group.autoscaling_group.name
  adjustment_type        = "ChangeInCapacity"
  scaling_adjustment     = -1
  cooldown               = 60
  policy_type            = "SimpleScaling"

}

resource "aws_cloudwatch_metric_alarm" "scaling_down_alarm" {
  alarm_name          = "scaling_down_alarm"
  alarm_description   = "Scaling Down alarm"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "60"
  statistic           = "Average"
  threshold           = "3"
  actions_enabled     = true
  alarm_actions       = [aws_autoscaling_policy.scale_down.arn]

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.autoscaling_group.name
  }

}