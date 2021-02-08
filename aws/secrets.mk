# Macroses
########################################################################################################################
# SSM Wrapper
SSM_WRAPPER_DOCKER_IMAGE ?= hazelops/ssm-wrapper:latest
SSM ?= $(DOCKER) run --user nobody -v $(HOME)/.aws/:/root/.aws -v $(ENV_DIR):/$(ENV_DIR) -e AWS_PROFILE=$(AWS_PROFILE) -e AWS_REGION=$(AWS_REGION) $(SSM_WRAPPER_DOCKER_IMAGE) ssm
SERVICE_SECRETS_BACKUP_FILE ?= $(INFRA_DIR)/env/$(ENV)/secrets/$(SVC)-backup.json
SERVICE_SECRETS_FILE = $(INFRA_DIR)/env/$(ENV)/secrets/$(SVC).json
SERVICE_SECRETS = $(shell cat $(SERVICE_SECRETS_FILE) | $(JQ) -e -r '.[].key' )
GLOBAL_SECRETS_BACKUP_FILE ?= $(INFRA_DIR)/env/$(ENV)/secrets/global-backup.json
GLOBAL_SECRETS_FILE = $(INFRA_DIR)/env/$(ENV)/secrets/global.json
GLOBAL_SECRETS = $(shell cat $(GLOBAL_SECRETS_FILE) | $(JQ) -e -r '.[].key' )

# TODO: Figure out whether to use shell's foreach or Make can build the list dynamically
CMD_SERVICE_SECRETS_PUSH = $(SSM) add -f $(SERVICE_SECRETS_FILE) -p $(ENV)/$(SVC) -k alias/aws/ssm && echo "\033[32m[OK]\033[0m $(SVC) secrets upload" || echo "\033[31m[ERROR]\033[0m $(SVC) secrets upload"
CMD_GLOBAL_SECRETS_PUSH = $(SSM) add -f $(GLOBAL_SECRETS_FILE) -p $(ENV)/global -k alias/aws/ssm && echo "\033[32m[OK]\033[0m Global secrets upload" || echo "\033[31m[ERROR]\033[0m Global secrets upload"
CMD_SERVICE_SECRETS_TAGS = @ (echo $(foreach item, $(SERVICE_SECRETS), \
		$(shell $(AWS) --profile=$(AWS_PROFILE) ssm add-tags-to-resource --resource-type "Parameter" --resource-id "/$(ENV)/$(SVC)/$(item)" \
		--tags "Key=Application,Value=$(SVC)" "Key=EnvVarName,Value=$(item)" || \
		echo "\033[31m[ERROR]\033[0m /$(ENV)/$(SVC)/* secrets tagged")) > /dev/null )

CMD_SERVICE_SECRETS_PULL = @$(SSM) list -p $(ENV)/$(SVC) -r json > $(SERVICE_SECRETS_BACKUP_FILE) && echo "\033[32m[OK]\033[0m /$(ENV)/$(SVC)/* secrets pulled" || echo "\033[31m[ERROR]\033[0m /$(ENV)/$(SVC)/* secrets getting"
CMD_GLOBAL_SECRETS_PULL = @$(SSM) list -p $(ENV)/global -r json > $(GLOBAL_SECRETS_BACKUP_FILE) && echo "\033[32m[OK]\033[0m /$(ENV)/global/* secrets pulled" || echo "\033[31m[ERROR]\033[0m /$(ENV)/global/* secrets getting"

CMD_SERVICE_SECRETS_DELETE = @ (echo $(foreach item, $(SERVICE_SECRETS), \
		$(shell $(SSM) delete -p $(ENV)/$(SVC) -n $(item) )) ) && \
		echo "\033[32m[OK]\033[0m /$(ENV)/$(SVC)/* secrets deleted" || echo "\033[31m[ERROR]\033[0m /$(ENV)/$(SVC)/* secrets deletion"
CMD_GLOBAL_SECRETS_DELETE = @ (echo $(foreach item, $(GLOBAL_SECRETS), \
		$(shell $(SSM) delete -p $(ENV)/global -n $(item) )) ) && \
		echo "\033[32m[OK]\033[0m /$(ENV)/global/* secrets deleted" || echo "\033[31m[ERROR]\033[0m /$(ENV)/global/* secrets deletion"

# Tasks
########################################################################################################################
secrets.push:
	@$(CMD_SERVICE_SECRETS_PUSH)
	@$(CMD_SERVICE_SECRETS_TAGS)
secrets.pull:
	@$(CMD_SERVICE_SECRETS_PULL)
secrets.delete:
	@$(CMD_SERVICE_SECRETS_DELETE)
global-secrets.push:
	@$(CMD_GLOBAL_SECRETS_PUSH)
global-secrets.pull:
	@$(CMD_GLOBAL_SECRETS_PULL)
global-secrets.delete:
	@$(CMD_GLOBAL_SECRETS_DELETE)
# Dependencies
########################################################################################################################
