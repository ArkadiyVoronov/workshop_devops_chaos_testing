# Fintech DevOps Workshop  
## Interactive workshop on fault‑tolerant testing of fintech applications using Docker, Prometheus and Grafana.

### 🚀 Quick start  

#### Option 1: GitHub Codespaces (recommended)  
1. Open the repository on GitHub.  
2. Click **Code → Codespaces → Create codespace on main**.  
3. Wait for the environment to spin up (≈ 2 minutes on the first launch).  
4. In the terminal run:  

```bash
docker compose up -d --build bash scripts/check_setup.sh
```  

5. Open the Grafana URL (port 3000) via the port‑forward popup.

#### Option 2: Local Docker (Linux / macOS / WSL)  

```bash
git clone https://github.com/ArkadiyVoronov/workshop_devops_chaos_testing.git
cd workshop_devops_with_app
docker compose up -d --build bash scripts/check_setup.sh
```

#### Option 3: Replit (alternative, no Docker)  
Press the **Run** button in Replit – the app starts instantly on port 5000 (without full monitoring stack).

### ⚠️ Important note about operating systems  

| OS | Status | Recommendations |
|---|---|---|
| **🐧 Linux** | ✅ Native | Works out‑of‑the‑box. Recommended to use Ubuntu/Debian. |
| **🍎 macOS** | ⚠️ Not tested | Should run via Docker Desktop, but may hit permission or mount‑path issues. Use **GitHub Codespaces** if problems appear. |
| **🪟 Windows** | ❌ Only via WSL 2 | Direct execution in PowerShell/CMD fails (`bash: command not found`, line‑ending issues). <br>**How to run correctly:** <br>1. Install [WSL 2](https://learn.microsoft.com/windows/wsl/install) (`wsl --install` in PowerShell). <br>2. Install Docker Desktop and enable WSL integration. <br>3. Open an **Ubuntu** (or other) terminal inside WSL, not PowerShell. <br>4. `cd` into the project folder inside Linux. <br>5. Run the commands as shown for Linux. <br>**Tip:** use GitHub Codespaces to avoid any setup hassle. |

> 💡 **Tip for Windows users:** GitHub Codespaces (Option 1) guarantees 100 % functionality in ~3 minutes.

### 🎬 Running the first scenario  

```bash
# Check service health
curl http://localhost:5000/health

# Open dashboards
# Prometheus: http://localhost:9090
# Grafana: http://localhost:3000 (admin/workshop)
# cAdvisor: http://localhost:8080
```

#### Injecting a failure (latency example)

```bash
# Option 1: via script
bash scripts/01_run_latency.sh

# Option 2: direct curl
curl -X POST http://localhost:5000/api/failures \
     -H "Content-Type: application/json" \
     -d '{"latency_ms": 3000}'
```

#### Monitoring in Grafana  

- Open Grafana → view the `fintech_request_latency_seconds_bucket` metric.  
- Check p95/p99:  

```bash
histogram_quantile(0.95, rate(fintech_request_latency_seconds_bucket[1m]))
```

#### Resetting after a scenario  

```bash
bash scripts/reset.sh
# or:
curl -X POST http://localhost:5000/api/reset
```

> **Important:** This is a teaching app. It **simulates** failures but does **not** include automatic recovery mechanisms (Circuit Breaker, Retry). Recovery is done manually via `/api/reset` for learning purposes.

### 📚 Information  

- **Architecture:** `docs/architecture.md`  
- **Practical cases:** `docs/cases/`  

### Available services  

| Service | URL | Purpose | Credentials |
|---|---|---|---|
| Fintech API | http://localhost:5000 | Main application | — |
| Prometheus | http://localhost:9090 | Metric collection & storage | — |
| cAdvisor | http://localhost:8080 | Metric collection & storage | — |
| Grafana | http://localhost:3000 | Metric visualization | `admin` / `workshop` |

![Application diagram](/docs/screenshots/architecture_diagram.png)

### Project structure  

```
workshop_devops_with_app/
├── docs/
│   ├── architecture.md
│   ├── coach-guide.md
│   ├── presentation.md
│   ├── monitoring.md
│   ├── testing_philosophy.md
│   ├── curl_guide.md
│   ├── api-endpoints.md
│   ├── scripts.md
│   ├── screenshots.md
│   └── cases/
│       ├── 01_latency.md
│       ├── 02_error_rate.md
│       ├── 03_db_slow.md
│       ├── 04_memory_leak.md
│       └── 05_chaos_mix.md
├── config/
│   ├── prometheus.yml
│   └── prometheus.rules.yml
├── grafana/
│   └── provisioning/
├── scripts/
│   ├── check_setup.sh
│   ├── 01_run_latency.sh
│   ├── 02_run_error_rate.sh
│   ├── 03_run_db_slow.sh
│   ├── 04_run_memory_leak.sh
│   ├── 05_run_chaos_mix.sh
│   └── reset.sh
├── app.py
├── docker-compose.yml
├── init.sql
├── .env.example
└── README.md
```

### 💰 Why it matters for financial systems  

Financial apps (payments, transfers, investments) demand **high reliability**. Typical issues:

| Problem | Consequence | Loss |
|---|---|---|
| **High latency** (slow responses) | Users wait > 10 s, think the system is down → duplicate payments, loss of trust | Up to 10 % user churn |
| **Error rate increase** | 5 % of transfers are rejected after money is already debited → disputes, regulatory fines | Reputation damage, regulatory penalties |
| **Slow DB** | Queue builds up → system hangs | Support overload, revenue drop |
| **Memory leak** | Process consumes all RAM → crash → all payments unavailable | Downtime = monetary loss, SLA penalties |

**Our workshop** lets you see these problems live in Grafana and learn how to resolve them.

### Practical scenarios  

| # | Scenario | Command | Metrics to watch |
|---|---|---|---|
| 1️⃣ | **Latency spike** | `bash scripts/01_run_latency.sh` | `p95/p99`, `RPS`, `active_transactions` |
| 2️⃣ | **Error rate rise** | `bash scripts/02_run_error_rate.sh` | `error_rate`, `status_5xx` |
| 3️⃣ | **Slow DB** | `bash scripts/03_run_db_slow.sh` | `db_latency`, `active_transactions` (growth) |
| 4️⃣ | **Memory leak** | `bash scripts/04_run_memory_leak.sh` | `memory_usage`, `container_restarts` |
| 5️⃣ | **Chaos mix** | `bash scripts/05_run_chaos_mix.sh` | All signals simultaneously (real‑world incident) |

**For each scenario:**  
1. Run the script → observe the “failure”.  
2. Open Grafana → watch metrics in real time.  
3. Identify the primary signal → investigate root cause.  
4. Execute `bash scripts/reset.sh` → restore baseline.

### ⚙️ Infrastructure management  

```bash
# Stop services (data persisted)
docker compose down

# Full cleanup (removes DB & metrics)
docker compose down -v

# Restart a single service
docker compose restart prometheus
```

### Running the scripts (ready‑made scenarios)

```bash
# Choose a scenario
bash scripts/01_run_latency.sh      # Latency
bash scripts/02_run_error_rate.sh   # Error Rate
bash scripts/03_run_db_slow.sh      # DB Slow
bash scripts/04_run_memory_leak.sh  # Memory Leak
bash scripts/05_run_chaos_mix.sh    # Chaos Mix

# Reset after any scenario
bash scripts/reset.sh
```

### Additional documentation  

- [Architecture & methodology](docs/architecture.md)  
- [Presentation description](docs/presentation.md)  
- [Coach guide](docs/coach-guide.md)  
- [Monitoring setup (Prometheus/Grafana)](docs/monitoring.md)  
- [Screenshots & examples](docs/screenshots.md)  
- [curl guide](docs/curl_guide.md)  
- [Script description](docs/scripts.md)  

### Practical case links  

- [Scenario 1: latency increase](docs/cases/01_latency.md)  
- [Scenario 2: error rate increase](docs/cases/02_error_rate.md)  
- [Scenario 3: slow database](docs/cases/03_db_slow.md)  
- [Scenario 4: memory leak](docs/cases/04_memory_leak.md)  
- [Scenario 5: combined chaos](docs/cases/05_chaos_mix.md)  

> **Note:** Some variables in `.env.example` are reserved for future extensions (frontend errors, security, etc.) and are not used in the current version of `app.py`.

### Quick pre‑demo checks  

```bash
# Verify everything is up
bash scripts/check_setup.sh

# Verify app health
curl -s http://localhost:5000/health | jq .

# Verify Prometheus gathers metrics
curl -s http://localhost:9090/api/v1/query?query=up | jq '.data.result[0]'

# Verify Grafana sees Prometheus
curl -s http://localhost:3000/api/datasources | jq '.[] | {name, url}'
```

### 📜 License  

MIT  

---  

*Feel free to open an issue or submit a pull request if you see any room for improvement – I’m always happy to collaborate!*
