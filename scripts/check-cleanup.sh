#!/bin/bash

# Azure Monitor Project - Cleanup Status Checker
# This script verifies that cleanup has completed successfully

RG="${1:-monitor}"

echo "🔍 ============================================="
echo "🔍   CLEANUP STATUS VERIFICATION TOOL       "  
echo "🔍 ============================================="
echo ""

echo "📋 Checking cleanup status for: $RG"
echo ""

# Check if resource group still exists
if az group show --name $RG >/dev/null 2>&1; then
    STATE=$(az group show --name $RG --query "properties.provisioningState" -o tsv)
    echo "📊 Resource Group Status: $STATE"
    
    if [ "$STATE" = "Deleting" ]; then
        echo "⏳ Deletion in progress..."
        echo "   • This can take 5-15 minutes to complete"
        echo "   • Azure is removing all resources and dependencies"
        echo ""
        echo "🔄 Remaining resources:"
        az resource list --resource-group $RG --query "[].{Name:name, Type:type}" -o table
        
        echo ""
        echo "💡 You can:"
        echo "   1. Wait for automatic completion"
        echo "   2. Re-run this script to check progress: ./scripts/check-cleanup.sh"
        echo "   3. Monitor in portal: https://portal.azure.com/#blade/HubsExtension/BrowseResourceGroups"
        
    elif [ "$STATE" = "Succeeded" ]; then
        echo "✅ Resource group exists but deletion may not have been initiated"
        echo ""
        RESOURCE_COUNT=$(az resource list --resource-group $RG --query "length(@)")
        echo "📊 Current resource count: $RESOURCE_COUNT"
        
        if [ "$RESOURCE_COUNT" -gt 0 ]; then
            echo ""
            echo "🗂️  Remaining resources:"
            az resource list --resource-group $RG --query "[].{Name:name, Type:type, Location:location}" -o table
            echo ""
            echo "💡 To delete these resources:"
            echo "   Run: ./scripts/cleanup.sh $RG"
        else
            echo "✅ Resource group is empty and can be safely deleted"
            echo "💡 Run: az group delete --name $RG --yes"
        fi
    else
        echo "⚠️  Resource group state: $STATE"
    fi
else
    echo "✅ SUCCESS: Resource group '$RG' has been completely removed!"
    echo ""
    echo "🔍 Verification complete:"
    echo "   • Resource group no longer exists"
    echo "   • All associated resources have been deleted"  
    echo "   • Billing for compute resources has stopped"
    echo ""
    echo "📝 Note: The NetworkWatcher resource in 'NetworkWatcherRG' is normal"
    echo "   • This is a system-managed Azure service"
    echo "   • It's automatically created and should NOT be deleted"
    echo "   • It doesn't incur additional charges"
    echo ""
    echo "🎯 Cleanup Status: COMPLETE ✅"
fi

echo ""
echo "🔄 To check again later, run: ./scripts/check-cleanup.sh $RG"