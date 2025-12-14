# Configure the Azure Provider
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>4.0"
    }
  }
  required_version = ">= 1.0"
}

provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
}

resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
}

resource "azurerm_log_analytics_workspace" "law" {
  name                = var.workspace_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "PerGB2018"
  retention_in_days   = 30

  tags = {
    Environment = "monitoring"
    Project     = "azure-monitor"
  }
}

# VM Insights Solution
resource "azurerm_log_analytics_solution" "vminsights" {
  solution_name         = "VMInsights"
  location              = azurerm_resource_group.rg.location
  resource_group_name   = azurerm_resource_group.rg.name
  workspace_resource_id = azurerm_log_analytics_workspace.law.id
  workspace_name        = azurerm_log_analytics_workspace.law.name

  plan {
    publisher = "Microsoft"
    product   = "OMSGallery/VMInsights"
  }

  depends_on = [azurerm_log_analytics_workspace.law]
}

# Virtual Network and Subnet
resource "azurerm_virtual_network" "vnet" {
  name                = "monitor-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_subnet" "subnet" {
  name                 = "internal"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.2.0/24"]
}

# Network Security Group and rule
resource "azurerm_network_security_group" "nsg" {
  name                = "monitor-nsg"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    name                       = "SSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# Public IP
resource "azurerm_public_ip" "pip" {
  name                = "monitor-pip"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  allocation_method   = "Static"
  sku                 = "Standard"
}

# Network Interface
resource "azurerm_network_interface" "nic" {
  name                = "monitor-nic"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.pip.id
  }
}

# Associate Network Security Group to Network Interface
resource "azurerm_network_interface_security_group_association" "nsg_association" {
  network_interface_id      = azurerm_network_interface.nic.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

# Linux Virtual Machine
resource "azurerm_linux_virtual_machine" "vm" {
  name                = var.vm_name
  size                = var.vm_size
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  admin_username      = var.admin_username

  disable_password_authentication = true

  network_interface_ids = [
    azurerm_network_interface.nic.id,
  ]

  admin_ssh_key {
    username   = var.admin_username
    public_key = file(var.ssh_public_key_path)
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }
}

# OMS Agent Extension for Log Analytics
resource "azurerm_virtual_machine_extension" "oms_agent" {
  name                 = "OmsAgentForLinux"
  virtual_machine_id   = azurerm_linux_virtual_machine.vm.id
  publisher            = "Microsoft.EnterpriseCloud.Monitoring"
  type                 = "OmsAgentForLinux"
  type_handler_version = "1.19"
  auto_upgrade_minor_version = true

  settings = jsonencode({
    workspaceId = azurerm_log_analytics_workspace.law.workspace_id
  })

  protected_settings = jsonencode({
    workspaceKey = azurerm_log_analytics_workspace.law.primary_shared_key
  })

  depends_on = [azurerm_log_analytics_workspace.law]
}

# Data Collection Rule (Optional - for Azure Monitor Agent)
# Note: OMS Agent doesn't require DCR, but keeping for future AMA migration
resource "azurerm_monitor_data_collection_rule" "dcr" {
  name                = "monitor-dcr"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

  destinations {
    log_analytics {
      workspace_resource_id = azurerm_log_analytics_workspace.law.id
      name                  = "destination-log"
    }
  }

  data_flow {
    streams      = ["Microsoft-InsightsMetrics", "Microsoft-Syslog", "Microsoft-Perf"]
    destinations = ["destination-log"]
  }

  data_sources {
    syslog {
      facility_names = ["*"]
      log_levels     = ["*"]
      name           = "test-datasource-syslog"
      streams        = ["Microsoft-Syslog"]
    }

    performance_counter {
      streams                       = ["Microsoft-Perf", "Microsoft-InsightsMetrics"]
      sampling_frequency_in_seconds = 60
      counter_specifiers            = ["\\Processor(_Total)\\% Processor Time", "\\Memory\\Available MBytes", "\\LogicalDisk(_Total)\\% Free Space"]
      name                          = "test-datasource-perfcounter"
    }
  }
}

# Data Collection Rule Association (commented out since using OMS Agent)
# resource "azurerm_monitor_data_collection_rule_association" "dcr_association" {
#   name                    = "monitor-dcr-association"
#   target_resource_id      = azurerm_linux_virtual_machine.vm.id
#   data_collection_rule_id = azurerm_monitor_data_collection_rule.dcr.id
# }

# Enhanced Metric Alerts System - Validated Configurations

# CPU High Alert (>80%) - ✅ VALIDATED & TESTED
resource "azurerm_monitor_metric_alert" "cpu_high_alert" {
  name                = "cpu-high-alert"
  resource_group_name = azurerm_resource_group.rg.name
  scopes              = [azurerm_linux_virtual_machine.vm.id]
  description         = "CPU exceeds ${var.cpu_threshold}% for 5 minutes"
  severity            = 2
  window_size         = "PT5M"
  frequency           = "PT1M"
  auto_mitigate       = true
  enabled             = true

  criteria {
    metric_namespace = "Microsoft.Compute/virtualMachines"
    metric_name      = "Percentage CPU"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = var.cpu_threshold
  }

  action {
    action_group_id = azurerm_monitor_action_group.main.id
  }

  tags = {
    Environment = "monitoring"
    AlertType   = "performance"
  }

  depends_on = [azurerm_monitor_action_group.main, azurerm_virtual_machine_extension.oms_agent]
}

# Memory Low Alert (<1.5GB available) - ✅ WORKING
resource "azurerm_monitor_metric_alert" "memory_low_alert" {
  name                = "memory-low-alert"
  resource_group_name = azurerm_resource_group.rg.name
  scopes              = [azurerm_linux_virtual_machine.vm.id]
  description         = "Available memory is below ${var.memory_threshold_gb}GB"
  severity            = 2
  window_size         = "PT5M"
  frequency           = "PT1M"
  auto_mitigate       = true
  enabled             = true

  criteria {
    metric_namespace = "Microsoft.Compute/virtualMachines"
    metric_name      = "Available Memory Bytes"
    aggregation      = "Average"
    operator         = "LessThan"
    threshold        = var.memory_threshold_bytes
  }

  action {
    action_group_id = azurerm_monitor_action_group.main.id
  }

  tags = {
    Environment = "monitoring"
    AlertType   = "memory"
  }

  depends_on = [azurerm_monitor_action_group.main, azurerm_virtual_machine_extension.oms_agent]
}

# Network Traffic Alert (>100MB/5min) - ✅ WORKING
resource "azurerm_monitor_metric_alert" "network_in_high_alert" {
  name                = "network-in-high-alert"
  resource_group_name = azurerm_resource_group.rg.name
  scopes              = [azurerm_linux_virtual_machine.vm.id]
  description         = "High network inbound traffic detected (>${var.network_threshold_mb}MB in 5 minutes)"
  severity            = 3
  window_size         = "PT5M"
  frequency           = "PT1M"
  auto_mitigate       = true
  enabled             = true

  criteria {
    metric_namespace = "Microsoft.Compute/virtualMachines"
    metric_name      = "Network In Total"
    aggregation      = "Total"
    operator         = "GreaterThan"
    threshold        = var.network_threshold_bytes
  }

  action {
    action_group_id = azurerm_monitor_action_group.main.id
  }

  tags = {
    Environment = "monitoring"
    AlertType   = "network"
  }

  depends_on = [azurerm_monitor_action_group.main, azurerm_virtual_machine_extension.oms_agent]
}

# VM Availability Alert - ✅ WORKING
resource "azurerm_monitor_metric_alert" "vm_availability_alert" {
  name                = "vm-availability-alert"
  resource_group_name = azurerm_resource_group.rg.name
  scopes              = [azurerm_linux_virtual_machine.vm.id]
  description         = "Virtual Machine is not available"
  severity            = 1
  window_size         = "PT5M"
  frequency           = "PT1M"
  auto_mitigate       = true
  enabled             = true

  criteria {
    metric_namespace = "Microsoft.Compute/virtualMachines"
    metric_name      = "VmAvailabilityMetric"
    aggregation      = "Average"
    operator         = "LessThan"
    threshold        = 1
  }

  action {
    action_group_id = azurerm_monitor_action_group.main.id
  }

  tags = {
    Environment = "monitoring"
    AlertType   = "availability"
  }

  depends_on = [azurerm_monitor_action_group.main, azurerm_virtual_machine_extension.oms_agent]
}

# Disk Performance Alert (uses available host metrics)
resource "azurerm_monitor_metric_alert" "disk_performance_alert" {
  name                = "disk-performance-alert"
  resource_group_name = azurerm_resource_group.rg.name
  scopes              = [azurerm_linux_virtual_machine.vm.id]
  description         = "High disk write operations detected (>${var.disk_ops_threshold} ops/sec)"
  severity            = 3
  window_size         = "PT5M"
  frequency           = "PT1M"
  auto_mitigate       = true
  enabled             = true

  criteria {
    metric_namespace = "Microsoft.Compute/virtualMachines"
    metric_name      = "OS Disk Write Operations/Sec"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = var.disk_ops_threshold
  }

  action {
    action_group_id = azurerm_monitor_action_group.main.id
  }

  tags = {
    Environment = "monitoring"
    AlertType   = "disk"
  }

  depends_on = [azurerm_monitor_action_group.main, azurerm_virtual_machine_extension.oms_agent]
}

# Enhanced Action Group for alerts
resource "azurerm_monitor_action_group" "main" {
  name                = "monitor-action-group"
  resource_group_name = azurerm_resource_group.rg.name
  short_name          = "monitor-ag"
  enabled             = true

  email_receiver {
    name                    = "admin"
    email_address          = var.alert_email
    use_common_alert_schema = true
  }

  tags = {
    Environment = "monitoring"
    Project     = "azure-monitor"
  }
}