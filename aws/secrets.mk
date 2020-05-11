# Macroses
########################################################################################################################
SERVICE_SECRETS = $(shell cat $(SERVICE_SECRETS_FILE) | $(JQ) -e -r '. | to_entries[] | .key' )

SERVICE_SECRETS_FILE = $(INFRA_DIR)/env/$(ENV)/secrets/$(SVC).json
# TODO: Figure out whether to use shell's foreach or Make can build the list dynamically
CMD_SERVICE_SECRETS_PUSH = @ (echo $(foreach item, $(SERVICE_SECRETS), \
		$(shell aws ssm --profile=$(AWS_PROFILE) put-parameter --name="/$(ENV)/$(SVC)/$(item)" --value="$(shell \
			cat $(SERVICE_SECRETS_FILE) | $(JQ) -r '.$(item)' \
		)" --type String --overwrite \
	)) > /dev/null ) && echo "\033[32m[OK]\033[0m $(SVC) secrets upload" || echo "\033[31m[ERROR]\033[0m $(SVC) secrets upload"

# Tasks
########################################################################################################################

# Dependencies
########################################################################################################################
