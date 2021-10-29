#### IZE Download script
CMD_DOWNLOAD_IZE = curl -s $(IZE_DOWNLOAD_URL) -o "$(TMPDIR)/$(OS_NAME).zip" && unzip -qq -o "$(TMPDIR)/$(OS_NAME).zip" -d "$(IZE_DIR)" && rm "$(TMPDIR)/$(OS_NAME).zip"

#### IZE Install script
CMD_INSTALL_IZE =  chmod +x $(IZE_DIR)/ize

# Tasks
########################################################################################################################
ize.install:
	@$(CMD_DOWNLOAD_IZE) && \
	$(CMD_INSTALL_IZE) && \
	@echo "\n\033[32m[OK]\033[0m IZE successfully installed"
