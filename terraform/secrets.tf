resource "random_password" "db" {
  length  = 24
  special = false
}

# recovery_window_in_days = 0 lets destroy and rebuild reuse the name immediately
resource "aws_secretsmanager_secret" "db" {
  name                    = "soar/db-credentials"
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "db" {
  secret_id = aws_secretsmanager_secret.db.id
  secret_string = jsonencode({
    host     = aws_route53_record.db.fqdn
    port     = 5432
    dbname   = "soar"
    username = "soaradmin"
    password = random_password.db.result
  })
}