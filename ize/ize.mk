#### Getting OS|Linux info
OS_NAME ?= shell uname -s
TMPDIR ?= "/tmp"

#### IZE Download script
CMD_DOWNLOAD_IZE = curl https://hazelops-ize-bin.s3.amazonaws.com/$(OS_NAME)/ize -o $(TMPDIR)/ize

#### IZE Install script
CMD_INSTALL_IZE = chmod +x $(TMPDIR)/ize && mv $(TMPDIR)/ize /usr/local/bin/ize

# Tasks
########################################################################################################################
ize.download:
	@$(CMD_DOWNLOAD_IZE)
ize.install:
	@$(CMD_INSTALL_IZE)
