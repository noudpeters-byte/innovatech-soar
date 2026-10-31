data "aws_ami" "al2023" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["al2023-ami-2023*-x86_64"]
  }
}

resource "aws_iam_role" "soar" {
  name = "soar-node-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "soar_ssm" {
  role       = aws_iam_role.soar.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "soar_cw" {
  role       = aws_iam_role.soar.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

resource "aws_iam_instance_profile" "soar" {
  name = "soar-node-profile"
  role = aws_iam_role.soar.name
}

resource "aws_launch_template" "soar" {
  name_prefix   = "soar-"
  image_id      = data.aws_ami.al2023.id
  instance_type = "t3.small"

  iam_instance_profile {
    name = aws_iam_instance_profile.soar.name
  }

  vpc_security_group_ids = [aws_security_group.soar.id]

  metadata_options {
    http_tokens = "required"
  }

  user_data = base64encode(<<-EOF
    #!/bin/bash
    set -e
    dnf install -y docker
    systemctl enable --now docker
  EOF
  )

  tag_specifications {
    resource_type = "instance"
    tags          = { Name = "soar-node" }
  }
}

resource "aws_autoscaling_group" "soar" {
  name                = "soar-asg"
  min_size            = 2
  max_size            = 2
  desired_capacity    = 2
  vpc_zone_identifier = [aws_subnet.soar_a.id, aws_subnet.soar_b.id]
  health_check_type   = "EC2"

  launch_template {
    id      = aws_launch_template.soar.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "soar-node"
    propagate_at_launch = true
  }

  # Launch nodes only after the endpoints and route associations exist,
  # so user_data can reach the package repos on first boot.
  depends_on = [
    aws_vpc_endpoint.s3,
    aws_vpc_endpoint.interface,
    aws_route_table_association.soar_a,
    aws_route_table_association.soar_b,
  ]
}