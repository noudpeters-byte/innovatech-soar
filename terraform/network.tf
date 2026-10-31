resource "aws_vpc" "soar" {
  cidr_block           = "10.20.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags                 = { Name = "soar-vpc" }
}

resource "aws_subnet" "soar_a" {
  vpc_id            = aws_vpc.soar.id
  cidr_block        = "10.20.1.0/24"
  availability_zone = "eu-central-1a"
  tags              = { Name = "soar-private-a" }
}

resource "aws_subnet" "soar_b" {
  vpc_id            = aws_vpc.soar.id
  cidr_block        = "10.20.2.0/24"
  availability_zone = "eu-central-1b"
  tags              = { Name = "soar-private-b" }
}

# Private route table: no internet route. Only the S3 gateway endpoint
# adds a route (the S3 prefix list), added by Terraform in endpoints.tf.
resource "aws_route_table" "soar_private" {
  vpc_id = aws_vpc.soar.id
  tags   = { Name = "soar-private-rt" }
}

resource "aws_route_table_association" "soar_a" {
  subnet_id      = aws_subnet.soar_a.id
  route_table_id = aws_route_table.soar_private.id
}

resource "aws_route_table_association" "soar_b" {
  subnet_id      = aws_subnet.soar_b.id
  route_table_id = aws_route_table.soar_private.id
}