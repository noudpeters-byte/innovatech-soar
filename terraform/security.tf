resource "aws_security_group" "soar" {
  name        = "soar-sg"
  description = "SOAR listener: syslog from on-prem"
  vpc_id      = aws_vpc.soar.id

  ingress {
    description = "Syslog TCP from on-prem"
    from_port   = 514
    to_port     = 514
    protocol    = "tcp"
    cidr_blocks = [var.onprem_cidr]
  }

  ingress {
    description = "Syslog UDP from on-prem"
    from_port   = 514
    to_port     = 514
    protocol    = "udp"
    cidr_blocks = [var.onprem_cidr]
  }

  egress {
    description = "HTTPS to VPC endpoints and S3"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "soar-sg" }
}

# Interface endpoints accept HTTPS from SOAR nodes only
resource "aws_security_group" "endpoints" {
  name        = "soar-endpoints-sg"
  description = "HTTPS from SOAR nodes to VPC endpoints"
  vpc_id      = aws_vpc.soar.id

  ingress {
    description     = "HTTPS from SOAR nodes"
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [aws_security_group.soar.id]
  }

  tags = { Name = "soar-endpoints-sg" }
}