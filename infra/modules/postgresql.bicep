@description('Name of the PostgreSQL Flexible Server')
param name string

@description('Azure region for the resource')
param location string

@description('PostgreSQL administrator login name')
param adminLogin string

@description('PostgreSQL administrator password')
@secure()
param adminPassword string

@description('Name of the application database to create')
param databaseName string

resource postgresql 'Microsoft.DBforPostgreSQL/flexibleServers@2023-06-01-preview' = {
  name: name
  location: location
  sku: {
    name: 'Standard_B1ms'
    tier: 'Burstable'
  }
  properties: {
    administratorLogin: adminLogin
    administratorLoginPassword: adminPassword
    // PostgreSQL version 17 or higher as required
    version: '17'
    authConfig: {
      activeDirectoryAuth: 'Enabled'
      passwordAuth: 'Enabled'
      tenantId: tenant().tenantId
    }
    storage: {
      storageSizeGB: 32
      autoGrow: 'Enabled'
    }
    backup: {
      backupRetentionDays: 7
      geoRedundantBackup: 'Disabled'
    }
    highAvailability: {
      mode: 'Disabled'
    }
    network: {
      publicNetworkAccess: 'Enabled'
    }
  }
}

// Firewall rule: allow traffic from Azure Services (required rule)
resource firewallRuleAzureServices 'Microsoft.DBforPostgreSQL/flexibleServers/firewallRules@2023-06-01-preview' = {
  parent: postgresql
  name: 'AllowAllAzureServices'
  properties: {
    startIpAddress: '0.0.0.0'
    endIpAddress: '0.0.0.0'
  }
}

// Application database — do NOT name it 'postgres' (built-in)
resource database 'Microsoft.DBforPostgreSQL/flexibleServers/databases@2023-06-01-preview' = {
  parent: postgresql
  name: databaseName
  properties: {
    charset: 'UTF8'
    collation: 'en_US.utf8'
  }
}

@description('Resource ID of the PostgreSQL Flexible Server')
output serverId string = postgresql.id

@description('Name of the PostgreSQL Flexible Server')
output serverName string = postgresql.name

@description('Fully qualified domain name of the PostgreSQL server')
output serverFqdn string = postgresql.properties.fullyQualifiedDomainName
