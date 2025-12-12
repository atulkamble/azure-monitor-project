#!/bin/bash
RG="monitor-rg"
VM="monitor-vm"
LAW="atul-law"

WID=$(az monitor log-analytics workspace show \
  --resource-group $RG \
  --workspace-name $LAW \
  --query customerId -o tsv)

az vm extension set \
  --publisher Microsoft.Azure.Monitor \
  --name AzureMonitorLinuxAgent \
  --resource-group $RG \
  --vm-name $VM \
  --workspace-id $WID