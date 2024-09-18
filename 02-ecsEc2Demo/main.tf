# Create an ECS cluster
resource "aws_ecs_cluster" "ecs_cluster" {
  name = "my-ecs-cluster"
}

resource "aws_ecs_capacity_provider" "ecs_capacity_provider" {
  name = "test1"

  auto_scaling_group_provider {
    auto_scaling_group_arn = aws_autoscaling_group.ecs_asg.arn

    managed_scaling {
      maximum_scaling_step_size = 1000
      minimum_scaling_step_size = 1
      status                    = "ENABLED"
      target_capacity           = 3
    }
  }
}

resource "aws_ecs_cluster_capacity_providers" "example" {
  cluster_name = aws_ecs_cluster.ecs_cluster.name

  capacity_providers = [aws_ecs_capacity_provider.ecs_capacity_provider.name]

  default_capacity_provider_strategy {
    base              = 1
    weight            = 100
    capacity_provider = aws_ecs_capacity_provider.ecs_capacity_provider.name
  }
}

#==== Tony
# IAM Role for ECS Task Execution (for EC2 cluster)
resource "aws_iam_role" "ecs_task_execution_role" {
  name = "ecsTaskExecutionRole"

  assume_role_policy = jsonencode({
    Version : "2012-10-17",
    Statement : [{
      Action : "sts:AssumeRole",
      Effect : "Allow",
      Principal : {
        Service : "ecs-tasks.amazonaws.com"
      }
    }]
  })
}

# Attach the necessary policies for task execution (EC2 tasks)
resource "aws_iam_role_policy_attachment" "ecs_task_execution_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# IAM Role for ECS Task (containers in the task)
resource "aws_iam_role" "ecs_task_role" {
  name = "ecsTaskRole"

  assume_role_policy = jsonencode({
    Version : "2012-10-17",
    Statement : [{
      Action : "sts:AssumeRole",
      Effect : "Allow",
      Principal : {
        Service : "ecs-tasks.amazonaws.com"
      }
    }]
  })
}
#====




# Define the ECS task definition for the service
resource "aws_ecs_task_definition" "ecs_task_definition" {
  family       = "my-ecs-task"
  network_mode = "awsvpc"
  #execution_role_arn = "arn:aws:iam::532199187081:role/ecsTaskExecutionRole"
  execution_role_arn = aws_iam_role.ecs_task_execution_role.arn # IAM role for task execution
  task_role_arn      = aws_iam_role.ecs_task_role.arn           # IAM role for containers in the task

  cpu = 256
  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "X86_64"
  }
  container_definitions = jsonencode([
    {
      name      = "tomc21"
      image     = "public.ecr.aws/docker/library/tomcat:jre21"
      cpu       = 256
      memory    = 512
      essential = true
      portMappings = [
        {
          containerPort = 80
          hostPort      = 80
          protocol      = "tcp"
        }
      ]
    }
  ])
}

# Define the ECS service that will run the task
resource "aws_ecs_service" "ecs_service" {
  name            = "my-ecs-service"
  cluster         = aws_ecs_cluster.ecs_cluster.id
  task_definition = aws_ecs_task_definition.ecs_task_definition.arn
  desired_count   = 2

  network_configuration {
    subnets         = [aws_subnet.subnet.id, aws_subnet.subnet2.id]
    security_groups = [aws_security_group.security_group.id]
  }

  force_new_deployment = true
  placement_constraints {
    type = "distinctInstance"
  }

  triggers = {
    redeployment = timestamp()
  }

  capacity_provider_strategy {
    capacity_provider = aws_ecs_capacity_provider.ecs_capacity_provider.name
    weight            = 100
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.ecs_tg.arn
    container_name   = "tomc21"
    container_port   = 80
  }

  depends_on = [aws_autoscaling_group.ecs_asg]
}
