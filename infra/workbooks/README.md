# Photo Album Telemetry Workbook

This folder contains a workbook template for the telemetry emitted by the app instrumentation.

## 1) Deploy monitoring stack (Application Insights)

Use the separate monitoring deployment entrypoint so app resources are not broadly redeployed.

```powershell
az deployment group create `
  --resource-group <RESOURCE_GROUP> `
  --template-file infra/monitoring.main.bicep `
  --parameters infra/monitoring.parameters.json `
  --parameters logAnalyticsWorkspaceResourceId="<LOG_ANALYTICS_WORKSPACE_RESOURCE_ID>"
```

Capture the output connection string:

```powershell
$deployment = az deployment group show --resource-group <RESOURCE_GROUP> --name <DEPLOYMENT_NAME> | ConvertFrom-Json
$connectionString = $deployment.properties.outputs.appInsightsConnectionString.value
```

## 2) Wire Application Insights to Container App

Pass the connection string to the existing app deployment parameter:

```powershell
az deployment group create `
  --resource-group <RESOURCE_GROUP> `
  --template-file infra/main.bicep `
  --parameters infra/main.parameters.json `
  --parameters appInsightsConnectionString="$connectionString" pgAdminPassword="<POSTGRES_ADMIN_PASSWORD>"
```

## 3) Import workbook in Azure Portal

1. Open Azure Monitor -> Workbooks -> New.
2. Select Advanced Editor.
3. Paste the contents of infra/workbooks/photoalbum-telemetry.workbook.json.
4. Save the workbook in the same resource group.

## 4) Validate telemetry

Run upload and delete actions in the app, then verify workbook charts populate within a few minutes.
