targetScope = 'resourceGroup'

// PARAMS
param location string = resourceGroup().location
param appName string
param vnetAddressSpace string
param snetDefaultAddressSpace string
param snetWebAppAddressSpace string
param env string
param deployLogAnalyticsWs bool = true
param logAnalyticsWsName string = 'laws-${appName}-${env}'
param subnetNameDefault string = 'default'
param subnetNameAsp string = 'snetWebApp'
param aspServerOS string = 'Linux'
param appServicePlanSku object = {
    name: 'S1'
    tier: 'Standard'
    size: 'S1'
    family: 'S'
    capacity: 1
}


//VARS
var tags = {}
var vnetName = 'vnet-${appName}-${env}'
var subnetsInfo = [
  {
    name: subnetNameDefault
    properties: {
      addressPrefix: snetDefaultAddressSpace
      privateEndpointNetworkPolicies: 'Disabled' //any value will be translated to Enabled
      privateLinkServiceNetworkPolicies: 'Enabled'
    }
  }
  {
    name: subnetNameAsp
    properties: {
      addressPrefix: snetWebAppAddressSpace
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
var appHostName = 'asp-${appName}-${env}'
var webAppContainerName = 'app-${appName}-${env}'
var AppSettingsKeyValuePairs = {
  ExtraAppSettingsTest: 'nothing'
}

//Create Resources

//create the Virtual Network to host all resources and its subnets
module vnet '../modules/networking/vnet.bicep' = {
  name: 'vnetDeployment-${vnetName}'
  params: {
    name: vnetName
    location: location
    vnetAddressSpace: vnetAddressSpace
    tags: tags
    subnetsInfo: subnetsInfo
  }
}

module laws '../modules/logs/logAnalyticsWS.bicep' = if (deployLogAnalyticsWs) {
  name: 'logAnalyticsWS-deployment'
  params: {
    name: logAnalyticsWsName
    location: location
    tags: tags
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
    diagnosticWorkspaceId: deployLogAnalyticsWs ? laws.outputs.logAnalyticsWSID : ''
  }
}

module webAppContainer '../modules/appService/functionOrApp.bicep' = {
  name: 'webAppContainer-deployment'
  params: {
    kind: 'app,linux,container'
    name: webAppContainerName
    location: location
    tags: tags
    serverFarmResourceId: appHost.outputs.resourceId
    systemAssignedIdentity: true
    diagnosticWorkspaceId: deployLogAnalyticsWs ? laws.outputs.logAnalyticsWSID : ''
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
