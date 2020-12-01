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
LOCALSTACK_IMAGE ?= localstack/localstack
LOCALSTACK_VERSION ?= latest
LOCALSTACK_ENDPOINT ?= http://$(LOCALSTACK_CONTAINER_IP):4566
LOCALSTACK_WEB_UI_PORT ?= 8088
LOCALSTACK_PORTS ?= "4565-4585"
LOCALSTACK_SERVICE_LIST ?= "dynamodb,s3,lambda,cloudformation,sts,iam,acm,ec2,route53,ssm,cloudwatch,apigateway" #etc. serverless? api-gateway?
CMD_LOCALSTACK_UP ?= @ ( $(DOCKER) run -d --name localstack -p $(LOCALSTACK_WEB_UI_PORT):$(LOCALSTACK_WEB_UI_PORT) \
	-p $(LOCALSTACK_PORTS):$(LOCALSTACK_PORTS) \
	-e SERVICES=$(LOCALSTACK_SERVICE_LIST) \
	-e DATA_DIR=/tmp/localstack/data \
	-e PORT_WEB_UI=$(LOCALSTACK_WEB_UI_PORT) \
	-e DOCKER_HOST=unix:///var/run/docker.sock \
	-v /tmp/localstack:/tmp/localstack \
	$(LOCALSTACK_IMAGE):$(LOCALSTACK_VERSION) > /dev/null) && \
	sleep 10 && \
	echo "\033[32m[OK]\033[0m Localstack is UP. \nUse locally: aws --endpoint-url=http://localhost:4566 [options] <command>" || \
	echo "\033[31m[ERROR]\033[0m Localstack start failed"

CMD_LOCALSTACK_DOWN ?= @ ( $(DOCKER) rm $$($(DOCKER) stop $$($(DOCKER) ps -a -q --filter ancestor=$(LOCALSTACK_IMAGE):$(LOCALSTACK_VERSION) --format="{{.ID}}")) > /dev/null) && echo "\033[32m[OK]\033[0m Localstack is DOWN." || echo "\033[31m[ERROR]\033[0m Localstack stopping failed"

LOCALSTACK_CONTAINER_IP ?= $$($(DOCKER) ps | grep "localstack" > /dev/null && echo "$(LOCALSTACK_IP)" || echo "")
LOCALSTACK_IP ?= $$($(DOCKER) inspect --format='{{range.NetworkSettings.Networks}}{{.IPAddress}}{{end}}' localstack)
AWS_ARGS ?= $$(if [ "$(ENV)" = "localstack" ] && [ $(LOCALSTACK_CONTAINER_IP) ]; then echo "--endpoint-url=http://$(LOCALSTACK_CONTAINER_IP):4566"; else echo ""; fi)

AWS ?= $(DOCKER) run -v $(HOME)/.aws/:/root/.aws -i amazon/aws-cli:2.0.40 $(AWS_ARGS)
CMD_AWS_LOGS_TAIL = @$(AWS) logs tail --profile $(AWS_PROFILE) $(SERVICE_NAME) --follow
CMD_AWS_EC2_IMPORT_KEY_PAIR = @$(AWS) ec2 import-key-pair  --key-name="$(EC2_KEY_PAIR_NAME)" --profile $(AWS_PROFILE) --public-key-material="$(SSH_PUBLIC_KEY_BASE64)"

