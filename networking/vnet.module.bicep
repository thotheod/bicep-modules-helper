@description('name of the resource (vnet)')
param name string

@description('Azure Region where the resource will be deployed in')
param region string

@description('key-value pairs as tags, to identify the resource')
param tags object

@description('CIDR to be allocated to the new vnet')
param vnetAddressSpace string 


param subnets array



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


var subnetsToCreate = [for item in subnets: {
  name: item.name
  properties: {
    addressPrefix: item.addressPrefix
    networkSecurityGroup: item.nsgId != null ? {
       id: item.nsgId
    } : null
    routeTable: item.udrId != null ? {
      id: item.udrId
    } : null
  }
}]

resource vnet 'Microsoft.Network/virtualNetworks@2021-05-01' = {
  name: name
  location: region
  tags: tags
  properties: {
    // enableDdosProtection: enableDdosProtection    
    addressSpace: {
      addressPrefixes: [
        vnetAddressSpace
      ]
    }    
    subnets: subnetsToCreate 
  }  
}



output vnetID string = vnet.id
output vnetName string = vnet.name

// INFO: based on second example of https://docs.microsoft.com/en-us/azure/azure-resource-manager/bicep/loops#array-and-index
output subnetsOutput array = [ for (item, i) in subnets: {
  subnetIndex: i
  name: vnet.properties.subnets[i].name
  id: vnet.properties.subnets[i].id
}]
