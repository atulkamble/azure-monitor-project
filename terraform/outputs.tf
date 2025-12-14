output "resource_group_name" {
  description = "The name of the resource group"
  value       = azurerm_resource_group.rg.name
}

output "resource_group_location" {
  description = "The location of the resource group"
  value       = azurerm_resource_group.rg.location
}

output "log_analytics_workspace_id" {
  description = "The ID of the Log Analytics workspace"
  value       = azurerm_log_analytics_workspace.law.id
}

output "log_analytics_workspace_name" {
  description = "The name of the Log Analytics workspace"
  value       = azurerm_log_analytics_workspace.law.name
}

output "log_analytics_workspace_customer_id" {
  description = "The customer ID (workspace ID) of the Log Analytics workspace"
  value       = azurerm_log_analytics_workspace.law.workspace_id
  sensitive   = true
}

output "vm_id" {
  description = "The ID of the virtual machine"
  value       = azurerm_linux_virtual_machine.vm.id
}

output "vm_name" {
  description = "The name of the virtual machine"
  value       = azurerm_linux_virtual_machine.vm.name
}

output "vm_size" {
  description = "The size of the virtual machine"
  value       = azurerm_linux_virtual_machine.vm.size
}

output "vm_public_ip" {
  description = "The public IP address of the VM"
  value       = azurerm_public_ip.pip.ip_address
}

output "vm_private_ip" {
  description = "The private IP address of the VM"
  value       = azurerm_network_interface.nic.private_ip_address
}

# Connection Information
output "ssh_connection_command" {
  description = "SSH command to connect to the VM"
  value       = "ssh ${var.admin_username}@${azurerm_public_ip.pip.ip_address}"
}

output "vm_connection_info" {
  description = "VM connection details"
  value = {
    public_ip    = azurerm_public_ip.pip.ip_address
    private_ip   = azurerm_network_interface.nic.private_ip_address
    username     = var.admin_username
    ssh_command  = "ssh ${var.admin_username}@${azurerm_public_ip.pip.ip_address}"
  }
}

# Monitoring Resources
output "action_group_id" {
  description = "The ID of the action group for alerts"
  value       = azurerm_monitor_action_group.main.id
}

output "alert_ids" {
  description = "IDs of all metric alerts"
  value = {
    cpu_alert              = azurerm_monitor_metric_alert.cpu_high_alert.id
    memory_alert          = azurerm_monitor_metric_alert.memory_low_alert.id
    network_alert         = azurerm_monitor_metric_alert.network_in_high_alert.id
    vm_availability_alert = azurerm_monitor_metric_alert.vm_availability_alert.id
    disk_performance_alert = azurerm_monitor_metric_alert.disk_performance_alert.id
  }
}

output "data_collection_rule_id" {
  description = "The ID of the data collection rule"
  value       = azurerm_monitor_data_collection_rule.dcr.id
}

# Alert Thresholds for Reference
output "alert_thresholds" {
  description = "Configured alert thresholds"
  value = {
    cpu_threshold_percent     = var.cpu_threshold
    memory_threshold_gb      = var.memory_threshold_gb
    network_threshold_mb     = var.network_threshold_mb
    disk_ops_threshold       = var.disk_ops_threshold
  }
}

# Testing Commands
output "stress_testing_commands" {
  description = "Commands to test alerts (run on the VM)"
  value = {
    cpu_stress    = "sudo apt update && sudo apt install -y stress-ng && sudo stress-ng --cpu 4 --timeout 300s"
    memory_stress = "sudo stress-ng --vm 1 --vm-bytes 3G --timeout 300s"
    network_test  = "# Network stress testing requires additional setup"
    disk_stress   = "sudo stress-ng --io 4 --timeout 300s"
  }
}

# Comprehensive Deployment Summary
output "deployment_summary" {
  description = "Complete summary of deployed Azure Monitor infrastructure"
  value = {
    # Basic Info
    resource_group        = azurerm_resource_group.rg.name
    location             = azurerm_resource_group.rg.location
    
    # VM Details
    vm_name              = azurerm_linux_virtual_machine.vm.name
    vm_size              = azurerm_linux_virtual_machine.vm.size
    vm_public_ip         = azurerm_public_ip.pip.ip_address
    vm_private_ip        = azurerm_network_interface.nic.private_ip_address
    
    # Monitoring
    workspace_name       = azurerm_log_analytics_workspace.law.name
    action_group_name    = azurerm_monitor_action_group.main.name
    alert_email          = var.alert_email
    
    # Connection
    ssh_command          = "ssh ${var.admin_username}@${azurerm_public_ip.pip.ip_address}"
    
    # Alerts Created
    alerts_configured    = [
      "cpu-high-alert (>${var.cpu_threshold}%)",
      "memory-low-alert (<${var.memory_threshold_gb}GB)",
      "network-in-high-alert (>${var.network_threshold_mb}MB/5min)",
      "vm-availability-alert",
      "disk-performance-alert (>${var.disk_ops_threshold} ops/sec)"
    ]
    
    # Next Steps
    validation_commands = [
      "./scripts/validate-alerts.sh ${azurerm_resource_group.rg.name} ${azurerm_linux_virtual_machine.vm.name}",
      "az monitor metrics alert list --resource-group ${azurerm_resource_group.rg.name} --output table"
    ]
  }
}