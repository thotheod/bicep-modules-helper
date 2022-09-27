# vnet.module.bicep

## Parameters to overwrite
- There are the three defaults ``` name, location``` and ```tags```
- ```vnetAddressSpace``` is used to set the address space of the vnets. Avoided to add array of CIDRs for the sake of simplicity
- ```subnetsInfo``` is the more complex param to set. details are given in the section below

## How to call it from ___main.bicep___
You need to define a ```var``` of type ```array``` to set the properties of the subnets parameter. 
Bare minimum properties to fill  in
- name
- addressPrefix

Pay special attention to the propert ```privateEndpointNetworkPolicies```. This needs to be set to ```Enabled``` in almost all circumastances. However if this subnet is going to host _Private Endpoints_, then you need to set it to ```Disabled```. 

__Sample code below:__ 
_Define the subnet variable with all the necessary props_:
``` bicep
// set the subnets props in a variable of type Array
var subnetsInfo = [
  {
    name: 'snet1'
    addressPrefix: '192.168.0.0/24'
    privateEndpointNetworkPolicies: 'Enabled'
    nsgId: null             // or ID of the resource
    routeTableId: null             // or ID of the resource
    natGatewayId: null      // or ID of the resource    
    delegations: [
      {
        name: 'delegation'
        properties: {
          serviceName: 'Microsoft.Web/serverfarms'
        }
      }
    ]
  {
    name: 'snet2'
    addressPrefix: '192.168.1.0/24'
    privateEndpointNetworkPolicies: 'Enabled'
    nsgId: nsgId            // or ID of the resource
    routeTableId: null             // or ID of the resource
    natGatewayId: null      // or ID of the resource
    serviceEndpoints: []    // empty array if not needed
    
  }
```

_Call the module_
``` bicep
module vnet '../networking/vnet.old.bicep' = {
  name: 'vnetDeployment-${vnetName}'
  params: {
    name: vnetName
    location: location
    vnetAddressSpace: vnetAddressSpace
    tags: resourceTags
    subnetsInfo: subnetsInfo
  }
```
## Get the outputs of the vnet module

### Default outputs 
``` bicep
output vnetName string = vnet.outputs.vnetName
output vnetId string = vnet.outputs.vnetID
```
### Subnet (dynamic) outputs
To get the resource name and ids of the subnets you need to do a for-loop on the variable subnetInfo (you cannot use the vnet's subnets in the loop because is not known in the time of the deployment)
```bicep
output subnets array = [for (item, i) in subnetsInfo: {
  subnetIndex: i
  subnetName: vnet.outputs.subnetsOutput[i].name
  subnetId: vnet.outputs.subnetsOutput[i].id
}]
```

***

# 