#output "private_subnet_ids" {
#  description = "The IDs of the private subnets as list"
#  value       = [aws_subnet.private_subnet.*.id]
#}