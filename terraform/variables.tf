variable "resource_group_name" {
  description = "The name of the resource group"
  type        = string
  default     = "monitor-rg"
}

variable "location" {
  description = "The location/region where resources will be created"
  type        = string
  default     = "eastus"
}

variable "workspace_name" {
  description = "The name of the Log Analytics workspace"
  type        = string
  default     = "atul-law"
}

variable "vm_name" {
  description = "The name of the virtual machine"
  type        = string
  default     = "monitor-vm"
}

variable "vm_size" {
  description = "The size of the virtual machine"
  type        = string
  default     = "Standard_B1s"
}

variable "admin_username" {
  description = "The admin username for the VM"
  type        = string
  default     = "azureuser"
}

variable "alert_email" {
  description = "Email address for alert notifications"
  type        = string
  default     = "admin@example.com"
}

variable "cpu_threshold" {
  description = "CPU threshold for alerts"
  type        = number
  default     = 80
}