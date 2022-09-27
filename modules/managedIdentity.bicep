@description('Required. The name of the user assigned managed Identity. 3-128, can contain "-" and "_"')
@minLength(3)
@maxLength(128)
param name string

@description('Optional. Location for all resources.')
param location string = resourceGroup().location

@description('Optional. Tags of the resource.')
param tags object = {}

resource amsMsi 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' = {
  name: name    //3-128, can contain '-' and '_'.
  location: location
  tags: tags
}

@description('The name of the managedIDentity.')
output name string = amsMsi.name

@description('The id of the managedIDentity.')
output id string = amsMsi.id

@description('The type of the managedIDentity.')
output type string = amsMsi.type

@description('The ServicePrincipalId of the managedIDentity.')
output principalId string = amsMsi.properties.principalId

@description('The TenantId of the managedIDentity.')
output tenantId string = amsMsi.properties.tenantId

@description('The clientId of the managedIDentity.')
output clientId string = amsMsi.properties.clientId
