@description('Name of the Log Analytics Workspace')
param name string

@description('Azure region for the resource')
param location string

resource logAnalytics 'Microsoft.OperationalInsights/workspaces@2022-10-01' = {
  name: name
  location: location
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: 30
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'
  }
}

@description('Resource ID of the Log Analytics Workspace')
output workspaceId string = logAnalytics.id

@description('Customer ID of the Log Analytics Workspace')
output customerId string = logAnalytics.properties.customerId

@description('Primary shared key of the Log Analytics Workspace')
@secure()
output primarySharedKey string = logAnalytics.listKeys().primarySharedKey
