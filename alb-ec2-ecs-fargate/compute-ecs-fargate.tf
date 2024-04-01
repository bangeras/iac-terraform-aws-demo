resource "aws_alb" "ecs_services_alb" {
  name            = "${var.vpc_suffix}-ecs-paymentservice-alb"
  subnets         = aws_subnet.public_subnet.*.id
  security_groups = [aws_security_group.alb_sg.id]
}

resource "aws_alb_target_group" "ecs_tg" {
  name        = "ecs-paymentservice-tg"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = aws_vpc.vpc.id
  target_type = "ip" # for Fargate

  #  health_check {
  #    healthy_threshold   = "3"
  #    interval            = "30"
  #    protocol            = "HTTP"
  #    matcher             = "200"
  #    timeout             = "3"
  #    path                = var.health_check_path
  #    unhealthy_threshold = "2"
  #  }
}

# aws_lb_target_group_attachment. That is primarily for attaching EC2 instances to a target group if you have no auto-scaling in place.
#For auto-scaled EC2 instance, or ECS managed containers, you let those service manage the target group attachment for you.


# Redirect all traffic from the ALB to the target group
resource "aws_alb_listener" "ec2_services_alb_listener" {
  load_balancer_arn = aws_alb.ecs_services_alb.id
  port              = 80
  protocol          = "HTTP"

  default_action {
    target_group_arn = aws_alb_target_group.ecs_tg.arn
    type             = "forward"
  }
}

# ECR repo
resource "aws_ecr_repository" "main" {
  name                 = "${var.vpc_suffix}-ecr"
  image_tag_mutability = "MUTABLE"
}

resource "aws_ecr_lifecycle_policy" "main" {
  repository = aws_ecr_repository.main.name

  policy = jsonencode({
    rules = [{
      rulePriority = 1
      description  = "keep last 10 images"
      action = {
        type = "expire"
      }
      selection = {
        tagStatus   = "any"
        countType   = "imageCountMoreThan"
        countNumber = 10
      }
    }]
  })
}

# ECS Cluster
resource "aws_ecs_cluster" "fargate_cluster" {
  name = "${var.vpc_suffix}-ecs-cluster"
}

# ECS Task definition
resource "aws_ecs_task_definition" "fargate_task" {
  family                   = "paymentservice-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]

  cpu           = "256"                                    # Set CPU units for the task
  memory        = "512"                                    # Set memory for the task
  task_role_arn = aws_iam_role.ecs_task_execution_role.arn # Specify your task execution role ARN

  container_definitions = jsonencode([{
    name  = "${var.vpc_suffix}-container-paymentservice"
    image = "nginx:latest"
    portMappings = [{
      containerPort = 80
      hostPort      = 80
    }]
  }])
}

resource "aws_ecs_service" "main" {
  name                               = "${var.vpc_suffix}-service-${var.env}"
  cluster                            = aws_ecs_cluster.fargate_cluster.id
  task_definition                    = aws_ecs_task_definition.fargate_task.arn
  desired_count                      = 3
  deployment_minimum_healthy_percent = 50
  deployment_maximum_percent         = 200
  launch_type                        = "FARGATE"

  network_configuration {
    security_groups  = [aws_security_group.ecs_sg.id]
    subnets          = aws_subnet.private_subnet.*.id
    assign_public_ip = false
  }

  load_balancer { # For ECS this configuration is used instead of aws_lb_target_group_attachment
    target_group_arn = aws_alb_target_group.ecs_tg.arn
    container_name   = "${var.vpc_suffix}-container-paymentservice"
    container_port   = 80
  }

  lifecycle {
    ignore_changes = [task_definition, desired_count]
  }
}