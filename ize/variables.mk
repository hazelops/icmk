# This file should contain variables used in current module
##################################################################
#### Default settings for IZE
MACOS_ARCH_NAME = $(shell uname -m)
MACOS_ARCH = $(shell echo $$(if [ "$(MACOS_ARCH_NAME)" = "x86_64" ]; then echo "amd64"; else echo "arm64"; fi))
LINUX_ARCH = 
IZE_DIR ?= $(INFRA_DIR)/bin
TMPDIR ?= /tmp
IZE_VERSION ?= 0.1.0
MACOS_ARCHIVE_NAME = ize_$(IZE_VERSION)_$(OS_NAME)_$(MACOS_ARCH).tar.gz
LINUX_ARCHIVE_NAME = ize_$(IZE_VERSION)_$(OS_NAME)_$(ARCH).tar.gz
IZE_ARCHIVE_NAME ?= $(shell echo $$(if [ "$(OS_NAME)" = "Linux" ]; then echo "$(LINUX_ARCHIVE_NAME)"; else echo "$(MACOS_ARCHIVE_NAME)"; fi))
IZE_DOWNLOAD_URL = https://github.com/hazelops/ize/releases/download/$(IZE_VERSION)/$(IZE_ARCHIVE_NAME)
