param vmId string

resource actionGroup 'Microsoft.Insights/actionGroups@2022-06-01' = {
  name: 'monitor-action-group'
  location: 'global'
  properties: {
    groupShortName: 'monitor-ag'
    enabled: true
    emailReceivers: [
      {
        name: 'sendtoadmin'
        emailAddress: 'admin@example.com'
        useCommonAlertSchema: true
      }
    ]
  }
}

resource cpuAlert 'Microsoft.Insights/metricAlerts@2018-03-01' = {
  name: 'cpu-alert'
  location: 'global'
  properties: {
    description: 'CPU High Alert'
    severity: 2
    enabled: true
    scopes: [vmId]
    evaluationFrequency: 'PT1M'
    windowSize: 'PT5M'
    criteria: {
      'odata.type': 'Microsoft.Azure.Monitor.SingleResourceMultipleMetricCriteria'
      allOf: [
        {
          name: 'cpu-threshold'
          metricName: 'Percentage CPU'
          metricNamespace: 'Microsoft.Compute/virtualMachines'
          timeAggregation: 'Average'
          operator: 'GreaterThan'
          threshold: 80
        }
      ]
    }
    actions: [
      {
        actionGroupId: actionGroup.id
      }
    ]
  }
}

resource memoryAlert 'Microsoft.Insights/metricAlerts@2018-03-01' = {
  name: 'memory-alert'
  location: 'global'
  properties: {
    description: 'Memory High Alert'
    severity: 2
    enabled: true
    scopes: [vmId]
    evaluationFrequency: 'PT1M'
    windowSize: 'PT5M'
    criteria: {
      'odata.type': 'Microsoft.Azure.Monitor.SingleResourceMultipleMetricCriteria'
      allOf: [
        {
          name: 'memory-threshold'
          metricName: 'Available Memory Bytes'
          metricNamespace: 'Microsoft.Compute/virtualMachines'
          timeAggregation: 'Average'
          operator: 'LessThan'
          threshold: 1073741824 // 1 GB in bytes
        }
      ]
    }
    actions: [
      {
        actionGroupId: actionGroup.id
      }
    ]
  }
}

output actionGroupId string = actionGroup.id
output cpuAlertId string = cpuAlert.id
output memoryAlertId string = memoryAlert.id