# Macroses
########################################################################################################################
ROOT_DIR ?= $(PWD)
INFRA_DIR ?= $(ROOT_DIR)/.infra

ICMK_VERSION ?= master

# Tasks
########################################################################################################################
.PHONY: update
init: icmk.install
init.bootstrap: icmk.install examples.simple

icmk.install: $(INFRA_DIR)/icmk
$(INFRA_DIR)/icmk:
	$(GIT) clone https://github.com/hazelops/icmk.git $(INFRA_DIR)/icmk
	cd $(INFRA_DIR)/icmk && $(GIT) checkout $(ICMK_VERSION)
	@echo "Done!"

icmk.clean:
	@rm -rf $(INFRA_DIR)/icmk && echo "Cleaning Done"

icmk.update:
	cd $(INFRA_DIR)/icmk && $(GIT) fetch --all && $(GIT) checkout $(ICMK_VERSION)

examples.simple: confirm $(INFRA_DIR)/icmk
	@cp $(INFRA_DIR)/icmk/examples/simple/Makefile ./Makefile
	@cp $(INFRA_DIR)/icmk/examples/simple/.envrc-example .envrc-example
	@cp -R $(INFRA_DIR)/icmk/examples/simple/.infra/.gitignore $(INFRA_DIR)/
	@cp -R $(INFRA_DIR)/icmk/examples/simple/.infra/env $(INFRA_DIR)/

confirm:
	@echo "\033[31mAre you sure? [y/N]\033[0m" && read ans && [ $${ans:-N} = y ] || (echo "\033[32mCancelled.\033[0m" && exit 1)

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

ifndef ENV
$(error Please set ENV via `export ENV=<env_name>` or use direnv)
endif

ifndef AWS_PROFILE
$(error Please set AWS_PROFILE via `export AWS_PROFILE=<aws_profile>` or use direnv)
endif
