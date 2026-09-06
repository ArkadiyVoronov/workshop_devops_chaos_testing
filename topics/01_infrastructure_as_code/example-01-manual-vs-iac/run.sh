#!/bin/bash
# Скрипт для быстрого запуска примера 01

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TF_DIR="$SCRIPT_DIR/terraform-config"

echo "🚀 Запуск примера: Manual vs IaC"
echo "=================================="
echo ""

cd "$TF_DIR"

echo "1️⃣  Инициализация Terraform..."
terraform init -input=false

echo ""
echo "2️⃣  Проверка конфигурации (validate)..."
terraform validate

echo ""
echo "3️⃣  Просмотр плана (plan)..."
terraform plan -out=tfplan

echo ""
echo "4️⃣  Применение (apply)..."
terraform apply -auto-approve tfplan

echo ""
echo "5️⃣  Демонстрация идемпотентности (повторный plan)..."
echo "   Ожидаемый результат: 'No changes'"
terraform plan

echo ""
echo "6️⃣  Очистка (destroy)..."
terraform destroy -auto-approve

echo ""
echo "✅ Пример завершён успешно!"
echo ""
echo "💡 Ключевые моменты:"
echo "   - Декларативный подход: описали ЧТО хотим, а не КАК"
echo "   - Идемпотентность: повторный запуск не меняет результат"
echo "   - State file: Terraform помнит состояние ресурсов"
