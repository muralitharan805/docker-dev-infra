---
name: redis-docker-setup
description: This skill should be loaded when the user wants to containerize Redis, configure a Redis Docker setup (standalone, cluster, or replication), or troubleshoot Redis containers using Docker/Docker Compose.
---

# Redis Docker Infrastructure & Deployment Setup

## Core Objective
This skill provides a standardized, production-ready framework for deploying, configuring, and optimizing Redis instances using Docker and Docker Compose. It ensures proper data persistence, memory management, and network security across localized or containerized environments.

## Evaluation Checklist / Step-by-Step Execution Loop

1. **Environment Assessment & Configuration**
   * Identify the required Redis deployment mode (Standalone, Master-Replica, Sentinel, or Cluster).
   * Verify the target Redis version (default to latest stable Alpine-based image unless specified otherwise).
   * Determine data persistence requirements: RDB (snapshots), AOF (Append Only File), or both.

2. **Docker Compose Composition**
   * Structure a standard `docker-compose.yml` file with appropriate API syntax.
   * Define dedicated named volumes for explicit host-to-container data mapping (`/data`).
   * Expose the default Redis port `6379` securely, binding to localhost for development or specific internal bridge networks for production.

3. **Performance & Security Tuning**
   * Inject baseline configurations via command flags or a custom `redis.conf` volume mount.
   * Implement a strong password policy using the `--requirepass` directive or environment variables.
   * Configure memory allocation limits (`maxmemory`) and eviction policies (e.g., `allkeys-lru`) to prevent host OOM (Out Of Memory) panics.

4. **Health Checking & Lifecycle Management**
   * Embed an explicit `healthcheck` block in the compose file utilizing `redis-cli ping` to track readiness.
   * Configure restart policies (`restart: unless-stopped`) to ensure high availability.

## Constraints & Output Rules

* **No Ephemeral Storage:** Never provide a configuration without explicit persistent volume mappings.
* **Security First:** Explicitly include password configuration or insert a noticeable comment/placeholder alerting the user to secure the instance before deployment.
* **Format Requirement:** Provide complete, standalone, copy-pasteable `docker-compose.yml` code blocks and any accompanying `redis.conf` templates side-by-side. Do not truncate snippets.
* **Directory Structure:** Ensure configurations assume a clean folder structure:
  ```text
  .
  ├── docker-compose.yml
  └── config/
      └── redis.conf