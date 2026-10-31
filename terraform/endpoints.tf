locals {
  endpoint_services = ["ssm", "ssmmessages", "ec2messages"]
}

# SSM agent connectivity (Session Manager)
resource "aws_vpc_endpoint" "interface" {
  for_each            = toset(local.endpoint_services)
  vpc_id              = aws_vpc.soar.id
  service_name        = "com.amazonaws.eu-central-1.${each.key}"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [aws_subnet.soar_a.id, aws_subnet.soar_b.id]
  security_group_ids  = [aws_security_group.endpoints.id]
  private_dns_enabled = true
  tags                = { Name = "soar-${each.key}-endpoint" }
}

# S3 gateway endpoint: Amazon Linux package repos are served from S3.
# route_table_ids adds the S3 prefix-list route to soar-private-rt.
resource "aws_vpc_endpoint" "s3" {
  vpc_id            = aws_vpc.soar.id
  service_name      = "com.amazonaws.eu-central-1.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = [aws_route_table.soar_private.id]
  tags              = { Name = "soar-s3-endpoint" }
}