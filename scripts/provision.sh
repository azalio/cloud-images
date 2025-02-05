#!/bin/bash

set -e

# Настройка времени и локали
sudo timedatectl set-timezone Europe/Moscow
sudo localectl set-locale LANG=en_US.UTF-8

# Обновляем систему и устанавливаем базовые утилиты
sudo apt-get update
sudo apt-get install -y curl vim net-tools
sudo apt-get clean
sudo rm -rf /var/lib/apt/lists/*

# Очистка истории
echo "Cleaning up..."
sudo rm -rf /root/.bash_history
sudo rm -rf /home/ubuntu/.bash_history
