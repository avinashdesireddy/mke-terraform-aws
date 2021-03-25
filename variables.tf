variable "cluster_name" {
  default = "avinash"
}

variable "aws_region" {
  default = "us-west-1"
}

variable "vpc_cidr" {
  default = "172.31.0.0/16"
}

variable "admin_password" {
  default = "Mkeadmin!"
}


variable "master_count" {
  default = 3
}

variable "worker_count" {
  default = 3
}

variable "windows_worker_count" {
  default = 1
}

variable "master_type" {
  default = "m5.large"
}

variable "worker_type" {
  default = "m5.large"
}

variable "master_volume_size" {
  default = 100
}

variable "worker_volume_size" {
  default = 100
}

variable "windows_administrator_password" {
  default = "Mkeadmin!"
}
