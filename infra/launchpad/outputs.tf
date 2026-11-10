output "instance_id" {
  value = aws_instance.main.id
}

output "security_group_id" {
  description = "Used by the bring-up runbook to add and remove the temporary SSH rule."
  value       = aws_security_group.main.id
}

output "public_ip" {
  value = aws_eip.main.public_ip
}

output "ssh" {
  description = "After nixos-anywhere installs the box."
  value       = "ssh matt@${aws_eip.main.public_ip}"
}
