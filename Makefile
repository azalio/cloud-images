PACKER_TEMPLATE := ubuntu-24-cilium.pkr.hcl

OUTPUT_DIR := output

SSH_KEY_NAME := packer-key

.PHONY: all build clean generate-key check check-auto

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

check:
	@echo "Starting VM for testing..."
	@echo "Close the VM window manually after checks"
	qemu-system-x86_64 \
		-m 4G \
		-smp 4 \
		-drive file=$(OUTPUT_DIR)/packer-ubuntu,format=qcow2 \
		-nic user,hostfwd=tcp:127.0.0.1:60022-:22 \
		-nographic

check-auto:
	@echo "Starting VM in background..."
	@OBJC_DISABLE_INITIALIZE_FORK_SAFETY=YES qemu-system-x86_64 \
		-m 4G \
		-smp 4 \
		-drive file=$(OUTPUT_DIR)/packer-ubuntu,format=qcow2 \
		-nic user,hostfwd=tcp:127.0.0.1:60022-:22 \
		-daemonize
	@echo "Waiting 30s for VM to boot..."
	@sleep 30
	@echo "Waiting for SSH connection..."
	@until ssh -q -o ConnectTimeout=2 \
		-o StrictHostKeyChecking=no \
		-o UserKnownHostsFile=/dev/null \
		-o GlobalKnownHostsFile=/dev/null \
		-i $(SSH_KEY_NAME) ubuntu@localhost -p 60022 exit; do \
		sleep 5; \
		echo "Retrying SSH connection..."; \
	done
	@ssh -o StrictHostKeyChecking=no \
		-o UserKnownHostsFile=/dev/null \
		-o GlobalKnownHostsFile=/dev/null \
		-i $(SSH_KEY_NAME) \
		ubuntu@localhost -p 60022 \
		"export KUBECONFIG=.kube/config; kubectl cluster-info && cilium version"
	@echo "Stopping VM..."
	@pkill qemu-system-x86_64 || true

clean:
	@echo "Cleaning build directory: $(OUTPUT_DIR) and SSH keys"
	rm -rf $(OUTPUT_DIR) $(SSH_KEY_NAME)*

