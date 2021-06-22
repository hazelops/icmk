# Macroses
########################################################################################################################

WAYPOINT ?= $(DOCKER) run \
	--user "root":"$(CURRENT_USERGROUP_ID)" \
	--rm \
	--hostname="$(USER)-icmk-waypoint" \
	-v "$(ENV_DIR)":"$(ENV_DIR)" \
	-v "$(INFRA_DIR)":"$(INFRA_DIR)" \
	-v "$(ROOT_DIR)":"$(ROOT_DIR)" \
	-v "$(HOME)/.aws/":"/home/waypoint/.aws:ro" \
	-v "$(HOME)/.aws/":"/root/.aws:ro" \
	-v "/var/run/docker.sock":"/var/run/docker.sock" \
	-w "$(ENV_DIR)" \
	-e AWS_PROFILE="$(AWS_PROFILE)" \
	-e ROOT_DIR="$(ROOT_DIR)" \
	-e ENV="$(ENV)" \
	$(WAYPOINT_DOCKER_IMAGE):$(WAYPOINT_VERSION)

CMD_WAYPOINT_SERVICE_BUILD ?= \
	@\
     	cd $(ENV_DIR) && \
    	cat $(WAYPOINT_CONFIG_FILE).gotpl | $(GOMPLATE) > $(WAYPOINT_CONFIG_FILE) && \
    	$(WAYPOINT) build -app $(SVC)

CMD_WAYPOINT_SERVICE_DEPLOY ?= \
	@\
     	cd $(ENV_DIR) && \
    	cat $(WAYPOINT_CONFIG_FILE).gotpl | $(GOMPLATE) > $(WAYPOINT_CONFIG_FILE) && \
    	$(WAYPOINT) deploy -release=false -app $(SVC)

CMD_WAYPOINT_SERVICE_RELEASE ?= \
	@\
     	cd $(ENV_DIR) && \
    	cat $(WAYPOINT_CONFIG_FILE).gotpl | $(GOMPLATE) > $(WAYPOINT_CONFIG_FILE) && \
    	$(WAYPOINT) release -app $(SVC)

CMD_WAYPOINT_INIT ?= \
	@\
     	cd $(ENV_DIR) && \
    	cat $(WAYPOINT_CONFIG_FILE).gotpl | $(GOMPLATE) > $(WAYPOINT_CONFIG_FILE) && \
    	$(WAYPOINT) init

CMD_WAYPOINT_INSTALL ?= \
	@\
     	cd $(ENV_DIR) && \
    	cat $(WAYPOINT_CONFIG_FILE).gotpl | $(GOMPLATE) > $(WAYPOINT_CONFIG_FILE) && \
    	$(WAYPOINT) install -accept-tos -platform=ecs -ecs-cluster=$(WAYPOINT_ECS_CLUSTER_NAME) -ecs-region=$(AWS_REGION) -runner=$(WAYPOINT_RUNNER_ENABLED) -ecs-server-image=$(WAYPOINT_DOCKER_IMAGE):$(WAYPOINT_VERSION)

CMD_WAYPOINT_DESTROY ?= \
	@\
     	cd $(ENV_DIR) && \
    	cat $(WAYPOINT_CONFIG_FILE).gotpl | $(GOMPLATE) > $(WAYPOINT_CONFIG_FILE) && \
    	$(WAYPOINT) destroy -auto-approve

CMD_WAYPOINT_CONFIG_SET ?= @$(WAYPOINT) config source-set --type=aws-ssm --config region=$(AWS_REGION)
# Tasks
########################################################################################################################
waypoint: waypoint.install waypoint.init
waypoint.config:
	$(CMD_WAYPOINT_CONFIG_SET)

waypoint.init: gomplate waypoint-dependency
	$(CMD_WAYPOINT_INIT)
	$(CMD_WAYPOINT_CONFIG_SET)

waypoint.install: gomplate waypoint-dependency
	$(CMD_WAYPOINT_INSTALL)

waypoint.destroy: gomplate waypoint-dependency
	$(CMD_WAYPOINT_DESTROY)

# Dependencies
########################################################################################################################
# Ensures terraform is installed
waypoint-dependency:
ifeq (, $(WAYPOINT))
	$(error "waypoint is not installed or incorrectly configured.")
endif
