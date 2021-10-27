#### Getting OS|Linux info
OS_NAME ?= shell uname -s
TMPDIR ?= "/tmp"

#### IZE Download script
CMD_DOWNLOAD_IZE = curl https://hazelops-ize-bin.s3.amazonaws.com/$(OS_NAME)/ize -o $(TMPDIR)/ize

#### IZE Install script
CMD_INSTALL_IZE = chmod +x $(TMPDIR)/ize && mv $(TMPDIR)/ize /usr/local/bin/ize

# Tasks
########################################################################################################################
ize.install:
	@$(CMD_DOWNLOAD_IZE) && \
	$(CMD_INSTALL_IZE) && \
	@echo "\n\033[32m[OK]\033[0m IZE installation successful."

ize.check:
ifeq (, $(shell which ize))
	@echo "\033[31m[FAILED]\033[0m IZE is not installed or incorrectly configured.\n You can download IZE \033[34mhttps://github.com/hazelops/ize/releases\033[0m \n and install it manually."
else
	@echo "\n\033[32m[OK]\033[0m IZE is installed."
endif
