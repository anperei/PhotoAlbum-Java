# Modernization Plan: Photo Album — Modernize and Deploy to Azure

**Project**: Photo Album

---

## Technical Framework

- **Language**: Java 25
- **Framework**: Spring Boot 4.1.0 (Spring Framework 7.x)
- **Build Tool**: Maven 3.9
- **Database**: Azure Database for PostgreSQL (Flexible Server) with Managed Identity (passwordless)
- **Key Dependencies**: Spring Data JPA (Jakarta EE), Spring Cloud Azure 7.3.0, Thymeleaf, Spring Boot Validation

---

## Overview

This modernization plan focuses on securing and deploying the Photo Album application to Azure. The application is already at a modern baseline — Java 25, Spring Boot 4.1.0, and PostgreSQL with Azure Managed Identity authentication are in place. The remaining work is:

- Scan and remediate known CVEs in project dependencies to ensure the application is secure before deployment.
- Deploy the containerized application to **Azure Container Apps** with a new Azure PostgreSQL Flexible Server provisioned using Bicep, prompting for Azure authentication to allow selection of the target subscription and environment.

The migration follows a two-phase approach: security hardening first, then deployment to Azure.

---

## Migration Impact Summary

| Application   | Original Service          | New Azure Service              | Authentication     | Comments                                              |
|---------------|---------------------------|--------------------------------|--------------------|-------------------------------------------------------|
| Photo Album   | Local / Docker deployment | Azure Container Apps           | Managed Identity   | New ACA environment provisioned via Bicep             |
| Photo Album   | Local PostgreSQL (Docker) | Azure Database for PostgreSQL  | Managed Identity   | Passwordless auth; already configured in app config   |

---

## Open Questions & Questionnaire

- [x] Q: Should the plan include environment/infrastructure provisioning? → A: Yes — provision new Azure infrastructure (Azure Container Apps + Azure Database for PostgreSQL)
- [x] Q: Should the plan include integration testing? → A: No — skip integration testing
- [x] Q: Should the plan include a security/CVE remediation task? → A: Yes — include security/CVE remediation (default)
- [x] Q: Which Azure deployment target should the plan use? → A: Azure Container Apps (default)
