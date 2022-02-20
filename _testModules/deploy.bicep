// that's the default, but put it here for completeness
targetScope = 'resourceGroup'

// PARAMS
param resourceTags object
param location string = resourceGroup().location
param appName string

param vnetAddressSpace string = '192.168.0.0/22'

var subnetsInfo = [
  {
    name: 'snet1'
    addressPrefix: '192.168.0.0/24'
    privateEndpointNetworkPolicies: 'Enabled' //any value will be translated to Enabled
    nsgId: null         // or ID of the resource
    routeTableId: null  // or ID of the resource
    natGatewayId: null  // or ID of the resource
    serviceEndpoints: [
      {
        service: 'Microsoft.Storage'
      }
      {
        service: 'Microsoft.Sql'
      }
    ]    
  }
  {
    name: 'snet2'
    addressPrefix: '192.168.1.0/24'
    privateEndpointNetworkPolicies: 'Disabled'
    nsgId: nsgId        // or ID of the resource
    routeTableId: null  // or ID of the resource
    natGatewayId: null  // or ID of the resource
    serviceEndpoints: []    
  }
]

//VARS
var env = resourceTags.Environment
var vnetName = 'vnet-${appName}-${env}'
var nsgId = nsg.id

//Create Resources

//create the Virtual Network to host all resources and its subnets
module vnet '../networking/vnet.module.bicep' = {
  name: 'vnetDeployment-${vnetName}'
  params: {
    name: vnetName
    location: location
    vnetAddressSpace: vnetAddressSpace
    tags: resourceTags
    subnetsInfo: subnetsInfo
  }
}

resource nsg 'Microsoft.Network/networkSecurityGroups@2020-06-01' = {
  name: 'nsg1'
  location: location
  tags: resourceTags
  properties: {
    securityRules: [
      {
        name: 'Client_communication_to_API_Management'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '80'
          sourceAddressPrefix: 'Internet'
          destinationAddressPrefix: 'VirtualNetwork'
          access: 'Allow'
          priority: 100
          direction: 'Inbound'
        }
      }
    ]
  }
}

output appName string = appName
output vnetName string = vnet.outputs.vnetName
output vnetId string = vnet.outputs.vnetID
output subnets array = [for (item, i) in subnetsInfo: {
  subnetIndex: i
  subnetName: vnet.outputs.subnetsOutput[i].name
  subnetId: vnet.outputs.subnetsOutput[i].id
}]
