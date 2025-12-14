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

# Alert Thresholds
variable "cpu_threshold" {
  description = "CPU threshold for alerts (percentage)"
  type        = number
  default     = 80
  validation {
    condition     = var.cpu_threshold >= 0 && var.cpu_threshold <= 100
    error_message = "CPU threshold must be between 0 and 100."
  }
}

variable "memory_threshold_gb" {
  description = "Memory threshold for alerts (GB available)"
  type        = number
  default     = 1.5
}

variable "memory_threshold_bytes" {
  description = "Memory threshold for alerts (bytes available) - 1.5GB = 1610612736 bytes"
  type        = number
  default     = 1610612736
}

variable "network_threshold_mb" {
  description = "Network traffic threshold for alerts (MB per 5-minute window)"
  type        = number
  default     = 100
}

variable "network_threshold_bytes" {
  description = "Network traffic threshold for alerts (bytes per 5-minute window) - 100MB = 104857600 bytes"
  type        = number
  default     = 104857600
}

variable "disk_ops_threshold" {
  description = "Disk operations threshold for alerts (operations per second)"
  type        = number
  default     = 50
}

# Infrastructure Configuration
variable "subscription_id" {
  description = "Azure subscription ID"
  type        = string
  default     = ""  # Can be set via environment variable AZURE_SUBSCRIPTION_ID
}

variable "ssh_public_key_path" {
  description = "Path to SSH public key file"
  type        = string
  default     = "~/.ssh/id_rsa.pub"
}