# output "lb_dns_name" {
#     value = aws_lb.msr_lb.dns_name
# }

output "public_ips" {
    value = aws_instance.msr_replica.*.public_ip
}

output "private_ips" {
    value = aws_instance.msr_replica.*.private_ip
}

output "machines" {
  value = aws_instance.msr_replica
}
