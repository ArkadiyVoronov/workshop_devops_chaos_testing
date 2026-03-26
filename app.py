import os
import time
import random
import threading
import gc
from datetime import datetime
from flask import Flask, jsonify, request
import psycopg2
from prometheus_client import Counter, Histogram, Gauge, generate_latest, CONTENT_TYPE_LATEST

app = Flask(__name__)

# === METRICS ===
REQUEST_COUNT = Counter('fintech_requests_total', 'Total requests', ['method', 'endpoint', 'status'])
REQUEST_LATENCY = Histogram('fintech_request_latency_seconds', 'Request latency', ['endpoint'])
ACTIVE_TRANSACTIONS = Gauge('fintech_active_transactions', 'Currently processing transactions')

# === FAILURE INJECTION STATE ===
_failure_state = {
    'latency_ms': 0,
    'error_rate': 0,
    'memory_leak_mb': 0,
    'db_slow': False,
    'db_fail': False,
}
_leaked_memory = []

def inject_failures():
    """Инъекция отказов на основе состояния"""
    state = _failure_state
    
    # Задержка
    if state['latency_ms'] > 0:
        time.sleep(state['latency_ms'] / 1000)
    
    # Случайные ошибки
    if state['error_rate'] > 0 and random.randint(1, 100) <= state['error_rate']:
        raise Exception("Simulated random failure")
    
    # Утечка памяти
    if state['memory_leak_mb'] > 0:
        _leaked_memory.append(bytearray(state['memory_leak_mb'] * 1024 * 1024))
    
    # Медленная БД
    if state['db_slow']:
        time.sleep(2)

# === ROUTES ===

@app.route('/')
def index():
    return jsonify({
        "service": "fintech-api",
        "version": "2.0.0",
        "endpoints": ["/health", "/metrics", "/api/balance", "/api/transfer", "/api/failures", "/api/reset"]
    })

@app.route('/health')
def health():
    start = time.time()
    
    # ИНЪЕКЦИЯ ОТКАЗОВ
    try:
        inject_failures()
    except Exception as e:
        REQUEST_LATENCY.labels(endpoint='/health').observe(time.time() - start)
        REQUEST_COUNT.labels(method='GET', endpoint='/health', status='500').inc()
        return jsonify({"status": "error", "error": str(e)}), 500
    
    try:
        conn = psycopg2.connect(os.getenv('DATABASE_URL'))
        conn.close()
        db_status = "connected"
        status = "healthy"
    except Exception as e:
        db_status = f"error: {str(e)}"
        status = "unhealthy"
    
    REQUEST_LATENCY.labels(endpoint='/health').observe(time.time() - start)
    REQUEST_COUNT.labels(method='GET', endpoint='/health', status='200' if status == 'healthy' else '503').inc()
    
    return jsonify({
        "status": status,
        "database": db_status,
        "timestamp": datetime.utcnow().isoformat()
    }), 200 if status == "healthy" else 503

@app.route('/metrics')
def metrics():
    REQUEST_COUNT.labels(method='GET', endpoint='/metrics', status='200').inc()
    return generate_latest(), 200, {'Content-Type': CONTENT_TYPE_LATEST}

@app.route('/api/balance')
def get_balance():
    start = time.time()
    try:
        inject_failures()
        
        conn = psycopg2.connect(os.getenv('DATABASE_URL'))
        cur = conn.cursor()
        cur.execute("SELECT account_number, balance FROM accounts WHERE user_id = 1")
        result = cur.fetchone()
        cur.close()
        conn.close()
        
        REQUEST_LATENCY.labels(endpoint='/api/balance').observe(time.time() - start)
        REQUEST_COUNT.labels(method='GET', endpoint='/api/balance', status='200').inc()
        
        return jsonify({
            "account": result[0] if result else "ACC-001",
            "balance": float(result[1]) if result else 1000.00,
            "currency": "USD"
        })
    except Exception as e:
        REQUEST_COUNT.labels(method='GET', endpoint='/api/balance', status='500').inc()
        return jsonify({"error": str(e)}), 500

@app.route('/api/transfer', methods=['POST'])
def transfer():
    start = time.time()
    ACTIVE_TRANSACTIONS.inc()
    
    try:
        inject_failures()
        
        data = request.get_json() or {}
        amount = data.get('amount', 0)
        to_account = data.get('to_account', 'unknown')
        
        # Симуляция обработки перевода
        time.sleep(0.1)
        
        REQUEST_LATENCY.labels(endpoint='/api/transfer').observe(time.time() - start)
        REQUEST_COUNT.labels(method='POST', endpoint='/api/transfer', status='200').inc()
        
        return jsonify({
            "status": "completed",
            "transaction_id": f"TXN-{random.randint(100000, 999999)}",
            "amount": amount,
            "to_account": to_account,
            "timestamp": datetime.utcnow().isoformat()
        })
    except Exception as e:
        REQUEST_COUNT.labels(method='POST', endpoint='/api/transfer', status='500').inc()
        return jsonify({"error": "Transfer failed", "details": str(e)}), 500
    finally:
        ACTIVE_TRANSACTIONS.dec()

@app.route('/api/failures', methods=['GET', 'POST'])
def manage_failures():
    """Управление инъекцией отказов"""
    global _failure_state
    
    if request.method == 'POST':
        data = request.get_json() or {}
        _failure_state.update({
            'latency_ms': data.get('latency_ms', _failure_state['latency_ms']),
            'error_rate': data.get('error_rate', _failure_state['error_rate']),
            'memory_leak_mb': data.get('memory_leak_mb', _failure_state['memory_leak_mb']),
            'db_slow': data.get('db_slow', _failure_state['db_slow']),
            'db_fail': data.get('db_fail', _failure_state['db_fail']),
        })
        return jsonify({"status": "updated", "config": _failure_state})
    
    return jsonify({"current_config": _failure_state})

@app.route('/api/reset', methods=['POST'])
def reset():
    """Сброс всех отказов и очистка памяти"""
    global _failure_state, _leaked_memory
    _failure_state = {k: (False if isinstance(v, bool) else 0) for k, v in _failure_state.items()}
    _leaked_memory = []
    gc.collect()
    return jsonify({"status": "reset complete"})

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)