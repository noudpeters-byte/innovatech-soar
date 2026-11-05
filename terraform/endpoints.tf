locals {
  interface_services = ["ssm", "ssmmessages", "ec2messages", "sns", "secretsmanager", "logs", "monitoring"]
}

# Interface endpoints: AWS APIs reached privately, no NAT needed
resource "aws_vpc_endpoint" "interface" {
  for_each            = toset(local.interface_services)
  vpc_id              = aws_vpc.soar.id
  service_name        = "com.amazonaws.${var.region}.${each.key}"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [aws_subnet.app_a.id, aws_subnet.app_b.id]
  security_group_ids  = [aws_security_group.endpoints.id]
  private_dns_enabled = true
  tags                = { Name = "soar-${each.key}-endpoint" }
}

# Gateway endpoint: Amazon Linux repos are served from S3
resource "aws_vpc_endpoint" "s3" {
  vpc_id            = aws_vpc.soar.id
  service_name      = "com.amazonaws.${var.region}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = [aws_route_table.private.id]
  tags              = { Name = "soar-s3-endpoint" }
}