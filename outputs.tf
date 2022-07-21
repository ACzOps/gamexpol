# Outputs to read assigned IP addresses
output "ansible-ip" {
  value = proxmox_vm_qemu.ansible.default_ipv4_address
}

output "pgpool-ip" {
  value = proxmox_vm_qemu.pgpool.default_ipv4_address
}

output "postgresql-ips" {
  value = proxmox_vm_qemu.postgresql.*.default_ipv4_address
}