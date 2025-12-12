#!/bin/bash

# Azure Monitor Basic Project - Complete Deployment Script
# This script deploys all components for Azure Monitor setup

set -e

# Variables
RG="monitor-rg"
LOCATION="eastus"
LAW="atul-law"
VM="monitor-vm"
ADMIN_USER="azureuser"

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
echo "🖥️ Deploying Virtual Machine: $VM"
az vm create \
  --resource-group $RG \
  --name $VM \
  --image UbuntuLTS \
  --admin-username $ADMIN_USER \
  --generate-ssh-keys \
  --size Standard_B1s

# Step 4: Install Azure Monitor Agent and enable VM Insights
echo "🔍 Installing Azure Monitor Agent..."
WID=$(az monitor log-analytics workspace show \
  --resource-group $RG \
  --workspace-name $LAW \
  --query customerId -o tsv)

az vm extension set \
  --name AzureMonitorLinuxAgent \
  --publisher Microsoft.Azure.Monitor \
  --resource-group $RG \
  --vm-name $VM \
  --workspace-id $WID

# Step 5: Create Action Group
echo "🔔 Creating Action Group for alerts..."
az monitor action-group create \
  --resource-group $RG \
  --name monitor-action-group \
  --short-name monitor-ag \
  --action email admin admin@example.com

# Step 6: Create CPU Alert
echo "⚠️ Creating CPU Alert Rule..."
VM_ID=$(az vm show -g $RG -n $VM --query id -o tsv)

az monitor metrics alert create \
  --name cpu-high-alert \
  --resource-group $RG \
  --scopes $VM_ID \
  --condition "avg Percentage CPU > 80" \
  --description "CPU exceeds 80%" \
  --window-size 5m \
  --evaluation-frequency 1m \
  --action-groups $(az monitor action-group show -g $RG -n monitor-action-group --query id -o tsv)

# Step 7: Create Dashboard
echo "📈 Creating Azure Dashboard..."
az portal dashboard create \
  --resource-group $RG \
  --name atul-monitor-dashboard \
  --input-path dashboard.json

echo "✅ Deployment Complete!"
echo ""
echo "🎯 Next Steps:"
echo "1. Go to Azure Portal → Monitor → Virtual Machines"
echo "2. Select your VM to view VM Insights"
echo "3. Check Log Analytics workspace for data"
echo "4. Test CPU alert by running: stress --cpu 4 --timeout 300s"
echo ""
echo "📊 Resources Created:"
echo "   • Resource Group: $RG"
echo "   • Log Analytics Workspace: $LAW"
echo "   • Virtual Machine: $VM"
echo "   • CPU Alert Rule: cpu-high-alert"
echo "   • Dashboard: atul-monitor-dashboard"