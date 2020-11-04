# Macroses
########################################################################################################################
SLS_DOCKER_IMAGE ?= amaysim/serverless
SLS_VERSION ?= 1.73.1
SLS_FILE ?= serverless.yml
EVENT_FILE ?= event.json
NODE_VERSION ?= 10.22.0-alpine3.9

# Docker executors
########################################################################################################################
SLS ?= $(DOCKER) run --rm --workdir=/opt/app -e AWS_PROFILE=$(AWS_PROFILE) -v $(ROOT_DIR)/$(PROJECT_PATH):/opt/app -v ~/.aws/:/root/.aws:ro $(SLS_DOCKER_IMAGE):$(SLS_VERSION) serverless
NPM ?= $(DOCKER) run --rm --workdir=/app -v $(ROOT_DIR)/$(PROJECT_PATH):/app node:$(NODE_VERSION) npm

# Serverless CLI Reference
########################################################################################################################
CMD_SLS_SERVICE_INSTALL = $(NPM) install --save-dev
CMD_SLS_SERVICE_DEPLOY = $(SLS) deploy --config $(SLS_FILE) --service $(SVC) --verbose --region $(AWS_REGION) --env $(ENV) --profile $(AWS_PROFILE)
CMD_SLS_SERVICE_INVOKE = $(SLS) invoke --function $(SVC) --path $(EVENT_FILE) --log --config $(SLS_FILE) --service $(SVC) --region $(AWS_REGION) --env $(ENV) --profile $(AWS_PROFILE)
CMD_SLS_SERVICE_DESTROY = $(SLS) remove --config $(SLS_FILE) --service $(SVC) --verbose --region $(AWS_REGION) --env $(ENV) --profile $(AWS_PROFILE)
CMD_SLS_SERVICE_BUILD = cd $(ROOT_DIR)/$(PROJECT_PATH) && make
CMD_SLS_SERVICE_SECRETS_PUSH = $(CMD_SERVICE_SECRETS_PUSH)
# This works with "serverless-domain-manager" plugin and provide domain creation and remove
CMD_SLS_SERVICE_CREATE_DOMAIN = $(SLS) create_domain --verbose --region $(AWS_REGION) --env $(ENV) --profile $(AWS_PROFILE)
CMD_SLS_SERVICE_DELETE_DOMAIN = $(SLS) delete_domain --verbose --region $(AWS_REGION) --env $(ENV) --profile $(AWS_PROFILE)

# Tasks
########################################################################################################################


# Dependencies
########################################################################################################################
# Ensures aws toolchain is installed
aws:
ifeq (, $(SLS))
	$(error "aws cli toolchain is not installed or incorrectly configured.")
endif
