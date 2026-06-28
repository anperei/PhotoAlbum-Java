# PhotoAlbum — Azure Infrastructure

This folder contains Bicep IaC templates and deployment scripts to provision the Azure infrastructure required by the PhotoAlbum Spring Boot application.

---

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                   Azure Resource Group                      │
│                                                             │
│  ┌─────────────────────┐     ┌─────────────────────────┐   │
│  │  Azure Container    │────▶│  Azure Database for     │   │
│  │  Apps (photo-album) │     │  PostgreSQL Flex v17    │   │
│  │                     │     │  (photoalbum db)        │   │
│  │  User-Assigned MI ──┼─────┤  AAD + Password Auth    │   │
│  └──────────┬──────────┘     └─────────────────────────┘   │
│             │                                               │
│             │ AcrPull role                                  │
│             ▼                                               │
│  ┌─────────────────────┐     ┌─────────────────────────┐   │
│  │  Azure Container    │     │  Container Apps         │   │
│  │  Registry (Basic)   │     │  Environment            │   │
│  └─────────────────────┘     │  (Log Analytics linked) │   │
│                               └─────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
```

---

## Resources Provisioned

| Resource | Name Pattern | Notes |
|---|---|---|
| User-Assigned Managed Identity | `azmi{token}` | Used by Container App to access ACR & PostgreSQL |
| Log Analytics Workspace | `azla{token}` | Linked to Container Apps Environment |
| Azure Container Registry | `azacr{token}` | Basic SKU; stores application image |
| Container Apps Environment | `azae{token}` | Linked to Log Analytics |
| PostgreSQL Flexible Server | `azpg{token}` | v17, Burstable B1ms, AAD+password auth |
| Azure Container App | `azca{token}` | 0.5 CPU / 1Gi; CORS enabled; placeholder image at provision |

> Resource names include a unique suffix from `uniqueString(subscriptionId, resourceGroupId, location, environmentName)` for global uniqueness.

---

## Prerequisites

- [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli) installed and logged in (`az login`)
- Contributor access on the target Azure subscription
- (Optional) [Bicep CLI](https://docs.microsoft.com/en-us/azure/azure-resource-manager/bicep/install) for local validation

---

## Deployment

### Windows (PowerShell)

```powershell
cd infra
.\deploy.ps1 -ResourceGroupName "rg-photoalbum" -PgAdminPassword "YourSecurePassword!"
```

All parameters with defaults:
```powershell
.\deploy.ps1 `
    -ResourceGroupName "rg-photoalbum" `
    -Location "eastus2" `
    -EnvironmentName "photoalbum" `
    -PgAdminLogin "pgadmin" `
    -PgAdminPassword "YourSecurePassword!" `
    -DatabaseName "photoalbum"
```

### Linux / macOS (Bash)

```bash
cd infra
chmod +x deploy.sh
./deploy.sh --resource-group rg-photoalbum --pg-admin-password "YourSecurePassword!"
```

---

## Parameters

| Parameter | Default | Description |
|---|---|---|
| `environmentName` | `photoalbum` | Token used in resource naming |
| `location` | `eastus2` | Azure region for all resources |
| `pgAdminLogin` | `pgadmin` | PostgreSQL admin username |
| `pgAdminPassword` | *(required)* | PostgreSQL admin password (never stored in files) |
| `databaseName` | `photoalbum` | PostgreSQL database name for the application |

---

## What the Deploy Script Does

1. **Verifies** Azure CLI is authenticated
2. **Creates** the resource group (idempotent)
3. **Deploys** the Bicep template via `az deployment group create`
4. **Installs** the `serviceconnector-passwordless` CLI extension
5. **Creates** a Service Connector linking the Container App to PostgreSQL using the User-Assigned Managed Identity (`--client-type springBoot`)
6. **Generates** `infra-config.md` with actual provisioned resource details for downstream tasks

---

## Post-Provision: Service Connector

The deploy script automatically runs:
```bash
az containerapp connection create postgres-flexible \
  --connection photoalbum-pg-connection \
  --source-id <containerAppId> \
  --tg <resourceGroup> \
  --server <postgresqlServerName> \
  --database photoalbum \
  --user-identity client-id=<clientId> subs-id=<subscriptionId> \
  --client-type springBoot \
  -c photo-album \
  -y
```

This:
- Creates a PostgreSQL AAD user mapped to the managed identity
- Grants the managed identity `azure_pg_owner` role on the database  
- Injects connection environment variables into the Container App

---

## Validate Bicep Templates

```bash
az bicep build --file infra/main.bicep
```

---

## File Structure

```
infra/
├── main.bicep              # Orchestrates all modules
├── main.parameters.json    # Non-sensitive deployment parameters
├── modules/
│   ├── identity.bicep      # User-Assigned Managed Identity
│   ├── loganalytics.bicep  # Log Analytics Workspace
│   ├── registry.bicep      # ACR + AcrPull role assignment
│   ├── containerapp-env.bicep  # Container Apps Environment
│   ├── postgresql.bicep    # PostgreSQL Flexible Server + database + firewall
│   └── containerapp.bicep  # Azure Container App
├── deploy.ps1              # Windows deployment script
├── deploy.sh               # Linux/macOS deployment script
├── infra-config.md         # Generated after provisioning (actual resource info)
├── README.md               # This file
└── compliance.md           # IaC rules compliance report
```
