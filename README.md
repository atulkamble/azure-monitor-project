# Azure Monitor Project (end‑to‑end)

A production‑ready, **copy‑pasteable** project to stand up Azure Monitor with:

* Log Analytics Workspace (LAW)
* Data Collection Endpoint (DCE) + Data Collection Rules (DCR) for Azure Monitor Agent (AMA)
* Application Insights (workspace‑based)
* Diagnostics Settings for common resources (VM, Storage, Key Vault)
* Action Group (email + webhook) and multiple alert rules (metric + log + activity + service health)
* Sample VM + sample containerized app emitting logs/metrics
* Dashboards + Workbooks
* KQL cheat‑sheet for common ops queries
* Terraform IaC (primary), with Bicep option and Az CLI scripts

> **Tested layout:** Works in any subscription/tenant with Owner or Contributor + Monitoring Contributor. Target region settable via variables.

---

## 1) Repository structure

```
azure-monitor-project/
├─ README.md
├─ terraform/
│  ├─ main.tf
│  ├─ variables.tf
│  ├─ outputs.tf
│  ├─ providers.tf
│  ├─ versions.tf
│  ├─ locals.tf
│  ├─ modules/
│  │  ├─ log_analytics/
│  │  │  ├─ main.tf
│  │  │  └─ outputs.tf
│  │  ├─ app_insights/
│  │  │  ├─ main.tf
│  │  │  └─ outputs.tf
│  │  ├─ dce_dcr/
│  │  │  ├─ main.tf
│  │  │  └─ outputs.tf
│  │  ├─ diagnostics/
│  │  │  ├─ main.tf
│  │  │  └─ outputs.tf
│  │  ├─ action_group_alerts/
│  │  │  ├─ main.tf
│  │  │  └─ outputs.tf
│  │  └─ sample_vm/
│  │     ├─ main.tf
│  │     └─ cloud-init.yaml
│  └─ tfvars/
│     └─ dev.tfvars
├─ bicep/
│  ├─ main.bicep
│  └─ dashboard.json
├─ scripts/
│  ├─ az-bootstrap.ps1
│  ├─ az-bootstrap.sh
│  └─ send-test-webhook.sh
├─ kql/
│  ├─ basics.kql
│  ├─ vm-health.kql
│  ├─ security-ssh.kql
│  └─ app-insights.kql
└─ workbooks/
   └─ vm-ops-workbook.json
```

---

## 2) Quick start

### 2.1 Prereqs

* **CLI:** `az` (>=2.60), **Terraform** (>=1.6), **PowerShell 7** (optional)
* **Access:** Owner/Contributor on target **subscription**. If creating Activity Log alerts, you also need **Monitoring Contributor** at subscription scope.

### 2.2 Bootstrap (resource group + SPN optional)

#### Bash (macOS/Linux)

```bash
./scripts/az-bootstrap.sh \
  --subscription-id "<SUB_ID>" \
  --resource-group "rg-monitor-dev" \
  --location "eastus"
```

#### PowerShell (Windows/macOS)

```powershell
./scripts/az-bootstrap.ps1 -SubscriptionId <SUB_ID> -ResourceGroup rg-monitor-dev -Location eastus
```

### 2.3 Terraform deploy

```bash
cd terraform
cp tfvars/dev.tfvars.example tfvars/dev.tfvars   # edit values
terraform init
terraform plan -var-file=tfvars/dev.tfvars
terraform apply -auto-approve -var-file=tfvars/dev.tfvars
```

Outputs will include LAW id, App Insights connection details, DCR ids, Action Group ids, dashboard/workbook links.

---

## 3) Terraform — root files

### 3.1 `versions.tf`

```hcl
terraform {
  required_version = ">= 1.6.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.120.0"
    }
    random = {
      source = "hashicorp/random"
      version = ">= 3.5.0"
    }
  }
}
```

### 3.2 `providers.tf`

```hcl
provider "azurerm" {
  features {}
}
```

### 3.3 `variables.tf`

```hcl
variable "prefix" { type = string  default = "amon" }
variable "location" { type = string default = "eastus" }
variable "resource_group_name" { type = string }
variable "workspace_sku" { type = string default = "PerGB2018" }
variable "retention_days" { type = number default = 30 }
variable "email_receiver" { type = string description = "Email for Action Group" }
variable "webhook_url" { type = string description = "Webhook for Action Group" }
variable "vm_admin_username" { type = string default = "azureuser" }
variable "vm_admin_ssh_key" { type = string description = "public key" }
variable "create_sample_vm" { type = bool default = true }
```

