# Macroses
########################################################################################################################
SERVICE_SECRETS_BACKUP_FILE ?= $(INFRA_DIR)/env/$(ENV)/secrets/$(SVC)_backup.json
SERVICE_SECRETS_FILE = $(INFRA_DIR)/env/$(ENV)/secrets/$(SVC).json
SERVICE_SECRETS = $(shell cat $(SERVICE_SECRETS_FILE) | $(JQ) -e -r '. | to_entries[] | .key' )

# TODO: Figure out whether to use shell's foreach or Make can build the list dynamically
CMD_SERVICE_SECRETS_PUSH = @ (echo $(foreach item, $(SERVICE_SECRETS), \
		$(shell aws ssm --profile=$(AWS_PROFILE) put-parameter --name="/$(ENV)/$(SVC)/$(item)" --value="$(shell \
			cat $(SERVICE_SECRETS_FILE) | $(JQ) -r '.$(item)' \
		)" --type SecureString --overwrite && \
		aws ssm add-tags-to-resource --resource-type "Parameter" --resource-id "/$(ENV)/$(SVC)/$(item)" \
		--tags "Key=Application,Value=$(SVC)" "Key=EnvVarName,Value=$(item)" \
	)) > /dev/null ) && echo "\033[32m[OK]\033[0m $(SVC) secrets upload" || echo "\033[31m[ERROR]\033[0m $(SVC) secrets upload"

CMD_SERVICE_SECRETS_DELETE = @ (echo $(foreach item, $(shell aws ssm --profile=$(AWS_PROFILE) get-parameters-by-path \
		--path "/$(ENV)/$(SVC)" --query "Parameters[*].Name" --recursive | $(JQ) -e -r '. | to_entries[] | .value' ), \
		$(shell aws ssm --profile=$(AWS_PROFILE) delete-parameter --name $(item))) > /dev/null ) && \
		echo "\033[32m[OK]\033[0m /$(ENV)/$(SVC)/* secrets deleted" || echo "\033[31m[ERROR]\033[0m /$(ENV)/$(SVC)/* secrets deletion"

CMD_SERVICE_ALL_SECRET_KEYS = $(foreach item, $(shell aws ssm --profile=$(AWS_PROFILE) get-parameters-by-path \
		--path "/$(ENV)/$(SVC)" --recursive | $(JQ) -e -r '.Parameters[] | .Name' ), $(item))
CMD_SERVICE_SECRETS_PULL = @ (echo $(shell echo "{\"INFO\":\"EMPTY_JSON_CREATED\"}" > $(SERVICE_SECRETS_BACKUP_FILE)) && \
		$(foreach item, $(CMD_SERVICE_ALL_SECRET_KEYS), \
		$(shell $(JQ) --arg value "$(shell echo $(item) | sed 's|.*/||')" '.[$$value] = "'$(shell aws ssm --profile=$(AWS_PROFILE) get-parameter --name $(item) --query Parameter.Value)'"' \
		$(SERVICE_SECRETS_BACKUP_FILE) > tmp.json && mv tmp.json $(SERVICE_SECRETS_BACKUP_FILE))) > /dev/null ) && \
		$(JQ) 'del(."INFO")' $(SERVICE_SECRETS_BACKUP_FILE) > tmp.json && mv tmp.json $(SERVICE_SECRETS_BACKUP_FILE) && \
		echo "\033[32m[OK]\033[0m /$(ENV)/$(SVC)/* secrets pulled" || echo "\033[31m[ERROR]\033[0m /$(ENV)/$(SVC)/* secrets getting"
# Tasks
########################################################################################################################
secrets.push:
	@$(CMD_SERVICE_SECRETS_PUSH)
secrets.delete:
	@$(CMD_SERVICE_SECRETS_DELETE)
# Dependencies
########################################################################################################################
