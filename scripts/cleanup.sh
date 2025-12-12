#!/bin/bash

# Azure Monitor Project - Cleanup Script
# This script removes all resources created by the project

set -e

RG="monitor-rg"

echo "🧹 Starting Azure Monitor Project Cleanup..."

# Confirmation prompt
echo "⚠️  This will delete the entire resource group '$RG' and all its resources."
read -p "Are you sure you want to proceed? (y/N): " -n 1 -r
echo

if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "🗑️  Deleting resource group: $RG"
    az group delete --name $RG --yes --no-wait
    echo "✅ Cleanup initiated. Resources will be deleted in the background."
else
    echo "❌ Cleanup cancelled."
    exit 1
fi