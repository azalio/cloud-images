# Makefile для сборки образа с помощью Packer

# Имя файла шаблона Packer
PACKER_TEMPLATE := ubuntu-24-cilium.pkr.hcl

# Каталог, куда Packer будет сохранять выходной образ
OUTPUT_DIR := output

# Имя SSH ключа
SSH_KEY_NAME := packer-key

.PHONY: all build clean generate-key

all: build

generate-key:
	@echo "Generating new SSH key..."
	@rm -rf packer-key
	ssh-keygen -t ed25519 -f $(SSH_KEY_NAME) -q -N ""

build: generate-key
	@echo "Запуск сборки образа..."
	@echo "Generating cloud-init config..."
	@mkdir -p cloud-init
	@sed "s|__REPLACE_ME__|$(shell cat $(SSH_KEY_NAME).pub)|" templates/cloud-init/user-data.tpl > cloud-init/user-data
	@echo "Validating Packer template..."
	packer validate $(PACKER_TEMPLATE)
	PACKER_LOG=1 packer build $(PACKER_TEMPLATE)

check:
	qemu-system-x86_64 -m 4G -smp 4 -drive file=output/packer-ubuntu,format=qcow2

clean:
	@echo "Очистка каталога сборки: $(OUTPUT_DIR) и SSH ключей"
	rm -rf $(OUTPUT_DIR) $(SSH_KEY_NAME)*

