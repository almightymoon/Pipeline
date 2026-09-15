# syntax=docker/dockerfile:1.7

FROM python:3.12-slim-bookworm AS builder

WORKDIR /build
COPY requirements.txt .
RUN pip install --no-cache-dir --prefix=/install -r requirements.txt

FROM python:3.12-slim-bookworm

LABEL org.opencontainers.image.title="demo-app" \
      org.opencontainers.image.description="DevSecOps pipeline sample application" \
      org.opencontainers.image.source="https://github.com/almightymoon/Pipeline"

# Apply OS security updates (e.g. libpcre2) before dropping privileges
RUN apt-get update \
 && apt-get upgrade -y --no-install-recommends \
 && rm -rf /var/lib/apt/lists/*

RUN groupadd --gid 10001 app \
 && useradd --uid 10001 --gid 10001 --home /app --shell /usr/sbin/nologin app

WORKDIR /app

COPY --from=builder /install /usr/local
COPY src/ ./src/

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PORT=8080 \
    APP_NAME=demo-app \
    APP_VERSION=0.1.0

USER 10001:10001

EXPOSE 8080

HEALTHCHECK --interval=15s --timeout=3s --start-period=5s --retries=3 \
  CMD python -c "import urllib.request; urllib.request.urlopen('http://127.0.0.1:8080/healthz')" || exit 1

CMD ["gunicorn", "--bind", "0.0.0.0:8080", "--workers", "2", "--threads", "4", "src.app:app"]
