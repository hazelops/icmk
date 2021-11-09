# Macroses
########################################################################################################################
# TODO: Waypoint Config mount is MacOS-only for now. Needs to be platform-independent
WAYPOINT ?= $(DOCKER) run \
	--user "root":"$(CURRENT_USERGROUP_ID)" \
	--rm \
	--hostname="$(USER)-icmk-waypoint" \
	-v "$(ENV_DIR)":"$(ENV_DIR)" \
	-v "$(INFRA_DIR)":"$(INFRA_DIR)" \
	-v "$(ROOT_DIR)":"$(ROOT_DIR)" \
	-v "$(HOME)/.aws/":"/home/waypoint/.aws:ro" \
	-v "$(HOME)/Library/Preferences/waypoint":"/home/waypoint/.config/waypoint" \
	-v "$(HOME)/.waypoint/":"/home/waypoint/.waypoint" \
	-v "$(HOME)/.aws/":"/root/.aws:ro" \
	-v "/var/run/docker.sock":"/var/run/docker.sock" \
	-w "$(ENV_DIR)" \
	-e AWS_PROFILE="$(AWS_PROFILE)" \
	-e ROOT_DIR="$(ROOT_DIR)" \
	-e ENV="$(ENV)" \
	$(WAYPOINT_DOCKER_IMAGE):$(WAYPOINT_VERSION)

WAYPOINT_INTERPOLATE_VARS ?= \
	sed -i "s/Env_VPC_PRIVATE_SUBNETS/$(VPC_PRIVATE_SUBNETS)/g" $(ENV_DIR)/waypoint.wpvars && \
	sed -i "s/Env_VPC_PUBLIC_SUBNETS/$(VPC_PUBLIC_SUBNETS)/g" $(ENV_DIR)/waypoint.wpvars && \
	sed -i "s/Env_ZONE_ID/$(ZONE_ID)/g" $(ENV_DIR)/waypoint.wpvars

CMD_WAYPOINT_SERVICE_BUILD ?= \
	@\
     	cd $(ENV_DIR) && \
    	cat $(ICMK_TEMPLATE_WAYPOINT_VARS) | $(GOMPLATE) > waypoint.wpvars && \
		$(WAYPOINT_INTERPOLATE_VARS) && \
		cat waypoint.wpvars && \
    	$(WAYPOINT) build -var-file=waypoint.wpvars -app $(SVC)

CMD_WAYPOINT_SERVICE_DEPLOY ?= \
	@\
     	cd $(ENV_DIR) && \
    	cat $(ICMK_TEMPLATE_WAYPOINT_VARS) | $(GOMPLATE) > waypoint.wpvars && \
    	$(WAYPOINT) deploy -var-file=waypoint.wpvars -release=false -app $(SVC)

CMD_WAYPOINT_SERVICE_RELEASE ?= \
	@\
     	cd $(ENV_DIR) && \
    	cat $(ICMK_TEMPLATE_WAYPOINT_VARS) | $(GOMPLATE) > waypoint.wpvars && \
    	$(WAYPOINT) release -app $(SVC)

CMD_WAYPOINT_INIT ?= \
	@\
     	cd $(ENV_DIR) && \
    	cat $(ICMK_TEMPLATE_WAYPOINT_VARS) | $(GOMPLATE) > waypoint.wpvars && \
    	$(WAYPOINT) init

CMD_WAYPOINT_INSTALL ?= \
	@\
     	cd $(ENV_DIR) && \
		cat $(ICMK_TEMPLATE_WAYPOINT_VARS) | $(GOMPLATE) > waypoint.wpvars && \
    	$(WAYPOINT) install -accept-tos -platform=ecs -ecs-cluster=$(WAYPOINT_ECS_CLUSTER_NAME) -ecs-region=$(AWS_REGION) -runner=$(WAYPOINT_RUNNER_ENABLED) -ecs-server-image=$(WAYPOINT_DOCKER_IMAGE):$(WAYPOINT_VERSION)

CMD_WAYPOINT_UNINSTALL ?= \
	@\
     	cd $(ENV_DIR) && \
    	cat $(ICMK_TEMPLATE_WAYPOINT_VARS) | $(GOMPLATE) > waypoint.wpvars && \
    	$(WAYPOINT) server uninstall -platform=ecs -ecs-cluster=$(WAYPOINT_ECS_CLUSTER_NAME) -ecs-region=$(AWS_REGION) -auto-approve -ignore-runner-error

CMD_WAYPOINT_DESTROY ?= \
	@\
     	cd $(ENV_DIR) && \
    	cat $(ICMK_TEMPLATE_WAYPOINT_VARS) | $(GOMPLATE) > waypoint.wpvars && \
    	$(WAYPOINT) destroy -auto-approve

CMD_WAYPOINT_AUTH ?= \
	@\
     	cd $(ENV_DIR) && \
    	cat $(ICMK_TEMPLATE_WAYPOINT_VARS) | $(GOMPLATE) > waypoint.wpvars && \
    	$(WAYPOINT) token new


CMD_WAYPOINT_CONFIG_SET ?= @$(WAYPOINT) config source-set --type=aws-ssm --config region=$(AWS_REGION)
# Tasks
########################################################################################################################
waypoint: waypoint.install waypoint.init
waypoint.config:
	$(CMD_WAYPOINT_CONFIG_SET)

waypoint.init: gomplate waypoint-dependency
	$(CMD_WAYPOINT_CONTEXT_CLEAR)
	$(CMD_WAYPOINT_INIT)
	$(CMD_WAYPOINT_CONFIG_SET)

waypoint.install: gomplate waypoint-dependency
	$(CMD_WAYPOINT_INSTALL)

waypoint.auth: gomplate waypoint-dependency
	$(CMD_WAYPOINT_AUTH)

waypoint.destroy: gomplate waypoint-dependency
	$(CMD_WAYPOINT_DESTROY)

waypoint.uninstall: gomplate waypoint-dependency
	$(CMD_WAYPOINT_UNINSTALL)

waypoint.context-create:
	$(CMD_WAYPOINT_CONTEXT_CREATE)
waypoint.debug: waypoint-dependency
	@echo "\033[32m=== Waypoint Info ===\033[0m"
	@echo "\033[36mDocker Image\033[0m: $(WAYPOINT_DOCKER_IMAGE):$(WAYPOINT_VERSION)"
	@echo "\033[36mVersion\033[0m: $(shell $(WAYPOINT) version)"

# Dependencies
########################################################################################################################
# Ensures terraform is installed
waypoint-dependency:
ifeq (, $(WAYPOINT))
	$(error "waypoint is not installed or incorrectly configured.")
endif
