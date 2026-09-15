"""Secure demo application for the DevSecOps pipeline."""

from __future__ import annotations

import os
import time
from typing import Any

from flask import Flask, jsonify

APP_NAME = os.getenv("APP_NAME", "demo-app")
APP_VERSION = os.getenv("APP_VERSION", "0.1.0")
START_TIME = time.time()

app = Flask(__name__)


def health_payload() -> dict[str, Any]:
    return {
        "status": "ok",
        "app": APP_NAME,
        "version": APP_VERSION,
        "uptime_seconds": round(time.time() - START_TIME, 2),
    }


@app.get("/healthz")
def healthz():
    return jsonify(health_payload()), 200


@app.get("/readyz")
def readyz():
    return jsonify({"ready": True}), 200


@app.get("/")
def index():
    return jsonify(
        {
            "message": "DevSecOps demo app",
            "docs": "/healthz",
            "version": APP_VERSION,
        }
    ), 200


@app.get("/metrics")
def metrics():
    # Minimal Prometheus text exposition for the demo
    uptime = time.time() - START_TIME
    body = "\n".join(
        [
            "# HELP demo_app_up 1 if the process is running",
            "# TYPE demo_app_up gauge",
            "demo_app_up 1",
            "# HELP demo_app_uptime_seconds Process uptime in seconds",
            "# TYPE demo_app_uptime_seconds gauge",
            f"demo_app_uptime_seconds {uptime:.2f}",
            "",
        ]
    )
    return body, 200, {"Content-Type": "text/plain; version=0.0.4"}


def create_app() -> Flask:
    return app


if __name__ == "__main__":
    port = int(os.getenv("PORT", "8080"))
    # Bind all interfaces inside the container; cluster NetworkPolicy restricts peers.
    app.run(host="0.0.0.0", port=port)
