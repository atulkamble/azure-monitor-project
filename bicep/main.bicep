targetScope = 'subscription'

param resourceGroupName string = 'monitor-rg'
param location string = 'eastus'
param workspaceName string = 'atul-law'
param vmName string = 'monitor-vm'
param adminUsername string = 'azureuser'
param sshPublicKey string

// Resource Group
resource rg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: resourceGroupName
  location: location
}

// Log Analytics Workspace
module law 'loganalytics.bicep' = {
  name: 'logAnalyticsDeployment'
  scope: rg
  params: {}
}

// Virtual Network
resource vnet 'Microsoft.Network/virtualNetworks@2021-02-01' = {
  name: 'monitor-vnet'
  location: location
  scope: rg
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.0.0.0/16'
      ]
    }
    subnets: [
      {
        name: 'default'
        properties: {
          addressPrefix: '10.0.1.0/24'
        }
      }
    ]
  }
}

// Public IP
resource pip 'Microsoft.Network/publicIPAddresses@2021-02-01' = {
  name: '${vmName}-pip'
  location: location
  scope: rg
  properties: {
    publicIPAllocationMethod: 'Dynamic'
  }
}

// Network Security Group
resource nsg 'Microsoft.Network/networkSecurityGroups@2021-02-01' = {
  name: '${vmName}-nsg'
  location: location
  scope: rg
  properties: {
    securityRules: [
      {
        name: 'SSH'
        properties: {
          priority: 1000
          protocol: 'Tcp'
          access: 'Allow'
          direction: 'Inbound'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '22'
        }
      }
    ]
  }
}

// Network Interface
resource nic 'Microsoft.Network/networkInterfaces@2021-02-01' = {
  name: '${vmName}-nic'
  location: location
  scope: rg
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: pip.id
          }
          subnet: {
            id: '${vnet.id}/subnets/default'
          }
        }
      }
    ]
    networkSecurityGroup: {
      id: nsg.id
    }
  }
}

// Virtual Machine
resource vm 'Microsoft.Compute/virtualMachines@2021-03-01' = {
  name: vmName
  location: location
  scope: rg
  properties: {
    hardwareProfile: {
      vmSize: 'Standard_B1s'
    }
    osProfile: {
      computerName: vmName
      adminUsername: adminUsername
      linuxConfiguration: {
        disablePasswordAuthentication: true
        ssh: {
          publicKeys: [
            {
              path: '/home/${adminUsername}/.ssh/authorized_keys'
              keyData: sshPublicKey
            }
          ]
        }
      }
    }
    storageProfile: {
      imageReference: {
        publisher: 'Canonical'
        offer: '0001-com-ubuntu-server-focal'
        sku: '20_04-lts-gen2'
        version: 'latest'
      }
      osDisk: {
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: 'Premium_LRS'
        }
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nic.id
        }
      ]
    }
  }
}

// Azure Monitor Agent Extension
resource amaExtension 'Microsoft.Compute/virtualMachines/extensions@2021-03-01' = {
  name: '${vm.name}/AzureMonitorLinuxAgent'
  location: location
  properties: {
    publisher: 'Microsoft.Azure.Monitor'
    type: 'AzureMonitorLinuxAgent'
    typeHandlerVersion: '1.0'
    autoUpgradeMinorVersion: true
  }
}

// VM Insights
module vmInsights 'vminsights.bicep' = {
  name: 'vmInsightsDeployment'
  scope: rg
  params: {
    vmId: vm.id
    workspaceId: law.outputs.workspaceId
  }
  dependsOn: [
    amaExtension
  ]
}

// Alerts
module alerts 'alerts.bicep' = {
  name: 'alertsDeployment'
  scope: rg
  params: {
    vmId: vm.id
  }
}

output resourceGroupName string = rg.name
output vmId string = vm.id
output workspaceId string = law.outputs.workspaceId
output publicIPAddress string = pip.properties.ipAddress