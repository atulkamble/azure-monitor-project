#!/bin/bash

# Azure Monitor Project - Cleanup Script
# This script removes all resources created by the Azure Monitor deployment
# 
# Usage: ./scripts/cleanup.sh [resource-group-name]
# Example: ./scripts/cleanup.sh my-custom-rg
#
# If no resource group is provided, uses default: monitor

set -e

# Configuration - can be overridden by command line argument
RG="${1:-monitor}"

echo "🧹 ============================================="
echo "🧹   AZURE MONITOR PROJECT CLEANUP TOOL     "
echo "🧹 ============================================="
echo ""

# Check if Azure CLI is logged in
if ! az account show >/dev/null 2>&1; then
    echo "❌ Error: Not logged into Azure CLI"
    echo "   Please run: az login"
    exit 1
fi

# Display current configuration
SUBSCRIPTION=$(az account show --query name -o tsv)
echo "📋 Cleanup Configuration:"
echo "   Subscription: $SUBSCRIPTION"
echo "   Resource Group: $RG"
echo ""

# Check if resource group exists
if ! az group show --name $RG >/dev/null 2>&1; then
    echo "❌ Error: Resource group '$RG' does not exist"
    echo "   Available resource groups:"
    az group list --query "[].name" -o tsv | grep -E "(monitor|azure)" || echo "   No matching resource groups found"
    exit 1
fi

# Show resources that will be deleted
echo "🔍 Resources in '$RG' that will be deleted:"
az resource list --resource-group $RG --query "[].{Name:name, Type:type, Location:location}" -o table

if [ $(az resource list --resource-group $RG --query "length(@)") -eq 0 ]; then
    echo "   (No resources found - resource group appears to be empty)"
fi

echo ""

# Enhanced confirmation prompt with multiple safeguards
echo "⚠️  WARNING: This action is IRREVERSIBLE!"
echo "⚠️  This will permanently delete:"
echo "   • Resource Group: $RG"
echo "   • All Virtual Machines and their disks"
echo "   • Log Analytics Workspace and all data"
echo "   • Network components (VNet, NSG, Public IPs)"
echo "   • Alert rules and action groups"
echo "   • All monitoring data and configurations"
echo ""
echo "💡 Alternative: Use 'az vm stop' to shut down VMs without deleting them"
echo ""

read -p "🔄 Type the resource group name to confirm deletion [$RG]: " CONFIRM_RG

if [ "$CONFIRM_RG" != "$RG" ]; then
    echo "❌ Resource group name mismatch. Cleanup cancelled for safety."
    exit 1
fi

read -p "🚨 Are you absolutely sure you want to DELETE EVERYTHING? (type 'DELETE' to confirm): " FINAL_CONFIRM

if [ "$FINAL_CONFIRM" != "DELETE" ]; then
    echo "❌ Final confirmation failed. Cleanup cancelled."
    echo "   To proceed, type 'DELETE' exactly as shown"
    exit 1
fi

echo ""
echo "🗑️  Initiating resource group deletion..."
echo "📊 This may take several minutes to complete"

# Start deletion with progress indication
if az group delete --name $RG --yes --no-wait; then
    echo "✅ Cleanup successfully initiated!"
    echo ""
    echo "📋 Cleanup Status:"
    echo "   • Deletion started for resource group: $RG"
    echo "   • Process running in background (--no-wait)"
    echo "   • All resources will be permanently removed"
    echo ""
    echo "🔍 Monitor Progress:"
    echo "   • Azure Portal: Resource Groups → $RG"
    echo "   • CLI Command: az group show --name $RG"
    echo "   • When complete, the resource group will no longer exist"
    echo ""
    echo "💰 Cost Impact:"
    echo "   • All compute costs will stop immediately"
    echo "   • Storage costs will stop after deletion completes"
    echo "   • Log Analytics data retention charges may continue briefly"
    echo ""
    echo "🎯 Next Steps:"
    echo "   1. Wait for deletion to complete (5-15 minutes typical)"
    echo "   2. Verify removal: az group list --query \"[?name=='$RG']\""
    echo "   3. Check Azure Portal to confirm no remaining resources"
else
    echo "❌ Failed to initiate cleanup"
    echo "   • Check your permissions on the resource group"
    echo "   • Ensure no resources have delete locks"
    echo "   • Try manual deletion via Azure Portal"
    exit 1
fi