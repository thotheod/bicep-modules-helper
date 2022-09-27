// @description('Optional, The description of the role assignment.')
// param roleDescription string = ''

// @description('The GUID of the RoleDefinition you wish to assign. Can be found by running: az role definition list --output json')
// param roleDefinitionId string 

// @description('The principalId to whom we need to assign the role.')
// param principalId string

// @allowed([
//   'ServicePrincipal'
//   'Device'
//   'ForeignGroup'
//   'Group'
//   'User'
// ])
// @description('Optional, default ServicePrinciple')
// param principalType string = 'ServicePrincipal'


// resource 'Microsoft.Authorization/roleAssignments@2020-10-01-preview' = {
//   name: guid(resourceGroup().id, principalId, roleDescription)
//   properties: {
//     description: roleDescription
//     roleDefinitionId: roleDefinitionId
//     principalId: principalId
//     principalType: principalType 
//   }
//   scope: res
// }