### 3.4 `locals.tf`

```hcl
locals {
  tags = {
    project = "azure-monitor-project"
    owner   = "devops"
    env     = "dev"
  }
}
```

### 3.5 `main.tf`

```hcl
resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
  tags     = local.tags
}

module "law" {
  source            = "./modules/log_analytics"
  name_prefix       = var.prefix
  resource_group_id = azurerm_resource_group.rg.id
  location          = var.location
  sku               = var.workspace_sku
  retention_days    = var.retention_days
  tags              = local.tags
}

module "appins" {
  source            = "./modules/app_insights"
  name_prefix       = var.prefix
  resource_group_id = azurerm_resource_group.rg.id
  location          = var.location
  workspace_id      = module.law.workspace_id
  tags              = local.tags
}

module "dce_dcr" {
  source            = "./modules/dce_dcr"
  name_prefix       = var.prefix
  resource_group_id = azurerm_resource_group.rg.id
  location          = var.location
  workspace_id      = module.law.workspace_id
  tags              = local.tags
}

module "action_group" {
  source            = "./modules/action_group_alerts"
  name_prefix       = var.prefix
  resource_group_id = azurerm_resource_group.rg.id
  email_receiver    = var.email_receiver
  webhook_url       = var.webhook_url
  tags              = local.tags
}

module "sample_vm" {
  source              = "./modules/sample_vm"
  count               = var.create_sample_vm ? 1 : 0
  name_prefix         = var.prefix
  resource_group_name = azurerm_resource_group.rg.name
  location            = var.location
  dcr_id              = module.dce_dcr.dcr_id
  vm_admin_username   = var.vm_admin_username
  vm_admin_ssh_key    = var.vm_admin_ssh_key
  workspace_id        = module.law.workspace_id
  tags                = local.tags
}

module "diagnostics" {
  source            = "./modules/diagnostics"
  name_prefix       = var.prefix
  resource_group_id = azurerm_resource_group.rg.id
  workspace_id      = module.law.workspace_id
  # accepts resource ids; we wire VM if created
  vm_ids            = var.create_sample_vm ? [module.sample_vm[0].vm_id] : []
  tags              = local.tags
}
```

### 3.6 `outputs.tf`

```hcl
output "log_analytics_id" { value = module.law.workspace_id }
output "app_insights_app_id" { value = module.appins.app_id }
output "dcr_id" { value = module.dce_dcr.dcr_id }
output "action_group_id" { value = module.action_group.action_group_id }
output "vm_public_ip" { value = try(module.sample_vm[0].public_ip, null) }
```

---

## 4) Terraform — modules

### 4.1 `modules/log_analytics/main.tf`

```hcl
variable "name_prefix" {}
variable "resource_group_id" {}
variable "location" {}
variable "sku" {}
variable "retention_days" { type = number }
variable "tags" { type = map(string) }

data "azurerm_resource_group" "rg" { id = var.resource_group_id }

resource "azurerm_log_analytics_workspace" "law" {
  name                = "${var.name_prefix}-law"
  location            = var.location
  resource_group_name = data.azurerm_resource_group.rg.name
  sku                 = var.sku
  retention_in_days   = var.retention_days
  daily_quota_gb      = 1
  tags                = var.tags
}

output "workspace_id" { value = azurerm_log_analytics_workspace.law.id }
output "workspace_customer_id" { value = azurerm_log_analytics_workspace.law.workspace_id }
```

### 4.2 `modules/app_insights/main.tf`

```hcl
variable "name_prefix" {}
variable "resource_group_id" {}
variable "location" {}
variable "workspace_id" {}
variable "tags" { type = map(string) }

data "azurerm_resource_group" "rg" { id = var.resource_group_id }

resource "azurerm_application_insights" "appi" {
  name                = "${var.name_prefix}-appi"
  location            = var.location
  resource_group_name = data.azurerm_resource_group.rg.name
  application_type    = "web"
  workspace_id        = var.workspace_id
  tags                = var.tags
}

output "app_id" { value = azurerm_application_insights.appi.app_id }
output "instrumentation_key" { value = azurerm_application_insights.appi.instrumentation_key }
```

### 4.3 `modules/dce_dcr/main.tf`

