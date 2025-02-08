#!/bin/bash -x

set -e

# Wait for full cloud-init completion
echo "Waiting for cloud-init to complete..."
sudo cloud-init status --wait >/dev/null 2>&1 || true

# Let apt-daemon finish initialization
sudo systemctl is-active apt-daily.service >/dev/null && \
  sudo systemctl stop apt-daily.service

# Configure timezone and locale
sudo timedatectl set-timezone Europe/Moscow

# Update system and install basic utilities
echo "Installing system packages..."
sudo apt-get update
sudo apt-get install --no-install-recommends -y \
    curl ca-certificates iptables-persistent golang less vim gpg strace

# containerD 
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Add the repository to Apt sources:
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt-get update
sudo apt install containerd.io

# enable cri and SystemdCgroup
containerd config dump | sudo tee /etc/containerd/config.toml
sudo sed -i 's/^disabled_plugins = \["cri"\]$/#&/' /etc/containerd/config.toml
sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml
sudo sed -i 's/pause:3.8/pause:3.10/' /etc/containerd/config.toml

sudo sed -i 's/^#\(net\.ipv4\.ip_forward=1\)$/\1/' /etc/sysctl.d/99-sysctl.conf
echo 1 | sudo tee /proc/sys/net/ipv4/ip_forward

sudo systemctl enable containerd
sudo systemctl restart containerd

#kubeadm 

curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.32/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.32/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list
sudo apt-get update

sudo apt-get install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl

sudo systemctl enable --now kubelet

sudo kubeadm init

# cilium
curl https://baltocdn.com/helm/signing.asc | gpg --dearmor | sudo tee /usr/share/keyrings/helm.gpg > /dev/null
sudo apt-get install apt-transport-https --yes
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/helm.gpg] https://baltocdn.com/helm/stable/debian/ all main" | sudo tee /etc/apt/sources.list.d/helm-stable-debian.list
sudo apt-get update
sudo apt-get install helm

mkdir .kube
sudo cp /etc/kubernetes/super-admin.conf .kube/config
sudo chmod 640 /home/ubuntu/.kube/config
sudo chgrp adm .kube/config
unset KUBECONFIG

CILIUM_CLI_VERSION=$(curl -s https://raw.githubusercontent.com/cilium/cilium-cli/main/stable.txt)
CLI_ARCH=amd64
if [ "$(uname -m)" = "aarch64" ]; then CLI_ARCH=arm64; fi
curl -L --fail --remote-name-all https://github.com/cilium/cilium-cli/releases/download/${CILIUM_CLI_VERSION}/cilium-linux-${CLI_ARCH}.tar.gz{,.sha256sum}
sha256sum --check cilium-linux-${CLI_ARCH}.tar.gz.sha256sum
sudo tar xzvfC cilium-linux-${CLI_ARCH}.tar.gz /usr/local/bin
rm cilium-linux-${CLI_ARCH}.tar.gz{,.sha256sum}

cilium install --version 1.16.6
# TODO - timeouts in health


cilium status --wait

# helm repo add cilium https://helm.cilium.io/
# helm install cilium cilium/cilium --version 1.16.6 --namespace kube-system

# # Install k3s without flannel, kube-proxy, and network-policy
# echo "Installing k3s..."
# # curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC='--flannel-backend=none --disable-network-policy --disable-kube-proxy' sh -
# curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC='--flannel-backend=none --disable-network-policy' sh -

# sleep 15 # Allow time for k3s installation

# echo "Configuring kubeconfig..."
# export KUBECONFIG=~/.kube/config
# mkdir -p ~/.kube
# # shellcheck disable=SC2024
# sudo k3s kubectl config view --raw > "$KUBECONFIG"
# chmod 600 "$KUBECONFIG"
# echo "export KUBECONFIG=$KUBECONFIG" >> ~/.bashrc

# echo "Installing Cilium CLI..."
# # shellcheck disable=SC2155
# export CILIUM_CLI_VERSION=$(curl -s https://raw.githubusercontent.com/cilium/cilium-cli/main/stable.txt)
# # shellcheck disable=SC2155
# export GOOS=$(go env GOOS)
# # shellcheck disable=SC2155
# export GOARCH=$(go env GOARCH)
# curl -L --remote-name-all "https://github.com/cilium/cilium-cli/releases/download/${CILIUM_CLI_VERSION}/cilium-${GOOS}-${GOARCH}.tar.gz{,.sha256sum}"
# sha256sum --check "cilium-${GOOS}-${GOARCH}.tar.gz.sha256sum"
# sudo tar -C /usr/local/bin -xzvf "cilium-${GOOS}-${GOARCH}.tar.gz"
# rm "cilium-${GOOS}-${GOARCH}.tar.gz" "cilium-${GOOS}-${GOARCH}.tar.gz.sha256sum"

# echo "Preloading Cilium images..."
# sudo ctr image pull quay.io/cilium/cilium:v1.16.6@sha256:1e0896b1c4c188b4812c7e0bed7ec3f5631388ca88325c1391a0ef9172c448da
# sudo ctr image pull quay.io/cilium/operator-generic:v1.16.6@sha256:13d32071d5a52c069fb7c35959a56009c6914439adc73e99e098917646d154fc
# sudo ctr image pull quay.io/cilium/cilium-envoy:v1.30.9-1737073743-40a016d11c0d863b772961ed0168eea6fe6b10a5@sha256:a69dfe0e54b24b0ff747385c8feeae0612cfbcae97bfcc8ee42a773bb3f69c88

# echo "Verifications:"
# cilium version
# # sudo ctr images ls
# kubectl get nodes -o wide

# cilium install --version 1.16.6 --set=ipam.operator.clusterPoolIPv4PodCIDRList="10.42.0.0/16"




echo "Deep cleaning..."
sudo apt-get purge -y golang
sudo apt-get autoremove -y
sudo apt-get clean
sudo rm -rf /var/lib/apt/lists/*
sudo rm -rf /usr/share/doc/*
sudo rm -rf /usr/share/man/*
sudo find /var/log -type f -exec truncate -s 0 {} \;

echo "Cleaning up..."
sudo rm -rf /root/.bash_history
sudo rm -rf /home/ubuntu/.bash_history

echo "Setup completed!"
echo "Kubernetes cluster info:"
# kubectl cluster-info
