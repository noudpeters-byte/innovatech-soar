resource "aws_security_group" "soar" {
  name        = "soar-sg"
  description = "SOAR listener nodes"
  vpc_id      = aws_vpc.soar.id
  tags        = { Name = "soar-sg" }
}

resource "aws_security_group" "endpoints" {
  name        = "soar-endpoints-sg"
  description = "HTTPS to interface endpoints"
  vpc_id      = aws_vpc.soar.id
  tags        = { Name = "soar-endpoints-sg" }
}

resource "aws_security_group" "db" {
  name        = "soar-db-sg"
  description = "PostgreSQL from SOAR nodes only"
  vpc_id      = aws_vpc.soar.id
  tags        = { Name = "soar-db-sg" }
}

# Rules are separate resources so the SOAR and DB groups can reference each other
# without a dependency cycle.

# Syslog into the listener
resource "aws_vpc_security_group_ingress_rule" "syslog_tcp" {
  security_group_id = aws_security_group.soar.id
  cidr_ipv4         = var.syslog_cidr
  from_port         = 514
  to_port           = 514
  ip_protocol       = "tcp"
}

resource "aws_vpc_security_group_ingress_rule" "syslog_udp" {
  security_group_id = aws_security_group.soar.id
  cidr_ipv4         = var.syslog_cidr
  from_port         = 514
  to_port           = 514
  ip_protocol       = "udp"
}

# Nodes to AWS APIs (SSM, SNS, Secrets Manager, S3)
resource "aws_vpc_security_group_egress_rule" "soar_https" {
  security_group_id = aws_security_group.soar.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
}

# DNS via the VPC resolver (needed for the private zone)
resource "aws_vpc_security_group_egress_rule" "soar_dns_udp" {
  security_group_id = aws_security_group.soar.id
  cidr_ipv4         = aws_vpc.soar.cidr_block
  from_port         = 53
  to_port           = 53
  ip_protocol       = "udp"
}

resource "aws_vpc_security_group_egress_rule" "soar_dns_tcp" {
  security_group_id = aws_security_group.soar.id
  cidr_ipv4         = aws_vpc.soar.cidr_block
  from_port         = 53
  to_port           = 53
  ip_protocol       = "tcp"
}

# Nodes to the database only
resource "aws_vpc_security_group_egress_rule" "soar_to_db" {
  security_group_id            = aws_security_group.soar.id
  referenced_security_group_id = aws_security_group.db.id
  from_port                    = 5432
  to_port                      = 5432
  ip_protocol                  = "tcp"
}

resource "aws_vpc_security_group_ingress_rule" "db_from_soar" {
  security_group_id            = aws_security_group.db.id
  referenced_security_group_id = aws_security_group.soar.id
  from_port                    = 5432
  to_port                      = 5432
  ip_protocol                  = "tcp"
}

resource "aws_vpc_security_group_ingress_rule" "endpoints_from_soar" {
  security_group_id            = aws_security_group.endpoints.id
  referenced_security_group_id = aws_security_group.soar.id
  from_port                    = 443
  to_port                      = 443
  ip_protocol                  = "tcp"
}

# Syslog to the listener nodes (node-to-node in the SOAR VPC)
resource "aws_vpc_security_group_egress_rule" "soar_syslog_tcp" {
  security_group_id = aws_security_group.soar.id
  cidr_ipv4         = var.syslog_cidr
  from_port         = 514
  to_port           = 514
  ip_protocol       = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "soar_syslog_udp" {
  security_group_id = aws_security_group.soar.id
  cidr_ipv4         = var.syslog_cidr
  from_port         = 514
  to_port           = 514
  ip_protocol       = "udp"
}