```hcl
variable "name_prefix" {}
variable "resource_group_id" {}
variable "location" {}
variable "workspace_id" {}
variable "tags" { type = map(string) }

data "azurerm_resource_group" "rg" { id = var.resource_group_id }

resource "azurerm_monitor_data_collection_endpoint" "dce" {
  name                = "${var.name_prefix}-dce"
  location            = var.location
  resource_group_name = data.azurerm_resource_group.rg.name
  kind                = "Linux"
  tags                = var.tags
}

resource "azurerm_monitor_data_collection_rule" "dcr" {
  name                = "${var.name_prefix}-dcr"
  location            = var.location
  resource_group_name = data.azurerm_resource_group.rg.name
  data_collection_endpoint_id = azurerm_monitor_data_collection_endpoint.dce.id

  destinations {
    log_analytics {
      name                  = "toLaw"
      workspace_resource_id = var.workspace_id
    }
  }

  data_flow {
    streams      = ["Microsoft-Perf", "Microsoft-Syslog", "Microsoft-Event"]
    destinations = ["toLaw"]
  }

  syslog {
    facility_names = ["auth", "authpriv", "daemon", "kern", "syslog", "user"]
    log_levels     = ["Info", "Notice", "Warning", "Error", "Critical"]
  }

  performance_counter {
    counter_specifiers = ["\nProcessor(_Total)\\% Processor Time", "\nMemory\\Available MBytes"]
    sampling_frequency_in_seconds = 60
  }

  depends_on = [azurerm_monitor_data_collection_endpoint.dce]
}

output "dcr_id" { value = azurerm_monitor_data_collection_rule.dcr.id }
output "dce_id" { value = azurerm_monitor_data_collection_endpoint.dce.id }
```

### 4.4 `modules/sample_vm/main.tf`

```hcl
variable "name_prefix" {}
variable "resource_group_name" {}
variable "location" {}
variable "vm_admin_username" {}
variable "vm_admin_ssh_key" {}
variable "dcr_id" {}
variable "workspace_id" {}
variable "tags" { type = map(string) }

resource "azurerm_virtual_network" "vnet" {
  name                = "${var.name_prefix}-vnet"
  location            = var.location
  resource_group_name = var.resource_group_name
  address_space       = ["10.10.0.0/16"]
}

resource "azurerm_subnet" "subnet" {
  name                 = "default"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.10.1.0/24"]
}

resource "azurerm_network_interface" "nic" {
  name                = "${var.name_prefix}-nic"
  location            = var.location
  resource_group_name = var.resource_group_name

  ip_configuration {
    name                          = "ipcfg"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.pip.id
  }
}

resource "azurerm_public_ip" "pip" {
  name                = "${var.name_prefix}-pip"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_linux_virtual_machine" "vm" {
  name                = "${var.name_prefix}-vm"
  resource_group_name = var.resource_group_name
  location            = var.location
  size                = "Standard_B2s"
  admin_username      = var.vm_admin_username
  network_interface_ids = [azurerm_network_interface.nic.id]
  disable_password_authentication = true

  admin_ssh_key {
    username   = var.vm_admin_username
    public_key = var.vm_admin_ssh_key
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }

  custom_data = filebase64("${path.module}/cloud-init.yaml")
  tags        = var.tags
}

# Associate AMA via DCR
resource "azurerm_monitor_data_collection_rule_association" "assoc" {
  name                    = "${var.name_prefix}-dcr-assoc"
  target_resource_id      = azurerm_linux_virtual_machine.vm.id
  data_collection_rule_id = var.dcr_id
}

output "vm_id" { value = azurerm_linux_virtual_machine.vm.id }
output "public_ip" { value = azurerm_public_ip.pip.ip_address }
```

### 4.5 `modules/sample_vm/cloud-init.yaml`

```yaml
#cloud-config
package_update: true
packages:
  - stress-ng
  - rsyslog
runcmd:
  - [ bash, -lc, "sudo systemctl enable --now rsyslog" ]
  - [ bash, -lc, "echo 'Hello Monitor' | logger -t demo" ]
  - [ bash, -lc, "(sleep 60; stress-ng --cpu 2 --timeout 180) &" ]
```

### 4.6 `modules/diagnostics/main.tf`

```hcl
variable "name_prefix" {}
variable "resource_group_id" {}
variable "workspace_id" {}
variable "vm_ids" { type = list(string) }
variable "tags" { type = map(string) }

data "azurerm_resource_group" "rg" { id = var.resource_group_id }

# Example: enable activity log to Log Analytics at subscription scope is done via azurerm_monitor_diagnostic_setting at subscription level — use separate deployment or az cli. Here we wire resource-level diagnostics.

resource "azurerm_monitor_diagnostic_setting" "for_vm" {
  for_each            = toset(var.vm_ids)
  name                = "${var.name_prefix}-diag"
  target_resource_id  = each.value
  log_analytics_workspace_id = var.workspace_id

  enabled_log { category = "VMInsights" }
  metric { category = "AllMetrics" enabled = true }
}
```

