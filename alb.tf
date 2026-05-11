resource "aws_instance" "app" {
  count                  = 2
  ami                    = "ami-0c02fb55956c7d316"
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.private[count.index].id
  vpc_security_group_ids = [aws_security_group.ec2.id]

  user_data = base64encode(<<-EOF
    #!/bin/bash
    yum update -y
    yum install -y httpd
    systemctl start httpd
    systemctl enable httpd
    echo "<h1>App Server ${count.index + 1}</h1>" > /var/www/html/index.html
    mkdir -p /var/www/html/app1 /var/www/html/app2
    echo "<h1>App 1 - Server ${count.index + 1}</h1>" > /var/www/html/app1/index.html
    echo "<h1>App 2 - Server ${count.index + 1}</h1>" > /var/www/html/app2/index.html
  EOF
  )

  tags = { Name = "${var.project_name}-app-${count.index + 1}" }
}

resource "aws_lb" "main" {
  name               = "${var.project_name}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = aws_subnet.public[*].id
  tags = { Name = "${var.project_name}-alb" }
}

resource "aws_lb_target_group" "app1" {
  name     = "${var.project_name}-app1-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check {
    path                = "/app1/index.html"
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }

  tags = { Name = "${var.project_name}-app1-tg" }
}

resource "aws_lb_target_group" "app2" {
  name     = "${var.project_name}-app2-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check {
    path                = "/app2/index.html"
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }

  tags = { Name = "${var.project_name}-app2-tg" }
}

resource "aws_lb_target_group_attachment" "app1" {
  count            = 2
  target_group_arn = aws_lb_target_group.app1.arn
  target_id        = aws_instance.app[count.index].id
  port             = 80
}

resource "aws_lb_target_group_attachment" "app2" {
  count            = 2
  target_group_arn = aws_lb_target_group.app2.arn
  target_id        = aws_instance.app[count.index].id
  port             = 80
}

resource "aws_lb_listener" "main" {
  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app1.arn
  }
}

resource "aws_lb_listener_rule" "app1" {
  listener_arn = aws_lb_listener.main.arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app1.arn
  }

  condition {
    path_pattern {
      values = ["/app1*"]
    }
  }
}

resource "aws_lb_listener_rule" "app2" {
  listener_arn = aws_lb_listener.main.arn
  priority     = 200

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app2.arn
  }

  condition {
    path_pattern {
      values = ["/app2*"]
    }
  }
}

output "alb_dns_name" {
  description = "DNS name of the ALB"
  value       = aws_lb.main.dns_name
}
