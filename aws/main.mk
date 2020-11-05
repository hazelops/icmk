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
AWS ?= $(DOCKER) run -v $(HOME)/.aws/:/root/.aws -i amazon/aws-cli:2.0.40
CMD_AWS_LOGS_TAIL = @$(AWS) logs tail --profile $(AWS_PROFILE) $(SERVICE_NAME) --follow
CMD_AWS_EC2_IMPORT_KEY_PAIR = @$(AWS) ec2 import-key-pair  --key-name="$(EC2_KEY_PAIR_NAME)" --profile $(AWS_PROFILE) --public-key-material="$(SSH_PUBLIC_KEY_BASE64)"

# Getting OS|Linux info
OS_NAME ?= $(shell uname -s)
OS_DISTRIB ?= $(shell awk '/DISTRIB_ID=/' /etc/*-release | sed 's/DISTRIB_ID=//')
LINUX_CPU_VENDOR ?= $(shell lscpu | grep "Vendor ID:")
LINUX_ARCH ?= $(shell uname -m | sed 's/x86_//;s/i[3-6]86/32/')
ARCH ?= $(shell echo $$(if echo "$(LINUX_CPU_VENDOR)" | grep -Fqe "Intel"; then echo "$(LINUX_ARCH)bit"; else echo "arm$(LINUX_ARCH)"; fi))
LINUX_DISTRIB_TEMP ?= $(shell echo $$([ "$(OS_DISTRIB)" = "Ubuntu" ] && echo "ubuntu" || echo "linux")) #> /dev/null
LINUX_DISTRIB ?= $(shell echo $(LINUX_DISTRIB_TEMP) | xargs)
LINUX_PACKAGE_EXT ?= $(shell echo $$([ "$(OS_DISTRIB)" = "Ubuntu" ] && echo ".deb" || echo ".rpm")) #> /dev/null
# Download Session Manager cmds
SSM_DOWNLOAD_FOR_MAC_OS ?= curl "https://s3.amazonaws.com/session-manager-downloads/plugin/latest/mac/sessionmanager-bundle.zip" -o "sessionmanager-bundle.zip" && unzip sessionmanager-bundle.zip
SSM_DOWNLOAD_FOR_LINUX_OS ?= curl "https://s3.amazonaws.com/session-manager-downloads/plugin/latest/$(LINUX_DISTRIB)_$(ARCH)/session-manager-plugin$(LINUX_PACKAGE_EXT)" -o "session-manager-plugin$(LINUX_PACKAGE_EXT)"
SSM_DOWNLOAD ?= $(shell echo $$(if [ "$(OS_NAME)" = "Linux" ]; then echo "$(SSM_DOWNLOAD_FOR_LINUX_OS)"; else echo "$(SSM_DOWNLOAD_FOR_MAC_OS)"; fi))
# Installation Session Manager cmds
LINUX_INSTALLER ?= $(shell echo $$(if [ "$(OS_DISTRIB)" = "Ubuntu" ]; then echo "sudo dpkg -i"; else echo "sudo yum install -y"; fi))
SSM_INSTALL_ON_MAC_OS ?= sudo ./sessionmanager-bundle/install -i /usr/local/sessionmanagerplugin -b /usr/local/bin/session-manager-plugin
SSM_INSTALL_ON_LINUX_OS ?= $(LINUX_INSTALLER) session-manager-plugin$(LINUX_PACKAGE_EXT)
SSM_INSTALL ?= $(shell echo $$(if [ "$(OS_NAME)" = "Linux" ]; then echo "$(SSM_INSTALL_ON_LINUX_OS)"; else echo "$(SSM_INSTALL_ON_MAC_OS)"; fi))
# Cleanup Session Manager installation package
SSM_CLEANUP_ON_MAC_OS ?= rm -rf sessionmanager-bundle sessionmanager-bundle.zip
SSM_CLEANUP_ON_LINUX_OS ?= rm -rf session-manager-plugin$(LINUX_PACKAGE_EXT)
SSM_CLEANUP ?= $(shell echo $$(if [ "$(OS_NAME)" = "Linux" ]; then echo "$(SSM_CLEANUP_ON_LINUX_OS)"; else echo "$(SSM_CLEANUP_ON_MAC_OS)"; fi))
# Post-install Session Manager check
SSM_POST_INSTALL_CHECK = $(shell session-manager-plugin)

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

aws.key-pair: aws.import-ssh-key
aws.import-ssh-key:
	$(CMD_AWS_EC2_IMPORT_KEY_PAIR)

# Install AWS SSM Session Manager plugin
ssm-plugin: ssm-plugin.download ssm-plugin.install ssm-plugin.check
ssm-plugin.download:
	@$(SSM_DOWNLOAD)
ssm-plugin.install:
	@$(SSM_INSTALL)
	@$(SSM_CLEANUP)
ssm-plugin.check:
ifeq (, $(SSM_POST_INSTALL_CHECK))
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