# Getting OS|Linux info
OS_NAME ?= $(shell uname -s)
LINUX_DISTRIB ?= $$(cat /etc/issue)
LINUX_ARCH ?= $(shell uname -m)
LINUX_BITS ?= $(shell uname -m | sed 's/x86_//;s/i[3-6]86/32/')
ARCH ?= $$(echo $$(if echo "$(LINUX_ARCH)" | grep -Fqe "arm"; then echo "arm$(LINUX_BITS)"; else echo "$(LINUX_BITS)bit"; fi))
LINUX_DISTRIB_TEMP ?= $$(echo $$(if echo "$(LINUX_DISTRIB)" | grep -Fqe "Ubuntu"; then echo "ubuntu"; elif echo "$(LINUX_DISTRIB)" | grep -Fqe "Debian"; then echo "ubuntu"; else echo "linux"; fi))
LINUX_DISTRIB ?= $$(echo $(LINUX_DISTRIB_TEMP) | xargs)
LINUX_PACKAGE_EXT ?= $$(echo $$(if echo "$(LINUX_DISTRIB)" | grep -Fqe "Ubuntu"; then echo ".deb"; elif echo "$(LINUX_DISTRIB)" | grep -Fqe "Debian"; then echo ".deb"; else echo ".rpm"; fi))
# Download Session Manager cmds
SSM_DOWNLOAD_FOR_MAC_OS ?= curl -s "https://s3.amazonaws.com/session-manager-downloads/plugin/latest/mac/sessionmanager-bundle.zip" > "sessionmanager-bundle.zip" && unzip -qq sessionmanager-bundle.zip
SSM_DOWNLOAD_FOR_LINUX_OS ?= curl -s "https://s3.amazonaws.com/session-manager-downloads/plugin/latest/$(LINUX_DISTRIB)_$(ARCH)/session-manager-plugin$(LINUX_PACKAGE_EXT)" > "session-manager-plugin$(LINUX_PACKAGE_EXT)"
CMD_SSM_DOWNLOAD ?= $(shell echo $$(if [ "$(OS_NAME)" = "Linux" ]; then echo "$(SSM_DOWNLOAD_FOR_LINUX_OS)"; else echo "$(SSM_DOWNLOAD_FOR_MAC_OS)"; fi))
# Installation Session Manager cmds
LINUX_INSTALLER ?= $$(echo $$(if echo "$(LINUX_DISTRIB)" | grep -Fqe "Ubuntu"; then echo "sudo dpkg -i"; elif echo "$(LINUX_DISTRIB)" | grep -Fqe "Debian"; then echo "sudo dpkg -i"; else echo "sudo yum install -y -q"; fi))
SSM_INSTALL_ON_MAC_OS ?= sudo ./sessionmanager-bundle/install -i /usr/local/sessionmanagerplugin -b /usr/local/bin/session-manager-plugin
SSM_INSTALL_ON_LINUX_OS ?= $(LINUX_INSTALLER) session-manager-plugin$(LINUX_PACKAGE_EXT)
CMD_SSM_INSTALL ?= $(shell echo $$(if [ "$(OS_NAME)" = "Linux" ]; then echo "$(SSM_INSTALL_ON_LINUX_OS)"; else echo "$(SSM_INSTALL_ON_MAC_OS)"; fi))
# Cleanup Session Manager installation package
SSM_CLEANUP_ON_MAC_OS ?= rm -rf sessionmanager-bundle sessionmanager-bundle.zip
SSM_CLEANUP_ON_LINUX_OS ?= rm -rf session-manager-plugin$(LINUX_PACKAGE_EXT)
CMD_SSM_CLEANUP ?= $(shell echo $$(if [ "$(OS_NAME)" = "Linux" ]; then echo "$(SSM_CLEANUP_ON_LINUX_OS)"; else echo "$(SSM_CLEANUP_ON_MAC_OS)"; fi))

# Tasks
########################################################################################################################
aws.debug: ## Show environment information for debug purposes
	@echo "\033[32m=== AWS Environment Info ===\033[0m"
	@echo "\033[36mAWS_DEV_ENV_NAME\033[0m: $(AWS_DEV_ENV_NAME) (set devEnvironmentName here https://console.aws.amazon.com/iam/home?region=us-east-1#/users/$(AWS_USER)?section=tags)"
	@echo "\033[36mAWS_ACCOUNT\033[0m: $(AWS_ACCOUNT)"
	@echo "\033[36mAWS_PROFILE\033[0m: $(AWS_PROFILE)"
	@echo "\033[36mAWS_USER\033[0m: $(AWS_USER)"

os.debug:
	@echo "\033[32m=== System Info ===\033[0m"
	@echo "\033[36mOS_NAME\033[0m: $(OS_NAME)"
	@echo "\033[36mLINUX_ARCH\033[0m: $(LINUX_ARCH)"
	@echo "\033[36mARCH\033[0m: $(ARCH)"

aws.profile:
	$(shell mkdir -p ~/.aws && echo "[$(AWS_PROFILE)]\naws_access_key_id = $(AWS_ACCESS_KEY_ID)\naws_secret_access_key = $(AWS_SECRET_ACCESS_KEY)\nregion = $(AWS_REGION)" >> ~/.aws/credentials)

aws.key-pair: aws.import-ssh-key
aws.import-ssh-key:
	$(CMD_AWS_EC2_IMPORT_KEY_PAIR)

# Install AWS SSM Session Manager plugin
ssm-plugin: ssm-plugin.download ssm-plugin.install ssm-plugin.check
ssm-plugin.download:
	@$(CMD_SSM_DOWNLOAD)
ssm-plugin.install:
	@$(CMD_SSM_INSTALL)
	@$(CMD_SSM_CLEANUP)
ssm-plugin.check:
ifeq (, $(shell which session-manager-plugin))
	@echo "\033[31m[FAILED]\033[0m SSM Session Manager Plugin is not installed or incorrectly configured.\nPlease go to https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager-working-with-install-plugin.html and install manually"
else
	@echo "\n\033[32m[OK]\033[0m SSM Session Manager Plugin is installed."
endif
	
# Dependencies
########################################################################################################################
# TODO: Add validation for ability to connect to AWS
# Ensures aws toolchain is installed
aws:
ifeq (, $(AWS))
	$(error "aws cli toolchain is not installed or incorrectly configured.")
endif
