terraform {
  required_version = ">= 1.2.0"

  required_providers {
    proxmox = {
      source  = "telmate/proxmox"
      version = "2.9.10"
    }
  }
}

provider "proxmox" {
  pm_api_url          = var.pm_api_url
  pm_api_token_id     = var.pm_api_token_id
  pm_api_token_secret = var.pm_api_token_secret

  pm_tls_insecure = true

  pm_log_enable = true
  pm_log_file   = "terraform-proxmox.log"
  pm_debug      = true
  pm_log_levels = {
    _default = "info"
  }
}

