# Azure Resources Config

## Environment Info

| Property | Value |
|----------|-------|
| Subscription ID | `2f65b79d-3590-4a33-ad16-dce4aa3ad142` |
| Resource Group | `rg-photoalbum` |
| Location | `eastus2` |

## Resource List

| Resource Type | Name | Region | Config Details |
|---------------|------|---------|----------------|
| User-Assigned Managed Identity | `azmi5ly5sxmc37fqi` | eastus2 | Client ID: `0ba018a1-bec9-4464-a0ec-3c28239d42ff` |
| Log Analytics Workspace | `azla5ly5sxmc37fqi` | eastus2 | Used by Container Apps Environment |
| Azure Container Registry | `azacr5ly5sxmc37fqi` | eastus2 | Login server: `azacr5ly5sxmc37fqi.azurecr.io` |
| Container Apps Environment | `azae5ly5sxmc37fqi` | eastus2 | Hosts the Container App |
| Azure Database for PostgreSQL | `azpg15ly5sxmc37fqi` | westus3 | FQDN: `azpg15ly5sxmc37fqi.postgres.database.azure.com`, Database: `photoalbum` |
| Azure Container App | `azca5ly5sxmc37fqi` | eastus2 | FQDN: `azca5ly5sxmc37fqi.nicecoast-c5a6b225.eastus2.azurecontainerapps.io`, Identity: `AZURE_CLIENT_ID` env var |
