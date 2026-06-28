@description('Name of the Container Apps Environment')
param name string

@description('Azure region for the resource')
param location string

@description('Log Analytics Workspace Customer ID')
param logAnalyticsCustomerId string

@description('Log Analytics Workspace Primary Shared Key')
@secure()
param logAnalyticsPrimarySharedKey string

resource containerAppEnv 'Microsoft.App/managedEnvironments@2023-05-01' = {
  name: name
  location: location
  properties: {
    appLogsConfiguration: {
      destination: 'log-analytics'
      logAnalyticsConfiguration: {
        customerId: logAnalyticsCustomerId
        sharedKey: logAnalyticsPrimarySharedKey
      }
    }
  }
}

@description('Resource ID of the Container Apps Environment')
output envId string = containerAppEnv.id

@description('Name of the Container Apps Environment')
output envName string = containerAppEnv.name
