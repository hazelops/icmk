# Macroses
########################################################################################################################
EVENT_JSON_FILE ?= $(INFRA_DIR)/env/$(ENV)/event.json
EVENT_JSON = $(shell cat $(EVENT_JSON_FILE) | $(BASE64))
FUNCTION_NAME ?= "$(ENV)-ecs-tasks-cleanup" #$(ENV)-$(SVC)

# Bastion commands to invoke Lambda function
LAMBDA_INVOKE_VIA_EVENT = $(shell $(AWS) --profile $(AWS_PROFILE) lambda invoke \
--function-name $(FUNCTION_NAME) \
--invocation-type Event \
--payload '$(EVENT_JSON)' lambda_response.json)


# Tasks
########################################################################################################################
lambda.event:
	$(LAMBDA_INVOKE_VIA_EVENT)

# Dependencies
########################################################################################################################
