variable "cluster_name" {
  default = "my-cluster"
}

variable "aws_region" {
  default = "us-west-1"
}

variable "vpc_cidr" {
  default = "172.31.0.0/16"
}

variable "admin_password" {}


variable "master_count" {
  default = 1
}

variable "msr_replica_count" {
  default = 1
}

variable "worker_count" {
  default = 2
}

variable "windows_worker_count" {
  default = 1
}

variable "master_type" {
  default = "t3.xlarge"
}

variable "worker_type" {
  default = "m5.large"
}

variable "instance_volume_size" {
  default = 100
}

variable "worker_volume_size" {
  default = 100
}

variable "windows_administrator_password" { }

variable "mke_ports" {
  default = ["443/tcp:443/tcp", "6443/tcp:6443/tcp"]
}

variable "msr_ports" {
  default = ["443/tcp:443/tcp"]
}