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
sudo apt-get install --no-install-recommends -y \
    curl ca-certificates iptables-persistent
sudo apt-get clean
sudo rm -rf /var/lib/apt/lists/*
 
# Устанавливаем k3s без flannel, kube-proxy и network-policy
echo "Installing k3s..."
curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC='--flannel-backend=none --disable-network-policy --disable-kube-proxy' sh -
sleep 15 # Даем время на установку k3s

# Устанавливаем cilium CLI
echo "Configuring kubeconfig..."
export KUBECONFIG=~/.kube/config
mkdir -p ~/.kube
sudo k3s kubectl config view --raw > "$KUBECONFIG"
chmod 600 "$KUBECONFIG"
echo "export KUBECONFIG=$KUBECONFIG" >> ~/.bashrc

echo "Installing Cilium CLI..."
# shellcheck disable=SC2155
export CILIUM_CLI_VERSION=$(curl -s https://raw.githubusercontent.com/cilium/cilium-cli/main/stable.txt)
# shellcheck disable=SC2155
export GOOS=$(go env GOOS)
# shellcheck disable=SC2155
export GOARCH=$(go env GOARCH)
curl -L --remote-name-all "https://github.com/cilium/cilium-cli/releases/download/${CILIUM_CLI_VERSION}/cilium-${GOOS}-${GOARCH}.tar.gz{,.sha256sum}"
sha256sum --check "cilium-${GOOS}-${GOARCH}.tar.gz.sha256sum"
sudo tar -C /usr/local/bin -xzvf "cilium-${GOOS}-${GOARCH}.tar.gz"
rm "cilium-${GOOS}-${GOARCH}.tar.gz" "cilium-${GOOS}-${GOARCH}.tar.gz.sha256sum"

# Предзагружаем образы Cilium
echo "Preloading Cilium images..."
sudo ctr image pull quay.io/cilium/cilium:v1.16.6@sha256:1e0896b1c4c188b4812c7e0bed7ec3f5631388ca88325c1391a0ef9172c448da
sudo ctr image pull quay.io/cilium/operator-generic:v1.16.6@sha256:13d32071d5a52c069fb7c35959a56009c6914439adc73e99e098917646d154fc
sudo ctr image pull quay.io/cilium/cilium-envoy:v1.30.9-1737073743-40a016d11c0d863b772961ed0168eea6fe6b10a5@sha256:a69dfe0e54b24b0ff747385c8feeae0612cfbcae97bfcc8ee42a773bb3f69c88

# Проверка установки
echo "Verifications:"
cilium version
sudo ctr images ls
kubectl get nodes -o wide

# Удаление ненужных пакетов
sudo apt-get purge -y golang
sudo apt-get autoremove -y

# Глубокая очистка
echo "Deep cleaning..."
sudo apt-get autoremove -y
sudo apt-get clean
sudo rm -rf /var/lib/apt/lists/*
sudo rm -rf /usr/share/doc/*
sudo rm -rf /usr/share/man/*
sudo find /var/log -type f -exec truncate -s 0 {} \;

# Очистка истории
echo "Cleaning up..."
sudo rm -rf /root/.bash_history
sudo rm -rf /home/ubuntu/.bash_history

# Финализация
echo "Setup completed!"
echo "Kubernetes cluster info:"
kubectl cluster-info
