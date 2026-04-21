# Fintech Workshop API

A Python Flask-based fintech API service designed for observability and chaos engineering workshops. It simulates a financial API with failure injection capabilities.

## Architecture

- **Backend**: Python Flask app (`app.py`) running on port 5000
- **Database**: PostgreSQL (Replit built-in), accessed via `DATABASE_URL` environment variable
- **Metrics**: Prometheus-compatible metrics exposed at `/metrics`

## Key Endpoints

- `GET /` — Service info and endpoint listing
- `GET /health` — Health check (DB connectivity)
- `GET /metrics` — Prometheus metrics
- `GET /api/balance` — Fetch account balance
- `POST /api/transfer` — Simulate a transfer
- `GET|POST /api/failures` — View/configure failure injection
- `POST /api/reset` — Reset all failure states

## Failure Injection

The app supports injecting artificial failures for workshop/educational purposes:
- `latency_ms` — Add artificial latency
- `error_rate` — Random error percentage (1-100)
- `memory_leak_mb` — Simulate memory leak per request
- `db_slow` — Slow DB queries (2s delay)
- `db_fail` — Simulate DB failures

## Running Locally

```bash
pip install -r requirements.txt
python app.py
```

## Database Schema

```sql
CREATE TABLE accounts (
    id SERIAL PRIMARY KEY,
    user_id INTEGER DEFAULT 1,
    account_number VARCHAR(20) DEFAULT 'ACC-001',
    balance DECIMAL(19,4) DEFAULT 10000.0000,
    created_at TIMESTAMP DEFAULT NOW()
);
```

## Deployment

Configured for autoscale deployment using Gunicorn:
```
gunicorn --bind=0.0.0.0:5000 --reuse-port app:app
```

## Notes

- Originally designed for Docker Compose (with Prometheus, Grafana, cAdvisor). In Replit, only the Flask app and PostgreSQL are used.
- The `.env` file references `db:5432` (Docker hostname) — Replit uses `DATABASE_URL` env var instead.
