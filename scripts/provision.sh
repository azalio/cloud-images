#!/bin/bash -x

set -e

# Ожидаем полного завершения cloud-init
echo "Waiting for cloud-init to complete..."
sudo cloud-init status --wait >/dev/null 2>&1 || true

# Даем apt-демону завершить инициализацию
sudo systemctl is-active apt-daily.service >/dev/null && \
  sudo systemctl stop apt-daily.service

# Настройка времени и локали
sudo timedatectl set-timezone Europe/Moscow

# Обновляем систему и устанавливаем базовые утилиты
echo "Installing system packages..."
sudo apt-get update
sudo apt-get install -y curl vim net-tools
sudo apt-get clean
sudo rm -rf /var/lib/apt/lists/*

# Очистка истории
echo "Cleaning up..."
sudo rm -rf /root/.bash_history
sudo rm -rf /home/ubuntu/.bash_history
