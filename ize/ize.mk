#### IZE Download script
CMD_DOWNLOAD_IZE = curl -L $(IZE_DOWNLOAD_URL) -o $(TMPDIR)/$(IZE_ARCHIVE_NAME) && tar -xvzf  $(TMPDIR)/$(IZE_ARCHIVE_NAME) -C $(IZE_DIR) && rm $(TMPDIR)/$(IZE_ARCHIVE_NAME)

#### IZE Install script
CMD_INSTALL_IZE =  chmod +x $(IZE_DIR)/ize

#### Create IZE folder
CMD_CREATE_IZE_FOLDER = mkdir -p $(IZE_DIR)

# Tasks
########################################################################################################################
ize.install:
	@$(CMD_CREATE_IZE_FOLDER) && \
	echo "\n\033[33m[...]\033[0m IZE downloading" && \
	$(CMD_DOWNLOAD_IZE) && \
	echo "\n\033[32m[OK]\033[0m IZE downloaded successfully" && \
	$(CMD_INSTALL_IZE) && \
	echo "\n\033[32m[OK]\033[0m IZE successfully installed"
