@description('Name of the resource Virtual Network (The name must begin with a letter or number, end with a letter, number or underscore, and may contain only letters, numbers, underscores, periods, or hyphens)')
@minLength(2)
@maxLength(64)
param name string

@description('Azure Region where the resource will be deployed in')
param location string = resourceGroup().location

@description('key-value pairs as tags, to identify the resource')
param tags object

@description('CIDR to be allocated to the new vnet i.e. 192.168.1.0/24')
param vnetAddressSpace string 


param defaultSnet object
param functionsSnet object

var defaultSnetConfig = {
  name: 'snet-default'
  properties: defaultSnet
}

var functionsSnetConfig = {
  name: 'snet-functions'
  properties: functionsSnet
}


var allSubnets = [
  defaultSnetConfig
  functionsSnetConfig
]


resource vnet 'Microsoft.Network/virtualNetworks@2020-06-01' = {
  name: name
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        vnetAddressSpace
      ]
    }
    subnets: allSubnets
  }
  tags: tags
}

output vnetId string = vnet.id
output defaultSnetId string = vnet.properties.subnets[0].id
output funcSnetId string = vnet.properties.subnets[1].id
