# Macroses
########################################################################################################################
SLS_VERSION ?= 1.73.1
SLS_FILE ?= serverless.yml
NODE_VERSION ?= 10.22.0-alpine3.9

SLS ?= @$(DOCKER) run --entrypoint=serverless -v $(ROOT_DIR)/$(PROJECT_PATH):/opt/app -v $(HOME)/.aws/:/root/.aws \
	-i amaysim/serverless:$(SLS_VERSION)
NPM ?= @$(DOCKER) run --workdir=/app --entrypoint=npm -v $(ROOT_DIR)/$(PROJECT_PATH):/app -i node:$(NODE_VERSION)

# Tasks
########################################################################################################################
#aws.debug: ## Show environment information for debug purposes
#	@echo "\033[32m=== AWS Environment Info ===\033[0m"
#	@echo "\033[36mENV\033[0m: $(ENV)"
#	@echo "\033[36mAWS_DEV_ENV_NAME\033[0m: $(AWS_DEV_ENV_NAME) (set devEnvironmentName here https://console.aws.amazon.com/iam/home?region=us-east-1#/users/$(AWS_USER)?section=tags)"
#	@echo "\033[36mAWS_ACCOUNT\033[0m: $(AWS_ACCOUNT)"
#	@echo "\033[36mAWS_PROFILE\033[0m: $(AWS_PROFILE)"
#	@echo "\033[36mAWS_USER\033[0m: $(AWS_USER)"
#	@echo "\033[36mTAG\033[0m: $(TAG)"
#
#aws.profile:
#	$(shell mkdir -p ~/.aws && echo "[$(AWS_PROFILE)]\naws_access_key_id = $(AWS_ACCESS_KEY_ID)\naws_secret_access_key = $(AWS_SECRET_ACCESS_KEY)\nregion = $(AWS_REGION)" >> ~/.aws/credentials)


# Dependencies
########################################################################################################################
# Ensures aws toolchain is installed
aws:
ifeq (, $(SLS))
	$(error "aws cli toolchain is not installed or incorrectly configured.")
endif

CMD_SLS_SERVICE_INSTALL = $(NPM) install --save-dev
CMD_SLS_SERVICE_DEPLOY = $(SLS) deploy --env $(ENV) --region $(AWS_REGION) --profile $(AWS_PROFILE) --service $(SVC) -c $(SLS_FILE)
CMD_SLS_SERVICE_BUILD = cd $(PROJECT_PATH) && make
CMD_SLS_SERVICE_DESTROY = $(SLS) remove --env $(ENV) --region $(AWS_REGION) --profile $(AWS_PROFILE) --service $(SVC) -c $(SLS_FILE)
CMD_SLS_SERVICE_SECRETS_PUSH = $(CMD_SLS_SERVICE_SECRETS_PUSH)