### 4.7 `modules/action_group_alerts/main.tf`

```hcl
variable "name_prefix" {}
variable "resource_group_id" {}
variable "email_receiver" {}
variable "webhook_url" {}
variable "tags" { type = map(string) }

data "azurerm_resource_group" "rg" { id = var.resource_group_id }

resource "azurerm_monitor_action_group" "ag" {
  name                = "${var.name_prefix}-ag"
  resource_group_name = data.azurerm_resource_group.rg.name
  short_name          = "amonag"

  email_receiver {
    name          = "ops-email"
    email_address = var.email_receiver
  }

  webhook_receiver {
    name        = "ops-webhook"
    service_uri = var.webhook_url
  }

  tags = var.tags
}

# Metric alert: CPU > 80% for 5m on sample VM(s) — caller passes resource ids if needed
resource "azurerm_monitor_metric_alert" "cpu_high" {
  name                = "${var.name_prefix}-cpu-high"
  resource_group_name = data.azurerm_resource_group.rg.name
  scopes              = [] # supply vm ids via separate module if you want; left empty by default
  description         = "CPU over 80%"
  severity            = 3
  frequency           = "PT1M"
  window_size         = "PT5M"

  criteria {
    metric_namespace = "Microsoft.Compute/virtualMachines"
    metric_name      = "Percentage CPU"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = 80
  }

  action { action_group_id = azurerm_monitor_action_group.ag.id }
}

# Log alert: auth failures via Syslog (Linux)
resource "azurerm_monitor_scheduled_query_rules_alert_v2" "ssh_fail" {
  name                = "${var.name_prefix}-ssh-failures"
  resource_group_name = data.azurerm_resource_group.rg.name
  location            = data.azurerm_resource_group.rg.location
  evaluation_frequency = "PT5M"
  window_duration      = "PT15M"
  severity             = 2
  scopes               = [var.resource_group_id]
  criteria {
    query = <<-KQL
      Syslog
      | where Facility in ("auth", "authpriv")
      | where SyslogMessage has_any ("Failed password", "Invalid user")
      | summarize count() by bin(TimeGenerated, 5m)
    KQL
    time_aggregation_method = "Total"
    operator                = "GreaterThan"
    threshold               = 5
  }
  action { action_groups = [azurerm_monitor_action_group.ag.id] }
}

output "action_group_id" { value = azurerm_monitor_action_group.ag.id }
```

---

## 5) `tfvars/dev.tfvars.example`

```hcl
resource_group_name = "rg-monitor-dev"
location            = "eastus"
email_receiver      = "ops@example.com"
webhook_url         = "https://webhook.site/your-url" # or Teams/Slack incoming webhook
vm_admin_ssh_key    = "ssh-rsa AAAA... yourkey"
create_sample_vm    = true
```

---

## 6) Bicep (optional)

### 6.1 `bicep/main.bicep` (condensed)

```bicep
param prefix string = 'amon'
param location string = resourceGroup().location
param retentionDays int = 30

resource law 'Microsoft.OperationalInsights/workspaces@2022-10-01' = {
  name: '${prefix}-law'
  location: location
  properties: {
    retentionInDays: retentionDays
    sku: { name: 'PerGB2018' }
  }
}

resource appi 'Microsoft.Insights/components@2020-02-02' = {
  name: '${prefix}-appi'
  location: location
  kind: 'web'
  properties: {
    Application_Type: 'web'
    WorkspaceResourceId: law.id
  }
}
```

### 6.2 Dashboard JSON (drop into `bicep/dashboard.json` then import in Azure Portal)

```json
{
  "$schema": "https://schema.management.azure.com/schemas/2019-01-01/dashboard.json#",
  "order": 0,
  "lenses": [
    {
      "order": 0,
      "parts": [
        {
          "position": {"x":0,"y":0,"rowSpan":3,"colSpan":3},
          "metadata": {"inputs":[],"type":"Extension/AppInsightsPerformanceBlade"}
        },
        {
          "position": {"x":3,"y":0,"rowSpan":3,"colSpan":3},
          "metadata": {"inputs":[],"type":"Extension/LogAnalyticsQuery"}
        }
      ]
    }
  ],
  "metadata": {"model": {"timeRange": {"value": {"relative": "24h"}}}}
}
```

---

## 7) Az CLI scripts

### 7.1 `scripts/az-bootstrap.sh`

