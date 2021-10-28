#### Default settings for IZE
IZE_DIR ?= $(INFRA_DIR)/bin
TMPDIR ?= "/tmp"
IZE_RELEASE ?= "v0.0.1"
IZE_DOWNLOAD_URL = "https://hazelops-ize-bin.s3.amazonaws.com/hazelops/ize/releases/download/$(IZE_RELEASE)/$(OS_NAME).zip"

#### IZE Download script
CMD_DOWNLOAD_IZE = curl -s $(IZE_DOWNLOAD_URL) -o "$(TMPDIR)/$(OS_NAME).zip" && unzip -qq -o "$(TMPDIR)/$(OS_NAME).zip" -d "$(IZE_DIR)" && rm "$(TMPDIR)/$(OS_NAME).zip"

#### IZE Install script
CMD_INSTALL_IZE =  chmod +x $(IZE_DIR)/ize

# Tasks
########################################################################################################################
ize.install:
	@$(CMD_DOWNLOAD_IZE) && \
	$(CMD_INSTALL_IZE)
	@echo "\n\033[32m[OK]\033[0m IZE successfully installed"
