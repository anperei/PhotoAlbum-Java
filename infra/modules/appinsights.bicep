@description('Name of the Application Insights resource')
param name string

@description('Azure region for the resource')
param location string

@description('Resource ID of the Log Analytics Workspace for workspace-based App Insights')
param logAnalyticsWorkspaceResourceId string

resource appInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: name
  location: location
  kind: 'web'
  properties: {
    Application_Type: 'web'
    WorkspaceResourceId: logAnalyticsWorkspaceResourceId
    IngestionMode: 'LogAnalytics'
    DisableIpMasking: false
  }
}

@description('Resource ID of Application Insights')
output appInsightsId string = appInsights.id

@description('Name of Application Insights')
output appInsightsName string = appInsights.name

@description('Connection string for Application Insights')
@secure()
output connectionString string = appInsights.properties.ConnectionString
