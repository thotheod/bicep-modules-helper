// ================ //
// Parameters       //
// ================ //
// General
@description('Required. Name of the site.')
param name string

@description('Optional. Location for all Resources.')
param location string = resourceGroup().location

@description('Optional. Tags of the resource.')
param tags object = {}

@description('Required. Type of site to deploy.')
@allowed([
  'functionapp'
  'functionapp,linux'
  'app'
  'app,linux,container'
])
param kind string

@allowed([
  'dotnet'
  'dotnet-isolated'
  'java'
  'node'
  'powershell'
  'python'
  ''
])
@description('Default is null, if kind is functionapp then required') //https://docs.microsoft.com/en-us/azure/azure-functions/functions-app-settings#functions_worker_runtime
param functionsWorkerRuntime string = ''

@description('Default is null, if functionsWorkerRuntime==dotnet, then version is 6 or 3.1')
param functionsWorkerRuntimeVersion string = ''

@description('Optional if hosting is serverless. The resource ID of the app service plan to use for the site.')
param serverFarmResourceId string = ''

@description('Optional. Configures a site to accept only HTTPS requests. Issues redirect for HTTP requests.')
param httpsOnly bool = true

@description('Optional. If client affinity is enabled.')
param clientAffinityEnabled bool = true

@description('Optional. Enables system assigned managed identity on the resource.')
param systemAssignedIdentity bool = false

@description('Optional. The ID(s) to assign to the resource.')
param userAssignedIdentityId string = ''

// @description('Optional. The ID(s) to assign to the resource.')
// param userAssignedIdentities object = {}

@description('Optional. Checks if Customer provided storage account is required.')
param storageAccountRequired bool = false

@description('Optional. Azure Resource Manager ID of the Virtual network and subnet to be joined by Regional VNET Integration. This must be of the form /subscriptions/{subscriptionName}/resourceGroups/{resourceGroupName}/providers/Microsoft.Network/virtualNetworks/{vnetName}/subnets/{subnetName}.')
param virtualNetworkSubnetId string = ''

// Site Config
@description('Optional. The site config object.')
param siteConfig object = {}

@description('Optional. Required if app of kind functionapp. Resource ID of the storage account to manage triggers and logging function executions.')
param storageAccountId string = ''

@description('Optional. Resource ID of the app insight to leverage for this resource.')
param appInsightId string = ''

@description('Optional. For function apps. If true the app settings "AzureWebJobsDashboard" will be set. If false not. In case you use Application Insights it can make sense to not set it for performance reasons.')
param setAzureWebJobsDashboard bool = contains(kind, 'functionapp') ? true : false

@description('Optional. The app settings-value pairs except for AzureWebJobsStorage, AzureWebJobsDashboard, APPINSIGHTS_INSTRUMENTATIONKEY and APPLICATIONINSIGHTS_CONNECTION_STRING.')
param appSettingsKeyValuePairs object = {}

@description('Optional. The auth settings V2 configuration.')
param authSettingV2Configuration object = {}

// // Private Endpoints
// @description('Optional. Configuration details for private endpoints.')
// param privateEndpoints array = []

// Role Assignments
// @description('Optional. Array of role assignment objects that contain the \'roleDefinitionIdOrName\' and \'principalId\' to define RBAC role assignments on this resource. In the roleDefinitionIdOrName attribute, you can provide either the display name of the role definition, or its fully qualified ID in the following format: \'/providers/Microsoft.Authorization/roleDefinitions/c2f4ef07-c644-48eb-af81-4b1b4947fb11\'.')
// param roleAssignments array = []

// Diagnostic Settings
@description('Optional. Specifies the number of days that logs will be kept for; a value of 0 will retain data indefinitely.')
@minValue(0)
@maxValue(365)
param diagnosticLogsRetentionInDays int = 365

@description('Optional. Resource ID of the diagnostic storage account.')
param diagnosticStorageAccountId string = ''

@description('Optional. Resource ID of log analytics workspace.')
param diagnosticWorkspaceId string = ''

@description('Optional. Resource ID of the diagnostic event hub authorization rule for the Event Hubs namespace in which the event hub should be created or streamed to.')
param diagnosticEventHubAuthorizationRuleId string = ''

@description('Optional. Name of the diagnostic event hub within the namespace to which logs are streamed. Without this, an event hub is created for each log category.')
param diagnosticEventHubName string = ''

