variable "resource_group_name" {
  description = "The name of the resource group"
  type        = string
  default     = "monitor"
}

variable "location" {
  description = "The location/region where resources will be created"
  type        = string
  default     = "eastus"
}

variable "workspace_name" {
  description = "The name of the Log Analytics workspace"
  type        = string
  default     = "mylaw"
}

variable "vm_name" {
  description = "The name of the virtual machine"
  type        = string
  default     = "monitor-vm"
}

variable "vm_size" {
  description = "The size of the virtual machine (Standard_B2s recommended for monitoring workloads)"
  type        = string
  default     = "Standard_B2s"
}

variable "admin_username" {
  description = "The admin username for the VM"
  type        = string
  default     = "azureuser"
}

variable "alert_email" {
  description = "Email address for alert notifications"
  type        = string
  default     = "atul_kamble@hotmail.com"
}

variable "cpu_threshold" {
  description = "CPU threshold for alerts (percentage)"
  type        = number
  default     = 80
}

variable "ssh_public_key_path" {
  description = "Path to SSH public key file"
  type        = string
  default     = "~/.ssh/id_rsa.pub"
}