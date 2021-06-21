# Macroses
########################################################################################################################

WAYPOINT ?= $(DOCKER) run \
	--rm \
	--hostname="$(USER)-icmk-waypoint" \
	-v "$(ENV_DIR)":"$(ENV_DIR)" \
	-v "$(INFRA_DIR)":"$(INFRA_DIR)" \
	-v "$(ROOT_DIR)":"$(ROOT_DIR)" \
	-v "$(HOME)/.aws/":"/.aws:ro" \
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



# Tasks
########################################################################################################################

# Dependencies
########################################################################################################################
# Ensures terraform is installed
waypoint:
ifeq (, $(WAYPOINT))
	$(error "waypoint is not installed or incorrectly configured.")
endif
