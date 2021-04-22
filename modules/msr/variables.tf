variable "cluster_name" {}

variable "vpc_id" {}

variable "security_group_id" {}

variable "subnet_ids" {
  type = list(string)
}

variable "image_id" {}

variable "ssh_key" {
  description = "SSH key name"
}

variable "msr_replica_count" {
  default = 1
}

variable "master_type" {
  default = "m5.large"
}

variable "master_volume_size" {
  default = 100
}
