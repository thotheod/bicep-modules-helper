@description('Name of the Media Services account. A Media Services account name is globally unique, all lowercase letters or numbers with no spaces.')
param name string

@description('Location for all resources.')
param location string = resourceGroup().location
param tags object

@description('ID of the Primary Storage Account')
param storageAccountIds array

@description('The User Managed Identity ID of the resource')
param userAssignedIdentityId string

// Diagnostic Settings
@description('Optional. Specifies the number of days that logs will be kept for; a value of 0 will retain data indefinitely.')
@minValue(0)
@maxValue(365)
param diagnosticLogsRetentionInDays int = 365

@description('Optional. The name of the diagnostic setting, if deployed.')
param diagnosticSettingsName string = '${name}-diagnosticSettings'

@description('Optional. Resource ID of the diagnostic storage account. For security reasons, it is recommended to set diagnostic settings to send data to either storage account, log analytics workspace or event hub.')
param diagnosticStorageAccountId string = ''

@description('Optional. Resource ID of the diagnostic log analytics workspace. For security reasons, it is recommended to set diagnostic settings to send data to either storage account, log analytics workspace or event hub.')
param diagnosticWorkspaceId string = ''

@description('Optional. Resource ID of the diagnostic event hub authorization rule for the Event Hubs namespace in which the event hub should be created or streamed to.')
param diagnosticEventHubAuthorizationRuleId string = ''

@description('Optional. Name of the diagnostic event hub within the namespace to which logs are streamed. Without this, an event hub is created for each log category. For security reasons, it is recommended to set diagnostic settings to send data to either storage account, log analytics workspace or event hub.')
param diagnosticEventHubName string = ''

@description('Optional. The name of logs that will be streamed.')
param diagnosticLogCategoriesToEnable array =  [
  'MediaAccount'
  'KeyDeliveryRequests'   //that costs to export
]

@description('Optional. The name of metrics that will be streamed.')
@allowed([
  'AllMetrics'
])
param diagnosticMetricsToEnable array = [
  'AllMetrics'
]

var diagnosticsMetrics = [for metric in diagnosticMetricsToEnable: {
  category: metric
  timeGrain: null
  enabled: true
  retentionPolicy: {
    enabled: true
    days: diagnosticLogsRetentionInDays
  }
}]


var diagnosticsLogs = [for category in diagnosticLogCategoriesToEnable: {
  category: category
  enabled: true
  retentionPolicy: {
    enabled: true
    days: diagnosticLogsRetentionInDays
  }
}]

// param userAssignedIdentities any

resource mediaService 'Microsoft.Media/mediaservices@2021-06-01' = {
  name: name
  location: location
  tags: tags
  properties: {
    storageAccounts: [for (storageAccountId, index) in storageAccountIds: {
      id: storageAccountId
      type: index == 0 ? 'Primary' : 'Secondary'   
      identity: {   //"The 'identity' field for all storage accounts must be null when 'StorageAuthentication' is set to 'System'
        useSystemAssignedIdentity: false
        userAssignedIdentity: userAssignedIdentityId
      }
    }]
    storageAuthentication: 'ManagedIdentity'  //default value is System
  }

   identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {   
      '${userAssignedIdentityId}': {} 
    }
  }

  // EXAMPLE
  // identity: {
  //   type: 'UserAssigned'
  //   userAssignedIdentities: {   
          // you can have one or more lines
  //     '/subscriptions/12345678-1234-1234-1234-123456789012/resourcegroups/validation-rg/providers/Microsoft.ManagedIdentity/userAssignedIdentities/adp-sxx-az-msi-x-001': {} 
  //     '/subscriptions/12345678-1234-1234-1234-123456789012/resourcegroups/validation-rg/providers/Microsoft.ManagedIdentity/userAssignedIdentities/adp-sxx-az-msi-x-002': {}
  //   }
  // }
}

resource ams_diagnosticSettings 'Microsoft.Insights/diagnosticsettings@2021-05-01-preview' = if ((!empty(diagnosticStorageAccountId)) || (!empty(diagnosticWorkspaceId)) || (!empty(diagnosticEventHubAuthorizationRuleId)) || (!empty(diagnosticEventHubName))) {
  name: diagnosticSettingsName
  properties: {
    storageAccountId: !empty(diagnosticStorageAccountId) ? diagnosticStorageAccountId : null
    workspaceId: !empty(diagnosticWorkspaceId) ? diagnosticWorkspaceId : null
    eventHubAuthorizationRuleId: !empty(diagnosticEventHubAuthorizationRuleId) ? diagnosticEventHubAuthorizationRuleId : null
    eventHubName: !empty(diagnosticEventHubName) ? diagnosticEventHubName : null
    metrics: diagnosticsMetrics
    logs: diagnosticsLogs
  }
  scope: mediaService
}


// =========== //
// Outputs     //
// =========== //
@description('The resource group the Media Services was deployed into.')
output resourceGroupName string = resourceGroup().name

@description('The name of the Media Services.')
output name string = mediaService.name

@description('The resource ID of the Media Services.')
output resourceId string = mediaService.id

@description('The location the resource was deployed into.')
output location string = mediaService.location

@description('The base Uri of the Service')
output baseUri string = 'https://${mediaService.name}.restv2.${resourceGroup().location}.media.azure.net'
