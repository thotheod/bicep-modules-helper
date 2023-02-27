param resourceTags object = {}
param location string = resourceGroup().location
param vnetAddressSpace string = '192.168.0.0/22'


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

module shared '../shared/naming.module.bicep' = {
  name: 'sharedNamingDeployment'
  params: {
    uniqueId: uniqueString(resourceGroup().id)
    location: location
  }
}

module vnet '../modules/networking/vnet.bicep' = {
  name: 'vnetSpoke-Deployment'
  params: {
    name: shared.outputs.resourcesNames.vnetSpoke
    location: location
    vnetAddressSpace: vnetAddressSpace
    tags: resourceTags
    subnetsInfo: subnetsInfo
  }
}

module storageModule 'call-module-example.bicep' = {
  name: 'storageModuleDeployment'
  params: {
    location: location
    tags: resourceTags
    // you can pass the shared resourceNames as param to the called module
    resourceNames: shared.outputs.resourcesNames
  }
}
