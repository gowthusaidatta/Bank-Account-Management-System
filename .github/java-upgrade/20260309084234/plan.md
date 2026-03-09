# Upgrade Plan: Bank Account Management System (20260309084234)

- **Generated**: 2026-03-09 08:42:34 UTC
- **HEAD Branch**: main
- **HEAD Commit ID**: 64d9272f4402114fa27d25153bc82915465c74f4

## Available Tools

**JDKs**
- JDK 17.0.17: C:\Program Files\Microsoft\jdk-17.0.17.10-hotspot\bin (current project JDK, used by step 2)
- JDK 21.0.9: C:\Program Files\Microsoft\jdk-21.0.9.10-hotspot\bin (target JDK, used by steps 3-5)

**Build Tools**
- Maven 3.9.11: C:\ProgramData\chocolatey\lib\maven\apache-maven-3.9.11\bin

## Guidelines

- Upgrade Java runtime to LTS version Java 21
- Maintain compatibility with existing Spring Boot 3.3.5 and Axon Framework 4.10.3
- Minimal dependency changes (only upgrade if compatibility requires it)

> Note: You can add any specific guidelines or constraints for the upgrade process here if needed, bullet points are preferred.

## Options

- Working branch: appmod/java-upgrade-20260309084234
- Run tests before and after the upgrade: true

## Upgrade Goals

- Upgrade Java from 17 to 21 (LTS)

### Technology Stack

| Technology/Dependency | Current | Min Compatible | Why Incompatible |
| --------------------- | ------- | -------------- | ---------------- |
| Java                  | 17      | 21             | User requested upgrade to Java 21 LTS |
| Spring Boot           | 3.3.5   | 3.3.5          | - (already compatible with Java 17-21) |
| Axon Framework        | 4.10.3  | 4.10.3         | - (supports Java 17+) |
| PostgreSQL Driver     | Managed by Spring Boot | Same | - (compatible) |
| Maven                 | 3.9.11  | 3.6.0+         | - (Maven 3.6+ supports Java 21) |

### Derived Upgrades

No derived dependency upgrades required. The project is using Spring Boot 3.3.5 and Axon Framework 4.10.3, both of which are already compatible with Java 21.

## Upgrade Steps

- **Step 1: Setup Environment**
  - **Rationale**: Verify all required JDKs and build tools are available (JDK 17, JDK 21, Maven already detected).
  - **Changes to Make**:
    - [ ] Verify JDK 17 is available at C:\Program Files\Microsoft\jdk-17.0.17.10-hotspot\bin
    - [ ] Verify JDK 21 is available at C:\Program Files\Microsoft\jdk-21.0.9.10-hotspot\bin
    - [ ] Verify Maven 3.9.11 is available at C:\ProgramData\chocolatey\lib\maven\apache-maven-3.9.11\bin
  - **Verification**:
    - Command: `#list_jdks(sessionId)` and `#list_mavens(sessionId)` to confirm availability
    - Expected: All required JDKs and Maven are available at documented paths

---

- **Step 2: Setup Baseline**
  - **Rationale**: Establish pre-upgrade compile and test results with Java 17 to measure upgrade success.
  - **Changes to Make**:
    - [ ] Run baseline compilation with JDK 17 (main + test code)
    - [ ] Run baseline tests with JDK 17
    - [ ] Document baseline test pass rate and any existing failures
  - **Verification**:
    - Command: `mvn clean test-compile` followed by `mvn clean test`
    - JDK: C:\Program Files\Microsoft\jdk-17.0.17.10-hotspot\bin
    - Expected: Document compilation result and test pass rate (baseline for comparison)

---

- **Step 3: Update Build Configuration for Java 21**
  - **Rationale**: Update Maven configuration to target Java 21 compilation and runtime.
  - **Changes to Make**:
    - [ ] Update `pom.xml`: Change `<java.version>` property from 17 to 21
    - [ ] Compile project with JDK 21 (main + test code)
    - [ ] Fix any compilation errors if they arise
  - **Verification**:
    - Command: `mvn clean test-compile`
    - JDK: C:\Program Files\Microsoft\jdk-21.0.9.10-hotspot\bin
    - Expected: Compilation SUCCESS for both main and test code

---

- **Step 4: Final Validation**
  - **Rationale**: Verify all upgrade goals met, project compiles successfully, and all tests pass with Java 21.
  - **Changes to Make**:
    - [ ] Verify pom.xml shows `<java.version>21</java.version>`
    - [ ] Run full clean build and test suite with JDK 21
    - [ ] Fix any test failures through iterative debugging (achieve 100% pass rate or ≥ baseline)
    - [ ] Verify application functionality with Java 21 runtime
  - **Verification**:
    - Command: `mvn clean test`
    - JDK: C:\Program Files\Microsoft\jdk-21.0.9.10-hotspot\bin
    - Expected: Compilation SUCCESS + 100% test pass rate (or ≥ baseline)

## Key Challenges

- **JDK Feature Compatibility**
  - **Challenge**: While Java 21 is backward compatible with Java 17, there may be deprecated APIs or behavioral changes that could affect the application.
  - **Strategy**: Compile and test thoroughly with JDK 21. Java 17 to 21 is a relatively smooth upgrade path as both are LTS versions. Monitor for any deprecation warnings during compilation.

- **Docker Configuration (Optional)**
  - **Challenge**: If the application is containerized, the Dockerfile should be updated to use a Java 21 base image.
  - **Strategy**: After successful local upgrade, update Dockerfile to use Java 21 runtime (e.g., eclipse-temurin:21-jdk or similar). This is an optional post-upgrade task and not blocking for the Java runtime upgrade.
