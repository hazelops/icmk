# Environment Validation
########################################################################################################################
ifndef ENV
$(error Please set ENV via `export ENV=<env_name>` or use direnv)
endif


-include $(INFRA_DIR)/env/$(ENV)/*.mk
include $(INFRA_DIR)/icmk/*/*.mk

# Macroses
########################################################################################################################
# Makefile Helpers
SVC = $(shell echo $(@) | $(CUT) -d. -f1 )
SVC_TYPE = $(shell echo $(SVC) | $(CUT) -d- -f1 )
ENV_BASE = dev
NPM_TOKEN ?= nil

ICMK_TEMPLATE_TERRAFORM_BACKEND_CONFIG = $(INFRA_DIR)/icmk/terraform/templates/backend.tf.gotmpl
ICMK_TEMPLATE_TERRAFORM_VARS = $(INFRA_DIR)/icmk/terraform/templates/terraform.tfvars.gotmpl
ICMK_TEMPLATE_TERRAFORM_TFPLAN = $(INFRA_DIR)/icmk/terraform/templates/terraform.tfplan.gotmpl

# We are using a tag from AWS User which would tell us which environment this user is using. You can always override it.
ENV ?= $(AWS_DEV_ENV_NAME)
ENV_DIR ?= $(INFRA_DIR)/env/$(ENV)
PROJECT_PATH ?= projects/$(SVC)

# Tasks
########################################################################################################################
.PHONY: auth help
all: help
env.debug: aws.debug
	@echo "\033[32m=== ICMK Info ===\033[0m"
	@echo "\033[36mENV\033[0m: $(ENV)"
	@echo "\033[36mTAG\033[0m: $(TAG)"
	@echo "\033[36mINFRA_DIR\033[0m: $(INFRA_DIR)"
	@echo "\033[36mPWD\033[0m: $(PWD)"
	@echo "\033[36mICMK_VERSION\033[0m: $(ICMK_VERSION)"

up: docker
	# TODO: This should probably use individual apps "up" definitions
	echo "TODO: aws ecs local up"

login: ecr.login ## Perform all required authentication (ECR)
auth: ecr.login
help: ## Display this help screen (default)
	@echo "\033[32m=== Available Tasks ===\033[0m"
	@grep -h -E '^([a-zA-Z_-]|\.)+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

use: env.use


## Tool Dependencies
DOCKER  ?= $(shell which docker)
COMPOSE ?= $(shell which docker-compose)

JQ ?= $(DOCKER) run -i colstrom/jq
CUT ?= $(DOCKER) run -i busybox:1.31.1 cut
REV ?= $(DOCKER) run -i busybox:1.31.1 rev
BASE64 ?= $(DOCKER) run -i busybox:1.31.1 base64


GOMPLATE ?= $(DOCKER) run \
	-e ENV="$(ENV)" \
	-e AWS_PROFILE="$(AWS_PROFILE)" \
	-e AWS_REGION="$(AWS_REGION)" \
	-e NAMESPACE="$(NAMESPACE)" \
	-e EC2_KEY_PAIR_NAME="$(EC2_KEY_PAIR_NAME)" \
	-e TAG="$(TAG)" \
	-e SSH_PUBLIC_KEY="$(SSH_PUBLIC_KEY)" \
	-e DOCKER_REGISTRY="$(DOCKER_REGISTRY)" \
	-e TERRAFORM_STATE_BUCKET_NAME="$(TERRAFORM_STATE_BUCKET_NAME)" \
	-e TERRAFORM_STATE_KEY="$(TERRAFORM_STATE_KEY)" \
	-e TERRAFORM_STATE_REGION="$(TERRAFORM_STATE_REGION)" \
	-e TERRAFORM_STATE_PROFILE="$(TERRAFORM_STATE_PROFILE)" \
	-e TERRAFORM_STATE_DYNAMODB_TABLE="$(TERRAFORM_STATE_DYNAMODB_TABLE)" \
	-e SHORT_SHA="$(SHORT_SHA)" \
	-e COMMIT_MESSAGE="$(COMMIT_MESSAGE)" \
	-e GITHUB_ACTOR="$(GITHUB_ACTOR)" \
	-v $(ENV_DIR):/temp \
	--rm -i hairyhenderson/gomplate

ECHO = @echo

# Dependencies
########################################################################################################################
# Ensures docker is installed - does not enforce version, please use latest
docker:
ifeq (, $(DOCKER))
	$(error "Docker is not installed or incorrectly configured. https://www.docker.com/")
#else
#	@$(DOCKER) --version
endif

# Ensures docker-compose is installed - does not enforce.
docker-compose: docker
ifeq (, $(COMPOSE))
	$(error "docker-compose is not installed or incorrectly configured.")
#else
#	@$(COMPOSE) --version
endif

# Ensures gomplate is installed
gomplate:
ifeq (, $(GOMPLATE))
	$(error "gomplate is not installed or incorrectly configured. https://github.com/hairyhenderson/gomplate")
endif

# Ensures jq is installed
jq:
ifeq (, $(JQ))
	$(error "jq is not installed or incorrectly configured.")
endif

# This is a workaround for syntax highlighters that break on a "Comment" symbol.
HASHSIGN = \#
