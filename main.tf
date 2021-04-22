provider "aws" {
  region = var.aws_region
}

module "vpc" {
  source       = "./modules/vpc"
  cluster_name = var.cluster_name
  host_cidr    = var.vpc_cidr
}

module "common" {
  source       = "./modules/common"
  cluster_name = var.cluster_name
  vpc_id       = module.vpc.id
}

/* MKE Manager Instances */
module "masters" {
  source                = "./modules/master"
  master_count          = var.master_count
  vpc_id                = module.vpc.id
  cluster_name          = var.cluster_name
  subnet_ids            = module.vpc.public_subnet_ids
  security_group_id     = module.common.security_group_id
  image_id              = module.common.image_id
  kube_cluster_tag      = module.common.kube_cluster_tag
  ssh_key               = var.cluster_name
}

/* MSR Replica Instances */
module "msr" {
  source                = "./modules/msr"
  msr_replica_count     = var.msr_replica_count
  vpc_id                = module.vpc.id
  cluster_name          = var.cluster_name
  subnet_ids            = module.vpc.public_subnet_ids
  security_group_id     = module.common.security_group_id
  image_id              = module.common.image_id
  ssh_key               = var.cluster_name
}

module "workers" {
  source                = "./modules/worker"
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

module "windows_workers" {
  source                         = "./modules/windows_worker"
  worker_count                   = var.windows_worker_count
  vpc_id                         = module.vpc.id
  cluster_name                   = var.cluster_name
  subnet_ids                     = module.vpc.public_subnet_ids
  security_group_id              = module.common.security_group_id
  image_id                       = module.common.windows_2019_image_id
  kube_cluster_tag               = module.common.kube_cluster_tag
  worker_type                    = var.worker_type
  windows_administrator_password = var.windows_administrator_password
}

locals {
  managers = [
    for host in module.masters.machines : {
      address = host.public_ip
      ssh = {
        user    = "ec2-user"
        keyPath = "./ssh_keys/${var.cluster_name}.pem"
      }
      role             = host.tags["Role"]
      privateInterface = "ens5"
    }
  ]
  replicas = [
    for host in module.msr.machines : {
      address = host.public_ip
      ssh = {
        user    = "ec2-user"
        keyPath = "./ssh_keys/${var.cluster_name}.pem"
      }
      role             = host.tags["Role"]
      privateInterface = "ens5"
    }
  ]

  workers = [
    for host in module.workers.machines : {
      address = host.public_ip
      ssh = {
        user    = "ec2-user"
        keyPath = "./ssh_keys/${var.cluster_name}.pem"
      }
      role             = host.tags["Role"]
      privateInterface = "ens5"
    }
  ]
  windows_workers = [
    for host in module.windows_workers.machines : {
      address = host.public_ip
      winRM = {
        user     = "Administrator"
        password = var.windows_administrator_password
        useHTTPS = true
        insecure = true
      }
      role             = host.tags["Role"]
      privateInterface = "Ethernet 2"
    }
  ]
  launchpad_tmpl = {
    apiVersion = "launchpad.mirantis.com/mke/v1.1"
    kind       = "mke"
    spec = {
      mke = {
        adminUsername = "admin"
        adminPassword = var.admin_password
        installFlags : [
          "--default-node-orchestrator=kubernetes",
          "--san=${module.masters.lb_dns_name}",
        ]
      }
      hosts = concat(local.managers, local.replicas, local.workers, local.windows_workers)
    }
  }
}

output "mke_cluster" {
  value = yamlencode(local.launchpad_tmpl)
}