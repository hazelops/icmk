# Macroses
########################################################################################################################
PROJ_PATH ?= $(PROJ_DIR)/$(SLS_SERVICE)-$(SLS_FUNCTION)

SLS_DOCKER_IMAGE ?= amaysim/serverless
SLS_VERSION ?= 1.73.1
SLS_FILE ?= serverless.yml
EVENT_FILE ?= event.json
NODE_VERSION ?= 10.22.0-alpine3.9

SLS ?= $(DOCKER) run --rm -e SLS_SERVICE=$(SLS_SERVICE) -e SLS_FUNCTION=$(SLS_FUNCTION) -v $(PROJ_PATH):/opt/app -v ~/.aws/:/root/.aws:ro $(SLS_DOCKER_IMAGE):$(SLS_VERSION) serverless
NPM ?= $(DOCKER) run --rm --workdir=/app -v $(PROJ_PATH):/app node:$(NODE_VERSION) npm

# Serverless CLI Reference
########################################################################################################################
CMD_SLS_INSTALL_PLUGINS = $(NPM) install --save-dev
CMD_SLS_SERVICE_DEPLOY = $(SLS) deploy --verbose --stage $(ENV) --region $(AWS_REGION) --config $(SLS_FILE)
CMD_SLS_SERVICE_INVOKE = $(SLS) invoke --function $(SLS_FUNCTION) --path $(EVENT_FILE) --stage $(ENV) --region $(AWS_REGION) --log
CMD_SLS_SERVICE_DESTROY = $(SLS) remove --stage $(ENV) --region $(AWS_REGION)

# Tasks
########################################################################################################################
sls.plugins:
	@ cd $(PROJ_PATH) && \
	$(CMD_SLS_INSTALL_PLUGINS)

sls.deploy:
	@ cd $(PROJ_PATH) && \
	$(CMD_SLS_SERVICE_DEPLOY)

sls.destroy:
	@ cd $(PROJ_PATH) && \
	$(CMD_SLS_SERVICE_DESTROY)

sls.invoke:
	@ cd $(PROJ_PATH) && \
	$(CMD_SLS_SERVICE_INVOKE)


# Dependencies
########################################################################################################################
# Ensures aws toolchain is installed
aws:
ifeq (, $(SLS))
	$(error "aws cli toolchain is not installed or incorrectly configured.")
endif

#CMD_SLS_SERVICE_BUILD = cd $(PROJECT_PATH) && make
#CMD_SLS_SERVICE_SECRETS_PUSH = $(CMD_SLS_SERVICE_SECRETS_PUSH)

