// that's the default, but put it here for completeness
targetScope = 'resourceGroup'

// PARAMS
param resourceTags object
param location string = resourceGroup().location
param appName string
param vnetAddressSpace string

param appServicePlanSku object = {
    name: 'S1'
    tier: 'Standard'
    size: 'S1'
    family: 'S'
    capacity: 1
}
param aspServerOS string = 'Linux'

//VARS
var env = resourceTags.Environment
var vnetName = 'vnet-${appName}-${env}'
var subnetsInfo = [
  {
    name: 'default'
    properties: {
      addressPrefix: '192.168.0.0/24'
      privateEndpointNetworkPolicies: 'Disabled' //any value will be translated to Enabled
      privateLinkServiceNetworkPolicies: 'Enabled'
    }
  }
  {
    name: 'snetWebApp'
    properties: {
      addressPrefix: '192.168.1.0/24'
      delegations: [
        {
          name: 'delegation'
          properties: {
            serviceName: 'Microsoft.Web/serverfarms'
          }
        }
      ] 
    }
  }
]

var lawsName = 'laws-${appName}'

var appHostName = 'asp-${appName}-${env}'
var webAppContainerName = 'app-${appName}-${env}'
var AppSettingsKeyValuePairs = {
  ExtraAppSettingsTest: 'nothing'
}


//var appInsFuncsName = 'ai-Funcs-${appName}'

//Create Resources

//create the Virtual Network to host all resources and its subnets
module vnet '../modules/networking/vnet.bicep' = {
  name: 'vnetDeployment-${vnetName}'
  params: {
    name: vnetName
    location: location
    vnetAddressSpace: vnetAddressSpace
    tags: resourceTags
    subnetsInfo: subnetsInfo
  }
}

module laws '../modules/logs/logAnalyticsWS.bicep' = {
  name: 'logAnalyticsWS-deployment'
  params: {
    name: lawsName
    location: location
    tags: resourceTags
  }
}

module appHost '../modules/appService/appServicePlan.bicep' = {
  name: 'asp-Host-deployment'
  params: {
    name: appHostName
    location: location
    sku: appServicePlanSku
    serverOS: aspServerOS
    isElasticPremium: false
    diagnosticWorkspaceId: laws.outputs.id
  }
}

module webAppContainer '../modules/appService/functionOrApp.bicep' = {
  name: 'webAppContainer-deployment'
  params: {
    kind: 'app,linux,container'
    name: webAppContainerName
    location: location
    tags: resourceTags
    serverFarmResourceId: appHost.outputs.resourceId
    systemAssignedIdentity: true
    diagnosticWorkspaceId: laws.outputs.id
    appSettingsKeyValuePairs: AppSettingsKeyValuePairs
    siteConfig: {
      linuxFxVersion: 'DOCKER|mcr.microsoft.com/appsvc/staticsite:latest' 
      alwaysOn: true
    }
  }
}


output appName string = appName
output vnetId string = vnet.outputs.vnetId
output subnets array = [for (item, i) in subnetsInfo: {
  subnetIndex: i
  subnetName: vnet.outputs.subnetsOutput[i].name
  subnetId: vnet.outputs.subnetsOutput[i].id
}]