@description('Optional. The name of logs that will be streamed.')
@allowed([
  'AppServiceHTTPLogs'
  'AppServiceConsoleLogs'
  'AppServiceAppLogs'
  'AppServiceAuditLogs'
  'AppServiceIPSecAuditLogs'
  'AppServicePlatformLogs'
  'FunctionAppLogs'
])
param diagnosticLogCategoriesToEnable array = kind == 'functionapp' ? [
  'FunctionAppLogs'
] : [
  'AppServiceHTTPLogs'
  'AppServiceConsoleLogs'
  'AppServiceAppLogs'
  'AppServiceAuditLogs'
  'AppServiceIPSecAuditLogs'
  'AppServicePlatformLogs'
]

@description('Optional. The name of metrics that will be streamed.')
@allowed([
  'AllMetrics'
])
param diagnosticMetricsToEnable array = [
  'AllMetrics'
]

@description('Optional. The name of the diagnostic setting, if deployed.')
param diagnosticSettingsName string = '${name}-diagnosticSettings'

// =========== //
// Variables   //
// =========== //

var azureWebJobsValues = !empty(storageAccountId) ? union({
  AzureWebJobsStorage: 'DefaultEndpointsProtocol=https;AccountName=${storageAccount.name};AccountKey=${storageAccount.listKeys().keys[0].value};'
}, ((setAzureWebJobsDashboard == true) ? {
  AzureWebJobsDashboard: 'DefaultEndpointsProtocol=https;AccountName=${storageAccount.name};AccountKey=${storageAccount.listKeys().keys[0].value};'
} : {})) : {}

var appInsightsValues = !empty(appInsightId) ? {
  APPINSIGHTS_INSTRUMENTATIONKEY: appInsight.properties.InstrumentationKey
  APPLICATIONINSIGHTS_CONNECTION_STRING: appInsight.properties.ConnectionString
} : {}


var funcNet6WindowsAppSettings = functionsWorkerRuntime == 'dotnet' &&  functionsWorkerRuntimeVersion == '6' ? {   //.net 6 function app, in windows hosting, func version ~4, default appSettings
      FUNCTIONS_EXTENSION_VERSION: '~4'
      FUNCTIONS_WORKER_RUNTIME: 'dotnet'
      WEBSITE_CONTENTSHARE: toLower(name)
      WEBSITE_CONTENTAZUREFILECONNECTIONSTRING:  'DefaultEndpointsProtocol=https;AccountName=${storageAccount.name};AccountKey=${listKeys(storageAccount.id, storageAccount.apiVersion).keys[0].value}'// '@Microsoft.KeyVault(VaultName=keyVaultName;SecretName=${secretNames.funcStorageConnectionString})' //'DefaultEndpointsProtocol=https;AccountName=${funcStorageExisting.name};EndpointSuffix=${environment().suffixes.storage};AccountKey=${funcStorageExisting.listKeys().keys[0].value}'
    } : {}

var funcNet31WindowsAppSettings = functionsWorkerRuntime == 'dotnet' &&  functionsWorkerRuntimeVersion == '3.1' ? {   //.net 6 function app, in windows hosting, func version ~4, default appSettings
      FUNCTIONS_EXTENSION_VERSION: '~3'
      FUNCTIONS_WORKER_RUNTIME: 'dotnet'
      WEBSITE_CONTENTSHARE: toLower(name)
      WEBSITE_CONTENTAZUREFILECONNECTIONSTRING:  'DefaultEndpointsProtocol=https;AccountName=${storageAccount.name};AccountKey=${listKeys(storageAccount.id, storageAccount.apiVersion).keys[0].value}'// '@Microsoft.KeyVault(VaultName=keyVaultName;SecretName=${secretNames.funcStorageConnectionString})' //'DefaultEndpointsProtocol=https;AccountName=${funcStorageExisting.name};EndpointSuffix=${environment().suffixes.storage};AccountKey=${funcStorageExisting.listKeys().keys[0].value}'
    } : {}    

var containerAppSettings = contains(kind, 'container') ? {
  DOCKER_REGISTRY_SERVER_PASSWORD: ''
  DOCKER_REGISTRY_SERVER_URL: 'https://mcr.microsoft.com'
  DOCKER_REGISTRY_SERVER_USERNAME: ''
  WEBSITES_ENABLE_APP_SERVICE_STORAGE: 'false'
} : {}


