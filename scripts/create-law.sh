#!/bin/bash
RG="monitor"
LAW="mylaw"
LOCATION="eastus"

az monitor log-analytics workspace create \
  --resource-group $RG \
  --workspace-name $LAW \
  --location $LOCATION