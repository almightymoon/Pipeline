"""Unit tests for the demo application."""

from src.app import create_app, health_payload


def test_health_payload_ok():
    payload = health_payload()
    assert payload["status"] == "ok"
    assert "version" in payload


def test_healthz_endpoint():
    client = create_app().test_client()
    resp = client.get("/healthz")
    assert resp.status_code == 200
    assert resp.get_json()["status"] == "ok"


def test_readyz_endpoint():
    client = create_app().test_client()
    resp = client.get("/readyz")
    assert resp.status_code == 200
    assert resp.get_json()["ready"] is True


def test_index():
    client = create_app().test_client()
    resp = client.get("/")
    assert resp.status_code == 200
    assert "DevSecOps" in resp.get_json()["message"]


def test_metrics_exposition():
    client = create_app().test_client()
    resp = client.get("/metrics")
    assert resp.status_code == 200
    assert b"demo_app_up 1" in resp.data
