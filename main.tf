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
  //image_id              = module.common.image_id
  image_id              = var.master_image_id
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
  //image_id              = module.common.image_id
  image_id              = var.worker_image_id
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
  image_id                       = "ami-0f57c51fc7ec22bba"
//  image_id                       = module.common.windows_2019_image_id
  kube_cluster_tag               = module.common.kube_cluster_tag
  worker_type                    = var.worker_type
  windows_administrator_password = var.windows_administrator_password
}

/* MKE LB Config */
module "mke_lb" {
  source = "./modules/loadbalancer"
  vpc_id                = module.vpc.id
  cluster_name          = var.cluster_name
  role_name             = "master"
  ports                 = var.mke_ports
  instances             = module.masters.machines.*.id
  subnet_ids            = module.vpc.public_subnet_ids
}

module "mke_dns" {
  source = "./modules/route_53"
  dns_name = "${var.cluster_name}-mke"
  loadbalancer  = module.mke_lb.loadbalancer
}


locals {
  managers = [
    for host in module.masters.machines : {
      ssh = {
        address = host.public_ip
        user    = "ec2-user"
        keyPath = "./ssh_keys/${var.cluster_name}.pem"
      }
      role             = host.tags["Role"]
    }
  ]
  replicas = [
    for host in module.msr.machines : {
      ssh = {
        address = host.public_ip
        user    = "ec2-user"
        keyPath = "./ssh_keys/${var.cluster_name}.pem"
      }
      role             = host.tags["Role"]
    }
  ]

  workers = [
    for host in module.workers.machines : {
      
      ssh = {
        address = host.public_ip
        user    = "ec2-user"
        keyPath = "./ssh_keys/${var.cluster_name}.pem"
      }
      role             = host.tags["Role"]
    }
  ]
  windows_workers = [
    for host in module.windows_workers.machines : {
      winRM = {
        address  = host.public_ip
        user     = "Administrator"
        password = var.windows_administrator_password
        useHTTPS = true
        insecure = true
      }
      role             = host.tags["Role"]
    }
  ]
  launchpad_tmpl = {
    apiVersion = "launchpad.mirantis.com/mke/v1.3"
    kind       = "mke"
    spec = {
      mke = {
        version    = "${var.mke_version}"
        adminUsername = "admin"
        adminPassword = var.admin_password
        caCertPath = "/Users/avinashdesireddy/go/src/github.com/avinashdesireddy/projects/letsencrypt/config/live/cluster.avinashdesireddy.com/fullchain.pem"
        certPath = "/Users/avinashdesireddy/go/src/github.com/avinashdesireddy/projects/letsencrypt/config/live/cluster.avinashdesireddy.com/cert.pem"
        keyPath = "/Users/avinashdesireddy/go/src/github.com/avinashdesireddy/projects/letsencrypt/config/live/cluster.avinashdesireddy.com/privkey.pem"
        licenseFilePath = "/Users/avinashdesireddy/secrets/docker_subscription.lic"
        installFlags : [
          "--default-node-orchestrator=kubernetes",
          "--san=${var.cluster_name}-mke.cluster.avinashdesireddy.com",
        ]
      }
      hosts = concat(local.managers, local.replicas, local.workers, local.windows_workers)
    }
  }
}

output "mke_cluster" {
  value = yamlencode(local.launchpad_tmpl)
}