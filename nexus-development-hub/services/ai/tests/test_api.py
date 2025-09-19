from fastapi.testclient import TestClient

from app.main import app


client = TestClient(app)


def test_health_endpoint():
    response = client.get("/health")
    assert response.status_code == 200
    assert response.json() == {"status": "ok"}


def test_ingest_dry_run():
    payload = {"embeddings": [[0.1, 0.2, 0.3]], "dry_run": True}
    response = client.post("/ingest", json=payload)
    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "dry-run"
    assert data["count"] == 1
    assert data["dry_run"] is True
