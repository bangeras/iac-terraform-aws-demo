# ALB Security Group
resource "aws_security_group" "alb_sg" {
  name        = "alb_sg"
  description = "SG for ALB"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "${var.vpc_suffix}-alb-sg"
  }
}

# EC2 Security Group
resource "aws_security_group" "ec2_sg" {
  name        = "ec2_sg"
  description = "SG for EC2"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    protocol  = "tcp"
    from_port = 80
    to_port   = 80
    #    cidr_blocks = ["0.0.0.0/0"]
    security_groups = [aws_security_group.alb_sg.id]
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "${var.vpc_suffix}-ec2-sg"
  }
}

# EC2 Security Group
resource "aws_security_group" "ecs_sg" {
  name        = "ecs_sg"
  description = "SG for ECS"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    protocol  = "tcp"
    from_port = 80
    to_port   = 80
    #    cidr_blocks = ["0.0.0.0/0"]
    security_groups = [aws_security_group.alb_sg.id]
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "${var.vpc_suffix}-ecs-sg"
  }
}

resource "aws_iam_role" "ecs_task_role" {
  name = "${var.vpc_suffix}-ecs-task-role"

  assume_role_policy = <<EOF
{
 "Version": "2012-10-17",
 "Statement": [
   {
     "Action": "sts:AssumeRole",
     "Principal": {
       "Service": "ecs-tasks.amazonaws.com"
     },
     "Effect": "Allow",
     "Sid": ""
   }
 ]
}
EOF
}

resource "aws_iam_policy" "ecs_task_role_policy" {
  name        = "${var.vpc_suffix}-ecs_task_role_policy"
  description = "Policy that allows access to AWS resources from ECS containers"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ecr:GetAuthorizationToken",
        "ecr:BatchCheckLayerAvailability",
        "ecr:GetDownloadUrlForLayer",
        "ecr:BatchGetImage"
      ],
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "ecs-task-role-policy-attachment" {
  role       = aws_iam_role.ecs_task_role.name
  policy_arn = aws_iam_policy.ecs_task_role_policy.arn
}

resource "aws_iam_role" "ecs_task_execution_role" {
  name = "${var.vpc_suffix}-ecs-task-execution-role"

  assume_role_policy = <<EOF
{
 "Version": "2012-10-17",
 "Statement": [
   {
     "Action": "sts:AssumeRole",
     "Principal": {
       "Service": "ecs-tasks.amazonaws.com"
     },
     "Effect": "Allow",
     "Sid": ""
   }
 ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "ecs-task-execution-role-policy-attachment" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}