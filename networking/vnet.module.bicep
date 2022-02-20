@description('name of the resource (vnet)')
param name string

@description('Azure Region where the resource will be deployed in')
param region string

@description('key-value pairs as tags, to identify the resource')
param tags object

@description('CIDR to be allocated to the new vnet')
param vnetAddressSpace string 
// param enableVmProtection bool = false
// param enableDdosProtection bool = false
// param snetApim object
// param snetDefault object
// param nsgId string
param subnets array
param subnetNsgs array
param subnetUdrs array



// @description('Service Endpoints enabled on the APIM subnet')
// param apimSubnetServiceEndpoints array = [
//   {
//     service: 'Microsoft.Storage'
//   }
//   {
//     service: 'Microsoft.Sql'
//   }
//   {
//     service: 'Microsoft.EventHub'
//   }
// ]


var subnetsToCreate = [for (item, i) in subnets: {
  name: item.name
  properties: {
    addressPrefix: item.addressPrefix
    networkSecurityGroup: item.needsNsg ? {
       id: subnetNsgs[i]
    } : null//json('null')
    routeTable: item.needsUDR ? {
      id: subnetUdrs[i]
    } : null//json('null')
  }
}]

resource vnet 'Microsoft.Network/virtualNetworks@2021-05-01' = {
  name: name
  location: region
  tags: tags
  properties: {
    // enableVmProtection: enableVmProtection
    // enableDdosProtection: enableDdosProtection
    
    addressSpace: {
      addressPrefixes: [
        vnetAddressSpace
      ]
    }    
    subnets: subnetsToCreate  
    // subnets:[
    //   {
    //     name: snetDefault.name
    //     properties: {
    //       addressPrefix: snetDefault.subnetPrefix
    //       privateEndpointNetworkPolicies: 'Enabled'
    //     }
    //   }
    //   {
    //     name: snetApim.name
    //     properties: {
    //       addressPrefix: snetApim.subnetPrefix
    //       privateEndpointNetworkPolicies: 'Enabled'
    //       networkSecurityGroup: {
    //         id: nsgId
    //       }
    //       routeTable: {
    //         id: udrId
    //       }
    //       serviceEndpoints: apimSubnetServiceEndpoints
    //     }
    //   }      
    // ]
  }  
}


output vnetID string = vnet.id
output vnetName string = vnet.name
// output snetDefaultID string = vnet.properties.subnets[0].id
// output snetApimID string = vnet.properties.subnets[1].id
