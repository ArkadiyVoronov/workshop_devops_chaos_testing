import requests, time, sys

API = "http://localhost:5000"
PROM = "http://localhost:9090"

print("=== QUICK TEST ===", flush=True)

# 1. Reset & inject failures
r = requests.post(f"{API}/api/reset", timeout=5)
print(f"Reset: {r.json()['status']}", flush=True)

r = requests.post(f"{API}/api/failures", json={"error_rate": 60, "latency_ms": 1000}, timeout=5)
print(f"Inject: {r.json()['status']}", flush=True)

# 2. Generate traffic
success, errors = 0, 0
for i in range(40):
    try:
        r = requests.get(f"{API}/api/balance", timeout=10)
        if r.status_code == 200:
            success += 1
        else:
            errors += 1
    except Exception as e:
        pass
print(f"Traffic: {success} ok, {errors} err", flush=True)

# 3. Check prometheus now
print("\n=== PROMETHEUS METRICS ===", flush=True)
for q in ["fintech_requests_total", "ALERTS", 'job:fintech_error_rate:5m']:
    try:
        r = requests.get(f"{PROM}/api/v1/query", params={"query": q}, timeout=5)
        data = r.json()
        for res in data['data']['result']:
            m = res['metric']
            labels = ",".join(f"{k}={v}" for k,v in m.items() if k != '__name__')
            print(f"  {q}: {labels} => {res['value'][1]}", flush=True)
        if not data['data']['result']:
            print(f"  {q}: (no data)", flush=True)
    except Exception as e:
        print(f"  {q}: ERROR {e}", flush=True)

print("\nDONE", flush=True)
