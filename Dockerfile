# ============================================================
# Stage 1: Build Flutter Web App
# ============================================================
FROM ghcr.io/cirruslabs/flutter:3.19.0 AS builder
WORKDIR /app
# Fix pathing - assuming we are at root
COPY frontend/pubspec.yaml frontend/pubspec.lock ./
RUN flutter pub get
COPY frontend/ .
RUN flutter build web --release

# ============================================================
# Stage 2: Main Production (Ubuntu Base)
# ============================================================
FROM ubuntu:22.04
ENV DEBIAN_FRONTEND=noninteractive

# Install dependencies (Nginx, Mongo 7.0, Redis, Python)
RUN apt-get update && apt-get install -y \
    python3 python3-pip nginx redis-server gnupg curl supervisor \
    && curl -fsSL https://www.mongodb.org/static/pgp/server-7.0.asc | gpg --dearmor -o /usr/share/keyrings/mongodb-server-7.0.gpg \
    && echo "deb [ arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-7.0.gpg ] https://repo.mongodb.org/apt/ubuntu jammy/mongodb-org/7.0 multiverse" | tee /etc/apt/sources.list.d/mongodb-org-7.0.list \
    && apt-get update && apt-get install -y mongodb-org \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app
RUN mkdir -p /data/db /data/configdb /var/log/mongodb /var/log/supervisor /app/backend

# Install Backend Dependencies
COPY backend/requirements.txt ./backend/
RUN pip3 install --no-cache-dir -r ./backend/requirements.txt

# Copy Sources
COPY backend/ ./backend/
COPY --from=builder /app/build/web /usr/share/nginx/html
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY nginx.huggingface.conf /etc/nginx/sites-enabled/default

# Env Vars
ENV MONGODB_URL=mongodb://localhost:27017/crop_disease_db
ENV REDIS_URL=redis://localhost:6379/0

EXPOSE 7860
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
