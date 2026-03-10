# =============================================================
# Production Dockerfile for Crop Disease Detection API
# Uses a slim requirements file (no PyTorch / training deps)
# to keep image size manageable (~2GB instead of ~10GB).
# =============================================================

FROM python:3.10-slim

# Prevents Python from writing .pyc files
ENV PYTHONDONTWRITEBYTECODE=1
# Prevents Python from buffering stdout/stderr
ENV PYTHONUNBUFFERED=1

WORKDIR /app

# Install system dependencies
# curl   → used by the HEALTHCHECK
# gcc/g++ → required by some Python packages at build time
# libgl1 + libglib2.0-0 → required by opencv-python-headless
RUN apt-get update && apt-get install -y --no-install-recommends \
    gcc \
    g++ \
    libgl1 \
    libglib2.0-0 \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Copy slim Docker requirements first (layer caching)
COPY requirements.docker.txt .

# Install Python dependencies
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir -r requirements.docker.txt

# Copy application source
COPY . .

# Create runtime directories (volumes will be mounted here)
RUN mkdir -p uploads/images uploads/heatmaps uploads/reports models logs

# Expose FastAPI port
EXPOSE 8000

# Health check — calls the /health endpoint
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD curl -f http://localhost:8000/health || exit 1

# Run with Gunicorn + Uvicorn workers
CMD ["gunicorn", "app.main:app", \
     "--workers", "2", \
     "--worker-class", "uvicorn.workers.UvicornWorker", \
     "--bind", "0.0.0.0:8000", \
     "--timeout", "120", \
     "--access-logfile", "-", \
     "--error-logfile", "-"]
