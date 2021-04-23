resource "aws_lb" "loadbalancer" {
  name               = "${var.cluster_name}-${var.role_name}-lb"
  internal           = false
  load_balancer_type = "network"
  subnets            = var.subnet_ids

  tags = {
    Cluster = var.cluster_name
  }
}

resource "aws_lb_target_group" "targets" {
  count    = length(var.ports)

  name     = "${var.cluster_name}-${var.role_name}-${element(local.target_ports, count.index)}"
  protocol = upper(element(local.target_protocols, count.index) != "" ? element(local.target_protocols, count.index) : "tcp")
  port     = element(local.target_ports, count.index)
  
  vpc_id   = var.vpc_id
}

resource "aws_lb_listener" "listener" {
  count             = length(var.ports)

  load_balancer_arn = aws_lb.loadbalancer.arn
  port              = element(local.listener_ports, count.index)
  protocol          = upper(element(local.listener_protocols, count.index) != "" ? element(local.listener_protocols, count.index) : "tcp")

  default_action {
    target_group_arn = element(aws_lb_target_group.targets.*.arn, count.index)
    type             = "forward"
  }
}

data "template_file" "target_group_arns" {
  count = length(var.ports) * length(var.instances)

  template = "$${target_group_arn}"
  vars = {
    target_group_arn = element(aws_lb_target_group.targets.*.arn, floor(count.index / length(var.instances)))
  }
}

resource "aws_lb_target_group_attachment" "target_group_attachment" {
  count            = length(var.ports) * length(var.instances)
  target_group_arn = element(data.template_file.target_group_arns.*.rendered, count.index)
  target_id        = element(var.instances, count.index)
}