FROM public.ecr.aws/docker/library/python:3.9-slim

# Установка wget для healthcheck
RUN apt-get update && apt-get install -y wget && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

# Запуск приложения Flask
CMD ["python", "app.py"]
