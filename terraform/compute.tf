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

resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.soar.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "cloudwatch" {
  role       = aws_iam_role.soar.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

# Least privilege: only the four things the listener needs
resource "aws_iam_role_policy" "soar_access" {
  name = "soar-app-access"
  role = aws_iam_role.soar.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      { Effect = "Allow", Action = ["sns:Publish"], Resource = aws_sns_topic.alerts.arn },
      { Effect = "Allow", Action = ["secretsmanager:GetSecretValue"], Resource = aws_secretsmanager_secret.db.arn },
      { Effect = "Allow", Action = ["s3:GetObject"], Resource = "${aws_s3_bucket.code.arn}/*" },
      { Effect = "Allow", Action = ["s3:ListBucket"], Resource = aws_s3_bucket.code.arn },
    ]
  })
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

  # Runs once at first boot: installs tools, pulls the code from S3,
  # and starts the listener as a service that restarts on failure.
  user_data = base64encode(<<-EOF
    #!/bin/bash
    set -e
    dnf install -y python3-pyyaml python3-boto3 python3-psycopg2
    mkdir -p /opt/soar /var/log/soar
    aws s3 sync s3://${aws_s3_bucket.code.bucket}/ /opt/soar/ --region ${var.region}

    cat > /etc/soar.env <<ENV
    AWS_REGION=${var.region}
    SNS_TOPIC_ARN=${aws_sns_topic.alerts.arn}
    SECRET_ID=${aws_secretsmanager_secret.db.name}
    INCIDENT_LOG=/var/log/soar/incidents.jsonl
    ENV

    cat > /etc/systemd/system/soar-listener.service <<UNIT
    [Unit]
    Description=SOAR syslog listener
    After=network-online.target

    [Service]
    EnvironmentFile=/etc/soar.env
    WorkingDirectory=/opt/soar
    ExecStart=/usr/bin/python3 /opt/soar/listener.py
    Restart=always

    [Install]
    WantedBy=multi-user.target
    UNIT

    systemctl daemon-reload
    systemctl enable --now soar-listener
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
  vpc_zone_identifier = [aws_subnet.app_a.id, aws_subnet.app_b.id]
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

  # Nodes boot only when everything they depend on exists
  depends_on = [
    aws_vpc_endpoint.interface,
    aws_vpc_endpoint.s3,
    aws_route_table_association.app_a,
    aws_route_table_association.app_b,
    aws_s3_object.soar_code,
    aws_secretsmanager_secret_version.db,
    aws_route53_record.db,
  ]
}