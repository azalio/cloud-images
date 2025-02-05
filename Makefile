# Makefile для сборки образа с помощью Packer

# Имя файла шаблона Packer
PACKER_TEMPLATE := ubuntu-24-cilium.pkr.hcl

# Каталог, куда Packer будет сохранять выходной образ
OUTPUT_DIR := output-ubuntu-24.04-kubevirt

.PHONY: all build clean

all: build

build:
	@echo "Запуск сборки образа по шаблону $(PACKER_TEMPLATE)..."
	# Запуск Packer с логированием
	PACKER_LOG=1 packer build $(PACKER_TEMPLATE)

clean:
	@echo "Очистка каталога сборки: $(OUTPUT_DIR)"
	rm -rf $(OUTPUT_DIR)

