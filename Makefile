# Makefile для сборки образа с помощью Packer

# Имя файла шаблона Packer
PACKER_TEMPLATE := ubuntu-24-cilium.pkr.hcl

# Каталог, куда Packer будет сохранять выходной образ
OUTPUT_DIR := output-ubuntu-24.04-kubevirt

# Имя SSH ключа
SSH_KEY_NAME := packer-key

.PHONY: all build clean generate-key

all: build

generate-key:
	@echo "Generating new SSH key..."
	ssh-keygen -t ed25519 -f $(SSH_KEY_NAME) -q -N ""

build: generate-key
	@echo "Запуск сборки образа по шаблону $(PACKER_TEMPLATE)..."
	# Запуск Packer с логированием
	PACKER_LOG=1 packer build $(PACKER_TEMPLATE)

clean:
	@echo "Очистка каталога сборки: $(OUTPUT_DIR) и SSH ключей"
	rm -rf $(OUTPUT_DIR) $(SSH_KEY_NAME)*

