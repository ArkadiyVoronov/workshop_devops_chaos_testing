#!/bin/bash
set -e

echo "=========================================="
echo "Пример 2.3: State Management"
echo "=========================================="
echo ""

cd "$(dirname "$0")"

# Очистка
if [ -f "terraform.tfstate" ]; then
    echo "🧹 Очистка предыдущего состояния..."
    terraform destroy -auto-approve 2>/dev/null || true
    rm -f terraform.tfstate terraform.tfstate.backup terraform.lock.hcl
    rm -rf .terraform/
fi

echo "📦 Шаг 1: Инициализация"
echo "-------------------------------------------"
terraform init
echo ""

echo "🚀 Шаг 2: Создание ресурсов"
echo "-------------------------------------------"
terraform apply -auto-approve
echo ""

echo "💾 Шаг 3: Просмотр state файла"
echo "-------------------------------------------"
echo "Содержимое terraform.tfstate (первые 50 строк):"
head -50 terraform.tfstate
echo ""

echo "📋 Шаг 4: Список ресурсов в state"
echo "-------------------------------------------"
terraform state list
echo ""

echo "🔍 Шаг 5: Детали ресурса"
echo "-------------------------------------------"
echo "terraform state show null_resource.resource1:"
terraform state show null_resource.resource1
echo ""

echo "🔄 Шаг 6: Refresh состояния"
echo "-------------------------------------------"
terraform refresh
echo ""

echo "💾 Шаг 7: Проверка backup файла"
echo "-------------------------------------------"
if [ -f "terraform.tfstate.backup" ]; then
    echo "✅ Backup файл создан: terraform.tfstate.backup"
    echo "Размер backup: $(wc -c < terraform.tfstate.backup) байт"
else
    echo "⚠️ Backup файл не найден"
fi
echo ""

echo "📊 Шаг 8: Pull state"
echo "-------------------------------------------"
terraform state pull | head -30
echo ""

echo "✅ Все команды state выполнены успешно!"
echo ""

echo "🧹 Шаг 9: Очистка"
echo "-------------------------------------------"
terraform destroy -auto-approve
rm -f terraform.tfstate terraform.tfstate.backup

echo ""
echo "=========================================="
echo "Пример завершен!"
echo "=========================================="
