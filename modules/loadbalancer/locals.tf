locals {
  listener_ports     = split(",", replace(join(",", var.ports), "/([0-9]+)\\/?([tu][cd]p)?:([0-9]+)\\/?([tu][cd]p)?/", "$1"))
  listener_protocols = split(",", replace(join(",", var.ports), "/([0-9]+)\\/?([tu][cd]p)?:([0-9]+)\\/?([tu][cd]p)?/", "$2"))
  target_ports       = split(",", replace(join(",", var.ports), "/([0-9]+)\\/?([tu][cd]p)?:([0-9]+)\\/?([tu][cd]p)?/", "$3"))
  target_protocols   = split(",", replace(join(",", var.ports), "/([0-9]+)\\/?([tu][cd]p)?:([0-9]+)\\/?([tu][cd]p)?/", "$4"))
}