# Пример 2.1: Basic Resource - Синтаксис и структура

#!/bin/bash
set -e

echo "=========================================="
echo "Пример 2.1: Basic Resource"
echo "=========================================="
echo ""

cd "$(dirname "$0")"

# Очистка от предыдущих запусков
if [ -f "terraform.tfstate" ]; then
    echo "🧹 Очистка предыдущего состояния..."
    terraform destroy -auto-approve 2>/dev/null || true
    rm -f terraform.tfstate terraform.tfstate.backup terraform.lock.hcl
    rm -rf .terraform/
fi

echo "📦 Шаг 1: Инициализация Terraform"
echo "-------------------------------------------"
terraform init
echo ""

echo "✅ Шаг 2: Проверка конфигурации"
echo "-------------------------------------------"
terraform validate
echo ""

echo "📋 Шаг 3: Просмотр плана (что будет создано)"
echo "-------------------------------------------"
terraform plan
echo ""

echo "🚀 Шаг 4: Применение конфигурации"
echo "-------------------------------------------"
terraform apply -auto-approve
echo ""

echo "💾 Шаг 5: Проверка состояния"
echo "-------------------------------------------"
terraform show
echo ""

echo "📊 Шаг 6: Вывод результатов"
echo "-------------------------------------------"
terraform output
echo ""

echo "🔄 Шаг 7: Демонстрация идемпотентности"
echo "-------------------------------------------"
echo "Запускаем plan повторно - должно быть 'No changes':"
terraform plan
echo ""

echo "🧹 Шаг 8: Очистка (опционально)"
echo "-------------------------------------------"
read -p "Удалить созданную инфраструктуру? (y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    terraform destroy -auto-approve
fi

echo ""
echo "=========================================="
echo "Пример завершен!"
echo "=========================================="
