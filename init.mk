# Macroses
########################################################################################################################
ROOT_DIR ?= $(PWD)
INFRA_DIR ?= $(ROOT_DIR)/.infra

ICMK_VERSION ?= master

# Tasks
########################################################################################################################
.PHONY: update
init: install examples.simple
install: $(INFRA_DIR)/icmk
$(INFRA_DIR)/icmk:
	$(GIT) clone https://github.com/hazelops/icmk.git $(INFRA_DIR)/icmk
	cd $(INFRA_DIR)/icmk && $(GIT) checkout $(ICMK_VERSION)

clean:
	@rm -rf $(INFRA_DIR)/icmk && echo "Cleaning Done"

update:
	cd $(INFRA_DIR)/icmk && $(GIT) fetch --all && $(GIT) checkout $(ICMK_VERSION)

examples.simple: $(INFRA_DIR)/icmk
	cp $(INFRA_DIR)/icmk/examples/simple/Makefile ./Makefile
	cp $(INFRA_DIR)/icmk/examples/simple/.envrc-example .envrc-example
	cp -dR $(INFRA_DIR)/icmk/examples/simple/env $(INFRA_DIR)/

# TOOLS
GIT  ?= $(shell which git)

# Dependencies
########################################################################################################################
# Ensures docker is installed - does not enforce version, please use latest
git:
ifeq (, $(GIT))
	$(error "Docker is not installed or incorrectly configured. https://www.docker.com/")
#else
#	@$(DOCKER) --version
endif
