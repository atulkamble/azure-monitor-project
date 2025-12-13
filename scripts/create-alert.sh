#!/bin/bash

# Azure Monitor Alert Creation Script
# Creates comprehensive metric alerts for VM monitoring
# Usage: ./create-alert.sh [resource-group] [vm-name] [action-group-name]

set -e  # Exit on any error

# Configuration Variables
RG="${1:-monitor}"
VM_NAME="${2:-monitor-vm}"
AG_NAME="${3:-monitor-action-group}"

echo "🔔 Creating Azure Monitor Alerts"
echo "   Resource Group: $RG"
echo "   VM Name: $VM_NAME"
echo "   Action Group: $AG_NAME"
echo ""

# Get VM ID and Action Group ID
echo "📊 Retrieving resource IDs..."
VM_ID=$(az vm show -g "$RG" -n "$VM_NAME" --query id -o tsv)
if [ -z "$VM_ID" ]; then
  echo "❌ Error: VM '$VM_NAME' not found in resource group '$RG'"
  exit 1
fi

ACTION_GROUP_ID=$(az monitor action-group show -g "$RG" -n "$AG_NAME" --query id -o tsv)
if [ -z "$ACTION_GROUP_ID" ]; then
  echo "❌ Error: Action Group '$AG_NAME' not found in resource group '$RG'"
  exit 1
fi

echo "✅ VM ID: $VM_ID"
echo "✅ Action Group ID: $ACTION_GROUP_ID"
echo ""

# CPU High Alert (>80%)
echo "📊 Creating CPU High Alert (>80%)..."
az monitor metrics alert create \
  --name cpu-high-alert \
  --resource-group "$RG" \
  --scopes "$VM_ID" \
  --condition "avg 'Percentage CPU' > 80" \
  --description "CPU exceeds 80% for 5 minutes" \
  --window-size 5m \
  --evaluation-frequency 1m \
  --severity 2 \
  --action "$ACTION_GROUP_ID" \
  --auto-mitigate true \
  --verbose

# Memory Low Alert (<15% available) - Note: Requires Azure Monitor Agent with guest OS metrics
echo "💾 Creating Memory Low Alert (<15% available)..."
az monitor metrics alert create \
  --name memory-low-alert \
  --resource-group "$RG" \
  --scopes "$VM_ID" \
  --condition "avg 'Available Memory Bytes' < 1610612736" \
  --description "Available memory is below 1.5GB (equivalent to ~15% on 8GB system)" \
  --window-size 5m \
  --evaluation-frequency 1m \
  --severity 2 \
  --action "$ACTION_GROUP_ID" \
  --auto-mitigate true \
  --verbose \
  || echo "⚠️  Memory alert creation failed - Azure Monitor Agent with guest OS metrics may not be configured"

# Disk Space Alert (<10% free space) - Note: Requires Azure Monitor Agent
echo "💿 Creating Disk Space Alert (<10% free space)..."
az monitor metrics alert create \
  --name disk-space-alert \
  --resource-group "$RG" \
  --scopes "$VM_ID" \
  --condition "avg 'Disk Free Space %' < 10" \
  --description "Disk free space is below 10%" \
  --window-size 5m \
  --evaluation-frequency 1m \
  --severity 2 \
  --action "$ACTION_GROUP_ID" \
  --auto-mitigate true \
  --verbose \
  || echo "⚠️  Disk space alert creation failed - Azure Monitor Agent with guest OS metrics may not be configured"

# Network In Alert (High traffic) - Optional
echo "🌐 Creating Network In Alert (>100MB/5min)..."
az monitor metrics alert create \
  --name network-in-high-alert \
  --resource-group "$RG" \
  --scopes "$VM_ID" \
  --condition "total 'Network In Total' > 104857600" \
  --description "High network inbound traffic detected (>100MB in 5 minutes)" \
  --window-size 5m \
  --evaluation-frequency 1m \
  --severity 3 \
  --action "$ACTION_GROUP_ID" \
  --auto-mitigate true \
  --verbose \
  || echo "⚠️  Network alert creation failed - metric may not be available"

# VM Availability Alert
echo "🖥️  Creating VM Availability Alert..."
az monitor metrics alert create \
  --name vm-availability-alert \
  --resource-group "$RG" \
  --scopes "$VM_ID" \
  --condition "avg 'VmAvailabilityMetric' < 1" \
  --description "Virtual Machine is not available" \
  --window-size 5m \
  --evaluation-frequency 1m \
  --severity 1 \
  --action "$ACTION_GROUP_ID" \
  --auto-mitigate true \
  --verbose \
  || echo "⚠️  VM availability alert creation failed - metric may not be available"

echo ""
echo "📋 Listing all created metric alerts..."
az monitor metrics alert list \
  --resource-group "$RG" \
  --output table

echo ""
echo "🎉 Alert creation completed!"
echo ""
echo "📝 Notes:"
echo "   • CPU alert uses host-level metrics (always available)"
echo "   • Memory and disk alerts require Azure Monitor Agent with guest OS metrics"
echo "   • Some alerts may fail if the VM hasn't been running long enough to generate metrics"
echo "   • Check Azure Portal → Monitor → Alerts to verify alert status"
echo ""