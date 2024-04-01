
# Launch EC2 instances in each private subnet
resource "aws_instance" "ec2" {
  ami           = var.ec2_ami
  count         = var.ec2_instance_count
  instance_type = var.ec2_instance_type

  subnet_id       = element(aws_subnet.private_subnet.*.id, count.index)
  user_data       = file("ec2-user-data.sh")
  security_groups = [aws_security_group.ec2_sg.id]

  tags = {
    #    Name = "${var.vpc_suffix}-ec2-${element(aws_subnet.private_subnet.*.id, count.index)}-${count.index}"
    Name = "svb-ec2-paymentservice"
  }
}

# TG for EC2 Services
resource "aws_lb_target_group" "ec2_tg" {
  name     = "ec2-paymentservice-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.vpc.id
}

# Register the EC2 running instance with the TG
resource "aws_lb_target_group_attachment" "ec2_tg_attachment" {
  target_group_arn = aws_lb_target_group.ec2_tg.arn
  count            = length(aws_instance.ec2)
  target_id        = element(aws_instance.ec2.*.id, count.index)
  port             = 80

  depends_on = [aws_instance.ec2]
}

# ALB for the EC2 services
resource "aws_lb" "ec2_services_alb" {
  name                       = "${var.vpc_suffix}-ec2-paymentservice-alb"
  load_balancer_type         = "application"
  internal                   = false # Scheme = Internet Facing
  security_groups            = [aws_security_group.alb_sg.id]
  subnets                    = [for subnet in aws_subnet.public_subnet : subnet.id] # aws_subnet.public_subnet.*.id
  enable_http2               = false
  enable_deletion_protection = false

  tags = {
    Name = "${var.vpc_suffix}-ec2-paymentservice-alb"
  }
}

resource "aws_lb_listener" "ec2_services_alb_listener" {
  load_balancer_arn = aws_lb.ec2_services_alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.ec2_tg.arn
  }
}
