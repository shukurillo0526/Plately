"""
Plately — Health & API Integration Tests
============================================
Tests the health check endpoint and root endpoint.
Uses a minimal test app to avoid importing the full main.py
(which triggers real Supabase/Ollama connections).
"""

import pytest
from unittest.mock import patch, AsyncMock, MagicMock
from starlette.testclient import TestClient
from fastapi import FastAPI

from app.middleware.request_middleware import RequestIdMiddleware
from app.middleware.error_handlers import register_error_handlers


@pytest.fixture
def client():
    """Create a minimal test app with health routes only."""
    from app.core.config import get_settings
    app = FastAPI(title="Test", version=get_settings().APP_VERSION)
    app.add_middleware(RequestIdMiddleware)
    register_error_handlers(app)

    # Mock the dependencies that health.py imports
    mock_db = MagicMock()
    mock_result = MagicMock()
    mock_result.data = [{"id": "test"}]
    mock_db.table.return_value.select.return_value.limit.return_value.execute.return_value = mock_result

    mock_ollama_instance = MagicMock()
    mock_ollama_instance.is_available = AsyncMock(return_value=False)
    mock_ollama_instance.list_models = AsyncMock(return_value=[])

    with patch("app.routers.health.get_supabase", return_value=mock_db), \
         patch("app.routers.health.get_ollama_service", return_value=mock_ollama_instance):
        from app.routers.health import router
        app.include_router(router)

        @app.get("/")
        async def root():
            return {"name": "Plately Intelligence API", "version": get_settings().APP_VERSION, "docs": "/docs"}

        yield TestClient(app)


class TestRootEndpoint:
    def test_root_returns_version(self, client):
        resp = client.get("/")
        assert resp.status_code == 200
        data = resp.json()
        assert data["version"] == "0.1.9"
        assert "docs" in data

    def test_root_has_request_id(self, client):
        resp = client.get("/")
        assert "X-Request-ID" in resp.headers


class TestHealthPing:
    def test_ping_returns_ok(self, client):
        resp = client.get("/api/v1/health/ping")
        assert resp.status_code == 200
        data = resp.json()
        assert data["status"] == "ok"
        assert "timestamp" in data


class TestHealthDeep:
    def test_health_returns_services(self, client):
        resp = client.get("/api/v1/health")
        data = resp.json()
        assert "services" in data
        assert "supabase" in data["services"]
        assert "version" in data

    def test_health_reports_supabase_up(self, client):
        resp = client.get("/api/v1/health")
        data = resp.json()
        assert data["services"]["supabase"]["status"] == "up"

    def test_health_has_timestamp(self, client):
        resp = client.get("/api/v1/health")
        data = resp.json()
        assert "timestamp" in data


class TestNotFound:
    def test_404_has_error_envelope(self, client):
        resp = client.get("/nonexistent/path/12345")
        assert resp.status_code == 404
        data = resp.json()
        assert data["status"] == "error"
        assert data["code"] == "NOT_FOUND"
        assert "request_id" in data
