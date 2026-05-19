# ==============================================================================
# STAGE 1: BUILD ENVIRONMENT (builder)
# ==============================================================================
# Use the official PostGIS Alpine image to compile pgvector and support GIS natively.
# This ensures compilation headers align perfectly with the target runtime.
FROM postgis/postgis:16-3.5-alpine AS builder

# Install build-time dependencies using BuildKit cache mounting to speed up builds.
# We require build-base, clang, llvm-dev, and git to compile C extensions.
RUN --mount=type=cache,target=/var/cache/apk \
    apk add --no-cache \
        git \
        build-base \
        clang \
        llvm-dev

# Define deterministic version of pgvector to build.
# This version includes patches for critical vulnerabilities (e.g., CVE-2026-3172).
ARG PGVECTOR_VERSION=v0.8.2

# Clone the repository and compile the extension without LLVM bitcode JIT compilation
# to avoid the missing clang-19 compiler dependency.
WORKDIR /tmp/pgvector
RUN git clone --depth 1 --branch ${PGVECTOR_VERSION} https://github.com/pgvector/pgvector.git . \
    && make with_llvm=no \
    && make install with_llvm=no

# ==============================================================================
# STAGE 2: FINAL RUNTIME ENVIRONMENT
# ==============================================================================
# Pin the exact same base PostGIS Alpine version for the production container.
FROM postgis/postgis:16-3.5-alpine

# Set OCI-compliant labels for metadata discovery
LABEL org.opencontainers.image.title="PostgreSQL pgvector" \
      org.opencontainers.image.description="Secure, production-ready PostgreSQL container with pgvector extension pre-installed" \
      org.opencontainers.image.version="16.6-pgvector-0.8.2" \
      org.opencontainers.image.vendor="Antigravity Infrastructure" \
      org.opencontainers.image.licenses="MIT"

# Copy ONLY the compiled extension binaries and metadata from the builder stage.
# This eliminates compiler bloat, keeping the image small and minimizing attack surface.
COPY --from=builder /usr/local/lib/postgresql/vector.so /usr/local/lib/postgresql/
COPY --from=builder /usr/local/share/postgresql/extension/vector* /usr/local/share/postgresql/extension/

# Ensure runtime directories are pre-created and have strict unprivileged permissions.
# The official alpine postgres runs under UID 70 (postgres) and GID 70 (postgres).
RUN mkdir -p /var/lib/postgresql/data /var/run/postgresql \
    && chown -R postgres:postgres /var/lib/postgresql/data /var/run/postgresql \
    && chmod 700 /var/lib/postgresql/data \
    && chmod 775 /var/run/postgresql

# Enforce strict non-root execution by switching to the non-privileged postgres user.
USER postgres

# Expose default PostgreSQL port
EXPOSE 5432
