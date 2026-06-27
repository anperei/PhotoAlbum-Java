<#
.SYNOPSIS
    Provisions Azure infrastructure for the PhotoAlbum application.

.DESCRIPTION
    Deploys the Bicep template to create Azure Container Apps, PostgreSQL, ACR,
    Managed Identity and supporting resources. After Bicep deployment, configures
    a Service Connector for passwordless PostgreSQL authentication via Managed Identity.

.PARAMETER ResourceGroupName
    Name of the Azure resource group to create or use.

.PARAMETER Location
    Azure region for all resources. Defaults to eastus2.

.PARAMETER EnvironmentName
    Environment name token used for resource naming. Defaults to photoalbum.

.PARAMETER PgAdminLogin
    PostgreSQL administrator login. Defaults to pgadmin.

.PARAMETER PgAdminPassword
    PostgreSQL administrator password (required, not stored in parameters file).

.PARAMETER DatabaseName
    Name of the application database. Defaults to photoalbum.

.EXAMPLE
    .\deploy.ps1 -ResourceGroupName "rg-photoalbum" -PgAdminPassword "MyS3cur3P@ss!"
#>
param(
    [string]$ResourceGroupName = "rg-photoalbum",
    [string]$Location = "eastus2",
    [string]$EnvironmentName = "photoalbum",
    [string]$PgAdminLogin = "pgadmin",
    [Parameter(Mandatory = $true)]
    [string]$PgAdminPassword,
    [string]$DatabaseName = "photoalbum"
)

$ErrorActionPreference = "Stop"
$scriptDir = $PSScriptRoot

# ─────────────────────────────────────────────────────────────────────────────
# 1. Verify Azure CLI login
# ─────────────────────────────────────────────────────────────────────────────
Write-Host "`n[1/6] Verifying Azure CLI login..." -ForegroundColor Cyan
$accountJson = az account show --output json 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Error "Not logged in to Azure. Run 'az login' first."
    exit 1
}
$account = $accountJson | ConvertFrom-Json
$subscriptionId = $account.id
Write-Host "    Subscription : $($account.name) ($subscriptionId)" -ForegroundColor Green

# ─────────────────────────────────────────────────────────────────────────────
# 2. Create Resource Group
# ─────────────────────────────────────────────────────────────────────────────
Write-Host "`n[2/6] Creating resource group '$ResourceGroupName' in '$Location'..." -ForegroundColor Cyan
az group create --name $ResourceGroupName --location $Location --output none
if ($LASTEXITCODE -ne 0) { Write-Error "Failed to create resource group."; exit 1 }
Write-Host "    Resource group ready." -ForegroundColor Green

# ─────────────────────────────────────────────────────────────────────────────
# 3. Deploy Bicep template
# ─────────────────────────────────────────────────────────────────────────────
Write-Host "`n[3/6] Deploying Bicep template (this may take 5-10 minutes)..." -ForegroundColor Cyan

$deployResult = az deployment group create `
    --resource-group $ResourceGroupName `
    --template-file "$scriptDir/main.bicep" `
    --parameters "@$scriptDir/main.parameters.json" `
    --parameters environmentName=$EnvironmentName `
                 location=$Location `
                 pgAdminLogin=$PgAdminLogin `
                 pgAdminPassword=$PgAdminPassword `
                 databaseName=$DatabaseName `
    --output json

if ($LASTEXITCODE -ne 0) {
    Write-Error "Bicep deployment failed. Review the errors above."
    exit 1
}

$deployment = $deployResult | ConvertFrom-Json
$outputs = $deployment.properties.outputs

# Extract deployment outputs
$identityId          = $outputs.identityId.value
$identityClientId    = $outputs.identityClientId.value
$identityName        = $outputs.identityName.value
$registryLoginServer = $outputs.registryLoginServer.value
$registryName        = $outputs.registryName.value
$containerAppName    = $outputs.containerAppName.value
$containerAppId      = $outputs.containerAppId.value
$containerAppFqdn    = $outputs.containerAppFqdn.value
$containerAppEnvName = $outputs.containerAppEnvName.value
$postgresqlServerName = $outputs.postgresqlServerName.value
$postgresqlServerFqdn = $outputs.postgresqlServerFqdn.value

Write-Host "    Bicep deployment succeeded." -ForegroundColor Green
Write-Host "    Container App  : $containerAppName"
Write-Host "    PostgreSQL     : $postgresqlServerName"
Write-Host "    Registry       : $registryLoginServer"

# ─────────────────────────────────────────────────────────────────────────────
# 4. Install Service Connector extension
# ─────────────────────────────────────────────────────────────────────────────
Write-Host "`n[4/6] Installing Service Connector passwordless extension..." -ForegroundColor Cyan
az extension add --name serviceconnector-passwordless --upgrade --output none 2>&1 | Out-Null
Write-Host "    Extension ready." -ForegroundColor Green

