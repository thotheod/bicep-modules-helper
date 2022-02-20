// that's the default, but put it here for completeness
targetScope = 'resourceGroup'

// PARAMS
param resourceTags object
param region string = resourceGroup().location
param appName string

param vnetAddressSpace string = '192.168.0.0/22'

// param snetDefault object = {
//   name: 'snet-default'
//   subnetPrefix: '192.168.0.0/24'
// }

// param snetApim object = {
//   name: 'snet-Apim'
//   subnetPrefix: '192.168.1.0/24'
// }

var subnets = [
  {
    name: 'snet1'
    addressPrefix: '192.168.0.0/24'
    privateEndpointNetworkPolicies: 'Enabled'
    needsNsg: false
    needsUDR: false

  }
  {
    name: 'snet2'
    addressPrefix: '192.168.1.0/24'
    privateEndpointNetworkPolicies: 'Enabled'
    needsNsg: true
    needsUDR: false
    // serviceEndpoints: apimSubnetServiceEndpoints   
  }      
]


var subnetNsgs = [
  null
  nsgId
]

var subnetUdrs = [
  null
  null
]


//VARS
var env = resourceTags.Environment
var vnetName = 'vnet-${appName}-${env}'
var nsgId  = nsg.id

//Create Resources

//create the Virtual Network to host all resources and its subnets
module vnet '../networking/vnet.module.bicep' = {
  name: 'vnetDeployment-${vnetName}'
  params: {
    name: vnetName
    region: region
    // nsgId: nsg.id
    // snetDefault: snetDefault
    // snetApim: snetApim
    vnetAddressSpace: vnetAddressSpace
    tags: resourceTags
    subnets: subnets
    subnetNsgs: subnetNsgs
    subnetUdrs: subnetUdrs
  }
}

resource nsg 'Microsoft.Network/networkSecurityGroups@2020-06-01' = {
  name: 'nsg1'
  location: region
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

output vnetName string = vnet.outputs.vnetName
output appName string = appName
// output aksSubnetID string = vnet.outputs.snetAksID
// output akvID string = keyVault.outputs.id
// output akvURL string = 'https://${toLower(keyVault.outputs.name)}.vault.azure.net/'//https://kv-dev-databricksexplore.vault.azure.net/
