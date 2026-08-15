output "instance_id" {
  value = aws_instance.main.id
}

output "public_ip" {
  value = aws_eip.main.public_ip
}

output "ssh" {
  description = "After nixos-anywhere installs the box."
  value       = "ssh matt@${aws_eip.main.public_ip}"
}
