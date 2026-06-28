# IaC Rules Compliance Report

Task: `003-infrastructure-bicep`  
Template: `infra/main.bicep`  
Deployment tool: `azcli`  

---

## Rules Applied

### General Region / SKU Rules
| Rule | Status | Evidence |
|------|--------|----------|
| Called `appmod-get-available-region-sku` before generating | ✅ Applied | Tool called; `eastus2` selected as it supports all required resource types |
| Resource region set per availability (may differ from resource group) | ✅ Applied | All resources use `location` param defaulting to `eastus2` |
| Resource names follow `az{resourcePrefix}{resourceToken}` format | ✅ Applied | `azmi`, `azla`, `azacr`, `azae`, `azpg`, `azca` prefixes used |
| Resource token scoped to `uniqueString(subscription().id, resourceGroup().id, location, environmentName)` | ✅ Applied | `var resourceToken = uniqueString(...)` in `main.bicep` |
| Alphanumeric-only names | ✅ Applied | `uniqueString` returns hex characters; all prefixes are alphanumeric |

### Deployment Tool Rules (azcli)
| Rule | Status | Evidence |
|------|--------|----------|
| `.ps1` extension for PowerShell script | ✅ Applied | `deploy.ps1` created |
| `.sh` extension for Bash script | ✅ Applied | `deploy.sh` created |
| All steps validated; script exits on any failure | ✅ Applied | `$ErrorActionPreference = "Stop"` and `set -euo pipefail`; `$LASTEXITCODE` checked after each step |

### Container App Rules
| Rule | Status | Evidence |
|------|--------|----------|
| Attach User-Assigned Managed Identity | ✅ Applied | `identity.type = 'UserAssigned'` with `userAssignedIdentities` in `containerapp.bicep` |
| AcrPull role assignment (`7f951dda-4ed3-4680-a7ca-43fe172d538d`) added for managed identity | ✅ Applied | `Microsoft.Authorization/roleAssignments` in `registry.bicep` |
| AcrPull role defined BEFORE any Container Apps | ✅ Applied | `registry` module deployed with `dependsOn: [registry]` on `containerApp` module |
| Only one AcrPull assignment per registry | ✅ Applied | Single `roleAssignments` resource in `registry.bicep` |
| Use managed identity (NOT system identity) for ACR connection | ✅ Applied | `registries[].identity = identityId` in Container App config |
| `registries` property configured in Container App | ✅ Applied | `properties.configuration.registries` set with login server + identity |
| Placeholder image `mcr.microsoft.com/azuredocs/containerapps-helloworld:latest` used | ✅ Applied | `properties.template.containers[0].image` in `containerapp.bicep` |
| Container App Environment connected to Log Analytics | ✅ Applied | `logAnalyticsConfiguration` with `customerId` + `sharedKey` in `containerapp-env.bicep` |
| CORS enabled via `corsPolicy` | ✅ Applied | `properties.configuration.ingress.corsPolicy` set in `containerapp.bicep` |
| No Key Vault (no application secrets to store — using Managed Identity for PostgreSQL) | ✅ Applied | Managed Identity passwordless auth eliminates all stored secrets |

### PostgreSQL Rules
| Rule | Status | Evidence |
|------|--------|----------|
| Version `17` or higher | ✅ Applied | `version: '17'` in `postgresql.bicep` |
| Database name is NOT `postgres` | ✅ Applied | Database named `photoalbum` (param `databaseName`) |
| Firewall rule to allow Azure Services (`0.0.0.0` → `0.0.0.0`) | ✅ Applied | `firewallRuleAzureServices` resource in `postgresql.bicep` |
| Admin username and password as Bicep parameters | ✅ Applied | `pgAdminLogin` and `@secure() pgAdminPassword` params in `main.bicep` |
| Post-provision Service Connector step for Managed Identity auth | ✅ Applied | Steps 4–5 in `deploy.ps1` and `deploy.sh` |
| Service Connector: `az extension add --name serviceconnector-passwordless` | ✅ Applied | Step 4 in both deploy scripts |
| Service Connector: `--user-identity client-id=XX subs-id=XX` | ✅ Applied | `--user-identity "client-id=$identityClientId" "subs-id=$subscriptionId"` |
| Service Connector: use `--user-identity`, NOT `--system-identity` | ✅ Applied | `--user-identity` used |
| Service Connector: `--client-type springBoot` | ✅ Applied | `--client-type springBoot` set |
| Service Connector: `-c containername` for Container App | ✅ Applied | `-c photo-album` set |
| Do NOT add `SPRING_DATASOURCE_*` env vars in Container App (let Service Connector configure) | ✅ Applied | No `SPRING_DATASOURCE_*` env vars in `containerapp.bicep` |

### Key Vault Rules
| Rule | Status | Evidence |
|------|--------|----------|
| Use Key Vault only when application has secrets to store | ✅ Applied (N/A) | Application uses Managed Identity for PostgreSQL — no secrets to store; Key Vault omitted |
