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

/* MKE Manager Instances for cluster #1 */
module "masters-1" {
  source                = "../modules/master"
  master_count          = var.master_count
  vpc_id                = module.vpc.id
  cluster_name          = var.cluster1
  subnet_ids            = module.vpc.public_subnet_ids
  security_group_id     = module.common.security_group_id
  //image_id              = module.common.image_id
  image_id              = var.master_image_id
  kube_cluster_tag      = module.common.kube_cluster_tag
  ssh_key               = var.cluster_name
}

/* MKE Manager Instances for cluster #2 */
module "masters-2" {
  source                = "../modules/master"
  master_count          = var.master_count
  vpc_id                = module.vpc.id
  cluster_name          = var.cluster2
  subnet_ids            = module.vpc.public_subnet_ids
  security_group_id     = module.common.security_group_id
  //image_id              = module.common.image_id
  image_id              = var.master_image_id
  kube_cluster_tag      = module.common.kube_cluster_tag
  ssh_key               = var.cluster_name
}

module "workers-1" {
  source                = "../modules/worker"
  worker_count          = var.worker_count
  vpc_id                = module.vpc.id
  cluster_name          = var.cluster1
  subnet_ids            = module.vpc.public_subnet_ids
  security_group_id     = module.common.security_group_id
  //image_id              = module.common.image_id
  image_id              = var.worker_image_id
  kube_cluster_tag      = module.common.kube_cluster_tag
  ssh_key               = var.cluster_name
  worker_type           = var.worker_type
}

module "workers-2" {
  source                = "../modules/worker"
  worker_count          = var.worker_count
  vpc_id                = module.vpc.id
  cluster_name          = var.cluster2
  subnet_ids            = module.vpc.public_subnet_ids
  security_group_id     = module.common.security_group_id
  //image_id              = module.common.image_id
  image_id              = var.worker_image_id
  kube_cluster_tag      = module.common.kube_cluster_tag
  ssh_key               = var.cluster_name
  worker_type           = var.worker_type
}

/* MKE LB Config */
module "mke_lb-1" {
  source = "../modules/loadbalancer"
  vpc_id                = module.vpc.id
  cluster_name          = var.cluster1
  role_name             = "master"
  ports                 = var.mke_ports
  instances             = module.masters-1.machines.*.id
  subnet_ids            = module.vpc.public_subnet_ids
}

module "mke_dns-1" {
  source = "../modules/route_53"
  dns_name = "${var.cluster1}-mke"
  loadbalancer  = module.mke_lb-1.loadbalancer
}

/* MKE LB Config #2 */
module "mke_lb-2" {
  source = "../modules/loadbalancer"
  vpc_id                = module.vpc.id
  cluster_name          = var.cluster2
  role_name             = "master"
  ports                 = var.mke_ports
  instances             = module.masters-2.machines.*.id
  subnet_ids            = module.vpc.public_subnet_ids
}

module "mke_dns-2" {
  source = "../modules/route_53"
  dns_name = "${var.cluster2}-mke"
  loadbalancer  = module.mke_lb-2.loadbalancer
}

locals {
  managers-1 = [
    for host in module.masters-1.machines : {
      ssh = {
        address = host.public_ip
        user    = "ec2-user"
        keyPath = "./ssh_keys/${var.cluster_name}.pem"
      }
      role             = host.tags["Role"]
    }
  ]

  managers-2 = [
    for host in module.masters-2.machines : {
      ssh = {
        address = host.public_ip
        user    = "ec2-user"
        keyPath = "./ssh_keys/${var.cluster_name}.pem"
      }
      role             = host.tags["Role"]
    }
  ]

  workers-1 = [
    for host in module.workers-1.machines : {
      
      ssh = {
        address = host.public_ip
        user    = "ec2-user"
        keyPath = "./ssh_keys/${var.cluster_name}.pem"
      }
      role             = host.tags["Role"]
    }
  ]

  workers-2 = [
    for host in module.workers-2.machines : {
      
      ssh = {
        address = host.public_ip
        user    = "ec2-user"
        keyPath = "./ssh_keys/${var.cluster_name}.pem"
      }
      role             = host.tags["Role"]
    }
  ]
  
  launchpad_tmpl-1 = {
    apiVersion = "launchpad.mirantis.com/mke/v1.3"
    kind       = "mke"
    spec = {
      mke = {
        version    = "${var.mke_version}"
        adminUsername = "admin"
        adminPassword = var.admin_password
        caCertPath = "${var.caCertPath}"
        certPath = "${var.certPath}"
        keyPath = "${var.keyPath}"
        licenseFilePath = "${var.licenseFilePath}"
        installFlags : [
          "--default-node-orchestrator=kubernetes",
          "--san=${var.cluster1}-mke.cluster.avinashdesireddy.com",
        ]
      }
      hosts = concat(local.managers-1, local.workers-1)
    }
  }

  launchpad_tmpl-2 = {
    apiVersion = "launchpad.mirantis.com/mke/v1.3"
    kind       = "mke"
    spec = {
      mke = {
        version    = "${var.mke_version}"
        adminUsername = "admin"
        adminPassword = var.admin_password
        caCertPath = "${var.caCertPath}"
        certPath = "${var.certPath}"
        keyPath = "${var.keyPath}"
        licenseFilePath = "${var.licenseFilePath}"
        installFlags : [
          "--default-node-orchestrator=kubernetes",
          "--san=${var.cluster2}-mke.cluster.avinashdesireddy.com",
        ]
      }
      hosts = concat(local.managers-2, local.workers-2)
    }
  }
}

output "mke_cluster-1" {
  value = yamlencode(local.launchpad_tmpl-1)
}

output "mke_cluster-2" {
  value = yamlencode(local.launchpad_tmpl-2)
}