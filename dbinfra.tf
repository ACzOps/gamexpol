# PGPool server
resource "proxmox_vm_qemu" "pgpool" {
  name = "pgpool"
  desc = "Virtual Machine for PGPool II"

  target_node = var.target_node
  onboot      = true

  clone   = var.template
  os_type = "cloud-init"
  agent   = 1

  cores   = 1
  sockets = 1
  memory  = 2048
  cpu     = "host"

  vga {
    type   = "std"
    memory = 4
  }

  network {
    model  = "virtio"
    bridge = "vmbr0"
  }

  ipconfig0 = "ip=dhcp,ip6=dhcp"

  disk {
    type    = "scsi"
    storage = "local-lvm"
    size    = "4G"
  }

  cicustom = "user=local:snippets/postgresql-ci.yml"
}

# PostgreSQL + etcd node servers
resource "proxmox_vm_qemu" "postgresql" {
  count = 3
  name  = "postgresql-${count.index + 1}"
  desc  = "Virtual Machine for PostgreSQL node ${count.index + 1}"

  target_node = var.target_node
  onboot      = true

  clone   = var.template
  os_type = "cloud-init"
  agent   = 1

  cores   = 2
  sockets = 1
  memory  = 2048
  cpu     = "host"

  vga {
    type   = "std"
    memory = 4
  }

  network {
    model  = "virtio"
    bridge = "vmbr0"
  }

  ipconfig0 = "ip=dhcp,ip6=dhcp"

  disk {
    type    = "scsi"
    storage = "local-lvm"
    size    = "15G"
  }

  cicustom = "user=local:snippets/postgresql-ci.yml"
}

# Ansible server
resource "proxmox_vm_qemu" "ansible" {
  name = "ansible"
  desc = "Virtual Machine for Ansible"

  target_node = var.target_node
  onboot      = true

  clone   = var.template
  os_type = "cloud-init"
  agent   = 1

  cores   = 4
  sockets = 1
  memory  = 6144
  cpu     = "host"

  vga {
    type   = "std"
    memory = 4
  }

  network {
    model  = "virtio"
    bridge = "vmbr0"
  }

  ipconfig0 = "ip=dhcp,ip6=dhcp"

  disk {
    type    = "scsi"
    storage = "local-lvm"
    size    = "10G"
  }

  cicustom = "user=local:snippets/ansible4db-ci.yml"
}


#### Ansible inventory YAML file creation

# Local variables with data to send inventory
locals {
  hypervisor_private_key_path = "/root/.ssh/dbkey"
  ansible_ssh_user            = "ansible"
  ansible_ssh_port            = 22
  ansible_local_inventory     = "/root/infra/database/ansible/ansible-inventory.yaml"
  ansible_remote_inventory    = "/home/ansible/ansible-inventory.yaml"
  ansible_config_path         = "/home/ansible/.ansible.cfg"
  ansible_private_key_path    = "/home/ansible/dbkey.pem"
}

resource "local_file" "ansible-inventory" {
  filename = local.ansible_local_inventory
  depends_on = [
    proxmox_vm_qemu.pgpool,
    proxmox_vm_qemu.ansible,
    proxmox_vm_qemu.postgresql
  ]

  content = <<DOC
---
all:
  vars:
    ansible_user: postgres
    ansible_private_key_file: ${local.ansible_private_key_path}
  hosts:
    pgpool:
      ansible_host: ${proxmox_vm_qemu.pgpool.default_ipv4_address}
    ansible:
      ansible_host: ${proxmox_vm_qemu.ansible.default_ipv4_address}
  children:
    postgresql:
      hosts:
        ${join("\n        ", [for x in proxmox_vm_qemu.postgresql.*.default_ipv4_address : format("postgresql-%d:\n          ansible_host: %s", index(proxmox_vm_qemu.postgresql.*.default_ipv4_address, x) + 1, x)])}
    DOC     
}

resource "null_resource" "ansible-provisioning" {
  depends_on = [local_file.ansible-inventory]

  connection {
    host        = proxmox_vm_qemu.ansible.default_ipv4_address
    type        = "ssh"
    private_key = file(local.hypervisor_private_key_path)
    port        = local.ansible_ssh_port
    user        = local.ansible_ssh_user
    agent       = false
  }

  # Sending Ansible inventory from local to Ansible server
  provisioner "file" {
    source      = local.ansible_local_inventory
    destination = local.ansible_remote_inventory
  }

  # Sending private key from local to Ansible server to connect to other VMs
  provisioner "file" {
    source      = local.hypervisor_private_key_path
    destination = local.ansible_private_key_path
  }

  # Create a simple config file for Ansible and check if both sent files are on Ansible server
  provisioner "remote-exec" {
    inline = ["stat ${local.ansible_remote_inventory} ${local.ansible_private_key_path}",
    "echo '[defaults]\ninventory = ${local.ansible_remote_inventory}' > ${local.ansible_config_path}"]
  }
}