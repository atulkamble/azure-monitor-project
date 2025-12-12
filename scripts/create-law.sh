#!/bin/bash
RG="monitor-rg"
LAW="atul-law"
LOCATION="eastus"

az monitor log-analytics workspace create \
  --resource-group $RG \
  --workspace-name $LAW \
  --location $LOCATION