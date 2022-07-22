# Local variables with cloud-init custom YAMLs
locals {
  ansible_cicustom    = "user=local:snippets/ansible-ci.yaml"
  gitea_cicustom      = local.common_cicustom
  jenkins_cicustom    = local.common_cicustom
  k8s_cplane_cicustom = local.common_cicustom
  k8s_node_cicustom   = local.common_cicustom
  pgpool_cicustom     = local.postgresql_cicustom
  postgresql_cicustom = "user=local:snippets/postgresql-ci.yaml"
  common_cicustom     = "user=local:snippets/common-ci.yaml"
}

#-----------------------------|       Configuration managers/provisioners       |------------------------------#

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

  cicustom = local.ansible_cicustom
}

#-----------------------------|       Databases + DB load balancers       |------------------------------#

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

  cicustom = local.pgpool_cicustom
}

# PostgreSQL node servers
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

  cicustom = local.postgresql_cicustom
}


#-----------------------------|           Version control servers           |------------------------------#

# Gitea server for local Git service 
resource "proxmox_vm_qemu" "gitea" {
  name = "gitea"
  desc = "Virtual Machine for Gitea source code repository"

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
    size    = "10G"
  }

  cicustom = local.gitea_cicustom
}


#-----------------------------|                Automation servers             |------------------------------#

# Jenkins server for CI/CD
resource "proxmox_vm_qemu" "jenkins" {
  name = "jenkins"
  desc = "Virtual Machine for Jenkins CI/CD"

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
    size    = "10G"
  }

  cicustom = local.jenkins_cicustom
}

#-----------------------------|             Orchestration managers            |------------------------------#

# Kubernetes control plane
resource "proxmox_vm_qemu" "k8s-cplane" {
  name = "k8s-cplane"
  desc = "Virtual Machine for Kubernetes control plane"

  target_node = var.target_node
  onboot      = true

  clone   = var.template
  os_type = "cloud-init"
  agent   = 1

  cores   = 4
  sockets = 1
  memory  = 4096
  cpu     = "host"

  network {
    model  = "virtio"
    bridge = "vmbr0"
  }

  ipconfig0 = "ip=dhcp,ip6=dhcp"

  vga {
    type   = "std"
    memory = 4
  }

  disk {
    type    = "scsi"
    storage = "local-lvm"
    size    = "20G"
  }

  cicustom = local.k8s_cplane_cicustom
}

# Kubernetes worker nodes
resource "proxmox_vm_qemu" "k8s-node" {
  count = 2
  name  = "k8s-node-${count.index + 1}"
  desc  = "Virtual Machine for Kubernetes worker node number ${count.index + 1}"

  target_node = var.target_node
  onboot      = true

  clone   = var.template
  os_type = "cloud-init"
  agent   = 1

  cores   = 2
  sockets = 1
  memory  = 2048
  cpu     = "host"

  network {
    model  = "virtio"
    bridge = "vmbr0"
  }

  ipconfig0 = "ip=dhcp,ip6=dhcp"

  vga {
    type   = "std"
    memory = 4
  }

  disk {
    type    = "scsi"
    storage = "local-lvm"
    size    = "10G"
  }

  cicustom = local.k8s_node_cicustom
}



### Ansible inventory YAML file creation

# Local variables with data to send inventory
locals {
  local_key_path  = "./dbkey.pem"
  remote_key_path = "/home/ansible/dbkey.pem"

  ansible_user             = "ansible"
  postgresql_user          = "postgres"
  ansible_ssh_user         = local.ansible_user
  ansible_ssh_port         = 22
  ansible_local_inventory  = "./ansible/ansible-inventory.yaml"
  ansible_remote_inventory = "/home/ansible/ansible-inventory.yaml"
  ansible_config_path      = "/home/ansible/.ansible.cfg"

  git_project        = "https://github.com/ACzOps/gamexpol.git"
  infra_playbook     = "/home/ansible/gamexpol/ansible/infra-playbook.yaml"
  script_local_path  = "./scripts/launch-ansible.sh"
  script_remote_path = "/home/ansible/launch-ansible.sh"
}

resource "local_file" "ansible-inventory" {
  filename = local.ansible_local_inventory
  depends_on = [
    proxmox_vm_qemu.pgpool,
    proxmox_vm_qemu.ansible,
    proxmox_vm_qemu.postgresql,
    proxmox_vm_qemu.gitea,
  ]

  content = <<DOC
---
all:
  vars: 
    ansible_private_key_file: ${local.remote_key_path}
    ansible_user: ${local.ansible_user}
  hosts:
    ansible:
      ansible_host: ${proxmox_vm_qemu.ansible.default_ipv4_address}
    gitea:
      ansible_host: ${proxmox_vm_qemu.gitea.default_ipv4_address}
    jenkins:
      ansible_host: ${proxmox_vm_qemu.jenkins.default_ipv4_address}
  children:
    postgresql:
      vars: 
        ansible_user: ${local.postgresql_user}
      hosts:
        ${join("\n        ", [for x in proxmox_vm_qemu.postgresql.*.default_ipv4_address : format("postgresql-%d:\n          ansible_host: %s", index(proxmox_vm_qemu.postgresql.*.default_ipv4_address, x) + 1, x)])}
    pgpool:
      vars: 
        ansible_user: ${local.postgresql_user}
      hosts:
        ${join("\n        ", [for x in proxmox_vm_qemu.pgpool.*.default_ipv4_address : format("pgpool-%d:\n          ansible_host: %s", index(proxmox_vm_qemu.pgpool.*.default_ipv4_address, x) + 1, x)])}
    kubernetes:
      hosts:
        cplane:
          ansible_host: ${proxmox_vm_qemu.k8s-cplane.default_ipv4_address}
        ${join("\n        ", [for x in proxmox_vm_qemu.k8s-node.*.default_ipv4_address : format("node-%d:\n          ansible_host: %s", index(proxmox_vm_qemu.k8s-node.*.default_ipv4_address, x) + 1, x)])}
    DOC     
}

resource "null_resource" "ansible-provisioning" {
  depends_on = [local_file.ansible-inventory]

  connection {
    host        = proxmox_vm_qemu.ansible.default_ipv4_address
    type        = "ssh"
    private_key = file(local.local_key_path)
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
    source      = local.local_key_path
    destination = local.remote_key_path
  }

  # Sending launching playbook script from local to Ansible server
  provisioner "file" {
    source      = local.script_local_path
    destination = local.script_remote_path
  }

  # Create a simple config file for Ansible, clone and launch project on Ansible server
  # TODO: Split Ansible playbooks into different project on GitHub or figure out cloning only one directory
  provisioner "remote-exec" {
    inline = ["echo '[defaults]\ninventory = ${local.ansible_remote_inventory}' > ${local.ansible_config_path}",
      "chmod 755 /home/ansible/launch-ansible.sh",
    "/home/ansible/launch-ansible.sh -repo ${local.git_project} -playbook ${local.infra_playbook}"]
  }
}