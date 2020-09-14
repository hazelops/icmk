# Macroses
########################################################################################################################
SLS_DOCKER_IMAGE ?= amaysim/serverless
SLS_VERSION ?= 1.73.1
SLS_FILE ?= serverless.yml
EVENT_FILE ?= event.json
NODE_VERSION ?= 10.22.0-alpine3.9

SLS ?= $(DOCKER) run --rm -e AWS_PROFILE=$(AWS_PROFILE) -v $(ROOT_DIR)/$(PROJECT_PATH):/opt/app -v ~/.aws/:/root/.aws:ro $(SLS_DOCKER_IMAGE):$(SLS_VERSION) serverless
NPM ?= $(DOCKER) run --rm --workdir=/app -v $(ROOT_DIR)/$(PROJECT_PATH):/app node:$(NODE_VERSION) npm

# Serverless CLI Reference
########################################################################################################################
CMD_SLS_SERVICE_INSTALL = $(NPM) install --save-dev
CMD_SLS_SERVICE_DEPLOY = $(SLS) deploy --verbose --stage $(ENV) --region $(AWS_REGION) --config $(SLS_FILE)
CMD_SLS_SERVICE_INVOKE = $(SLS) invoke --function $(SVC) --path $(EVENT_FILE) --stage $(ENV) --region $(AWS_REGION) --log
CMD_SLS_SERVICE_DESTROY = $(SLS) remove --stage $(ENV) --region $(AWS_REGION)

# Tasks
########################################################################################################################


# Dependencies
########################################################################################################################
# Ensures aws toolchain is installed
aws:
ifeq (, $(SLS))
	$(error "aws cli toolchain is not installed or incorrectly configured.")
endif

# Backwards Compatibility, should be removed in 2.0
########################################################################################################################
CMD_SLS_INSTALL = @cd $(ROOT_DIR)/$(PROJECT_PATH) && $(CMD_SLS_SERVICE_INSTALL)
CMD_SLS_DEPLOY = @cd $(ROOT_DIR)/$(PROJECT_PATH) && $(CMD_SLS_SERVICE_DEPLOY)
CMD_SLS_DESTROY = @cd $(ROOT_DIR)/$(PROJECT_PATH) && $(CMD_SLS_SERVICE_DESTROY)
CMD_SLS_INVOKE= @cd $(ROOT_DIR)/$(PROJECT_PATH) && $(CMD_SLS_SERVICE_INVOKE)
