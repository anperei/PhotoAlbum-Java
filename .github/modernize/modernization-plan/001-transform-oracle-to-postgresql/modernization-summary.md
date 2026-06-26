# Modernization Summary: Oracle to PostgreSQL Migration

**Task ID:** 001-transform-oracle-to-postgresql  
**Status:** Completed  
**Skill Used:** migration-oracle-to-postgresql

## Overview

Migrated the PhotoAlbum Java application's database layer from Oracle Database to Azure Database for PostgreSQL. All Oracle-specific JDBC drivers, SQL syntax, dialect settings, and column definitions have been replaced with PostgreSQL equivalents.

## Changes Made

### 1. `pom.xml`
- **Removed:** Oracle JDBC driver dependency (`com.oracle.database.jdbc:ojdbc11`)
- **Added:** PostgreSQL JDBC driver (`org.postgresql:postgresql`, version managed by Spring Boot BOM)
- Updated project description from Oracle to PostgreSQL

### 2. `src/main/resources/application.properties`
- **Changed** datasource URL from Oracle JDBC (`jdbc:oracle:thin:@oracle-db:1521/FREEPDB1`) to PostgreSQL JDBC with Azure environment variables (`jdbc:postgresql://${POSTGRESQL_SERVER}.postgres.database.azure.com:${POSTGRESQL_PORT}/${POSTGRESQL_DATABASE}?sslmode=require`)
- **Changed** `spring.datasource.username` to use `${POSTGRESQL_USERNAME}` environment variable
- **Changed** `spring.datasource.password` to use `${POSTGRESQL_PASSWORD}` environment variable
- **Changed** `spring.datasource.driver-class-name` from `oracle.jdbc.OracleDriver` to `org.postgresql.Driver`
- **Changed** `spring.jpa.database-platform` from `org.hibernate.dialect.OracleDialect` to `org.hibernate.dialect.PostgreSQLDialect`

### 3. `src/main/resources/application-docker.properties`
- Same datasource URL, driver class name, and JPA dialect changes as above
- Updated comment from "Oracle DB" to "Azure Database for PostgreSQL"
- Updated file upload comment to reference PostgreSQL

### 4. `src/test/resources/application-test.properties`
- Updated H2 in-memory database URL to use PostgreSQL compatibility mode: `jdbc:h2:mem:testdb;MODE=PostgreSQL;DATABASE_TO_LOWER=TRUE`
- Ensures native PostgreSQL SQL queries execute correctly against H2 in tests

### 5. `src/main/java/com/photoalbum/model/Photo.java`
- **Changed** `columnDefinition = "NUMBER(19,0)"` → `columnDefinition = "bigint"` for `fileSize` field
- **Changed** `columnDefinition = "TIMESTAMP DEFAULT SYSTIMESTAMP"` → `columnDefinition = "TIMESTAMP DEFAULT CURRENT_TIMESTAMP"` for `uploadedAt` field
- Updated Javadoc comment from "Oracle database" to "PostgreSQL database"

### 6. `src/main/java/com/photoalbum/repository/PhotoRepository.java`
All native SQL queries were converted from Oracle syntax to PostgreSQL syntax:

| Query Method | Oracle Change | PostgreSQL Replacement |
|---|---|---|
| `findAllOrderByUploadedAtDesc` | Uppercase identifiers | Lowercase identifiers |
| `findPhotosUploadedBefore` | `ROWNUM <= 10` on outer query | `LIMIT 10` clause |
| `findPhotosUploadedAfter` | `NVL(FILE_PATH, ...)` | `COALESCE(file_path, ...)` |
| `findPhotosByUploadMonth` | Oracle-specific comment; uppercase | TO_CHAR kept (PostgreSQL compatible); lowercase |
| `findPhotosWithPagination` | Double-nested `ROWNUM` pagination | `ROW_NUMBER() OVER (ORDER BY ...)` subquery |
| `findPhotosWithStatistics` | Uppercase identifiers | Lowercase identifiers; window functions compatible |

### 7. `src/main/java/com/photoalbum/service/impl/PhotoServiceImpl.java`
- Updated log messages referencing "Oracle database" to just "database"
- Updated inline comment from "Store actual photo data in Oracle database" to PostgreSQL

### 8. `docker-compose.yml`
- **Replaced** Oracle Database Free container (`gvenzl/oracle-free:latest`) with PostgreSQL 16 container (`postgres:16`)
- Updated container name from `photoalbum-oracle` to `photoalbum-postgres`
- Updated environment variables for PostgreSQL format (`POSTGRES_DB`, `POSTGRES_USER`, `POSTGRES_PASSWORD`)
- Changed port from `1521` to `5432`
- Replaced Oracle-specific volume with PostgreSQL volume (`postgres_data`)
- Updated healthcheck from Oracle `healthcheck.sh` to `pg_isready`
- Reduced startup time from 180s to 30s (PostgreSQL starts much faster)
- Removed Oracle init scripts volume mount
- Updated app service environment variables to use `SPRING_DATASOURCE_URL` with local PostgreSQL URL

## SQL Syntax Conversions

| Oracle Syntax | PostgreSQL Equivalent |
|---|---|
| `ROWNUM <= N` | `LIMIT N` |
| `NVL(expr, default)` | `COALESCE(expr, default)` |
| `NUMBER(19,0)` | `bigint` |
| `TIMESTAMP DEFAULT SYSTIMESTAMP` | `TIMESTAMP DEFAULT CURRENT_TIMESTAMP` |
| Nested ROWNUM pagination | `ROW_NUMBER() OVER (ORDER BY ...)` window function |
| Uppercase table/column names | Lowercase table/column names |

## Test Results

- **Build:** ✅ SUCCESS
- **Unit Tests:** ✅ 1/1 passed (0 failures, 0 errors)
- **Consistency Check:** ✅ No Critical or Major issues; 3 Minor observations

## Consistency Check Results

- **Critical Issues:** 0
- **Major Issues:** 0
- **Minor Issues:** 3 (environment variable configuration expected at runtime; TO_CHAR compatibility confirmed)
