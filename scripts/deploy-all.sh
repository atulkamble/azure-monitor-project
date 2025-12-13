#!/bin/bash

# Azure Monitor Complete Project - Deployment Script
# This script deploys all components for comprehensive Azure Monitor setup
# Includes: VM, Log Analytics, Monitoring Agent, Alerts, and Dashboard
#
# Usage: ./scripts/deploy-all.sh [email@domain.com]
# Example: ./scripts/deploy-all.sh user@example.com
#
# If no email is provided, uses default: atul_kamble@hotmail.com

set -e

# Configuration Variables - MODIFY THESE AS NEEDED
RG="monitor"
LOCATION="eastus"
LAW="mylaw"
VM="monitor-vm"
ADMIN_USER="azureuser"

# Email for alert notifications - CHANGE THIS TO YOUR EMAIL
ALERT_EMAIL="${1:-atul_kamble@hotmail.com}"

# Display configuration
echo "📋 Deployment Configuration:"
echo "   Resource Group: $RG"
echo "   Location: $LOCATION"
echo "   Alert Email: $ALERT_EMAIL"
echo ""

echo "🚀 Starting Azure Monitor Project Deployment..."

# Step 1: Create Resource Group
echo "📦 Creating Resource Group: $RG"
az group create \
  --name $RG \
  --location $LOCATION

# Step 2: Create Log Analytics Workspace
echo "📊 Creating Log Analytics Workspace: $LAW"
az monitor log-analytics workspace create \
  --resource-group $RG \
  --workspace-name $LAW \
  --location $LOCATION

# Step 3: Deploy Virtual Machine
echo "🖥️ Deploying Virtual Machine: $VM (Ubuntu 22.04 LTS, Standard_B2s)"
az vm create \
  --resource-group $RG \
  --name $VM \
  --image Ubuntu2204 \
  --admin-username $ADMIN_USER \
  --generate-ssh-keys \
  --size Standard_B2s \
  --priority Regular \
  --output table

# Get VM public IP for later reference
VM_PUBLIC_IP=$(az vm show --resource-group $RG --name $VM --show-details --query publicIps -o tsv)
echo "✅ VM created successfully. Public IP: $VM_PUBLIC_IP"

# Step 4: Install Log Analytics Agent and enable VM monitoring
echo "🔍 Installing Log Analytics Agent..."
WID=$(az monitor log-analytics workspace show \
  --resource-group $RG \
  --workspace-name $LAW \
  --query customerId -o tsv)

WKEY=$(az monitor log-analytics workspace get-shared-keys \
  --resource-group $RG \
  --workspace-name $LAW \
  --query primarySharedKey -o tsv)

az vm extension set \
  --name OmsAgentForLinux \
  --publisher Microsoft.EnterpriseCloud.Monitoring \
  --resource-group $RG \
  --vm-name $VM \
  --settings "{\"workspaceId\":\"$WID\"}" \
  --protected-settings "{\"workspaceKey\":\"$WKEY\"}"

# Step 5: Create Action Group
echo "🔔 Creating Action Group for alerts (Email: $ALERT_EMAIL)..."
az monitor action-group create \
  --resource-group $RG \
  --name monitor-action-group \
  --short-name monitor-ag \
  --action email admin $ALERT_EMAIL

# Step 6: Create Metric Alerts
echo "⚠️ Creating Metric Alert Rules..."
VM_ID=$(az vm show -g $RG -n $VM --query id -o tsv)
AG_ID=$(az monitor action-group show -g $RG -n monitor-action-group --query id -o tsv)

# CPU High Alert
echo "  📊 Creating CPU Alert (>80%)..."
az monitor metrics alert create \
  --name cpu-high-alert \
  --resource-group $RG \
  --scopes $VM_ID \
  --condition "avg Percentage CPU > 80" \
  --description "CPU exceeds 80% for 5 minutes" \
  --window-size 5m \
  --evaluation-frequency 1m \
  --severity 2 \
  --action $AG_ID

# Memory Low Alert
echo "  💾 Creating Memory Alert (<15% available)..."
az monitor metrics alert create \
  --name memory-low-alert \
  --resource-group $RG \
  --scopes $VM_ID \
  --condition "avg Available Memory Percentage < 15" \
  --description "Available memory is below 15%" \
  --window-size 5m \
  --evaluation-frequency 1m \
  --severity 2 \
  --action $AG_ID 2>/dev/null || echo "    ⚠️ Memory alert creation skipped (metric may not be available yet)"

# Step 7: Create Dashboard (Optional)
echo "📈 Creating Azure Dashboard..."
if [ -f "dashboard.json" ]; then
  az config set extension.use_dynamic_install=yes_without_prompt 2>/dev/null
  az portal dashboard create \
    --resource-group $RG \
    --name monitor-dashboard \
    --input-path dashboard.json 2>/dev/null || echo "    ⚠️ Dashboard creation skipped (manual creation recommended)"
else
  echo "    ⚠️ Dashboard template not found, skipping dashboard creation"
fi

echo ""
echo "🎉 ============================================="
echo "🎉   AZURE MONITOR DEPLOYMENT COMPLETE!     "
echo "🎉 ============================================="
echo ""
echo "📊 Resources Successfully Created:"
echo "   ✅ Resource Group: $RG"
echo "   ✅ Log Analytics Workspace: $LAW"
echo "   ✅ Virtual Machine: $VM (Ubuntu 22.04 LTS)"
echo "   ✅ VM Size: Standard_B2s (2 vCPUs, 4 GB RAM)"
echo "   ✅ Public IP: $VM_PUBLIC_IP"
echo "   ✅ Log Analytics Agent: Installed and Connected"
echo "   ✅ Action Group: monitor-action-group ($ALERT_EMAIL)"
echo "   ✅ CPU Alert: >80% threshold"
echo "   ✅ Memory Alert: <15% available (if supported)"
echo ""
echo "🚀 Next Steps:"
echo "   1. SSH into VM: ssh $ADMIN_USER@$VM_PUBLIC_IP"
echo "   2. Install stress testing: sudo apt update && sudo apt install stress-ng -y"
echo "   3. Test CPU alert: stress-ng --cpu 2 --timeout 300s"
echo "   4. View VM Insights: Azure Portal → Monitor → Virtual Machines → $VM"
echo "   5. Query logs: Azure Portal → Log Analytics Workspaces → $LAW"
echo ""
echo "📱 Monitoring Links:"
echo "   • VM Insights: https://portal.azure.com/#blade/Microsoft_Azure_Monitoring/AzureMonitoringBrowseBlade/virtualMachines"
echo "   • Log Analytics: https://portal.azure.com/#blade/HubsExtension/BrowseResource/resourceType/Microsoft.OperationalInsights%2Fworkspaces"
echo "   • Alerts: https://portal.azure.com/#blade/Microsoft_Azure_Monitoring/AzureMonitoringBrowseBlade/alertsV2"
echo "   • Dashboard: atul-monitor-dashboard"
