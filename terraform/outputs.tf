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

output "ssh_connection_command" {
  description = "SSH command to connect to the VM"
  value       = "ssh ${var.admin_username}@${azurerm_public_ip.pip.ip_address}"
}

output "action_group_id" {
  description = "The ID of the action group for alerts"
  value       = azurerm_monitor_action_group.main.id
}

output "cpu_alert_id" {
  description = "The ID of the CPU metric alert"
  value       = azurerm_monitor_metric_alert.cpu_alert.id
}

output "data_collection_rule_id" {
  description = "The ID of the data collection rule"
  value       = azurerm_monitor_data_collection_rule.dcr.id
}

output "deployment_summary" {
  description = "Summary of deployed resources"
  value = {
    resource_group    = azurerm_resource_group.rg.name
    location         = azurerm_resource_group.rg.location
    vm_name          = azurerm_linux_virtual_machine.vm.name
    vm_size          = azurerm_linux_virtual_machine.vm.size
    vm_public_ip     = azurerm_public_ip.pip.ip_address
    workspace_name   = azurerm_log_analytics_workspace.law.name
    alert_email      = var.alert_email
    ssh_command      = "ssh ${var.admin_username}@${azurerm_public_ip.pip.ip_address}"
  }
}