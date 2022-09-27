@description('Name of the resource Virtual Network (The name must begin with a letter or number, end with a letter, number or underscore, and may contain only letters, numbers, underscores, periods, or hyphens)')
@minLength(2)
@maxLength(64)
param name string

@description('Azure Region where the resource will be deployed in')
param location string = resourceGroup().location

@description('key-value pairs as tags, to identify the resource')
param tags object

@description('CIDR to be allocated to the new vnet i.e. 192.168.0.0/24')
param vnetAddressSpace string

param subnetsInfo array

resource vnet 'Microsoft.Network/virtualNetworks@2020-06-01' = {
  name: name
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        vnetAddressSpace
      ]
    }
    subnets: subnetsInfo
  }
  tags: tags
}

output vnetId string = vnet.id
output vnetName string = vnet.name

// INFO: based on second example of https://docs.microsoft.com/en-us/azure/azure-resource-manager/bicep/loops#array-and-index
output subnetsOutput array = [ for (item, i) in subnetsInfo: {
  subnetIndex: i
  id: vnet.properties.subnets[i].id
  name: vnet.properties.subnets[i].name  
}]
