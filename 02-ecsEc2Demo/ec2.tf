
# Create the IAM role for ECS instances
resource "aws_iam_role" "ecs_instance_role" {
  name = "ecsInstanceRole"

  assume_role_policy = jsonencode({
    Version : "2012-10-17"
    Statement : [{
      Action : "sts:AssumeRole"
      Effect : "Allow"
      Principal : {
        Service : "ec2.amazonaws.com"
      }
    }]
  })
}

# Attach the AmazonEC2ContainerServiceforEC2Role policy to the role
resource "aws_iam_role_policy_attachment" "ecs_instance_role_attachment" {
  role       = aws_iam_role.ecs_instance_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

# Optional: Attach additional policies if needed
resource "aws_iam_role_policy_attachment" "additional_policy_attachment" {
  role       = aws_iam_role.ecs_instance_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}


# Create the IAM instance profile for ECS instances
resource "aws_iam_instance_profile" "ecs_instance_profile" {
  name = "ecsInstanceProfile"
  role = aws_iam_role.ecs_instance_role.name
}

# Create an EC2 key pair named ec2ecsglog
resource "tls_private_key" "ec2ecsglog_key" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "aws_key_pair" "ec2ecsglog_key_pair" {
  key_name   = "ec2ecsglog" # Key pair name
  public_key = tls_private_key.ec2ecsglog_key.public_key_openssh
}

#======

resource "aws_launch_template" "ecs_lt" {
  name_prefix   = "ecs-template"
  image_id      = "ami-00f07845aed8c0ee7"
  instance_type = "t3.micro"

  key_name               = "ec2ecsglog"
  vpc_security_group_ids = [aws_security_group.security_group.id]

  # IAM instance profile for the ECS instances
  iam_instance_profile {
    name = aws_iam_instance_profile.ecs_instance_profile.name
  }


  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      volume_size = 30
      volume_type = "gp2"
    }
  }

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "ecs-instance"
    }
  }

  user_data = filebase64("${path.module}/ecs.sh")
}

resource "aws_autoscaling_group" "ecs_asg" {
  vpc_zone_identifier = [aws_subnet.subnet.id, aws_subnet.subnet2.id]
  desired_capacity    = 2
  max_size            = 3
  min_size            = 1

  launch_template {
    id      = aws_launch_template.ecs_lt.id
    version = "$Latest"
  }

  tag {
    key                 = "AmazonECSManaged"
    value               = true
    propagate_at_launch = true
  }
}

//Alb
resource "aws_lb" "ecs_alb" {
  name               = "ecs-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.security_group.id]
  subnets            = [aws_subnet.subnet.id, aws_subnet.subnet2.id]

  tags = {
    Name = "ecs-alb"
  }
}

resource "aws_lb_listener" "ecs_alb_listener" {
  load_balancer_arn = aws_lb.ecs_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.ecs_tg.arn
  }
}

resource "aws_lb_target_group" "ecs_tg" {
  name        = "ecs-target-group"
  port        = 80
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = aws_vpc.main.id

  health_check {
    path = "/"
  }
}



