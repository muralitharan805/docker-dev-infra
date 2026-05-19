# Enterprise PostgreSQL with pgvector (Alpine-based)

A secure, performance-optimized, and containerized PostgreSQL 16 database featuring the `pgvector v0.8.2` extension. Engineered to serve as a high-performance vector database for local AI development, semantic search, and retrieval-augmented generation (RAG) across multiple parallel projects.

---

## 🚀 Key Features

* **Multi-Stage Build**: Keeps final runtime images tiny by leaving compilation tools in a builder layer.
* **Patched pgvector v0.8.2**: Built with the latest secure release patching critical buffer overflow issues (`CVE-2026-3172`).
* **Deterministic Versioning**: Avoids `latest` tags; pins base environment to stable `postgres:16.6-alpine`.
* **Auto-Initialization**: Built-in entrypoint hook registers the `vector` SQL extension automatically upon initial database provision.
* **Environment Isolation**: Secrets are kept completely separated via `.env` parameter interpolation.
* **Health & Dependability**: Includes a robust healthcheck schema utilizing `pg_isready`.
* **Resource Hardening**: Configured with limits on memory (1.5GB) and CPU (1.5 cores) to prevent heavy vector indexing operations from locking your host environment.
* **Strict Non-Root Safety**: Forced execution under the non-privileged `postgres` system account (UID 70/GID 70).

---

## 🛠️ Getting Started (Local Quickstart)

### 1. Provision Configuration Variables
The environment relies on an isolated `.env` configuration. A default one has been generated for you. If you need to make changes (such as shifting the port), you can edit the `.env` file:
```bash
# Check the active variables
cat .env
```

### 2. Launch the Database Service
Start the container using Compose. This will trigger the multi-stage build, compile `pgvector`, set permissions, and launch the service:
```bash
docker compose up --build -d
```

### 3. Verify Service Health
Monitor the container startup. It will transition to a green `healthy` state once PostgreSQL is ready to accept connections:
```bash
docker compose ps
```

---

## 💾 Data Persistence & Disaster Recovery (Re-creation Safety)

All database records, vector tables, and HNSW indexes are stored inside a **named persistent Docker volume** (`pgvector_data_volume`) on your host filesystem. This guarantees that **your database state remains completely intact and safe** in the following scenarios:

* **Container Deletion/Re-creation**: Running `docker compose down` or deleting the container with `docker rm -f pgvector-db` removes the container layer but **leaves the persistent volume completely untouched**.
* **Image Deletion/Rebuild**: Deleting the local image or force-rebuilding it (`docker compose up --build`) has no effect on the data. The compilation of a new image is completely separate from the storage volume.
* **Database Upgrades/Migrations**: When you bring up a new container, Docker automatically re-attaches the existing `pgvector_data_volume` to the `/var/lib/postgresql/data` directory inside the container, instantly restoring all your tables and vectors.

### ⚠️ Essential Storage Operations Rules

* **To Stop & Remove Container Safely (Data Preserved)**:
  ```bash
  docker compose down
  ```
  *(Stops and deletes the container interface. Your database data remains 100% intact and will load back instantly on the next `docker compose up`).*

* **To Wipe & Clear the Database (Destructive Operation)**:
  ```bash
  docker compose down -v
  ```
  *(Adding the `-v` or `--volumes` flag instructs Docker Compose to **permanently delete the named volume and wipe all data**. Only use this when you explicitly want to clear the database and start from scratch).*

---

## 🧪 Verification & Query Diagnostics

To verify that the database is active and `pgvector` has been initialized correctly, run the following verification checks:

### Connect and Check Version
Run an interactive session via `psql` to check the version of the extension:
```bash
docker compose exec -it pgvector-db psql -U vector_admin -d vectordb -c "SELECT extname, extversion FROM pg_extension WHERE extname = 'vector';"
```
**Expected Output:**
```text
 extname | extversion 
---------+------------
 vector  | 0.8.2
(1 row)
```

### Test Vector Search Queries
Execute a quick SQL block to create an experimental vector column, insert embeddings, and run a cosine distance search:
```bash
docker compose exec -it pgvector-db psql -U vector_admin -d vectordb -c "
-- 1. Create a table with a 3-dimensional vector column
CREATE TABLE IF NOT EXISTS test_embeddings (id bigserial PRIMARY KEY, embedding vector(3));

-- 2. Insert test vector records
INSERT INTO test_embeddings (embedding) VALUES ('[1,2,3]'), ('[4,5,6]'), ('[7,8,9]');

-- 3. Query using Cosine Distance (<=>) against a search query [3,2,1]
SELECT id, embedding, embedding <=> '[3,2,1]' AS distance FROM test_embeddings ORDER BY distance ASC;
"
```

