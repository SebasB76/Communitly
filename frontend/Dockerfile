# ---------- sdk: Flutter instalado desde el tarball oficial ----------
# Las imagenes de la comunidad van atrasadas: el proyecto pide Dart ^3.13.0,
# que llega con Flutter 3.47.0.
FROM debian:bookworm-slim AS sdk

ARG FLUTTER_VERSION=3.47.0

ENV DEBIAN_FRONTEND=noninteractive \
    FLUTTER_SUPPRESS_ANALYTICS=true \
    PATH="/opt/flutter/bin:/opt/flutter/bin/cache/dart-sdk/bin:${PATH}"

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        ca-certificates curl git unzip xz-utils \
    && rm -rf /var/lib/apt/lists/*

RUN curl -fsSL -o /tmp/flutter.tar.xz \
      "https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_${FLUTTER_VERSION}-stable.tar.xz" \
    && tar -xJf /tmp/flutter.tar.xz -C /opt \
    && rm /tmp/flutter.tar.xz \
    && git config --global --add safe.directory /opt/flutter \
    && flutter --version

WORKDIR /app

# ---------- build: compila Flutter web ----------
FROM sdk AS build

# El navegador corre en el host, por eso apunta al puerto publicado del backend
ARG API_BASE=http://localhost:8000/api

COPY pubspec.yaml pubspec.lock ./
RUN flutter pub get

COPY . .
RUN flutter build web --release --dart-define=API_BASE=$API_BASE

# ---------- serve: sirve el build estatico ----------
FROM nginx:alpine AS serve

COPY --from=build /app/build/web /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80
