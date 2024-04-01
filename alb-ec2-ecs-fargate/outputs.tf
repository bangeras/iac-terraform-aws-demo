output "private_subnet_ids" {
  description = "The IDs of the private subnets as list"
  value       = [aws_subnet.private_subnet.*.id]
}

output "public_subnet_ids" {
  description = "The IDs of the public subnets as list"
  value       = [aws_subnet.public_subnet.*.id]
}