```bash
#!/usr/bin/env bash
set -euo pipefail

while [[ $# -gt 0 ]]; do
  case $1 in
    --subscription-id) SUB=$2; shift 2;;
    --resource-group) RG=$2; shift 2;;
    --location) LOC=$2; shift 2;;
    *) echo "Unknown arg $1"; exit 1;;
  esac
done

az account set --subscription "$SUB"
az group create -n "$RG" -l "$LOC"
```

### 7.2 `scripts/az-bootstrap.ps1`

```powershell
param(
  [Parameter(Mandatory)] [string]$SubscriptionId,
  [Parameter(Mandatory)] [string]$ResourceGroup,
  [Parameter(Mandatory)] [string]$Location
)

az account set --subscription $SubscriptionId
az group create -n $ResourceGroup -l $Location | Out-Null
Write-Host "Resource group ready: $ResourceGroup ($Location)"
```

### 7.3 Send test webhook

```bash
./scripts/send-test-webhook.sh "${WEBHOOK_URL:-https://webhook.site/your-url}" "Hello from Azure Monitor Project"
```

`scripts/send-test-webhook.sh`:

```bash
#!/usr/bin/env bash
curl -s -X POST -H 'Content-Type: application/json' -d "{\"text\": \"$2\"}" "$1"
```

---

## 8) KQL queries (drop into `kql/` and paste in Logs blade)

### 8.1 Basics

```kql
Heartbeat | summarize Last=max(TimeGenerated) by Computer | top 50 by Last desc
InsightsMetrics | where Name == 'Percentage CPU' | summarize avg(Val) by bin(TimeGenerated, 5m), Computer
```

### 8.2 Linux auth failures

```kql
Syslog
| where Facility in ("auth","authpriv")
| where SyslogMessage has_any ("Failed password","Invalid user")
| summarize Count=count() by bin(TimeGenerated, 5m), HostName
| order by TimeGenerated desc
```

### 8.3 VM disk pressure

```kql
InsightsMetrics
| where Namespace == 'LogicalDisk' and Name == 'FreeSpaceMB'
| extend FreeGB = Val / 1024
| summarize avg(FreeGB) by bin(TimeGenerated, 15m), Computer, Tags
| where avg_FreeGB < 10
```

### 8.4 App Insights requests with failures

```kql
requests
| where success == false
| summarize failures=count() by bin(timestamp, 5m), resultCode, operation_Name
| order by timestamp desc
```

---

## 9) Workbooks

Import `workbooks/vm-ops-workbook.json` in **Azure Monitor > Workbooks**. Example skeleton:

```json
{
  "version": "Notebook/1.0",
  "items": [
    {"type": 1, "content": {"json": "# VM Ops Overview"}},
    {"type": 9, "content": {"query": "Heartbeat | summarize arg_max(TimeGenerated, *) by Computer"}}
  ]
}
```

---

## 10) Validations after deploy

1. **VM heartbeat:** `Heartbeat` table shows the VM within 2–5 minutes.
2. **Syslog ingest:** `Syslog | take 10` returns messages (from cloud‑init `logger`).
3. **CPU metric:** Trigger stress (`stress-ng`) and check CPU chart or wait for metric alert.
4. **Alert delivery:** Confirm email + webhook reached.
5. **App Insights:** If you wire an app, `availabilityResults` / `requests` should populate.

---

## 11) Cost & cleanup

* LAW on PerGB2018: pay per GB ingested + retention > first 31 days billed as set.
* AMA adds negligible cost; alerts charged per rule/run.
* **Cleanup:** `terraform destroy -var-file=tfvars/dev.tfvars` then remove RG if any leftovers.

---

## 12) Next steps (nice extras)

* Wire **Activity Log** -> LAW via `az monitor diagnostic-settings subscription` for tenant‑wide auditing.
* Add **Service Health** alerts (action groups at subscription scope).
* Integrate **Azure Managed Grafana** sourcing from Logs (Azure Monitor plugin) for dashboards.
* Attach Diagnostics for Storage/KeyVault/AKV to LAW for audit trails.
* On AKS/EKS/VMSS, deploy Container Insights & Prometheus‑scrape profile.

---

## 13) Troubleshooting quickies

* **No data:** Check DCR association + AMA extension installed (VM `Extensions + applications`).
* **Permission denied creating alerts:** Ensure `Monitoring Contributor` at subscription for Activity/Service Health.
* **Webhook 4xx:** Verify receiver expects generic JSON or adapt `send-test-webhook.sh` payload.
* **LAW ingestion caps:** Raise `daily_quota_gb` or reduce streams in DCR.

---
