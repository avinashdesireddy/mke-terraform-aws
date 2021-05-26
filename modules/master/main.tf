resource "aws_security_group" "master" {
  name        = "${var.cluster_name}-managers"
  description = "mke cluster managers"
  vpc_id      = var.vpc_id

  ingress {
    from_port = 2379
    to_port   = 2380
    protocol  = "tcp"
    self      = true
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 444
    to_port     = 444
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 6443
    to_port     = 6443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

locals {
  subnet_count = "${length(var.subnet_ids)}"
}

resource "aws_instance" "mke_master" {
  count = var.master_count

  tags = map(
    "Name", "${var.cluster_name}-master-${count.index + 1}",
    "Role", "manager",
    "${var.kube_cluster_tag}", "shared"
  )

  instance_type          = var.master_type
  ami                    = var.image_id
  key_name               = var.ssh_key
  vpc_security_group_ids = [var.security_group_id, aws_security_group.master.id]
  subnet_id              = var.subnet_ids[count.index % local.subnet_count]
  ebs_optimized          = true
  user_data              = <<EOF
#!/bin/bash
# Use full qualified private DNS name for the host name.  Kube wants it this way.
HOSTNAME=$(curl http://169.254.169.254/latest/meta-data/hostname)
echo $HOSTNAME > /etc/hostname
sed -i "s|\(127\.0\..\.. *\)localhost|\1$HOSTNAME|" /etc/hosts
hostname $HOSTNAME
sed -i s/SELINUX=enforcing/SELINUX=disabled/g /etc/selinux/config
setenforce 0
curl https://get.mirantis.com/ | DOCKER_URL="https://repos.mirantis.com" bash
systemctl enable docker && systemctl start docker
EOF

  lifecycle {
    ignore_changes = [ami]
  }

  root_block_device {
    volume_type = "gp2"
    volume_size = var.master_volume_size
  }
}

# data "aws_route53_zone" "selected" {
#   name         = "cluster.avinashdesireddy.com."
# }

# resource "aws_route53_record" "www" {
#   zone_id = data.aws_route53_zone.selected.zone_id
#   name    = "${var.cluster_name}-mke.${data.aws_route53_zone.selected.name}"
#   type    = "A"

#   alias {
#     name                   = aws_lb.mke_master.dns_name
#     zone_id                = aws_lb.mke_master.zone_id
#     evaluate_target_health = true
#   }
# }
