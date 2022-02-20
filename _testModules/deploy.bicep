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
    nsgId: null
    udrId: null

  }
  {
    name: 'snet2'
    addressPrefix: '192.168.1.0/24'
    privateEndpointNetworkPolicies: 'Enabled'
    nsgId: nsgId
    udrId: null
    // serviceEndpoints: apimSubnetServiceEndpoints   
  }      
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
    vnetAddressSpace: vnetAddressSpace
    tags: resourceTags
    subnets: subnets    
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
output vnetId string = vnet.outputs.vnetID
output subnets array = [ for (item, i) in subnets: {
  subnetIndex: i
  subnetName: vnet.outputs.subnetsOutput[i].name
  subnetId: vnet.outputs.subnetsOutput[i].id
}]

output appName string = appName
