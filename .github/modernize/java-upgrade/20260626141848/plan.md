# Upgrade Plan: photo-album (20260626141848)

- **Generated**: 2026-06-26 14:18:48
- **HEAD Branch**: modernize
- **HEAD Commit ID**: 1e4dfc6a92a7cceb2c953c849f1a10aa6bff22e9

## Available Tools

**JDKs**
- JDK 8: not available (baseline will be skipped)
- JDK 25: **<TO_BE_INSTALLED>** (required by steps 3–N and final validation)

**Build Tools**
- Maven: not available on system; no Maven wrapper present → **<TO_BE_INSTALLED>** (Maven 3.9.9 recommended)

## Guidelines

> Note: You can add any specific guidelines or constraints for the upgrade process here if needed, bullet points are preferred.

- Fully autonomous execution — no user confirmation pauses.
- Working artifacts stored under `.github/modernize/upgrade-plan/001-upgrade-spring-boot-4x/`.
- Success criteria: passBuild=true, generateNewUnitTests=false, passUnitTests=true.

## Options

- Working branch: appmod/java-upgrade-20260626141848
- Run tests before and after the upgrade: true

## Upgrade Goals

- Spring Boot: 2.7.18 → 4.1.0 (latest 4.x release)
- Java: 8 → 25
- Spring Framework: 5.x → 7.x (transitive via Spring Boot 4.x)
- Jakarta EE: javax.* → jakarta.* namespace migration

## Technology Stack

| Technology/Dependency         | Current          | Min Compatible      | Why Incompatible                                              |
|-------------------------------|------------------|---------------------|---------------------------------------------------------------|
| Java                          | 8                | 17 (SB4 min), 25 target | User requested Java 25                                    |
| Spring Boot                   | 2.7.18           | 4.1.0               | User requested Spring Boot 4.x                                |
| Spring Framework              | 5.3.x            | 7.x                 | Spring Boot 4.x includes Spring Framework 7.x                 |
| Hibernate                     | 5.6.x            | 6.x                 | Spring Boot 3+ uses Hibernate 6.x; Spring Boot 4 continues    |
| Jakarta EE (javax.* ⚠️ EOL)   | javax.* (EE8)    | jakarta.* (EE10)    | Spring Boot 3+ requires jakarta.* namespace                   |
| Maven (wrapper)               | not present      | 3.9.x               | No wrapper present; Maven 3.9+ recommended for Java 25        |
| maven-compiler-plugin         | managed by SB    | 3.11+               | Recommended for Java 25 support                               |
| ojdbc8                        | managed by SB    | ojdbc11+            | ojdbc8 compiled for Java 8 target; ojdbc11 preferred for JVM 25 |
| spring-boot-devtools          | optional         | compatible          | No breaking change expected                                   |
| commons-io                    | 2.11.0           | 2.11+ ok            | No breaking change                                            |
| H2 (test)                     | managed by SB2   | 2.x                 | Spring Boot 4 manages H2 2.x; no changes needed               |

## Derived Upgrades

| Derived Change                     | Justification                                                      |
|------------------------------------|--------------------------------------------------------------------|
| Java source/target 8 → 25          | User requested                                                     |
| Spring Framework 5.x → 7.x        | Transitive via spring-boot-starter-parent 4.1.0                   |
| Hibernate 5.6.x → 6.x             | Transitive via Spring Boot 4.x                                     |
| javax.* → jakarta.* namespace      | Spring Boot 3+ requires Jakarta EE 9+; mandatory for SB4           |
| ojdbc8 → ojdbc11 artifact          | ojdbc8 pinned to Java 8 class target; ojdbc11 is Java 25 compatible |
| Dockerfile: Java 8 → Java 25       | CI/CD alignment with new runtime                                   |
| H2Dialect class: verify still valid| Hibernate 6.x may adjust dialect resolution                        |
| OracleDialect: verify still valid  | Hibernate 6.x keeps OracleDialect in same package                  |

## Impact Analysis

### Dependency Changes

| File       | Dependency                      | Current  | Action  | Target  | Reason                                                       |
|------------|----------------------------------|----------|---------|---------|--------------------------------------------------------------|
| pom.xml    | spring-boot-starter-parent       | 2.7.18   | upgrade | 4.1.0   | User requested Spring Boot 4.x                               |
| pom.xml    | java.version property            | 1.8      | upgrade | 25      | User requested Java 25                                       |
| pom.xml    | maven.compiler.source            | 8        | upgrade | 25      | Must match Java version                                      |
| pom.xml    | maven.compiler.target            | 8        | upgrade | 25      | Must match Java version                                      |
| pom.xml    | ojdbc8 (artifactId)              | ojdbc8   | replace | ojdbc11 | Prefer ojdbc11 jar for modern JVMs; add explicit version     |

### Source Code Changes

