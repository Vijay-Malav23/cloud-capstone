# Cloud Capstone - Multi-Tier Containerized Backend

A containerized RESTful API backend built with Spring Boot 3, Spring Security 6 (stateless JWT), and PostgreSQL 16, orchestrated via Docker Compose.

## Architecture & Tech Stack
- **Framework:** Spring Boot 3.3.4 (Java 17)
- **Data Persistence:** Spring Data JPA, Hibernate ORM, PostgreSQL 16
- **Security:** Spring Security 6 with stateless JWT authentication & Role-Based Access Control (`ROLE_ADMIN`, `ROLE_USER`)
- **Containerization:** Multi-stage Dockerfile and Docker Compose with persistent named volume (`db_data`)
- **API Documentation:** OpenAPI 3.0 / Swagger UI (`/swagger-ui/index.html`)
- **Observability:** Spring Boot Actuator (`/actuator/health`, `/actuator/metrics`)

---

## Getting Started

### Prerequisites
- Docker Desktop & Docker Compose
- Java 17+ & Maven (optional for local non-container builds)

### Run with Docker Compose
```bash
docker compose up --build
