Cloud Capstone - Multi-Tier RBAC Backend

Containerized REST API built with Spring Boot 3, Spring Security 6 (stateless JWT), and PostgreSQL, fully orchestrated with Docker Compose.

Architecture
- Backend: Java 17, Spring Boot 3.3.4, Hibernate / JPA
- **Security:** JWT Authentication with Role-Based Access Control (`ROLE_ADMIN`, `ROLE_USER`)
-Database: PostgreSQL 16 with persistent Docker named volume (`db_data`)
-Documentation:OpenAPI 3.0 / Swagger UI


```bash
docker compose up --build
API Docs & Swagger UI: http://localhost:8080/swagger-ui/index.html

Actuator Health Check: http://localhost:8080/actuator/health