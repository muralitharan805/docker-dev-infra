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

## 🔗 Dynamic & Automatic Multi-Database Provisioning

By design, this environment supports **fully automated multi-database provisioning**. Any new developer pulling this repository can immediately initialize multiple isolated databases (e.g. `civicpath`, `analytics_db`) pre-loaded with the `vector`, `postgis`, and `postgis_topology` extensions without writing a single line of SQL or running manual database commands.

---

### Step 1: Define Databases in `.env`
Databases are managed entirely through the `.env` file. To add or change databases, open the `.env` file and look for the `POSTGRES_MULTIPLE_DATABASES` variable. List your target databases separated by commas:

```ini
# Central default database (used to establish initial connection)
POSTGRES_DB=vectordb

# Additional application databases to automatically create & initialize
POSTGRES_MULTIPLE_DATABASES=civicpath,analytics_db
```

---

### Step 2: Run the Compose Setup
When developers pull this code, they just run the standard compose up command:
```bash
# Make the helper entrypoint script executable (first-time setup only)
chmod +x init-scripts/init-multiple-databases.sh

# Build and start the container
docker compose up -d
```

During this initial startup, the container mounts and runs [01-init-multiple-databases.sh](file:///home/murali/Documents/genral-docker/postgres/init-scripts/init-multiple-databases.sh) **before** PostGIS registers itself. This automatically:
1. Creates the primary `vectordb` and registers the extensions.
2. Loops through `POSTGRES_MULTIPLE_DATABASES` and creates `civicpath` and `analytics_db`.
3. Installs and registers the `vector`, `postgis`, and `postgis_topology` extensions inside every single database.

---

### Step 3: Verification & Connection URIs
Developers can verify that their databases were successfully created and the extensions are active:

#### Verify PostGIS & Vector Extensions:
```bash
# Check 'civicpath' database
docker compose exec -it pgvector-db psql -U vector_admin -d civicpath -c "SELECT PostGIS_Version();"

# Check 'analytics_db' database
docker compose exec -it pgvector-db psql -U vector_admin -d analytics_db -c "SELECT PostGIS_Version();"
```

#### Standard Connection Settings:
Use the credentials specified in your `.env` to configure your applications:
* **Host**: `localhost` (or `127.0.0.1` / `pgvector-db` if inside a shared docker network)
* **Port**: `5432` *(or whatever `POSTGRES_PORT` is specified in your `.env`)*
* **Username**: `vector_admin`
* **Password**: `pgV3ct0r_53cur3_Pa55w0rd!`
* **Connection URIs**:
  * **Civicpath**: `postgresql://vector_admin:pgV3ct0r_53cur3_Pa55w0rd!@localhost:5432/civicpath`
  * **Analytics**: `postgresql://vector_admin:pgV3ct0r_53cur3_Pa55w0rd!@localhost:5432/analytics_db`

---

### ⚠️ Adding a New Database Later
If a developer already has a running container and wants to add a new database:

1. **Option A: Hot-Fix (Preserves active data)**:
   Add the database to the `.env` list, then manually execute the setup:
   ```bash
   docker compose exec -it pgvector-db psql -U vector_admin -d vectordb
   ```
   ```sql
   CREATE DATABASE my_new_db;
   \c my_new_db
   CREATE EXTENSION IF NOT EXISTS vector;
   CREATE EXTENSION IF NOT EXISTS postgis;
   CREATE EXTENSION IF NOT EXISTS postgis_topology;
   ```

2. **Option B: Reset & Re-initialize (Destroys local database state)**:
   If there is no critical local data, simply update the `POSTGRES_MULTIPLE_DATABASES` variable in your `.env` and rebuild the persistent volume:
   ```bash
   # Wipes the persistent volume and starts clean
   docker compose down -v
   docker compose up -d
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