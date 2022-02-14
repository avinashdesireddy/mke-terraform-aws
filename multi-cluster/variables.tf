variable "cluster_name" {
}

variable "cluster1" {  
}

variable "cluster2" {  
}

variable "aws_region" {
  default = "us-west-1"
}

variable "vpc_cidr" {
  default = "172.31.0.0/16"
}

variable "admin_password" {
}

variable "master_count" {
  default = 1
}

variable "msr_replica_count" {
  default = 0
}

variable "worker_count" {
  default = 1
}

variable "windows_worker_count" {
  default = 1
}

variable "master_type" {
  default = "m5.2xlarge"
}

variable "worker_type" {
  default = "m5.2xlarge"
}

variable "instance_volume_size" {
  default = 100
}

variable "worker_volume_size" {
  default = 200
}

variable "windows_administrator_password" {
  default = "Password1"
}

variable "mke_ports" {
  default = ["443/tcp:443/tcp", "6443/tcp:6443/tcp"]
}

variable "msr_ports" {
  default = ["443/tcp:443/tcp"]
}

variable "mke_version" {
  default = "latest"
}

variable "master_image_id" {
  default = ""
}

variable "worker_image_id" {
  default = ""
}
