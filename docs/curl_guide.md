# Руководство по curl

В воркшопе все сценарии строятся вокруг простых HTTP-запросов с помощью `curl`.

## Зачем curl

- **Прозрачность**  
  Каждый участник видит точный запрос: метод, URL, заголовки, тело. Легко копировать и изменять примеры.

- **Повторяемость**  
  Команды `curl` одинаково работают:
  - локально;
  - в GitHub Codespaces;
  - в CI-джобах (например, для smoke-тестов).

- **Связка с наблюдаемостью**  
  Любой запрос, сделанный через `curl`,:
  - увеличивает счётчик `fintech_requests_total`;
  - попадает в гистограмму `fintech_request_latency_seconds`;
  - виден в Prometheus и Grafana по эндпоинту и статусу.

### Как мы используем curl в кейсах

- Базовая проверка здоровья сервиса:

```bash
curl http://localhost:5000/health
```
- Инъекция отказов (пример — задержка 2000 мс):
```bash
curl -X POST http://localhost:5000/api/failures \
  -H "Content-Type: application/json" \
  -d '{"latency_ms": 2000}'
```
- Сброс всех инъекций::
```bash
curl -X POST http://localhost:5000/api/reset
```
Эти команды являются «входной точкой» для всех кейсов: после них мы открываем Prometheus/Grafana и смотрим, как изменились метрики.

Больше контекста о том, зачем нам observability и хаос-инженерия — в [testing_philosophy.md](testing_philosophy.md).


