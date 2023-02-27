@description('Location for all Resources.')
param location string

@description('a unique ID that can be appended (or prepended) in azure resource names that require some kind of uniqueness')
param uniqueId string


var naming = json(loadTextContent('./naming-rules.jsonc'))

// get arbitary 5 first characters (instead of something like 5yj4yjf5mbg72), to save string length. This may cause non uniqueness
var uniqueIdShort = substring(uniqueId, 0, 5)
var resourceTypeToken = 'RES_TYPE'

// Define and adhere to a naming convention, such as: https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/ready/azure-best-practices/resource-naming
var namingBase = '${resourceTypeToken}-${naming.workloadName}-${naming.environment}-${naming.regionAbbreviations[toLower(location)]}'
var namingBaseUnique = '${resourceTypeToken}-${uniqueIdShort}-${naming.workloadName}-${naming.environment}-${naming.regionAbbreviations[toLower(location)]}'

var resourceNames = {
  rgSpoke: replace(namingBase, resourceTypeToken, '${naming.resourceTypeAbbreviations.resourceGroup}-spoke')
  vnetSpoke: '${replace(namingBase, resourceTypeToken, naming.resourceTypeAbbreviations.virtualNetwork)}-spoke'
  vnetHub: '${replace(namingBase, resourceTypeToken, naming.resourceTypeAbbreviations.virtualNetwork)}-hub'
  // Storage account names (and other resources) have strict naming rules. You may ignore here, but sanitize as much as possible in the resource module
  //storageAppOne: replace(namingBaseUnique, resourceTypeToken, naming.resourceTypeAbbreviations.storageAccount)
  //or without if you decide not to have module naming sanitization, you can add some basic rules here:....
  storageAppOne: take ( toLower( replace ( replace(namingBaseUnique, resourceTypeToken, naming.resourceTypeAbbreviations.storageAccount), '-', '' ) ), 24 )
}

output resourcesNames object = resourceNames