| File                         | Location         | Current                         | Required Change                           | Reason                              |
|------------------------------|------------------|---------------------------------|-------------------------------------------|-------------------------------------|
| model/Photo.java             | imports 3–7      | javax.persistence.*             | jakarta.persistence.*                     | Jakarta EE 10 namespace migration   |
| model/Photo.java             | imports 4–7      | javax.validation.constraints.*  | jakarta.validation.constraints.*          | Jakarta EE 10 namespace migration   |

Note: `javax.imageio.ImageIO` in PhotoServiceImpl.java is part of Java SE standard library — no change needed.

### Configuration Changes

| File                           | Property/Setting                               | Current                              | Required Change                       | Reason                                |
|--------------------------------|------------------------------------------------|--------------------------------------|---------------------------------------|---------------------------------------|
| application.properties         | spring.jpa.database-platform                   | org.hibernate.dialect.OracleDialect  | (keep — still valid in Hibernate 6.x) | Hibernate 6 retains same package      |
| application-test.properties    | spring.jpa.database-platform                   | org.hibernate.dialect.H2Dialect      | (keep — still valid in Hibernate 6.x) | Hibernate 6 retains same package      |
| application-test.properties    | spring.datasource.url                          | jdbc:h2:mem:testdb                   | Add `MODE=MySQL` or keep — check compatibility | H2 2.x compatibility with Hibernate 6 |

### CI/CD Changes

| File        | Location       | Current                                | Required Change                              |
|-------------|----------------|----------------------------------------|----------------------------------------------|
| Dockerfile  | FROM line 1    | maven:3.9.6-eclipse-temurin-8          | maven:3.9.9-eclipse-temurin-25 (or 21)        |
| Dockerfile  | FROM line 17   | eclipse-temurin:8-jre                  | eclipse-temurin:25-jre                        |

### Risks & Warnings

- **Hibernate 6 @Lob on byte[] with Oracle**: In Hibernate 6, `@Lob byte[]` mapping behavior changed. Oracle BLOB storage with byte[] should still work but may need explicit `@Column(columnDefinition="BLOB")` instead of `@Lob`. **Mitigation**: Keep `@Lob` initially; if tests fail with BLOB mapping, add `@JdbcTypeCode(SqlTypes.BINARY)` or use `@Column(columnDefinition="BLOB")`.
- **H2 2.x test compatibility with Hibernate 6**: H2 2.x changed some SQL behaviours. Spring Boot 4 manages H2 2.x. **Mitigation**: Verify contextLoads test passes; if DDL issues arise, add `spring.jpa.properties.hibernate.globally_quoted_identifiers=true` or set H2 compatibility mode.
- **Spring Boot 4.x property changes**: Some auto-configuration properties may have been renamed (e.g., `spring.jpa.hibernate.ddl-auto` is still valid). **Mitigation**: Run build and check for deprecation warnings.
- **No Maven wrapper present**: Maven must be installed separately. **Mitigation**: Install Maven 3.9.9 in Step 1.

## Upgrade Steps

- Step 1: Setup Environment — Install JDK 25 and Maven 3.9.9
  - **Rationale**: No JDK or Maven available on system; both required for all subsequent steps.
  - **Changes to Make**: Install JDK 25 via `#install-jdk(version: "25")`; install Maven 3.9.9 via `#install-maven(version: "latest")`.
  - **Verification**: `#list-jdks`, `#list-mavens`. Expected: JDK 25 and Maven 3.9.9 listed.

- Step 2: Setup Baseline — (SKIP — base JDK 8 not available)
  - **Rationale**: JDK 8 is not available; baseline test run is skipped.
  - **Verification**: N/A

- Step 3: Upgrade pom.xml (Spring Boot 4.1.0, Java 25, ojdbc11)
  - **Rationale**: Core dependency upgrade — bumps Spring Boot parent, Java version properties, and switches Oracle JDBC artifact.
  - **Changes to Make**: All Dependency Changes rows from Impact Analysis.
  - **Verification**: `mvn clean test-compile -q` with JDK 25. Expected: Compilation SUCCESS.

- Step 4: Migrate javax.* → jakarta.* Namespace
  - **Rationale**: Spring Boot 3+ requires jakarta.* namespace; javax.persistence/javax.validation imports in Photo.java must be updated.
  - **Changes to Make**: All Source Code Changes from Impact Analysis (Photo.java imports).
  - **Verification**: `mvn clean test-compile -q` with JDK 25. Expected: Compilation SUCCESS.

- Step 5: Update Dockerfile for Java 25
  - **Rationale**: CI/CD alignment — Dockerfile must reference Java 25 base images.
  - **Changes to Make**: All CI/CD Changes from Impact Analysis.
  - **Verification**: Dockerfile review (no build command needed for this step).

- Step 6: Final Validation
  - **Rationale**: Ensure all upgrade goals met; verify 100% test pass rate.
  - **Changes to Make**: Fix any remaining compilation errors or test failures (iterative loop).
  - **Verification**: `mvn clean test` with JDK 25. Expected: All tests pass, BUILD SUCCESS.
