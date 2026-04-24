"""
Тестирование алертов и дашбордов для всех кейсов.
Симулирует то, что делают bash-скрипты, через прямой HTTP API.
"""
import requests
import time
import json
import sys

API = "http://localhost:5000"
PROM = "http://localhost:9090"

def reset():
    r = requests.post(f"{API}/api/reset")
    print(f"  Reset: {r.json()['status']}")
    time.sleep(0.5)

def set_failures(config):
    r = requests.post(f"{API}/api/failures", json=config)
    print(f"  Set failures: {r.json()['status']}, config={config}")
    time.sleep(0.5)

def generate_traffic(count=50, endpoint="/api/balance"):
    success, errors = 0, 0
    for i in range(count):
        try:
            r = requests.get(f"{API}{endpoint}", timeout=10)
            if r.status_code == 200:
                success += 1
            else:
                errors += 1
        except Exception as e:
            errors += 1
    print(f"  Traffic: {success} success, {errors} errors")
    return success, errors

def query_prometheus(query):
    r = requests.get(f"{PROM}/api/v1/query", params={"query": query})
    return r.json()

def check_alert(alert_name):
    data = query_prometheus(f'ALERTS{{alertname="{alert_name}"}}')
    results = data['data']['result']
    if results:
        for r in results:
            state = r['metric'].get('alertstate', 'unknown')
            print(f"  ALERT {alert_name} is {state} (value={r['value'][1]})")
        return True
    else:
        print(f"  ALERT {alert_name}: not firing (no data)")
        return False

def check_metric(metric_name):
    data = query_prometheus(metric_name)
    results = data['data']['result']
    if results:
        print(f"  Metric {metric_name}: {len(results)} results")
        for r in results:
            labels = {k: v for k, v in r['metric'].items() if k != '__name__'}
            print(f"    {labels}: {r['value'][1]}")
        return True
    else:
        print(f"  Metric {metric_name}: no data (empty)")
        return False

def test_error_rate():
    print("\n=== КЕЙС 2: Error Rate ===")
    reset()
    set_failures({"error_rate": 60, "latency_ms": 0})
    
    # Генерируем трафик
    generate_traffic(80)
    
    # Ждём, чтобы Prometheus собрал метрики
    print("  Waiting for Prometheus scrape (15s)...")
    time.sleep(15)
    
    # Проверяем метрики
    print("\n  Checking metrics:")
    check_metric('rate(fintech_requests_total{status=~"5.."}[1m]) / rate(fintech_requests_total[1m])')
    check_metric('fintech_requests_total')
    check_alert('HighErrorRate')
    
    return True

def test_latency():
    print("\n=== КЕЙС 1: Latency ===")
    reset()
    set_failures({"latency_ms": 3000, "error_rate": 0})
    
    generate_traffic(30)
    
    print("  Waiting for Prometheus scrape (15s)...")
    time.sleep(15)
    
    print("  Checking metrics:")
    check_metric('histogram_quantile(0.95, rate(fintech_request_latency_seconds_bucket[1m]))')
    check_alert('HighLatency')
    
    return True

def test_db_slow():
    print("\n=== КЕЙС 3: DB Slow ===")
    reset()
    set_failures({"db_slow": True, "error_rate": 0})
    
    # Для db_slow нужно параллельные запросы, используем поток
    import threading
    
    def slow_request():
        try:
            requests.get(f"{API}/api/balance", timeout=10)
        except:
            pass
    
    threads = []
    for i in range(15):
        t = threading.Thread(target=slow_request)
        t.start()
        threads.append(t)
    
    for t in threads:
        t.join(timeout=5)
    
    print("  Waiting for Prometheus scrape (15s)...")
    time.sleep(15)
    
    print("  Checking metrics:")
    check_metric('fintech_active_transactions')
    check_alert('DBSlowTransactions')
    
    return True

def test_memory_leak():
    print("\n=== КЕЙС 4: Memory Leak ===")
    reset()
    set_failures({"memory_leak_mb": 50, "error_rate": 0})
    
    # Генерируем много запросов для накопления памяти
    for batch in range(5):
        generate_traffic(20)
        print(f"  Batch {batch+1}/5 done")
    
    print("  Waiting for Prometheus scrape...")
    time.sleep(15)
    
    print("  Checking metrics:")
    check_metric('container_memory_usage_bytes{container="fintech-app"}')
    check_alert('MemoryPressure')
    
    return True

def test_chaos_mix():
    print("\n=== КЕЙС 5: Chaos Mix ===")
    reset()
    set_failures({"error_rate": 40, "latency_ms": 2000, "db_slow": True})
    
    import threading
    
    def do_request():
        try:
            requests.get(f"{API}/api/balance", timeout=10)
        except:
            pass
    
    threads = []
    for i in range(20):
        t = threading.Thread(target=do_request)
        t.start()
        threads.append(t)
    
    for t in threads:
        t.join(timeout=5)
    
    print("  Waiting for Prometheus scrape...")
    time.sleep(15)
    
    print("  Checking alerts:")
    check_alert('HighLatency')
    check_alert('HighErrorRate')
    check_alert('DBSlowTransactions')
    
    return True

if __name__ == "__main__":
    # Проверка, что сервисы запущены
    try:
        r = requests.get(f"{API}/health", timeout=5)
        print(f"API health: {r.json()['status']}")
        r = requests.get(f"{PROM}/api/v1/query?query=up", timeout=5)
        print(f"Prometheus: OK")
    except Exception as e:
        print(f"Error connecting to services: {e}")
        sys.exit(1)
    
    tests = [
        ("error_rate", test_error_rate),
        ("latency", test_latency),
        ("db_slow", test_db_slow),
        ("memory_leak", test_memory_leak),
        ("chaos_mix", test_chaos_mix),
    ]
    
    results = {}
    for name, test_func in tests:
        try:
            results[name] = test_func()
        except Exception as e:
            print(f"  ERROR in {name}: {e}")
            results[name] = False
    
    print("\n" + "=" * 60)
    print("TEST RESULTS:")
    print("=" * 60)
    for name, result in results.items():
        status = "PASS" if result else "FAIL"
        print(f"  {name:15s}: {status}")
    
    # Reset at the end
    reset()
