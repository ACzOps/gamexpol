variable "pm_api_token_id" {
  type      = string
  sensitive = true
}

variable "pm_api_token_secret" {
  type      = string
  sensitive = true
}

variable "pm_api_url" {
  type = string
}

variable "ssh_pubkey" {
  type = string
}

variable "target_node" {
  type    = string
  default = "dell"
}

variable "template" {
  type    = string
  default = "ubuntu-ci"
}