---

## 🔗 Standalone Execution & Creating Custom Databases (CRM & PMO)

By design, this container runs as a **pure standalone PostgreSQL database engine**. Once the service is running, you can connect to it using your favorite database client (such as DBeaver, pgAdmin, VS Code Database Extensions, or the command line `psql`) and manually create your databases for `CRM` and `PMO`.

---

### Step 1: Connect to Standalone Engine
Use the credentials specified in your `.env` to connect to the central instance:
* **Host**: `localhost` (or `127.0.0.1`)
* **Port**: `5432` *(or whatever `POSTGRES_PORT` is specified in your `.env`)*
* **Default Database**: `vectordb` *(used to establish initial connection)*
* **Username**: `vector_admin`
* **Password**: `pgV3ct0r_53cur3_Pa55w0rd!`
* **Admin Connection URI**:
  ```text
  postgresql://vector_admin:pgV3ct0r_53cur3_Pa55w0rd!@localhost:5432/vectordb
  ```

---

### Step 2: Create CRM and PMO Databases Manually
You can create the databases using standard SQL or terminal tools.

#### Option A: SQL Command (Recommended)
Connect to the database server using your client tool and run the following queries:

```sql
-- 1. Create the CRM database and register pgvector
CREATE DATABASE crm_db;
\c crm_db;
CREATE EXTENSION IF NOT EXISTS vector;

-- 2. Create the PMO database and register pgvector
CREATE DATABASE pmo_db;
\c pmo_db;
CREATE EXTENSION IF NOT EXISTS vector;
```

#### Option B: Automated Terminal Commands
Alternatively, you can create them directly from your shell by running `createdb` and `psql` execution queries inside the active container:

```bash
# 1. Create and initialize crm_db
docker compose exec -it pgvector-db createdb -U vector_admin crm_db
docker compose exec -it pgvector-db psql -U vector_admin -d crm_db -c "CREATE EXTENSION IF NOT EXISTS vector;"

# 2. Create and initialize pmo_db
docker compose exec -it pgvector-db createdb -U vector_admin pmo_db
docker compose exec -it pgvector-db psql -U vector_admin -d pmo_db -c "CREATE EXTENSION IF NOT EXISTS vector;"
```

---

### Step 3: Configure Your Local Projects

Once the databases are created, configure your respective projects using these standard connection strings:

#### 1. CRM Project Connection Settings:
* **Database Host**: `localhost` *(or `pgvector-db` if running inside shared docker-compose networks)*
* **Database Port**: `5432`
* **Database Name**: `crm_db`
* **Username**: `vector_admin`
* **Password**: `pgV3ct0r_53cur3_Pa55w0rd!`
* **Connection String / URI**:
  ```text
  postgresql://vector_admin:pgV3ct0r_53cur3_Pa55w0rd!@localhost:5432/crm_db
  ```

#### 2. PMO Project Connection Settings:
* **Database Host**: `localhost` *(or `pgvector-db` if running inside shared docker-compose networks)*
* **Database Port**: `5432`
* **Database Name**: `pmo_db`
* **Username**: `vector_admin`
* **Password**: `pgV3ct0r_53cur3_Pa55w0rd!`
* **Connection String / URI**:
  ```text
  postgresql://vector_admin:pgV3ct0r_53cur3_Pa55w0rd!@localhost:5432/pmo_db
  ```

---

## ⚙️ High-Performance Configuration Tweaks

For massive vector operations (such as high-dimensional semantic search or generating complex HNSW indexes), you can configure performance optimizations in Postgres by tuning key values. 

If needed, create a custom `postgresql.conf` and mount it, or pass configurations directly as startup parameters in `docker-compose.yml`:
```yaml
services:
  pgvector-db:
    # ...
    command: postgres -c shared_buffers=512MB -c work_mem=64MB -c maintenance_work_mem=256MB
```
* **`shared_buffers`**: Increase to load more indices into RAM (recommended: 25% of available memory).
* **`maintenance_work_mem`**: Increase to speed up vector index creation (e.g., `hnsw` index builds).
* **`work_mem`**: Speeds up in-memory sorts and filtered query operations.

---

## 🔒 Security Hardening Notes

1. **Production Deployment**: For production, ensure you do not commit your `.env` file to version control. Keep `.env` added to your `.gitignore`.
2. **Non-Root Integrity**: The Docker container runs under `USER postgres` (UID 70). This means that even if a critical exploit occurs, the attacker cannot obtain superuser command access to the underlying Docker host.

```
docker exec -it pgvector-db psql -U vector_admin -d vectordb
```