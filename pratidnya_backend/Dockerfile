# ==============================================================================
# PRATIDNYA LEGAL TECH (ASIVERTICALS)
# STAGE 1: Build & Dependency Wheel Resolver
# ==============================================================================
FROM python:3.11-slim as builder

ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1

WORKDIR /install

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    curl \
    && rm -rf /var/lib/apt/lists/*

COPY requirements.txt .

# Install production dependencies
RUN pip install --no-cache-dir --prefix=/install -r requirements.txt

# ==============================================================================
# STAGE 2: Production Container (OOM Protected for Render 2GB RAM Starter Plan)
# ==============================================================================
FROM python:3.11-slim as runner

ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PORT=8000 \
    APP_ENV=PRODUCTION \
    TORCH_HOME=/app/cache/torch \
    SPACY_DATA=/app/cache/spacy

WORKDIR /app

RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Copy compiled python modules from builder
COPY --from=builder /install /usr/local

# Security: Create non-root system user (DPDP Act Compliance)
RUN groupadd -r pratidnya && useradd -r -g pratidnya -m -d /home/pratidnya pratidnya

# Copy application source tree
COPY . /app

# Ensure cache directories have proper ownership
RUN mkdir -p /app/cache/torch /app/cache/spacy && \
    chown -R pratidnya:pratidnya /app

USER pratidnya


# Healthcheck probe for Render orchestrator
HEALTHCHECK --interval=30s --timeout=10s --start-period=45s --retries=3 \
    CMD curl -f http://127.0.0.1:${PORT}/healthz || exit 1

EXPOSE 8000

# Strict: Single-worker uvicorn to prevent memory multiplication on Render
CMD ["sh", "-c", "uvicorn app.main:app --host 0.0.0.0 --port ${PORT} --workers 1 --loop uvloop --http httptools --lifespan on"]
