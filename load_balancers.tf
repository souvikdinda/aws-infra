resource "aws_lb" "applicationLoadBalancer" {
  name               = "load-balancer"
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = [module.subnets[0].public-subnets-id, module.subnets[1].public-subnets-id, module.subnets[2].public-subnets-id]

  tags = {
    Name = "load-balancer"
  }
}

resource "aws_lb_target_group" "lb_target_group" {
  name     = "load-balancer-target-group"
  port     = 8080
  protocol = "HTTP"
  vpc_id   = aws_vpc.main_vpc.id

  health_check {
    path = "/healthz"
    port = 8080
  }
}

resource "aws_lb_listener" "listener_http" {
  load_balancer_arn = aws_lb.applicationLoadBalancer.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.lb_target_group.arn
  }
}

resource "aws_lb_listener" "listener_https" {
  load_balancer_arn = aws_lb.applicationLoadBalancer.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = local.certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.lb_target_group.arn
  }
}