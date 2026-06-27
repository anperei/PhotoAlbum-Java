#!/usr/bin/env bash
# deploy.sh — Provisions Azure infrastructure for the PhotoAlbum application.
#
# Usage:
#   ./deploy.sh [OPTIONS]
#
# Options:
#   --resource-group    Azure resource group name (default: rg-photoalbum)
#   --location          Azure region (default: eastus2)
#   --environment-name  Environment name token for resource naming (default: photoalbum)
#   --pg-admin-login    PostgreSQL admin login (default: pgadmin)
#   --pg-admin-password PostgreSQL admin password (required)
#   --database-name     PostgreSQL database name (default: photoalbum)
#
# Example:
#   ./deploy.sh --resource-group rg-photoalbum --pg-admin-password "MyS3cur3P@ss!"

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ── Defaults ──────────────────────────────────────────────────────────────────
RESOURCE_GROUP="rg-photoalbum"
LOCATION="eastus2"
ENVIRONMENT_NAME="photoalbum"
PG_ADMIN_LOGIN="pgadmin"
PG_ADMIN_PASSWORD=""
DATABASE_NAME="photoalbum"

# ── Parse arguments ───────────────────────────────────────────────────────────
while [[ $# -gt 0 ]]; do
    case "$1" in
        --resource-group)    RESOURCE_GROUP="$2";    shift 2 ;;
        --location)          LOCATION="$2";          shift 2 ;;
        --environment-name)  ENVIRONMENT_NAME="$2";  shift 2 ;;
        --pg-admin-login)    PG_ADMIN_LOGIN="$2";    shift 2 ;;
        --pg-admin-password) PG_ADMIN_PASSWORD="$2"; shift 2 ;;
        --database-name)     DATABASE_NAME="$2";     shift 2 ;;
        *) echo "Unknown option: $1"; exit 1 ;;
    esac
done

if [[ -z "$PG_ADMIN_PASSWORD" ]]; then
    echo "Error: --pg-admin-password is required."
    exit 1
fi

# ── Colours ───────────────────────────────────────────────────────────────────
CYAN='\033[0;36m'; GREEN='\033[0;32m'; RED='\033[0;31m'; NC='\033[0m'
step() { echo -e "\n${CYAN}[$1/6] $2${NC}"; }
ok()   { echo -e "    ${GREEN}$1${NC}"; }
err()  { echo -e "${RED}Error: $1${NC}" >&2; exit 1; }

# ─────────────────────────────────────────────────────────────────────────────
# 1. Verify Azure CLI login
# ─────────────────────────────────────────────────────────────────────────────
step 1 "Verifying Azure CLI login..."
ACCOUNT_JSON=$(az account show --output json 2>&1) || err "Not logged in to Azure. Run 'az login' first."
SUBSCRIPTION_ID=$(echo "$ACCOUNT_JSON" | python3 -c "import sys,json; print(json.load(sys.stdin)['id'])")
SUBSCRIPTION_NAME=$(echo "$ACCOUNT_JSON" | python3 -c "import sys,json; print(json.load(sys.stdin)['name'])")
ok "Subscription: $SUBSCRIPTION_NAME ($SUBSCRIPTION_ID)"

# ─────────────────────────────────────────────────────────────────────────────
# 2. Create Resource Group
# ─────────────────────────────────────────────────────────────────────────────
step 2 "Creating resource group '$RESOURCE_GROUP' in '$LOCATION'..."
az group create --name "$RESOURCE_GROUP" --location "$LOCATION" --output none
ok "Resource group ready."

# ─────────────────────────────────────────────────────────────────────────────
# 3. Deploy Bicep template
# ─────────────────────────────────────────────────────────────────────────────
step 3 "Deploying Bicep template (this may take 5-10 minutes)..."

DEPLOY_OUTPUT=$(az deployment group create \
    --resource-group "$RESOURCE_GROUP" \
    --template-file "$SCRIPT_DIR/main.bicep" \
    --parameters "@$SCRIPT_DIR/main.parameters.json" \
    --parameters environmentName="$ENVIRONMENT_NAME" \
                 location="$LOCATION" \
                 pgAdminLogin="$PG_ADMIN_LOGIN" \
                 pgAdminPassword="$PG_ADMIN_PASSWORD" \
                 databaseName="$DATABASE_NAME" \
    --output json) || err "Bicep deployment failed."

# Extract outputs
get_output() {
    echo "$DEPLOY_OUTPUT" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d['properties']['outputs']['$1']['value'])"
}

