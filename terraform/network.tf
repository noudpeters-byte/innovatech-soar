resource "aws_vpc" "soar" {
  cidr_block           = "10.20.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags                 = { Name = "soar-vpc" }
}

# Application subnets (listener nodes)
resource "aws_subnet" "app_a" {
  vpc_id            = aws_vpc.soar.id
  cidr_block        = "10.20.1.0/24"
  availability_zone = "eu-central-1a"
  tags              = { Name = "soar-app-a" }
}

resource "aws_subnet" "app_b" {
  vpc_id            = aws_vpc.soar.id
  cidr_block        = "10.20.2.0/24"
  availability_zone = "eu-central-1b"
  tags              = { Name = "soar-app-b" }
}

# Database subnets (RDS needs two AZs)
resource "aws_subnet" "db_a" {
  vpc_id            = aws_vpc.soar.id
  cidr_block        = "10.20.21.0/24"
  availability_zone = "eu-central-1a"
  tags              = { Name = "soar-db-a" }
}

resource "aws_subnet" "db_b" {
  vpc_id            = aws_vpc.soar.id
  cidr_block        = "10.20.22.0/24"
  availability_zone = "eu-central-1b"
  tags              = { Name = "soar-db-b" }
}

# One private route table, no internet route.
# The S3 gateway endpoint adds the only extra route (see endpoints.tf).
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.soar.id
  tags   = { Name = "soar-private-rt" }
}

resource "aws_route_table_association" "app_a" {
  subnet_id      = aws_subnet.app_a.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "app_b" {
  subnet_id      = aws_subnet.app_b.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "db_a" {
  subnet_id      = aws_subnet.db_a.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "db_b" {
  subnet_id      = aws_subnet.db_b.id
  route_table_id = aws_route_table.private.id
}