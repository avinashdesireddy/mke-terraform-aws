provider "aws" {
  region = var.aws_region
}

module "vpc" {
  source       = "../modules/vpc"
  cluster_name = var.cluster_name
  host_cidr    = var.vpc_cidr
}

module "common" {
  source       = "../modules/common"
  cluster_name = var.cluster_name
  vpc_id       = module.vpc.id
}

/* MKE Manager Instances */
module "masters" {
  source                = "../modules/master"
  master_count          = var.master_count
  vpc_id                = module.vpc.id
  cluster_name          = var.cluster_name
  subnet_ids            = module.vpc.public_subnet_ids
  security_group_id     = module.common.security_group_id
  image_id              = module.common.image_id
  kube_cluster_tag      = module.common.kube_cluster_tag
  ssh_key               = var.cluster_name
}

/* MKE LB Config */
module "mke_lb" {
  source = "../modules/loadbalancer"
  vpc_id                = module.vpc.id
  cluster_name          = var.cluster_name
  role_name             = "master"
  ports                 = var.mke_ports
  instances             = module.masters.machines.*.id
  subnet_ids            = module.vpc.public_subnet_ids
}

module "mke_dns" {
  source = "../modules/route_53"
  dns_name = "panda-mke"
  loadbalancer  = module.mke_lb.loadbalancer
}

/* MSR Replica Instances */
module "msr" {
  source                = "../modules/msr"
  msr_replica_count     = var.msr_replica_count
  vpc_id                = module.vpc.id
  cluster_name          = var.cluster_name
  subnet_ids            = module.vpc.public_subnet_ids
  security_group_id     = module.common.security_group_id
  image_id              = module.common.image_id
  ssh_key               = var.cluster_name
}
/* MSR LB Config */
module "msr_lb" {
  source = "../modules/loadbalancer"
  vpc_id                = module.vpc.id
  cluster_name          = var.cluster_name
  role_name             = "msr"
  ports                 = var.msr_ports
  instances             = module.msr.machines.*.id
  subnet_ids            = module.vpc.public_subnet_ids
}

module "msr_dns" {
  source = "../modules/route_53"
  dns_name = "panda-msr"
  loadbalancer          = module.msr_lb.loadbalancer
}

module "workers" {
  source                = "../modules/worker"
  worker_count          = var.worker_count
  vpc_id                = module.vpc.id
  cluster_name          = var.cluster_name
  subnet_ids            = module.vpc.public_subnet_ids
  security_group_id     = module.common.security_group_id
  image_id              = module.common.image_id
  kube_cluster_tag      = module.common.kube_cluster_tag
  ssh_key               = var.cluster_name
  worker_type           = var.worker_type
}

locals {
  managers = [
    for host in module.masters.machines : {
      address = host.public_ip
      name = host.tags.Name
    }
  ]
  replicas = [
    for host in module.msr.machines : {
      address = host.public_ip
      name = host.tags.Name
    }
  ]

  workers = [
    for host in module.workers.machines : {
      address = host.public_ip
      name = host.tags.Name
    }
  ]

  hosts_tmpl = {
    hosts = concat(local.managers, local.replicas, local.workers)
  }
}

output "mke_cluster" {
  value = <<EOT
%{ for host in local.hosts_tmpl.hosts ~}
${host.address} ${host.name}
%{ endfor ~}
EOT
}