# Deployment Progress

## Task: 002-deployment-azure-container-apps

| Step | Status | Notes |
|------|--------|-------|
| Dockerfile check | ✅ Complete | `./Dockerfile` present (multi-stage Maven 3.9.9 + OpenJDK 25) |
| Source fix: SERVER_PORT | ✅ Complete | Updated `application.properties`, `application-docker.properties`, `containerapp.bicep` |
| AzCLI env setup | ✅ Complete | Already logged in; `serviceconnector-passwordless` v3.3.6 present |
| Bicep provisioning | ✅ Complete | All 6 modules deployed; `az deployment group create` succeeded |
| Service Connector | ✅ Complete | `photoalbum_pg_connection` created (2nd attempt after fixing hyphen in name) |
| infra-config.md | ✅ Complete | Written to `infra/infra-config.md` |
| ACR build & push | ✅ Complete | Run ID: ch2 — `maven:3.9-eclipse-temurin-25-alpine` + `eclipse-temurin:25-jre-alpine` |
| Container App update | ✅ Complete | Image updated to `azacr5ly5sxmc37fqi.azurecr.io/photo-album:latest` |
| Validation | ✅ Complete | App logs: Spring Boot started, Managed Identity authenticated, Hibernate schema created |
| Summary | ✅ Complete | `deployment-summary.md` and `modernization-summary.md` written |

