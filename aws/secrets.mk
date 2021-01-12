# Macroses
########################################################################################################################
SERVICE_SECRETS_FILE = $(INFRA_DIR)/env/$(ENV)/secrets/$(SVC).json
SERVICE_SECRETS = $(shell cat $(SERVICE_SECRETS_FILE) | $(JQ) -e -r '. | to_entries[] | .key' )

# TODO: Figure out whether to use shell's foreach or Make can build the list dynamically
CMD_SERVICE_SECRETS_PUSH = @ (echo $(foreach item, $(SERVICE_SECRETS), \
		$(shell $(AWS) --profile=$(AWS_PROFILE) ssm put-parameter --name="/$(ENV)/$(SVC)/$(item)" --value="$(shell \
			cat $(SERVICE_SECRETS_FILE) | $(JQ) -r '.$(item)' \
		)" --type SecureString --overwrite && \
		$(AWS) --profile=$(AWS_PROFILE) ssm add-tags-to-resource --resource-type "Parameter" --resource-id "/$(ENV)/$(SVC)/$(item)" \
		--tags "Key=Application,Value=$(SVC)" "Key=EnvVarName,Value=$(item)" \
	)) > /dev/null ) && echo "\033[32m[OK]\033[0m $(SVC) secrets upload" || echo "\033[31m[ERROR]\033[0m $(SVC) secrets upload"

CMD_SERVICE_SECRETS_DELETE = @ (echo $(foreach item, $(shell $(AWS) --profile=$(AWS_PROFILE) ssm get-parameters-by-path \
		--path "/$(ENV)/$(SVC)" --query "Parameters[*].Name" --recursive | $(JQ) -e -r '. | to_entries[] | .value' ), \
		$(shell $(AWS) --profile=$(AWS_PROFILE) ssm delete-parameter --name $(item))) > /dev/null ) && \
		echo "\033[32m[OK]\033[0m /$(ENV)/$(SVC)/* secrets deleted" || echo "\033[31m[ERROR]\033[0m /$(ENV)/$(SVC)/* secrets deletion"

# Tasks
########################################################################################################################
secrets.push:
	@$(CMD_SERVICE_SECRETS_PUSH)
secrets.delete:
	@$(CMD_SERVICE_SECRETS_DELETE)
# Dependencies
########################################################################################################################
