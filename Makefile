# Makefile для сборки образа с помощью Packer

# Имя файла шаблона Packer
PACKER_TEMPLATE := ubuntu-24-cilium.pkr.hcl

# Каталог, куда Packer будет сохранять выходной образ
OUTPUT_DIR := output-ubuntu-24.04-kubevirt

# Файл с публичным ключом SSH
SSH_PUBLIC_KEY_FILE := packer-key.pub

# Файл с данными для cloud-init
USER_DATA_FILE := cloud-init/user-data

.PHONY: all build clean

all: build

build:
	@echo "Запуск сборки образа по шаблону $(PACKER_TEMPLATE)..."
	# Читаем содержимое публичного ключа SSH и заменяем SSH_PUBLIC_KEY в user-data файле
	sed "s/SSH_PUBLIC_KEY/$(shell cat $(SSH_PUBLIC_KEY_FILE))/" $(USER_DATA_FILE) > $(USER_DATA_FILE).tmp
	# Перемещаем временный файл обратно в user-data
	mv $(USER_DATA_FILE).tmp $(USER_DATA_FILE)
	# Запуск Packer с логированием
	PACKER_LOG=1 packer build $(PACKER_TEMPLATE)

clean:
	@echo "Очистка каталога сборки: $(OUTPUT_DIR)"
	rm -rf $(OUTPUT_DIR)

