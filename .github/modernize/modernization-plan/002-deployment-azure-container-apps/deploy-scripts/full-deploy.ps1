<#
.SYNOPSIS
    Full deploy script: provision Azure infrastructure, build & push Docker image, update Container App.

.DESCRIPTION
    1. Verify AZ CLI and login
    2. Prompt user to select subscription
    3. Provision resources via Bicep (infra/deploy.ps1)
    4. Build and push image to ACR via az acr build
    5. Update Container App to use the new image
    6. Verify deployment

.PARAMETER ResourceGroupName
    Target resource group name. Defaults to rg-photoalbum.

.PARAMETER PgAdminPassword
    PostgreSQL admin password (required).
#>
param(
    [string]$ResourceGroupName = "rg-photoalbum",
    [Parameter(Mandatory = $true)]
    [string]$PgAdminPassword
)

$ErrorActionPreference = "Stop"
$repoRoot = Resolve-Path "$PSScriptRoot\..\..\..\..\..\"

# ─────────────────────────────────────────────────────────────────────────────
# Step 1: AZ CLI check + login
# ─────────────────────────────────────────────────────────────────────────────
Write-Host "`n[1/5] Verifying Azure CLI..." -ForegroundColor Cyan
$azVer = az version --output json 2>&1
if ($LASTEXITCODE -ne 0) { Write-Error "Azure CLI not found. Install from https://aka.ms/installazurecli"; exit 1 }
Write-Host "    AZ CLI ready." -ForegroundColor Green

# ─────────────────────────────────────────────────────────────────────────────
# Step 2: Provision infrastructure
# ─────────────────────────────────────────────────────────────────────────────
Write-Host "`n[2/5] Provisioning Azure infrastructure..." -ForegroundColor Cyan
& "$repoRoot\infra\deploy.ps1" -ResourceGroupName $ResourceGroupName -PgAdminPassword $PgAdminPassword
if ($LASTEXITCODE -ne 0) { Write-Error "Provisioning failed."; exit 1 }

# ─────────────────────────────────────────────────────────────────────────────
# Step 3: Read provisioning outputs from infra-config.md / az deployment
# ─────────────────────────────────────────────────────────────────────────────
Write-Host "`n[3/5] Reading deployment outputs..." -ForegroundColor Cyan
$deployJson = az deployment group show `
    --resource-group $ResourceGroupName `
    --name "main" `
    --output json | ConvertFrom-Json

$outputs = $deployJson.properties.outputs
$registryLoginServer = $outputs.registryLoginServer.value
$registryName        = $outputs.registryName.value
$containerAppName    = $outputs.containerAppName.value

Write-Host "    ACR             : $registryLoginServer"
Write-Host "    Container App   : $containerAppName"

# ─────────────────────────────────────────────────────────────────────────────
# Step 4: Build & push via ACR remote build
# ─────────────────────────────────────────────────────────────────────────────
Write-Host "`n[4/5] Building image via ACR remote build..." -ForegroundColor Cyan
$imageTag = "$registryLoginServer/photo-album:latest"

az acr build `
    --registry $registryName `
    --resource-group $ResourceGroupName `
    --image "photo-album:latest" `
    --file "$repoRoot\Dockerfile" `
    "$repoRoot"

if ($LASTEXITCODE -ne 0) { Write-Error "ACR build failed."; exit 1 }
Write-Host "    Image pushed: $imageTag" -ForegroundColor Green

# ─────────────────────────────────────────────────────────────────────────────
# Step 5: Update Container App with new image
# ─────────────────────────────────────────────────────────────────────────────
Write-Host "`n[5/5] Updating Container App image..." -ForegroundColor Cyan
az containerapp update `
    --name $containerAppName `
    --resource-group $ResourceGroupName `
    --image $imageTag

if ($LASTEXITCODE -ne 0) { Write-Error "Container App update failed."; exit 1 }
Write-Host "    Container App updated to $imageTag" -ForegroundColor Green

Write-Host "`n✅ Deployment complete!" -ForegroundColor Green
