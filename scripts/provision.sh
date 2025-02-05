#!/bin/bash

set -e

# Обновляем систему и устанавливаем базовые утилиты
sudo apt-get update
sudo apt-get install -y curl vim net-tools
sudo apt-get clean
sudo rm -rf /var/lib/apt/lists/*
