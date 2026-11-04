variable "region" {
  type    = string
  default = "eu-central-1"
}

variable "alert_email" {
  type    = string
  default = "noudpeters8@gmail.com"
}

# Who may send syslog to the listener. Temporary: the SOAR VPC only,
# until the hybrid design is agreed with Andrius.
variable "syslog_cidr" {
  type    = string
  default = "10.20.0.0/16"
}

# Standby in a second AZ. Doubles RDS cost; set to false to save money.
variable "db_multi_az" {
  type    = bool
  default = true
}