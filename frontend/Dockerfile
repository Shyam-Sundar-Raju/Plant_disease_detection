# ============================================================
# Stage 1: Build Flutter Web App
# ============================================================
FROM ghcr.io/cirruslabs/flutter:3.19.0 AS builder

WORKDIR /app

# Copy manifests
COPY pubspec.yaml pubspec.lock ./
RUN flutter pub get

# Copy source and build
COPY . .
RUN flutter build web --release

# ============================================================
# Stage 2: Serve with Nginx
# ============================================================
FROM nginx:1.27-alpine

# Copy custom config for CORS/Proxy
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Copy build files from Stage 1
COPY --from=builder /app/build/web /usr/share/nginx/html

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
