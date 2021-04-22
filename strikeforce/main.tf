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
  dns_name = "mke"
  loadbalancer          = module.mke_lb.loadbalancer
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
  dns_name = "msr"
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
  //image_id              = "ami-09d9c5cdcfb8fc655"
  kube_cluster_tag      = module.common.kube_cluster_tag
  ssh_key               = var.cluster_name
  worker_type           = var.worker_type
}

module "windows_workers" {
  source                         = "../modules/windows_worker"
  worker_count                   = var.windows_worker_count
  vpc_id                         = module.vpc.id
  cluster_name                   = var.cluster_name
  subnet_ids                     = module.vpc.public_subnet_ids
  security_group_id              = module.common.security_group_id
  image_id                       = "ami-05a67f224fcf5c170"
  //image_id                       = module.common.windows_2019_image_id
  kube_cluster_tag               = module.common.kube_cluster_tag
  worker_type                    = var.worker_type
  windows_administrator_password = var.windows_administrator_password
}

/*
locals {
  managers = [
    for host in module.masters.machines : {
      role             = host.tags["Role"]
      ssh = {
        address = host.public_ip
        user    = "ec2-user"
        keyPath = "./ssh_keys/${var.cluster_name}.pem"
      }
    }
  ]
  replicas = [
    for host in module.msr.machines : {
      role             = host.tags["Role"]
      ssh = {
        address = host.public_ip
        user    = "ec2-user"
        keyPath = "./ssh_keys/${var.cluster_name}.pem"
      }
    }
  ]

  workers = [
    for host in module.workers.machines : {
      role             = host.tags["Role"]      
      ssh = {
        address = host.public_ip
        user    = "ec2-user"
        keyPath = "./ssh_keys/${var.cluster_name}.pem"
      }
    }
  ]
  windows_workers = [
    for host in module.windows_workers.machines : {
      role             = host.tags["Role"]
      winRM = {
        address = host.public_ip
        user     = "Administrator"
        password = var.windows_administrator_password
        useHTTPS = true
        insecure = true
      }
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
*/
/*resource "local_file" "AnsibleInventory" {
 content = templatefile("inventory.tmpl",
  {
    names = aws_instance.mke_master.*.public_ip
  }
 )
 filename = "inventory"
}
*/