var expandedAppSettings = union(appSettingsKeyValuePairs, azureWebJobsValues, appInsightsValues, authSettingV2Configuration, funcNet6WindowsAppSettings, funcNet31WindowsAppSettings, containerAppSettings)

var diagnosticsLogs = [for category in diagnosticLogCategoriesToEnable: {
  category: category
  enabled: true
  retentionPolicy: {
    enabled: true
    days: diagnosticLogsRetentionInDays
  }
}]

var diagnosticsMetrics = [for metric in diagnosticMetricsToEnable: {
  category: metric
  timeGrain: null
  enabled: true
  retentionPolicy: {
    enabled: true
    days: diagnosticLogsRetentionInDays
  }
}]

var userAssignedIdentities = (!empty(userAssignedIdentityId)) ? {   
      '${userAssignedIdentityId}': {} 
    } : {}

var identityType = systemAssignedIdentity ? (!empty(userAssignedIdentities) ? 'SystemAssigned,UserAssigned' : 'SystemAssigned') : (!empty(userAssignedIdentities) ? 'UserAssigned' : 'None')

var identity = identityType != 'None' ? {
  type: identityType
  userAssignedIdentities: !empty(userAssignedIdentities) ? userAssignedIdentities : null
} : null


// =========== //
// Existing resources //
// =========== //
resource appInsight 'microsoft.insights/components@2020-02-02' existing = if (!empty(appInsightId)) {
  name: last(split(appInsightId, '/'))
  scope: resourceGroup(split(appInsightId, '/')[2], split(appInsightId, '/')[4])
}

resource storageAccount 'Microsoft.Storage/storageAccounts@2021-02-01' existing = if (!empty(storageAccountId)) {
  name: last(split(storageAccountId, '/'))
  scope: resourceGroup(split(storageAccountId, '/')[2], split(storageAccountId, '/')[4])
}


// =========== //
// Deployments //
// =========== //

resource app 'Microsoft.Web/sites@2021-03-01' = {
  name: name
  location: location
  kind: kind
  tags: tags
  identity: identity

  properties: {
    serverFarmId: serverFarmResourceId
    clientAffinityEnabled: clientAffinityEnabled
    httpsOnly: httpsOnly    
    storageAccountRequired: storageAccountRequired
    virtualNetworkSubnetId: !empty(virtualNetworkSubnetId) ? virtualNetworkSubnetId : any(null)
    siteConfig: siteConfig
    keyVaultReferenceIdentity:  !empty(userAssignedIdentityId) ? userAssignedIdentityId : 'SystemAssigned'  // https://docs.microsoft.com/en-us/azure/app-service/app-service-key-vault-references?tabs=azure-cli#access-vaults-with-a-user-assigned-identity
  }
}

resource appSettings 'Microsoft.Web/sites/config@2020-12-01' = {
  name: 'appsettings'
  kind: kind
  parent: app
  properties: expandedAppSettings
}

resource app_diagnosticSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = if (!empty(diagnosticStorageAccountId) || !empty(diagnosticWorkspaceId) || !empty(diagnosticEventHubAuthorizationRuleId) || !empty(diagnosticEventHubName)) {
  name: diagnosticSettingsName
  properties: {
    storageAccountId: !empty(diagnosticStorageAccountId) ? diagnosticStorageAccountId : null
    workspaceId: !empty(diagnosticWorkspaceId) ? diagnosticWorkspaceId : null
    eventHubAuthorizationRuleId: !empty(diagnosticEventHubAuthorizationRuleId) ? diagnosticEventHubAuthorizationRuleId : null
    eventHubName: !empty(diagnosticEventHubName) ? diagnosticEventHubName : null
    metrics: diagnosticsMetrics
    logs: diagnosticsLogs
  }
  scope: app
}

// =========== //
// Outputs     //
// =========== //
@description('The name of the site.')
output name string = app.name

@description('The resource ID of the site.')
output resourceId string = app.id

@description('The resource group the site was deployed into.')
output resourceGroupName string = resourceGroup().name

@description('The principal ID of the system assigned identity.')
output systemAssignedPrincipalId string = systemAssignedIdentity && contains(app.identity, 'principalId') ? app.identity.principalId : ''

@description('The location the resource was deployed into.')
output location string = app.location
