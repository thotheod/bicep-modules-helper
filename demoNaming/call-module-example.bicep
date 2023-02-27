param tags object
param location string 
param resourceNames object


// you can get the shared resourceNames as param input, or you could instantiate them in the module once again, as below (possibly for setting another location here.)
// module sharedInMpduleExample '../shared/NamingPrefix.example.bicep' = {
//   name: 'sharedNamingDeployment'
//   params: {
//     uniqueId: uniqueString(resourceGroup().id)
//     location: location
//   }
// }

module stg '../modules/storage/storage.bicep' = {
  name: 'stg-deplyment'
  params: {
    name: resourceNames.storageAppOne
    tags: tags
    location: location
  }
}
