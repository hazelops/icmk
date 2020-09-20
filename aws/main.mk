# Environment Validation
########################################################################################################################
ifndef AWS_REGION
$(error Please set AWS_REGION via `export AWS_REGION=<aws_region>` or use direnv. This is nessesary for additional tools that are not able to read a region from your AWS profile)
endif

# Macroses
########################################################################################################################
# We don't check for AWS_PROFILE, but instead we assume the profile name
AWS_PROFILE ?= $(NAMESPACE)-$(ENV_BASE)
AWS_USER ?= $(shell aws --profile=$(AWS_PROFILE) iam get-user | $(JQ) -r ".User.UserName")
AWS_ACCOUNT ?= $(shell [ -f ~/.aws/credentials ] && $(AWS) --profile=$(AWS_PROFILE) sts get-caller-identity | $(JQ) -r '.Account' || echo "nil" )
AWS_DEV_ENV_NAME ?= $(shell aws --profile=$(AWS_PROFILE) iam list-user-tags --user-name $(AWS_USER) | ( $(JQ) -e -r '.Tags[] | select(.Key == "devEnvironmentName").Value'))
# This can be overriden for different args, like setting an endpoint, like localstack
AWS_ARGS ?= $(AWS_LOCALSTACK_ARG)
LOCALSTACK_IMAGE ?= localstack/localstack-full
LOCALSTACK_VERSION ?= latest
LOCALSTACK_ENDPOINT ?= http://localhost:4566
LOCALSTACK_WEB_UI_PORT ?= 8088
LOCALSTACK_PORTS ?= "4565-4585"
#We need to come up with idea where to keep and how to pass the $LOCALSTACK_SERVICE_LIST 
LOCALSTACK_SERVICE_LIST ?= "dynamodb,s3,lambda" #etc. serverless? api-gateway?
AWS_LOCALSTACK_ARG ?= $(shell echo $$([[ "$(ENABLE_LOCALSTACK)" == "1" ]] && echo "--endpoint-url=$(LOCALSTACK_ENDPOINT)" || "") )

LOCALSTACK_START ?= $(DOCKER) run -d -p $(LOCALSTACK_WEB_UI_PORT):$(LOCALSTACK_WEB_UI_PORT) -p $(LOCALSTACK_PORTS):$(LOCALSTACK_PORTS) -e SERVICES=dynamodb -e DATA_DIR=/tmp/localstack/data -e PORT_WEB_UI=$(LOCALSTACK_WEB_UI_PORT) -e DOCKER_HOST=unix:///var/run/docker.sock -v ${TMPDIR:-/tmp/localstack}:/tmp/localstack $(LOCALSTACK_IMAGE):$(LOCALSTACK_VERSION)
LOCALSTACK_STOP ?= $(DOCKER) rm $($(DOCKER) stop $($(DOCKER) ps -a -q --filter ancestor=$(LOCALSTACK_IMAGE):$(LOCALSTACK_VERSION) --format="{{.ID}}"))

AWS ?= $(DOCKER) run -v $(HOME)/.aws/:/root/.aws -i amazon/aws-cli:2.0.40 $(AWS_ARGS)
# Tasks
########################################################################################################################
aws.debug: ## Show environment information for debug purposes
	@echo "\033[32m=== AWS Environment Info ===\033[0m"
	@echo "\033[36mAWS_DEV_ENV_NAME\033[0m: $(AWS_DEV_ENV_NAME) (set devEnvironmentName here https://console.aws.amazon.com/iam/home?region=us-east-1#/users/$(AWS_USER)?section=tags)"
	@echo "\033[36mAWS_ACCOUNT\033[0m: $(AWS_ACCOUNT)"
	@echo "\033[36mAWS_PROFILE\033[0m: $(AWS_PROFILE)"
	@echo "\033[36mAWS_USER\033[0m: $(AWS_USER)"

aws.profile:
	$(shell mkdir -p ~/.aws && echo "[$(AWS_PROFILE)]\naws_access_key_id = $(AWS_ACCESS_KEY_ID)\naws_secret_access_key = $(AWS_SECRET_ACCESS_KEY)\nregion = $(AWS_REGION)" >> ~/.aws/credentials)


# Dependencies
########################################################################################################################
# TODO: Add validation for ability to connect to AWS
# Ensures aws toolchain is installed
aws:
ifeq (, $(AWS))
	$(error "aws cli toolchain is not installed or incorrectly configured.")
endif
