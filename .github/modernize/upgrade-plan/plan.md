# Modernization Plan: upgrade-plan

**Project**: Photo Album (photo-album)

---

## Technical Framework

- **Language**: Java 1.8 (Java 8)
- **Framework**: Spring Boot 2.7.18, Spring Framework 5.x
- **Build Tool**: Maven
- **Database**: Oracle Database (ojdbc8)
- **Key Dependencies**: Spring Data JPA, Hibernate, Thymeleaf, Spring Boot Validation, Commons IO

---

## Overview

> This upgrade modernizes the Photo Album Spring Boot application from an end-of-support technology stack to the latest stable versions. The application currently runs on Java 8 and Spring Boot 2.7.18, both of which have reached end-of-OSS-support. The new stack will:
>
> - Upgrade Spring Boot to 4.x and Java to 25 (latest LTS), resolving all mandatory upgrade blockers identified in the assessment
> - Upgrade Spring Framework to 7.x as part of the Spring Boot 4.x upgrade
> - Migrate Java EE namespace (`javax.*`) to Jakarta EE (`jakarta.*`) required by Spring Boot 3+ and above

---

## Migration Impact Summary

| Application   | Original Service         | New Version           | Comments                                 |
|---------------|--------------------------|-----------------------|------------------------------------------|
| photo-album   | Java 8                   | Java 25               | Mandatory upgrade — end of support       |
| photo-album   | Spring Boot 2.7.18       | Spring Boot 4.x       | Mandatory upgrade — end of OSS support   |
| photo-album   | Spring Framework 5.x     | Spring Framework 7.x  | Included in Spring Boot 4.x upgrade      |
| photo-album   | Jakarta EE (javax.*)     | Jakarta EE (jakarta.*)| Included in Spring Boot 4.x upgrade      |

---

## Open Questions & Questionnaire

- [x] Q: Which Azure deployment target should the plan use? → A: No deployment — upgrade only
- [x] Q: Which Spring Boot/Java version should the upgrade target? → A: Spring Boot 4.x with Java 25 (latest)
- [x] Q: Should Oracle be migrated to Azure PostgreSQL? → A: No — keep Oracle database, upgrade only
- [x] Q: Should the plan include security/CVE remediation? → A: No — skip security scan
