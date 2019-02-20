provider "aws" {
  access_key = "${var.access_key}"
  secret_key = "${var.secret_key}"
  region     = "us-east-2"
}

#uploading SSL certificates to IAM
resource "aws_iam_server_certificate" "hello-world" {
  name             = "hello-world"
  certificate_body = "${file("certs/cert.pem")}"
  private_key      = "${file("certs/private.pem")}"
}

#Creating a VPC
resource "aws_vpc" "hello-world" {
  cidr_block           = "10.10.0.0/16"
  enable_dns_hostnames = "true"

  tags = {
    Name = "hello-world"
  }
}

#Creating two subnets across two availability zones
#First subnet

resource "aws_subnet" "hello-world1" {
  vpc_id                  = "${aws_vpc.hello-world.id}"
  cidr_block              = "10.10.1.0/24"
  availability_zone       = "us-east-2a"
  map_public_ip_on_launch = "true"

  tags = {
    Name = "hello-world"
  }
}

#Second Subnet

resource "aws_subnet" "hello-world2" {
  vpc_id                  = "${aws_vpc.hello-world.id}"
  cidr_block              = "10.10.2.0/24"
  availability_zone       = "us-east-2b"
  map_public_ip_on_launch = "true"

  tags = {
    Name = "hello-world"
  }
}

#creating internet gateway

resource "aws_internet_gateway" "hello-world" {
  vpc_id = "${aws_vpc.hello-world.id}"

  tags = {
    Name = "hello-world"
  }
}

#Creating a route to the world using internet gateway

resource "aws_default_route_table" "hello-world" {
  default_route_table_id = "${aws_vpc.hello-world.default_route_table_id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.hello-world.id}"
  }

  tags = {
    Name = "hello-world"
  }
}

#Creating a Classic Elastic Load Balancer using the two subnets

resource "aws_elb" "hello-world" {
  name            = "hello-world-elb"
  security_groups = ["${aws_default_security_group.hello-world.id}"]
  subnets         = ["${aws_subnet.hello-world1.id}", "${aws_subnet.hello-world2.id}"]

  listener {
    instance_port      = 443
    instance_protocol  = "https"
    lb_port            = 443
    lb_protocol        = "https"
    ssl_certificate_id = "${aws_iam_server_certificate.hello-world.arn}"
  }

  listener {
    instance_port     = 80
    instance_protocol = "http"
    lb_port           = 80
    lb_protocol       = "http"
  }

  health_check {
    healthy_threshold   = 3
    unhealthy_threshold = 3
    timeout             = 5
    target              = "TCP:443"
    interval            = 60
  }

  cross_zone_load_balancing   = true
  idle_timeout                = 300
  connection_draining         = true
  connection_draining_timeout = 300

  tags = {
    Name = "hello-world-elb"
  }
}

#Creating an autoscaling group with the helath check type ELB

resource "aws_autoscaling_group" "hello-world-asg" {
  vpc_zone_identifier  = ["${aws_subnet.hello-world1.id}", "${aws_subnet.hello-world2.id}"]
  name                 = "hello-world-asg"
  max_size             = "${var.asg_max}"
  min_size             = "${var.asg_min}"
  desired_capacity     = "${var.asg_desired}"
  health_check_type    = "ELB"
  force_delete         = true
  launch_configuration = "${aws_launch_configuration.hello-world-lc.name}"
  load_balancers       = ["${aws_elb.hello-world.name}"]

  tag {
    key                 = "Name"
    value               = "hello-world-asg"
    propagate_at_launch = "true"
  }
}

# Scale up policy
resource "aws_autoscaling_policy" "scale-up" {
  name                   = "auto-scaling-up-policy"
  scaling_adjustment     = "1"
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  policy_type            = "SimpleScaling"
  autoscaling_group_name = "${aws_autoscaling_group.hello-world-asg.name}"
}

# scale up alarm
resource "aws_cloudwatch_metric_alarm" "excess-cpu-alarm" {
  alarm_name          = "cpu-policy-scaleup"
  alarm_description   = "excess-cpu-alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "60"
  statistic           = "Average"
  threshold           = "60"

  dimensions = {
    "AutoScalingGroupName" = "${aws_autoscaling_group.hello-world-asg.name}"
  }

  actions_enabled = true
  alarm_actions   = ["${aws_autoscaling_policy.scale-up.arn}"]
}

# scale down policy
resource "aws_autoscaling_policy" "scale-down" {
  name                   = "auto-scale-down-policy"
  scaling_adjustment     = "-1"
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  policy_type            = "SimpleScaling"
  autoscaling_group_name = "${aws_autoscaling_group.hello-world-asg.name}"
}

# scale down alarm
resource "aws_cloudwatch_metric_alarm" "lesser-cpu-alarm" {
  alarm_name          = "cpu-policy-scaledown"
  alarm_description   = "lesser-cpu-alarm"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "60"
  statistic           = "Average"
  threshold           = "60"

  dimensions = {
    "AutoScalingGroupName" = "${aws_autoscaling_group.hello-world-asg.name}"
  }

  actions_enabled = true
  alarm_actions   = ["${aws_autoscaling_policy.scale-down.arn}"]
}

#Launch configuration for the auto scaling group

resource "aws_launch_configuration" "hello-world-lc" {
  name = "hello-world-lc"

  # using RHEL image id for US-EAST-2 region
  image_id      = "ami-0b500ef59d8335eee"
  instance_type = "${var.instance_type}"

  # Security group
  security_groups = ["${aws_default_security_group.hello-world.id}"]
  user_data       = "${file("userdata.sh")}"
  key_name        = "${var.key_name}"
}

# associating the subnets with route table
resource "aws_route_table_association" "hello-world1" {
  subnet_id      = "${aws_subnet.hello-world1.id}"
  route_table_id = "${aws_default_route_table.hello-world.id}"
}

resource "aws_route_table_association" "hello-world2" {
  subnet_id      = "${aws_subnet.hello-world2.id}"
  route_table_id = "${aws_default_route_table.hello-world.id}"
}

# Allow acces to the world for HTTP and HTTPS

resource "aws_default_security_group" "hello-world" {
  vpc_id = "${aws_vpc.hello-world.id}"

  # SSH access from anywhere
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTP access from anywhere
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTPS access from anywhere
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # outbound internet access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
