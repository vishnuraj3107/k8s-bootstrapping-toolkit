# =============================================================================
# Dockerfile - Sample Flask Application
# Author: Vishnu Raj
# =============================================================================

# ── Stage 1: Builder ──────────────────────────────────────────────────────────
FROM python:3.11-slim AS builder

WORKDIR /app

# Install dependencies in a virtual env for clean copy
COPY requirements.txt .
RUN python -m venv /opt/venv && \
    /opt/venv/bin/pip install --upgrade pip && \
    /opt/venv/bin/pip install --no-cache-dir -r requirements.txt

# ── Stage 2: Runtime ──────────────────────────────────────────────────────────
FROM python:3.11-slim AS runtime

# Security: run as non-root user
RUN useradd --create-home --shell /bin/bash appuser

WORKDIR /app

# Copy virtual env and app source
COPY --from=builder /opt/venv /opt/venv
COPY src/ .

# Use venv
ENV PATH="/opt/venv/bin:$PATH"

# Runtime environment variables
ENV APP_VERSION="1.0.0" \
    APP_ENV="production" \
    PORT="5000"

# Switch to non-root
USER appuser

EXPOSE 5000

# Health check built into image
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:5000/health')"

CMD ["python", "app.py"]
