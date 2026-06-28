@description('Name of the User-Assigned Managed Identity')
param name string

@description('Azure region for the resource')
param location string

resource identity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: name
  location: location
}

@description('Resource ID of the managed identity')
output identityId string = identity.id

@description('Client ID of the managed identity')
output identityClientId string = identity.properties.clientId

@description('Principal ID of the managed identity')
output identityPrincipalId string = identity.properties.principalId

@description('Name of the managed identity')
output identityName string = identity.name
