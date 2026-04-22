<<<<<<< HEAD
FROM python:3.9-slim
=======
FROM public.ecr.aws/docker/library/python:3.9-slim
>>>>>>> ef52d2375bbdea727f2f4ea0b5a483547b753eed

# Установка wget для healthcheck
RUN apt-get update && apt-get install -y wget && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

# Запуск приложения Flask
CMD ["python", "app.py"]
