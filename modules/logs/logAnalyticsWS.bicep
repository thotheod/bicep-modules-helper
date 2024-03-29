@description('Required. Name of the Bastion Service.')
param name string

@description('Azure region where the resources will be deployed in')
param location string

param tags object = {}

@description('Optional. Service Tier: PerGB2018, Free, Standalone, PerGB or PerNode.')
@allowed([
  'Free'
  'Standalone'
  'PerNode'
  'PerGB2018'
])
param serviceTier string = 'PerGB2018'

@description('Optional, default 90. Number of days data will be retained for.')
@minValue(0)
@maxValue(730)
param dataRetention int = 90

@description('Optional. The network access type for accessing Log Analytics ingestion.')
@allowed([
  'Enabled'
  'Disabled'
])
param publicNetworkAccessForIngestion string = 'Enabled'

@description('Optional. The network access type for accessing Log Analytics query.')
@allowed([
  'Enabled'
  'Disabled'
])
param publicNetworkAccessForQuery string = 'Enabled'

@description('Optional. Set to \'true\' to use resource or workspace permissions and \'false\' (or leave empty) to require workspace permissions.')
param useResourcePermissions bool = false

var lawsMaxLength = 63
var lawsNameSantized = replace(name, '_', '-')
var lawsName = length(lawsNameSantized) > lawsMaxLength ? substring(lawsNameSantized, 0, lawsMaxLength) : lawsNameSantized

resource laws 'Microsoft.OperationalInsights/workspaces@2022-10-01' = {
  location: location
  name: lawsName
  tags: tags
  properties: {
    retentionInDays: dataRetention
    publicNetworkAccessForIngestion: publicNetworkAccessForIngestion
    publicNetworkAccessForQuery: publicNetworkAccessForQuery
    sku:{
      name:serviceTier
    }
    features: {
      enableLogAccessUsingOnlyResourcePermissions: useResourcePermissions
    }
  }
}

@description('The name of the resource.')
output logAnalyticsWSName string = laws.name

@description('The resource ID of the resource.')
output logAnalyticsWSID string = laws.id