# ─────────────────────────────────────────────────────────────────────────────
# 5. Create Service Connector (Container App → PostgreSQL via Managed Identity)
# ─────────────────────────────────────────────────────────────────────────────
Write-Host "`n[5/6] Creating Service Connector for passwordless PostgreSQL access..." -ForegroundColor Cyan
Write-Host "    Container App  : $containerAppId"
Write-Host "    PostgreSQL     : $postgresqlServerName / $DatabaseName"
Write-Host "    Identity       : client-id=$identityClientId"

az containerapp connection create postgres-flexible `
    --connection "photoalbum_pg_connection" `
    --source-id $containerAppId `
    --tg $ResourceGroupName `
    --server $postgresqlServerName `
    --database $DatabaseName `
    --user-identity "client-id=$identityClientId" "subs-id=$subscriptionId" `
    --client-type springBoot `
    -c photo-album `
    -y

if ($LASTEXITCODE -ne 0) {
    Write-Error "Service Connector creation failed. Review the errors above."
    exit 1
}
Write-Host "    Service Connector created successfully." -ForegroundColor Green

# ─────────────────────────────────────────────────────────────────────────────
# 6. Generate infra-config.md
# ─────────────────────────────────────────────────────────────────────────────
Write-Host "`n[6/6] Generating infra-config.md..." -ForegroundColor Cyan

$infraConfig = @"
# Azure Resources Config

## Environment Info

| Property | Value |
|----------|-------|
| Subscription ID | ``$subscriptionId`` |
| Resource Group | ``$ResourceGroupName`` |
| Location | ``$Location`` |

## Resource List

| Resource Type | Name | Region | Config Details |
|---------------|------|---------|----------------|
| User-Assigned Managed Identity | ``$identityName`` | $Location | Client ID: ``$identityClientId`` |
| Log Analytics Workspace | ``azla$(az deployment group show --resource-group $ResourceGroupName --name loganalytics-deploy --query properties.outputs.workspaceId.value -o tsv 2>/dev/null)`` | $Location | Used by Container Apps Environment |
| Azure Container Registry | ``$registryName`` | $Location | Login server: ``$registryLoginServer`` |
| Container Apps Environment | ``$containerAppEnvName`` | $Location | Hosts the Container App |
| Azure Database for PostgreSQL | ``$postgresqlServerName`` | $Location | FQDN: ``$postgresqlServerFqdn``, Database: ``$DatabaseName`` |
| Azure Container App | ``$containerAppName`` | $Location | FQDN: ``$containerAppFqdn``, Identity: ``AZURE_CLIENT_ID`` env var |
"@

$infraConfig | Set-Content -Path "$scriptDir/infra-config.md" -Encoding UTF8
Write-Host "    infra-config.md written to $scriptDir/infra-config.md" -ForegroundColor Green

# ─────────────────────────────────────────────────────────────────────────────
# Summary
# ─────────────────────────────────────────────────────────────────────────────
Write-Host ""
Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host " Provisioning Complete!" -ForegroundColor Green
Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host " Container App URL  : https://$containerAppFqdn"
Write-Host " PostgreSQL FQDN    : $postgresqlServerFqdn"
Write-Host " Registry           : $registryLoginServer"
Write-Host " Managed Identity   : $identityName (client: $identityClientId)"
Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor Cyan