IDENTITY_ID=$(get_output identityId)
IDENTITY_CLIENT_ID=$(get_output identityClientId)
IDENTITY_NAME=$(get_output identityName)
REGISTRY_LOGIN_SERVER=$(get_output registryLoginServer)
REGISTRY_NAME=$(get_output registryName)
CONTAINER_APP_NAME=$(get_output containerAppName)
CONTAINER_APP_ID=$(get_output containerAppId)
CONTAINER_APP_FQDN=$(get_output containerAppFqdn)
CONTAINER_APP_ENV_NAME=$(get_output containerAppEnvName)
POSTGRESQL_SERVER_NAME=$(get_output postgresqlServerName)
POSTGRESQL_SERVER_FQDN=$(get_output postgresqlServerFqdn)

ok "Bicep deployment succeeded."
echo "    Container App  : $CONTAINER_APP_NAME"
echo "    PostgreSQL     : $POSTGRESQL_SERVER_NAME"
echo "    Registry       : $REGISTRY_LOGIN_SERVER"

# ─────────────────────────────────────────────────────────────────────────────
# 4. Install Service Connector extension
# ─────────────────────────────────────────────────────────────────────────────
step 4 "Installing Service Connector passwordless extension..."
az extension add --name serviceconnector-passwordless --upgrade --output none 2>/dev/null || true
ok "Extension ready."

# ─────────────────────────────────────────────────────────────────────────────
# 5. Create Service Connector (Container App → PostgreSQL via Managed Identity)
# ─────────────────────────────────────────────────────────────────────────────
step 5 "Creating Service Connector for passwordless PostgreSQL access..."
echo "    Container App  : $CONTAINER_APP_ID"
echo "    PostgreSQL     : $POSTGRESQL_SERVER_NAME / $DATABASE_NAME"
echo "    Identity       : client-id=$IDENTITY_CLIENT_ID"

az containerapp connection create postgres-flexible \
    --connection "photoalbum-pg-connection" \
    --source-id "$CONTAINER_APP_ID" \
    --tg "$RESOURCE_GROUP" \
    --server "$POSTGRESQL_SERVER_NAME" \
    --database "$DATABASE_NAME" \
    --user-identity "client-id=$IDENTITY_CLIENT_ID" "subs-id=$SUBSCRIPTION_ID" \
    --client-type springBoot \
    -c photo-album \
    -y || err "Service Connector creation failed."

ok "Service Connector created successfully."

# ─────────────────────────────────────────────────────────────────────────────
# 6. Generate infra-config.md
# ─────────────────────────────────────────────────────────────────────────────
step 6 "Generating infra-config.md..."

cat > "$SCRIPT_DIR/infra-config.md" <<EOF
# Azure Resources Config

## Environment Info

| Property | Value |
|----------|-------|
| Subscription ID | \`$SUBSCRIPTION_ID\` |
| Resource Group | \`$RESOURCE_GROUP\` |
| Location | \`$LOCATION\` |

## Resource List

| Resource Type | Name | Region | Config Details |
|---------------|------|---------|----------------|
| User-Assigned Managed Identity | \`$IDENTITY_NAME\` | $LOCATION | Client ID: \`$IDENTITY_CLIENT_ID\` |
| Azure Container Registry | \`$REGISTRY_NAME\` | $LOCATION | Login server: \`$REGISTRY_LOGIN_SERVER\` |
| Container Apps Environment | \`$CONTAINER_APP_ENV_NAME\` | $LOCATION | Hosts the Container App |
| Azure Database for PostgreSQL | \`$POSTGRESQL_SERVER_NAME\` | $LOCATION | FQDN: \`$POSTGRESQL_SERVER_FQDN\`, Database: \`$DATABASE_NAME\` |
| Azure Container App | \`$CONTAINER_APP_NAME\` | $LOCATION | FQDN: \`$CONTAINER_APP_FQDN\`, Identity: \`AZURE_CLIENT_ID\` env var |
EOF

ok "infra-config.md written."

# ─────────────────────────────────────────────────────────────────────────────
# Summary
# ─────────────────────────────────────────────────────────────────────────────
echo ""
echo -e "${CYAN}════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN} Provisioning Complete!${NC}"
echo -e "${CYAN}════════════════════════════════════════════════════════════${NC}"
echo " Container App URL  : https://$CONTAINER_APP_FQDN"
echo " PostgreSQL FQDN    : $POSTGRESQL_SERVER_FQDN"
echo " Registry           : $REGISTRY_LOGIN_SERVER"
echo " Managed Identity   : $IDENTITY_NAME (client: $IDENTITY_CLIENT_ID)"
echo -e "${CYAN}════════════════════════════════════════════════════════════${NC}"
