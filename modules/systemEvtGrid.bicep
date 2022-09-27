@minLength(3)
@maxLength(50)
@description('Required. The name of the Event Grid Topic. it can only contain letters, numbers, and dashes')
param name string

@description('Optional. Location for all Resources.')
param location string = resourceGroup().location

@description('Required. Source for the system topic.')
param source string

@description('Required. TopicType for the system topic.')
param topicType string

// @description('Optional. Specifies the number of days that logs will be kept for; a value of 0 will retain data indefinitely.')
// @minValue(0)
// @maxValue(365)
// param diagnosticLogsRetentionInDays int = 365

// @description('Optional. Resource ID of the diagnostic storage account.')
// param diagnosticStorageAccountId string = ''

// @description('Optional. Resource ID of the diagnostic log analytics workspace.')
// param diagnosticWorkspaceId string = ''

// @description('Optional. Resource ID of the diagnostic event hub authorization rule for the Event Hubs namespace in which the event hub should be created or streamed to.')
// param diagnosticEventHubAuthorizationRuleId string = ''

// @description('Optional. Name of the diagnostic event hub within the namespace to which logs are streamed. Without this, an event hub is created for each log category.')
// param diagnosticEventHubName string = ''

// @description('Optional. Configuration Details for private endpoints.')
// param privateEndpoints array = []

// @description('Optional. Array of role assignment objects that contain the \'roleDefinitionIdOrName\' and \'principalId\' to define RBAC role assignments on this resource. In the roleDefinitionIdOrName attribute, you can provide either the display name of the role definition, or its fully qualified ID in the following format: \'/providers/Microsoft.Authorization/roleDefinitions/c2f4ef07-c644-48eb-af81-4b1b4947fb11\'.')
// param roleAssignments array = []



@description('Optional. Enables system assigned managed identity on the resource.')
param systemAssignedIdentity bool = false

@description('Optional. The ID(s) to assign to the resource.')
param userAssignedIdentities object = {}

@description('Optional. Tags of the resource.')
param tags object = {}



var identityType = systemAssignedIdentity ? (!empty(userAssignedIdentities) ? 'SystemAssigned,UserAssigned' : 'SystemAssigned') : (!empty(userAssignedIdentities) ? 'UserAssigned' : 'None')

var identity = identityType != 'None' ? {
  type: identityType
  userAssignedIdentities: !empty(userAssignedIdentities) ? userAssignedIdentities : null
} : null

// @description('Optional. The name of logs that will be streamed.')
// @allowed([
//   'DeliveryFailures'
// ])
// param diagnosticLogCategoriesToEnable array = [
//   'DeliveryFailures'
// ]

// @description('Optional. The name of metrics that will be streamed.')
// @allowed([
//   'AllMetrics'
// ])
// param diagnosticMetricsToEnable array = [
//   'AllMetrics'
// ]

// @description('Optional. The name of the diagnostic setting, if deployed.')
// param diagnosticSettingsName string = '${name}-diagnosticSettings'

// var diagnosticsLogs = [for category in diagnosticLogCategoriesToEnable: {
//   category: category
//   enabled: true
//   retentionPolicy: {
//     enabled: true
//     days: diagnosticLogsRetentionInDays
//   }
// }]

// var diagnosticsMetrics = [for metric in diagnosticMetricsToEnable: {
//   category: metric
//   timeGrain: null
//   enabled: true
//   retentionPolicy: {
//     enabled: true
//     days: diagnosticLogsRetentionInDays
//   }
// }]

// resource defaultTelemetry 'Microsoft.Resources/deployments@2021-04-01' = if (enableDefaultTelemetry) {
//   name: 'pid-47ed15a6-730a-4827-bcb4-0fd963ffbd82-${uniqueString(deployment().name, location)}'
//   properties: {
//     mode: 'Incremental'
//     template: {
//       '$schema': 'https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#'
//       contentVersion: '1.0.0.0'
//       resources: []
//     }
//   }
// }

resource systemTopic 'Microsoft.EventGrid/systemTopics@2021-12-01' = {
  name: name
  location: location
  identity: identity
  tags: tags
  properties: {
    source: source
    topicType: topicType
  }
}

@description('The name of the event grid system topic.')
output name string = systemTopic.name

@description('The resource ID of the event grid system topic.')
output resourceId string = systemTopic.id

@description('The name of the resource group the event grid system topic was deployed into.')
output resourceGroupName string = resourceGroup().name

@description('The principal ID of the system assigned identity.')
output systemAssignedPrincipalId string = systemAssignedIdentity && contains(systemTopic.identity, 'principalId') ? systemTopic.identity.principalId : ''

@description('The location the resource was deployed into.')
output location string = systemTopic.location
