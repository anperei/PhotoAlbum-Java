@description('Name of the Azure Container Registry')
param name string

@description('Azure region for the resource')
param location string

@description('Principal ID of the managed identity to assign AcrPull role')
param identityPrincipalId string

// AcrPull role definition ID
var acrPullRoleDefinitionId = '7f951dda-4ed3-4680-a7ca-43fe172d538d'

resource registry 'Microsoft.ContainerRegistry/registries@2023-07-01' = {
  name: name
  location: location
  sku: {
    name: 'Basic'
  }
  properties: {
    adminUserEnabled: false
    publicNetworkAccess: 'Enabled'
    zoneRedundancy: 'Disabled'
  }
}

// MANDATORY: AcrPull role assignment for the user-assigned managed identity
// Defined BEFORE any container apps, as required by rules
resource acrPullRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(registry.id, identityPrincipalId, acrPullRoleDefinitionId)
  scope: registry
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', acrPullRoleDefinitionId)
    principalId: identityPrincipalId
    principalType: 'ServicePrincipal'
  }
}

@description('Resource ID of the Container Registry')
output registryId string = registry.id

@description('Login server URL of the Container Registry')
output loginServer string = registry.properties.loginServer

@description('Name of the Container Registry')
output registryName string = registry.name
