variable "domain_name" {}
variable "aws_region" {}

variable "tags" {
  type    = "map"
  default = {}
}

variable "hosted_zone" {}

variable "domain_aliases" {
  type  = list
  default = {}
}
