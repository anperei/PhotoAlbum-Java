@description('Name of the Container App')
param name string

@description('Azure region for the resource')
param location string

@description('Resource ID of the Container Apps Environment')
param containerAppEnvId string

@description('Login server of the Azure Container Registry')
param registryLoginServer string

@description('Resource ID of the User-Assigned Managed Identity')
param identityId string

@description('Client ID of the User-Assigned Managed Identity')
param identityClientId string

@description('Name of the User-Assigned Managed Identity (used as PostgreSQL username)')
param identityName string

@description('Application Insights connection string. Leave empty to disable telemetry export wiring.')
param appInsightsConnectionString string = ''

resource containerApp 'Microsoft.App/containerApps@2023-05-01' = {
  name: name
  location: location
  // Attach User-Assigned Managed Identity (MANDATORY)
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${identityId}': {}
    }
  }
  properties: {
    managedEnvironmentId: containerAppEnvId
    configuration: {
      ingress: {
        external: true
        targetPort: 8080
        transport: 'auto'
        // CORS enabled as required
        corsPolicy: {
          allowedOrigins: ['*']
          allowedMethods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS', 'PATCH']
          allowedHeaders: ['*']
          allowCredentials: false
        }
      }
      // Registry connection using managed identity (NOT system identity)
      registries: [
        {
          server: registryLoginServer
          identity: identityId
        }
      ]
    }
    template: {
      containers: [
        {
          name: 'photo-album'
          // MANDATORY: Use base placeholder image at provisioning time
          image: 'mcr.microsoft.com/azuredocs/containerapps-helloworld:latest'
          resources: {
            cpu: json('0.5')
            memory: '1Gi'
          }
          env: concat([
            {
              name: 'SPRING_PROFILES_ACTIVE'
              value: 'docker'
            }
            {
              name: 'AZURE_CLIENT_ID'
              value: identityClientId
            }
            {
              name: 'MANAGED_IDENTITY_NAME'
              value: identityName
            }
            {
              name: 'SPRING_CLOUD_AZURE_CREDENTIAL_MANAGED_IDENTITY_ENABLED'
              value: 'true'
            }
            {
              name: 'SPRING_CLOUD_AZURE_CREDENTIAL_CLIENT_ID'
              value: identityClientId
            }
            // Externalized server port — resolves hardcoded port assessment finding
            {
              name: 'SERVER_PORT'
              value: '8080'
            }
          ], empty(appInsightsConnectionString)
            ? []
            : [
                {
                  name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
                  value: appInsightsConnectionString
                }
              ])
        }
      ]
      scale: {
        minReplicas: 1
        maxReplicas: 3
      }
    }
  }
}

@description('Resource ID of the Container App')
output containerAppId string = containerApp.id

@description('Name of the Container App')
output containerAppName string = containerApp.name

@description('Fully qualified domain name of the Container App')
output containerAppFqdn string = containerApp.properties.configuration.ingress.fqdn
