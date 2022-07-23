# Outputs to read assigned IP addresses
output "ansible-ip" {
  value = proxmox_vm_qemu.ansible.default_ipv4_address
}

output "gitea-ip" {
  value = proxmox_vm_qemu.gitea.default_ipv4_address
}

output "jenkins-ip" {
  value = proxmox_vm_qemu.jenkins.default_ipv4_address
}

output "pgpool-ip" {
  value = proxmox_vm_qemu.pgpool.default_ipv4_address
}

output "postgresql-ips" {
  value = proxmox_vm_qemu.postgresql.*.default_ipv4_address
}

output "k8s-cplane-ip" {
  value = proxmox_vm_qemu.k8s-cplane.default_ipv4_address
}

output "k8s-node-ips" {
  value = proxmox_vm_qemu.k8s-node.*.default_ipv4_address
}