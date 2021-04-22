variable "cluster_name" {}

variable "vpc_id" {}

variable "role_name" {}

variable "instances" {}

variable "ports" {
  description = "List of listening ports to target ports"
  type        = list
  default     = ["443/tcp:443/tcp", "6443/tcp:6443/tcp"]
}

variable "subnet_ids" {
  type = list(string)
}