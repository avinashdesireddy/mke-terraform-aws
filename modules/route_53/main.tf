
data "aws_route53_zone" "selected" {
  name         = "cluster.avinashdesireddy.com."
}

resource "aws_route53_record" "www" {
  zone_id = data.aws_route53_zone.selected.zone_id
  name    = "${var.dns_name}.${data.aws_route53_zone.selected.name}"
  type    = "A"

  alias {
    name                   = var.loadbalancer.dns_name
    zone_id                = var.loadbalancer.zone_id
    evaluate_target_health = true
  }
}