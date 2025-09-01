# --- Network Load Balancer ---
resource "aws_lb" "main" {
  name               = "${var.project_name}-nlb"
  internal           = false
  load_balancer_type = "network"
  subnets            = aws_subnet.public[*].id

  tags = {
    Name = "${var.project_name}-nlb"
  }
}

# --- Target Group para o Nginx ---
resource "aws_lb_target_group" "nginx" {
  name        = "${var.project_name}-nginx-tg"
  port        = 443
  protocol    = "TCP"
  vpc_id      = aws_vpc.main.id
  target_type = "ip"

  health_check {
    enabled             = true
    protocol            = "TCP"
    interval            = 30
    timeout             = 10
    healthy_threshold   = 3
    unhealthy_threshold = 3
  }

  tags = {
    Name = "${var.project_name}-nginx-tg"
  }
}

# --- Listener TCP ---
resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.main.arn
  port              = "443"
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.nginx.arn
  }
}



# --- Output para o DNS do NLB ---
output "alb_dns_name" {
  description = "DNS name of the Network Load Balancer"
  value       = aws_lb.main.dns_name
}

output "alb_zone_id" {
  description = "Zone ID of the Network Load Balancer"
  value       = aws_lb.main.zone_id
}
