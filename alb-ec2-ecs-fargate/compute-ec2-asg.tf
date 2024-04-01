resource "aws_launch_template" "ec2_launch_template" {
  name_prefix            = "${var.vpc_suffix}-ec2-launch_template"
  image_id               = "ami-00952f27cf14db9cd"
  instance_type          = "t3.micro"
  vpc_security_group_ids = [aws_security_group.ec2_sg.id]
  user_data              = filebase64("ec2-user-data.sh")
  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "${var.vpc_suffix}-asg-ec2-paymentservice"
    }
  }
}

resource "aws_autoscaling_group" "asg" {
  name = "${var.vpc_suffix}-asg"
  #  availability_zones   = local.availability_zones
  desired_capacity     = 2
  max_size             = 4
  min_size             = 1
  health_check_type    = "EC2"
  termination_policies = ["OldestInstance"]
  vpc_zone_identifier  = aws_subnet.private_subnet.*.id
  target_group_arns    = [aws_lb_target_group.ec2_tg.arn]

  launch_template {
    id      = aws_launch_template.ec2_launch_template.id
    version = "$Latest"
  }
}

# Create a new load balancer attachment
resource "aws_autoscaling_attachment" "asg_alb" {
  autoscaling_group_name = aws_autoscaling_group.asg.id
  lb_target_group_arn    = aws_lb_target_group.ec2_tg.arn
}