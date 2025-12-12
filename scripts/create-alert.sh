#!/bin/bash
VM_ID=$(az vm show -g monitor-rg -n monitor-vm --query id -o tsv)

az monitor metrics alert create \
  --name cpu-high-alert \
  --resource-group monitor-rg \
  --scopes $VM_ID \
  --condition "avg Percentage CPU > 80" \
  --description "CPU exceeds 80%" \
  --window-size 5m \
  --evaluation-frequency 1m