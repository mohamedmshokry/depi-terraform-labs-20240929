provider "aws" {
  region = "eu-north-1"
}

data "aws_vpc" "default" {
 default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

resource "aws_security_group" "elb-asg-sg" {
  name        = "asg-lt-sg"
  description = "SG for ASG Launch Template"
  vpc_id = data.aws_vpc.default.id

  ingress {
    from_port   = "22"
    to_port     = "22"
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  ingress {
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "tls_private_key" "asg_lt_webkey" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# terraform output -raw private_key > ansible_ssh_key.pem
resource "aws_key_pair" "generated_key" {
  key_name   = var.key_name
  public_key = tls_private_key.asg_lt_webkey.public_key_openssh
}

# Use `local_sensitive_file` for sensitive content
resource "local_sensitive_file" "asg_lt_webkey" {
  content             = tls_private_key.asg_lt_webkey.private_key_pem
  filename            = "${path.module}/asg_lt_webkey.pem"
  file_permission     = "0600"  # Secure permissions for the key
}

resource "aws_launch_template" "template" {
  name_prefix     = "depi-lt"
  image_id        = var.asg_ami
  instance_type   = var.asg_instance_type
  key_name = aws_key_pair.generated_key.key_name

  vpc_security_group_ids = [aws_security_group.elb-asg-sg.id]
  
  user_data = filebase64("${path.module}/install_apache.sh")
}

resource "aws_lb" "depi-alb" {
  name               = "depi-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.elb-asg-sg.id]
  subnets            = data.aws_subnets.default.ids

  enable_deletion_protection = false
}

resource "aws_lb_target_group" "depi-tg" {
  name     = "depi-target-group"
  port     = 80
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.default.id

  health_check {
    path                = "/"
    protocol            = "HTTP"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 3
    unhealthy_threshold = 3
  }
}

resource "aws_lb_listener" "depi-alb-listener" {
  load_balancer_arn = aws_lb.depi-alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.depi-tg.arn
  }
}

resource "aws_autoscaling_group" "depi-asg" {
  name                  = "depi-asg-01"  
  availability_zones    = ["eu-north-1a", "eu-north-1b", "eu-north-1c"]
  desired_capacity      = 2
  max_size              = 5
  min_size              = 1
  health_check_type     = var.asg_health_check_type
  health_check_grace_period = 300
  target_group_arns     = [aws_lb_target_group.depi-tg.arn]

  launch_template {
    id      = aws_launch_template.template.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "depi-asg-instance"
    propagate_at_launch = true
  }
}

resource "aws_autoscaling_policy" "depi-asg-scalingpolicy" {
  autoscaling_group_name = aws_autoscaling_group.depi-asg.name
  name                   = "Traget Tracking scaling based on CPU utilization"
  policy_type            = "TargetTrackingScaling"

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }

    target_value = 40.0
  }
}

# Force scaling
# aws autoscaling set-desired-capacity --auto-scaling-group-name "depi-asg-01" --desired-capacity 5