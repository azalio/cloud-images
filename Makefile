PACKER_TEMPLATE := ubuntu-24-cilium-amd64.pkr.hcl

OUTPUT_DIR := output

SSH_KEY_NAME := packer-key

# SSH options for automation
SSH_OPTS := -o StrictHostKeyChecking=no \
            -o UserKnownHostsFile=/dev/null \
            -o GlobalKnownHostsFile=/dev/null \
            -o ConnectTimeout=5
SSH_PORT := 60022

QEMU_CMD := qemu-system-x86_64

.PHONY: all build clean generate-key check-auto

all: build

generate-key:
	@echo "Generating new SSH key..."
	@rm -rf packer-key
	ssh-keygen -t ed25519 -f $(SSH_KEY_NAME) -q -N ""

build: clean generate-key
	@echo "Starting image build..."
	@echo "Generating cloud-init config..."
	@mkdir -p cloud-init
	@sed "s|__REPLACE_ME__|$(shell cat $(SSH_KEY_NAME).pub)|" templates/cloud-init/user-data.tpl > cloud-init/user-data
	@echo "Validating Packer template..."
	packer validate $(PACKER_TEMPLATE)
	PACKER_LOG=1 packer build $(PACKER_TEMPLATE)

check-auto:
	@echo "[$(shell date +%T)] Starting QEMU VM in background..."
	@OBJC_DISABLE_INITIALIZE_FORK_SAFETY=YES $(QEMU_CMD) \
		-m 4G \
		-smp 4 \
		-drive file=$(OUTPUT_DIR)/packer-ubuntu,format=qcow2 \
		-nic user,hostfwd=tcp:127.0.0.1:60022-:22 \
		-daemonize
	@echo "[$(shell date +%T)] Waiting 30s for VM to boot..."
	@sleep 30
	@echo "[$(shell date +%T)] Waiting for SSH readiness..."
	@until ssh -q $(SSH_OPTS) -i $(SSH_KEY_NAME) ubuntu@localhost -p $(SSH_PORT) exit; do \
		sleep 5; \
		echo "[$(shell date +%T)] Retrying SSH..."; \
	done
	@echo "[$(shell date +%T)] Testing Kubernetes cluster..."
	@ssh $(SSH_OPTS) -i $(SSH_KEY_NAME) ubuntu@localhost -p $(SSH_PORT) \
		"export KUBECONFIG=.kube/config; sudo systemctl status k3s; kubectl cluster-info ; cilium version"
	@echo "[$(shell date +%T)] Tests passed!"
	@echo "[$(shell date +%T)] Stopping VM..."
	@pkill $(QEMU_CMD) || true

output/packer-ubuntu: build
	@echo "[$(shell date +%T)] Image verified: $@"

ssh:
	@if [ ! -f "output/packer-ubuntu" ]; then \
		echo "[$(shell date +%T)] Image not found - starting build..."; \
		make build || exit 1; \
	fi

	@echo sleep 60

	@echo "Starting SSH session with auto-built image"
	@echo "[$(shell date +%T)] Starting QEMU VM in background..."
	@OBJC_DISABLE_INITIALIZE_FORK_SAFETY=YES $(QEMU_CMD) \
		-m 8G \
		-smp 8 \
		-nographic -serial none -monitor none \
		-drive file=$(OUTPUT_DIR)/packer-ubuntu,format=qcow2 \
		-nic user,hostfwd=tcp:127.0.0.1:60022-:22 &
	@echo "[$(shell date +%T)] Waiting for SSH connection..."
	@until ssh -q $(SSH_OPTS) -i $(SSH_KEY_NAME) ubuntu@localhost -p $(SSH_PORT) exit; do sleep 1; done
	@ssh $(SSH_OPTS) -i $(SSH_KEY_NAME) ubuntu@localhost -p $(SSH_PORT) || true
	@echo "[$(shell date +%T)] Stopping VM..."; pkill -f "$(QEMU_CMD).*$(OUTPUT_DIR)/packer-ubuntu" || true

upload-image: output/packer-ubuntu
	@echo "[$(shell date +%T)] Uploading image to Git LFS..."
	@git lfs track "output/packer-ubuntu"
	@git add .gitattributes output/packer-ubuntu
	@git commit -m "Add new image built on $(shell date +%Y-%m-%d)"
	@git push origin main
	@echo "[$(shell date +%T)] Image uploaded to Git LFS."

clean:
	@echo "Cleaning build directory: $(OUTPUT_DIR) and SSH keys"
	rm -rf $(OUTPUT_DIR) $(SSH_KEY_NAME)*

