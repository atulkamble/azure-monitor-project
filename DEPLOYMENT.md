# Azure Monitor Basic Project

## Prerequisites
- Azure CLI installed and logged in
- Terraform (if using Terraform deployment)
- SSH key pair generated (`ssh-keygen -t rsa -b 2048`)

## Quick Start

### Option 1: One-Click Deployment (Azure CLI)
```bash
chmod +x scripts/deploy-all.sh
./scripts/deploy-all.sh
```

### Option 2: Terraform Deployment
```bash
cd terraform
terraform init
terraform plan
terraform apply
```

### Option 3: Bicep Deployment
```bash
# Deploy main Bicep template
az deployment sub create \
  --location eastus \
  --template-file bicep/main.bicep \
  --parameters sshPublicKey="$(cat ~/.ssh/id_rsa.pub)"
```

### Option 4: Step-by-Step Manual Deployment
```bash
# 1. Create Resource Group
az group create --name monitor-rg --location eastus

# 2. Create Log Analytics Workspace
chmod +x scripts/create-law.sh
./scripts/create-law.sh

# 3. Deploy VM and enable monitoring
chmod +x scripts/enable-vminsights.sh
./scripts/enable-vminsights.sh

# 4. Set up alerts
chmod +x scripts/create-alert.sh
./scripts/create-alert.sh
```

## Testing the Setup

### 1. Verify VM Insights
- Go to Azure Portal → Virtual Machines → monitor-vm → Insights
- Check performance charts and dependency map

### 2. Test CPU Alert
```bash
# SSH into VM
ssh azureuser@<vm-public-ip>

# Generate CPU load
stress --cpu 4 --timeout 300s
```

### 3. Query Log Analytics
Go to Azure Portal → Log Analytics → atul-law → Logs and run:
```kusto
Perf
| where CounterName == "% Processor Time"
| summarize avg(CounterValue) by bin(TimeGenerated, 5m)
| render timechart
```

## Cleanup
```bash
chmod +x scripts/cleanup.sh
./scripts/cleanup.sh
```

## Architecture Components

- **Resource Group**: monitor-rg
- **Log Analytics Workspace**: atul-law
- **Virtual Machine**: monitor-vm (Ubuntu LTS)
- **Azure Monitor Agent**: Collects performance data
- **Data Collection Rule**: Defines what data to collect
- **Metric Alert**: CPU usage > 80%
- **Action Group**: Email notifications
- **Dashboard**: Visual monitoring interface

## Estimated Costs (East US)
- VM (B1s): ~$7.60/month
- Log Analytics (1GB): ~$2.30/month
- **Total**: ~$10/month

## Troubleshooting

### VM Agent Issues
```bash
# Check agent status
az vm extension list --resource-group monitor-rg --vm-name monitor-vm

# Reinstall agent
az vm extension delete --name AzureMonitorLinuxAgent --resource-group monitor-rg --vm-name monitor-vm
./scripts/enable-vminsights.sh
```

### No Data in Log Analytics
- Wait 5-10 minutes for data to appear
- Verify data collection rule is associated with VM
- Check VM agent health in VM Insights

### Alert Not Triggering
- Verify metric alert rule is enabled
- Check action group email configuration
- Test with sustained CPU load (5+ minutes)