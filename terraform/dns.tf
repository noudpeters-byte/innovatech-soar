# Private zone: names resolve only inside the SOAR VPC (P2-04)
resource "aws_route53_zone" "internal" {
  name = "innovatech.internal"
  vpc {
    vpc_id = aws_vpc.soar.id
  }
}

resource "aws_route53_record" "db" {
  zone_id = aws_route53_zone.internal.zone_id
  name    = "db.innovatech.internal"
  type    = "CNAME"
  ttl     = 60
  records = [aws_db_instance.postgres.address]
}