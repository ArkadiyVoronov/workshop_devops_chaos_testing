FROM python:3.9-slim

# Установка wget для healthcheck (curl часто нет в slim образах)
RUN apt-get update && apt-get install -y wget && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

# Команда запуска твоего приложения
# Замени на свою, например: uvicorn main:app --host 0.0.0.0 --port 5000
CMD ["python", "main.py"]
