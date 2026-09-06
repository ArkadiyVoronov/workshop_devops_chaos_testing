#!/bin/bash
set -e

echo "=========================================="
echo "Пример 2.2: Variables and Outputs"
echo "=========================================="
echo ""

cd "$(dirname "$0")"

# Очистка
if [ -f "terraform.tfstate" ]; then
    echo "🧹 Очистка предыдущего состояния..."
    terraform destroy -auto-approve 2>/dev/null || true
    rm -f terraform.tfstate terraform.tfstate.backup terraform.lock.hcl *.tfvars
    rm -rf .terraform/
fi

echo "📦 Шаг 1: Инициализация"
echo "-------------------------------------------"
terraform init
echo ""

echo "✅ Шаг 2: Проверка конфигурации"
echo "-------------------------------------------"
terraform validate
echo ""

echo "📋 Шаг 3: Plan с значениями по умолчанию"
echo "-------------------------------------------"
terraform plan
echo ""

echo "🚀 Шаг 4: Apply с значениями по умолчанию"
echo "-------------------------------------------"
terraform apply -auto-approve
echo ""

echo "📊 Шаг 5: Вывод результатов"
echo "-------------------------------------------"
terraform output
echo ""

echo "🔄 Шаг 6: Демонстрация переопределения переменных"
echo "-------------------------------------------"
echo "Создаем файл custom.tfvars..."
cat > custom.tfvars <<EOF
project_name = "production-app"
environment  = "staging"
instance_count = 3
instance_type = "t3.small"
enabled_features = ["monitoring", "backup", "logging"]
custom_tags = {
  CostCenter = "engineering"
  Team       = "platform"
}
EOF

echo "Запускаем plan с кастомными переменными..."
terraform plan -var-file="custom.tfvars"
echo ""

echo "💡 Примечание: Для применения с кастомными переменными используйте:"
echo "   terraform apply -var-file=\"custom.tfvars\""
echo ""

echo "🧹 Шаг 7: Очистка"
echo "-------------------------------------------"
# Автоматическая очистка для демонстрации
terraform destroy -auto-approve
rm -f custom.tfvars

echo ""
echo "=========================================="
echo "Пример завершен!"
echo "=========================================="
