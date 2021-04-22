resource "aws_security_group" "msr" {
  name        = "${var.cluster_name}-msr-replicas"
  description = "msr"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

locals {
  subnet_count = "${length(var.subnet_ids)}"
}

resource "aws_instance" "msr_replica" {
  count = var.msr_replica_count

  tags = map(
    "Name", "${var.cluster_name}-msr-${count.index + 1}",
    "Role", "msr"
  )

  instance_type          = var.master_type
  ami                    = var.image_id
  key_name               = var.ssh_key
  vpc_security_group_ids = [var.security_group_id, aws_security_group.msr.id]
  subnet_id              = var.subnet_ids[count.index % local.subnet_count]
  ebs_optimized          = true
  user_data              = <<EOF
#!/bin/bash
# Use full qualified private DNS name for the host name.  Kube wants it this way.
HOSTNAME=$(curl http://169.254.169.254/latest/meta-data/hostname)
echo $HOSTNAME > /etc/hostname
sed -i "s|\(127\.0\..\.. *\)localhost|\1$HOSTNAME|" /etc/hosts
hostname $HOSTNAME
EOF

  lifecycle {
    ignore_changes = [ami]
  }

  root_block_device {
    volume_type = "gp2"
    volume_size = var.master_volume_size
  }
}

resource "aws_lb" "msr_lb" {
  name               = "${var.cluster_name}-msr-lb"
  internal           = false
  load_balancer_type = "network"
  subnets            = var.subnet_ids

  tags = {
    Cluster = var.cluster_name
  }
}

resource "aws_lb_target_group" "msr_https" {
  name     = "${var.cluster_name}-msr-api"
  port     = 443
  protocol = "TCP"
  vpc_id   = var.vpc_id
}

resource "aws_lb_listener" "msr_https" {
  load_balancer_arn = aws_lb.msr_lb.arn
  port              = 443
  protocol          = "TCP"

  default_action {
    target_group_arn = aws_lb_target_group.msr_https.arn
    type             = "forward"
  }
}

resource "aws_lb_target_group_attachment" "msr_https" {
  count            = var.msr_replica_count
  target_group_arn = aws_lb_target_group.msr_https.arn
  target_id        = aws_instance.msr_replica[count.index].id
  port             = 443
}

data "aws_route53_zone" "selected" {
  name         = "cluster.avinashdesireddy.com."
}

resource "aws_route53_record" "www" {
  zone_id = data.aws_route53_zone.selected.zone_id
  name    = "${var.cluster_name}-msr.${data.aws_route53_zone.selected.name}"
  type    = "A"

  alias {
    name                   = aws_lb.msr_lb.dns_name
    zone_id                = aws_lb.msr_lb.zone_id
    evaluate_target_health = true
  }
}