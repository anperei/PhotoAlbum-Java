targetScope = 'resourceGroup'

@description('Environment name used for unique resource naming')
param environmentName string = 'photoalbum'

@description('Azure region for monitoring resources')
param location string = 'eastus2'

@description('Existing Log Analytics workspace resource ID used by the app environment')
param logAnalyticsWorkspaceResourceId string

var resourceToken = uniqueString(subscription().id, resourceGroup().id, location, environmentName)

module appInsights 'modules/appinsights.bicep' = {
  name: 'appinsights-deploy'
  params: {
    name: 'azappi${resourceToken}'
    location: location
    logAnalyticsWorkspaceResourceId: logAnalyticsWorkspaceResourceId
  }
}

output appInsightsId string = appInsights.outputs.appInsightsId
output appInsightsName string = appInsights.outputs.appInsightsName
@secure()
output appInsightsConnectionString string = appInsights.outputs.connectionString
