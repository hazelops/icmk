# This file should contain variables used in current module
##################################################################
# main variables
WAYPOINT_VERSION ?= latest
WAYPOINT_DOCKER_IMAGE = hazelops/waypoint
WAYPOINT_CONFIG_FILE ?= $(ENV_DIR)/waypoint.hcl
WAYPOINT_ECS_CLUSTER_NAME ?= $(ENV)-$(NAMESPACE)-waypoint
WAYPOINT_RUNNER_ENABLED ?= true
