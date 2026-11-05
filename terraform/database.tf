resource "aws_db_subnet_group" "soar" {
  name       = "soar-db-subnets"
  subnet_ids = [aws_subnet.db_a.id, aws_subnet.db_b.id]
  tags       = { Name = "soar-db-subnets" }
}

resource "aws_db_instance" "postgres" {
  identifier              = "soar-postgres"
  engine                  = "postgres"
  instance_class          = "db.t3.micro"
  allocated_storage       = 20
  db_name                 = "soar"
  username                = "soaradmin"
  password                = random_password.db.result
  db_subnet_group_name    = aws_db_subnet_group.soar.name
  vpc_security_group_ids  = [aws_security_group.db.id]
  publicly_accessible     = false
  storage_encrypted       = true
  multi_az                = var.db_multi_az
  backup_retention_period = 1
  skip_final_snapshot     = true
  tags                    = { Name = "soar-postgres" }
}