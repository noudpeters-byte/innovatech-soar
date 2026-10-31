variable "region" {
  type    = string
  default = "eu-central-1"
}

variable "onprem_cidr" {
  description = "CIDR of the simulated on-prem network that sends syslog"
  type        = string
  default     = "10.10.0.0/16"
}