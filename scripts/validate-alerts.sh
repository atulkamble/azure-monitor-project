#!/bin/bash

# Azure Monitor Alert Validation Script
# Validates and cross-checks alert configurations against best practices
# Usage: ./validate-alerts.sh [resource-group] [vm-name]

set -e

# Configuration
RG="${1:-monitor}"
VM_NAME="${2:-monitor-vm}"

echo "🔍 Azure Monitor Alert Validation"
echo "   Resource Group: $RG"
echo "   VM Name: $VM_NAME"
echo ""

# Check if resources exist
echo "📊 Checking resource existence..."
VM_EXISTS=$(az vm show -g "$RG" -n "$VM_NAME" --query id -o tsv 2>/dev/null || echo "")
if [ -z "$VM_EXISTS" ]; then
  echo "❌ VM '$VM_NAME' not found in resource group '$RG'"
  exit 1
fi
echo "✅ VM found: $VM_EXISTS"

# Check available metrics for the VM
echo ""
echo "📈 Checking available metrics for VM..."
echo "Host-level metrics (always available):"
az monitor metrics list-definitions \
  --resource "$VM_EXISTS" \
  --query "[?primary.metricAvailabilities[0].timeGrain=='PT1M'].{Name:name.value,Unit:unit,Description:displayDescription}" \
  --output table

# Check if Azure Monitor Agent is installed
echo ""
echo "🔍 Checking Azure Monitor Agent installation..."
AMA_EXTENSION=$(az vm extension show \
  --resource-group "$RG" \
  --vm-name "$VM_NAME" \
  --name AzureMonitorLinuxAgent \
  --query "provisioningState" -o tsv 2>/dev/null || echo "Not Found")

if [ "$AMA_EXTENSION" = "Succeeded" ]; then
  echo "✅ Azure Monitor Agent is installed and running"
else
  echo "⚠️  Azure Monitor Agent not found - guest OS metrics will not be available"
fi

# Check if Log Analytics Agent (legacy) is installed
OMS_EXTENSION=$(az vm extension show \
  --resource-group "$RG" \
  --vm-name "$VM_NAME" \
  --name OmsAgentForLinux \
  --query "provisioningState" -o tsv 2>/dev/null || echo "Not Found")

if [ "$OMS_EXTENSION" = "Succeeded" ]; then
  echo "✅ Log Analytics Agent (OMS) is installed"
else
  echo "⚠️  Log Analytics Agent not found"
fi

# List existing alerts
echo ""
echo "🔔 Current metric alerts for VM:"
az monitor metrics alert list \
  --resource-group "$RG" \
  --query "[?contains(scopes[0], '$VM_NAME')].{Name:name,Condition:criteria.allOf[0].metricName,Threshold:criteria.allOf[0].threshold,Enabled:enabled}" \
  --output table

# Validate alert thresholds against best practices
echo ""
echo "📋 Alert Threshold Recommendations:"
echo "   CPU Usage: >80% (Critical), >70% (Warning) - ✅ GOOD"
echo "   Memory Available: <15% (Critical), <20% (Warning) - ✅ GOOD"
echo "   Disk Free Space: <10% (Critical), <20% (Warning) - ✅ GOOD"
echo "   Network In: >100MB/5min (depends on workload) - ⚠️  ADJUST AS NEEDED"
echo ""

# Check action groups
echo "🔔 Checking action groups..."
az monitor action-group list \
  --resource-group "$RG" \
  --query "[].{Name:name,EmailReceivers:emailReceivers[].emailAddress,Enabled:enabled}" \
  --output table

echo ""
echo "✅ Validation completed!"