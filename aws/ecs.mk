# Macroses
########################################################################################################################
TAG ?= $(ENV)
TAG_LATEST ?= $(ENV)-latest

SCALE ?= 3
ECS_CLUSTER_NAME ?= $(ENV)-$(NAMESPACE)
ECS_SERVICE_NAME ?= $(ENV)-$(SVC)
ECS_TASK_NAME ?= $(ENV)-$(SVC)
DOCKER_REGISTRY ?= $(AWS_ACCOUNT).dkr.ecr.$(AWS_REGION).amazonaws.com
DOCKER_IMAGE_NAME ?= $(NAMESPACE)-$(SVC)
DOCKERFILE ?= Dockerfile
PROJECT_PATH ?= projects/$(SVC)
ECS_DEPLOY_VERSION ?= 1.10.1
ENABLE_BUILDKIT ?= 1
ENABLE_INLINE_CACHE ?= $(ENABLE_BUILDKIT)

ECS_SERVICE_TASK_NETWORK_CONFIG = $(shell cat $(INFRA_DIR)/env/$(ENV)/output.json | $(JQ) -rc '.$(shell echo $(SVC) | sed 's/-/_/g')_task_network_configuration.value')
ECS_SERVICE_TASK_LAUNCH_TYPE = $(shell cat $(INFRA_DIR)/env/$(ENV)/output.json | $(JQ) -rc '.$(shell echo $(SVC) | sed 's/-/_/g')_task_launch_type.value')

ECS_SERVICE_TASK_ID = $(shell $(AWS) ecs --profile $(AWS_PROFILE) run-task --cluster $(ECS_CLUSTER_NAME) --task-definition "$(ECS_SERVICE_TASK_DEFINITION_ARN)" --network-configuration '$(ECS_SERVICE_TASK_NETWORK_CONFIG)' --launch-type "$(ECS_SERVICE_TASK_LAUNCH_TYPE)" | $(JQ) -r '.tasks[].taskArn' | $(REV) | $(CUT) -d'/' -f1 | $(REV) && sleep 1)
ECS_SERVICE_TASK_DEFINITION_ARN = $(shell $(AWS) ecs --profile $(AWS_PROFILE) describe-task-definition --task-definition $(ECS_TASK_NAME) | $(JQ) -r '.taskDefinition.taskDefinitionArn')

CMD_ECS_SERVICE_DEPLOY = @$(ECS) deploy --profile $(AWS_PROFILE) $(ECS_CLUSTER_NAME) $(ECS_SERVICE_NAME) --task $(ECS_SERVICE_TASK_DEFINITION_ARN) --image $(SVC) $(DOCKER_REGISTRY)/$(DOCKER_IMAGE_NAME):$(TAG) --diff --rollback
CMD_ECS_SERVICE_DOCKER_BUILD = DOCKER_BUILDKIT=$(ENABLE_BUILDKIT) $(DOCKER) build \
	. \
	-t $(DOCKER_IMAGE_NAME) \
	-t $(DOCKER_REGISTRY)/$(DOCKER_IMAGE_NAME):$(TAG) \
	-t $(DOCKER_REGISTRY)/$(DOCKER_IMAGE_NAME):$(TAG_LATEST) \
	-f $(PROJECT_PATH)/$(DOCKERFILE) \
	--cache-from $(DOCKER_REGISTRY)/$(DOCKER_IMAGE_NAME):$(TAG_LATEST) \
	--build-arg DOCKER_REGISTRY=$(DOCKER_REGISTRY) \
	--build-arg DOCKER_IMAGE_NAME=$(DOCKER_IMAGE_NAME) \
	--build-arg ENV=$(ENV) \
	--build-arg BUILDKIT_INLINE_CACHE=$(ENABLE_INLINE_CACHE) \
	--build-arg PROJECT_PATH=$(PROJECT_PATH)

