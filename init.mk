# Macroses
########################################################################################################################
ROOT_DIR ?= $(shell pwd)
INFRA_DIR ?= $(ROOT_DIR)/.infra

ICMK_VERSION ?= origin/master
ICMK_REPO ?= https://github.com/hazelops/icmk.git
ICMK_GIT_REVISION = $(shell cd $(INFRA_DIR)/icmk && $(GIT) rev-parse HEAD) $(shell cd $(INFRA_DIR)/icmk && $(GIT) describe --tags)

# Tasks
########################################################################################################################
.PHONY: update
init: icmk.install
init.bootstrap: icmk.install examples.simple

icmk.install: $(INFRA_DIR)/icmk
$(INFRA_DIR)/icmk:
	@echo "Installing icmk from $(ICMK_VERSION)"
	mkdir -p $(INFRA_DIR) && cd $(INFRA_DIR) && $(GIT) submodule add $(ICMK_REPO) icmk
	cd $(INFRA_DIR)/icmk && $(GIT) fetch --all && $(GIT) reset $(ICMK_VERSION) --hard
	@rm -f $(TMPDIR)/icmk.mk && rm -f $(TMPDIR)/icmk.mk
	@echo "Done!"

icmk.clean:
	@rm -rf $(INFRA_DIR)/icmk && echo "Cleaning Done"

icmk.update: ## Updates ICMK
	@[ -d "$(INFRA_DIR)/icmk" ] && (cd $(INFRA_DIR)/icmk && $(GIT) fetch --all --tags && $(GIT) reset $(ICMK_VERSION) --hard && $(GIT) checkout $(ICMK_VERSION)) || (echo "No ICMK installed. Please install it first." && exit 1)

icmk.update-init: ## Updates ICMK with a remote init script
	@echo Updating via new init from https://hzl.xyz/icmk
	@make icmk.update -f $$(curl -Ls https://hzl.xyz/icmk > $$TMPDIR/icmk.mk && echo "$$TMPDIR/icmk.mk")

examples.simple: confirm $(INFRA_DIR)/icmk
	@cp $(INFRA_DIR)/icmk/examples/simple/Makefile ./Makefile
	@cp $(INFRA_DIR)/icmk/examples/simple/.envrc-example .envrc-example
	@cp -R $(INFRA_DIR)/icmk/examples/simple/.infra/.gitignore $(INFRA_DIR)/
	@cp -R $(INFRA_DIR)/icmk/examples/simple/.infra/env $(INFRA_DIR)/

confirm:
	@echo "\033[31mAre you sure? [y/N]\033[0m" && read ans && [ $${ans:-N} = y ] || (echo "\033[32mCancelled.\033[0m" && exit 1)

# Dependencies
########################################################################################################################
# Core Dependencies
GIT  ?= $(shell which git)
DOCKER  ?= $(shell which docker)

# Ensures git is installed - does not enforce version, please use latest
git:
ifeq (, $(GIT))
	$(error "Docker is not installed or incorrectly configured. https://www.docker.com/")
#else
#	@$(DOCKER) --version
endif

EXECUTABLES = $(GIT) $(DOCKER) aws
K := $(foreach exec,$(EXECUTABLES),\
        $(if $(shell which $(exec)),some string,$(error "No $(exec) found in PATH. Please install it.")))

# This ensures we include main.mk only if it's there. If not we don't error out (IE in case of bootstrap)
-include $(INFRA_DIR)/icmk/main.mk
