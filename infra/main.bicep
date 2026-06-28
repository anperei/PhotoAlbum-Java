targetScope = 'resourceGroup'

@description('Environment name used for unique resource naming')
param environmentName string = 'photoalbum'

@description('Azure region for all resources (must be available for all resource types)')
param location string = 'eastus2'

@description('PostgreSQL administrator login name')
param pgAdminLogin string = 'pgadmin'

@description('PostgreSQL administrator password — must be provided at deploy time')
@secure()
param pgAdminPassword string

@description('Azure region for PostgreSQL Flexible Server (may differ from main location due to regional availability)')
param pgLocation string = 'westus3'

@description('Name of the application database to create in PostgreSQL')
param databaseName string = 'photoalbum'

@description('Application Insights connection string for telemetry export. Keep empty to skip wiring.')
param appInsightsConnectionString string = ''

// Resource token — scoped to subscription + resource group + location + environment name
var resourceToken = uniqueString(subscription().id, resourceGroup().id, location, environmentName)

// ─────────────────────────────────────────────────────────────────────────────
// User-Assigned Managed Identity
// ─────────────────────────────────────────────────────────────────────────────
module identity 'modules/identity.bicep' = {
  name: 'identity-deploy'
  params: {
    name: 'azmi${resourceToken}'
    location: location
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Log Analytics Workspace (required by Container Apps Environment)
// ─────────────────────────────────────────────────────────────────────────────
module logAnalytics 'modules/loganalytics.bicep' = {
  name: 'loganalytics-deploy'
  params: {
    name: 'azla${resourceToken}'
    location: location
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Azure Container Registry + AcrPull role assignment
// MUST be defined BEFORE any Container Apps
// ─────────────────────────────────────────────────────────────────────────────
module registry 'modules/registry.bicep' = {
  name: 'registry-deploy'
  params: {
    name: 'azacr${resourceToken}'
    location: location
    identityPrincipalId: identity.outputs.identityPrincipalId
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Container Apps Environment (connected to Log Analytics)
// ─────────────────────────────────────────────────────────────────────────────
module containerAppEnv 'modules/containerapp-env.bicep' = {
  name: 'containerappenv-deploy'
  params: {
    name: 'azae${resourceToken}'
    location: location
    logAnalyticsCustomerId: logAnalytics.outputs.customerId
    logAnalyticsPrimarySharedKey: logAnalytics.outputs.primarySharedKey
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Azure Database for PostgreSQL Flexible Server
// ─────────────────────────────────────────────────────────────────────────────
module postgresql 'modules/postgresql.bicep' = {
  name: 'postgresql-deploy'
  params: {
    // Add index suffix '1' to avoid naming conflict with previously failed deployment
    // pgLocation (westus3) used because eastus2 is restricted for this subscription
    name: 'azpg1${resourceToken}'
    location: pgLocation
    adminLogin: pgAdminLogin
    adminPassword: pgAdminPassword
    databaseName: databaseName
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Azure Container App
// Depends on registry (AcrPull role must be assigned first)
// ─────────────────────────────────────────────────────────────────────────────
module containerApp 'modules/containerapp.bicep' = {
  name: 'containerapp-deploy'
  params: {
    name: 'azca${resourceToken}'
    location: location
    containerAppEnvId: containerAppEnv.outputs.envId
    registryLoginServer: registry.outputs.loginServer
    identityId: identity.outputs.identityId
    identityClientId: identity.outputs.identityClientId
    identityName: identity.outputs.identityName
    appInsightsConnectionString: appInsightsConnectionString
  }
}
// Note: implicit dependency on registry module already exists via registryLoginServer param reference.
// The AcrPull role assignment inside registry.bicep completes as part of that module before outputs are available.

// ─────────────────────────────────────────────────────────────────────────────
// Outputs (consumed by deploy scripts and downstream tasks)
// ─────────────────────────────────────────────────────────────────────────────
output identityId string = identity.outputs.identityId
output identityClientId string = identity.outputs.identityClientId
output identityName string = identity.outputs.identityName
output registryLoginServer string = registry.outputs.loginServer
output registryName string = registry.outputs.registryName
output containerAppName string = containerApp.outputs.containerAppName
output containerAppId string = containerApp.outputs.containerAppId
output containerAppFqdn string = containerApp.outputs.containerAppFqdn
output containerAppEnvName string = containerAppEnv.outputs.envName
output containerAppEnvId string = containerAppEnv.outputs.envId
output postgresqlServerName string = postgresql.outputs.serverName
output postgresqlServerFqdn string = postgresql.outputs.serverFqdn
