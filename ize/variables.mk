# This file should contain variables used in current module
##################################################################
#### Default settings for IZE
MACOS_BITS ?= $(shell uname -m | sed 's/x86_//;s/i[3-6]86/32/')
IZE_DIR ?= $(INFRA_DIR)/bin
TMPDIR ?= /tmp
IZE_VERSION ?= 0.1.0
IZE_ARCHIVE_NAME = ize_$(IZE_VERSION)_$(OS_NAME)_$(ARCH).tar.gz
IZE_DOWNLOAD_URL = https://github.com/hazelops/ize/releases/download/$(IZE_VERSION)/$(IZE_ARCHIVE_NAME)