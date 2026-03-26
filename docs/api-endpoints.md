# API Endpoints

| Endpoint | Метод | Описание | Метрики | Пример |
|----------|-------|----------|---------|--------|
| `/` | GET | Info | ✅ | `curl localhost:5000/` |
| `/health` | GET | Health check | ✅ | `curl localhost:5000/health` |
| `/metrics` | GET | Prometheus | ✅ | `curl localhost:5000/metrics` |
| `/api/balance` | GET | Баланс счёта | ✅ | `curl localhost:5000/api/balance` |
| `/api/transfer` | POST | Перевод | ✅ | `curl -X POST ...` |
| `/api/failures` | GET/POST | Инъекция | ✅ | `curl -X POST -d '{}'` |
| `/api/reset` | POST | Сброс | ✅ | `curl -X POST` |