CMD_ECS_SERVICE_DOCKER_PUSH = \
	$(DOCKER) push $(DOCKER_REGISTRY)/$(DOCKER_IMAGE_NAME):$(TAG) && \
	$(DOCKER) push $(DOCKER_REGISTRY)/$(DOCKER_IMAGE_NAME):$(TAG_LATEST)

# TODO: Add log polling instead of sleep?
CMD_ECS_SERVICE_TASK_RUN = @echo "Task for definition $(ECS_SERVICE_TASK_DEFINITION_ARN) has been started.\nLogs: https://console.aws.amazon.com/ecs/home?region=$(AWS_REGION)$(HASHSIGN)/clusters/$(ECS_CLUSTER_NAME)/tasks/$(ECS_SERVICE_TASK_ID)/details"
CMD_ECS_SERVICE_SCALE = @$(ECS) scale --profile $(AWS_PROFILE) $(ECS_CLUSTER_NAME) $(ECS_TASK_NAME) $(SCALE)
CMD_ECS_SERVICE_DESTROY = echo "Destroy $(SVC) is not implemented"

CMD_ECS_SERVICE_LOCAL_UP = $(ECS_CLI) local up --task-def-remote $(ECS_SERVICE_TASK_DEFINITION_ARN)
CMD_ECS_SERVICE_LOCAL_DOWN = $(ECS_CLI) local down --task-def-remote $(ECS_SERVICE_TASK_DEFINITION_ARN)

CMD_ECS_SERVICE_BIN = $(DOCKER) run -it --rm $(DOCKER_REGISTRY)/$(DOCKER_IMAGE_NAME):$(TAG) $(SVC)

ECS ?= $(DOCKER) run -v $(HOME)/.aws/:/root/.aws -i fabfuel/ecs-deploy:$(ECS_DEPLOY_VERSION) ecs
ECS_CLI ?= $(DOCKER) run \
	-v /var/run/docker.sock:/var/run/docker.sock \
	-v $(HOME)/.aws/:/root/.aws \
	-e AWS_PROFILE=$(AWS_PROFILE) \
	-e AWS_REGION=$(AWS_REGION) \
	-i jexperton/ecs-cli

# Tasks
########################################################################################################################
ecr.login: aws
	@echo $(shell $(AWS) --profile=$(AWS_PROFILE) ecr get-login-password | docker login --username AWS --password-stdin $(DOCKER_REGISTRY))

# Dependencies
########################################################################################################################
# Ensures ecs-deploy is installed
ecs:
ifeq (, $(ECS))
	$(error "ecs-deploy is not installed or incorrectly configured. Run \\n`pip install ecs-deploy`. More info: https://github.com/fabfuel/ecs-deploy")
endif

# Ensures ecs-cli is installed
ecs-cli:
ifeq (, $(ECS_CLI))
	$(error "AWS ecs-cli is not installed or incorrectly configured." )
endif

# Backwards Compatibility, should be removed in 2.0
########################################################################################################################
CMD_SERVICE_DEPLOY = $(CMD_ECS_SERVICE_DEPLOY)
CMD_SERVICE_DOCKER_BUILD = $(CMD_ECS_SERVICE_DOCKER_BUILD)
CMD_SERVICE_DOCKER_PUSH = $(CMD_ECS_SERVICE_DOCKER_PUSH)
CMD_SERVICE_TASK_RUN = $(CMD_ECS_SERVICE_TASK_RUN)
CMD_SERVICE_SCALE = $(CMD_ECS_SERVICE_SCALE)
CMD_SERVICE_DESTROY = $(CMD_ECS_SERVICE_DESTROY)
CMD_SERVICE_LOCAL_UP =$(CMD_ECS_SERVICE_LOCAL_UP)
CMD_SERVICE_LOCAL_DOWN = $(CMD_ECS_SERVICE_LOCAL_DOWN)
CMD_SERVICE_BIN = $(CMD_ECS_SERVICE_BIN)
