# Macroses
########################################################################################################################
TAG ?= $(ENV)
SCALE ?= 3
ECS_CLUSTER_NAME ?= $(ENV)-$(NAMESPACE)
ECS_SERVICE_NAME ?= $(ENV)-$(SVC)
ECS_TASK_NAME ?= $(ENV)-$(SVC)
DOCKER_REGISTRY ?= $(AWS_ACCOUNT).dkr.ecr.$(AWS_REGION).amazonaws.com
DOCKER_IMAGE_NAME ?= $(NAMESPACE)-$(SVC)
DOCKERFILE ?= Dockerfile
PROJECT_PATH ?= projects/$(SVC)


ECS_SERVICE_TASK_ID = $(shell $(AWS) ecs --profile $(AWS_PROFILE) run-task --cluster $(NAMESPACE)-$(ENV) --task-definition "$(ECS_SERVICE_TASK_DEFINITION_ARN)" | $(JQ) -r '.tasks[].taskArn' | $(REV) | $(CUT) -d'/' -f1 | $(REV) && sleep 1)
ECS_SERVICE_TASK_DEFINITION_ARN = $(shell cat $(INFRA_DIR)/env/$(ENV)/output.json | $(JQ) -r '.$(shell echo $(SVC) | sed 's/-/_/g')_task_definition_arn.value')

CMD_ECS_SERVICE_DEPLOY = @$(ECS) deploy --profile $(AWS_PROFILE) $(ECS_CLUSTER_NAME) $(ECS_SERVICE_NAME) --task $(ECS_TASK_NAME) --image $(SVC) $(DOCKER_REGISTRY)/$(DOCKER_IMAGE_NAME):$(TAG) --diff --rollback
CMD_ECS_SERVICE_DOCKER_BUILD = $(DOCKER) build \
	. \
	-t $(DOCKER_IMAGE_NAME) \
	-t $(DOCKER_REGISTRY)/$(DOCKER_IMAGE_NAME):$(TAG) \
	-f $(PROJECT_PATH)/$(DOCKERFILE) \
	--build-arg PROJECT_PATH=$(PROJECT_PATH)

CMD_ECS_SERVICE_DOCKER_PUSH = $(DOCKER) push $(DOCKER_REGISTRY)/$(DOCKER_IMAGE_NAME):$(TAG)

# TODO: Add log polling instead of sleep?
CMD_ECS_SERVICE_TASK_RUN = @echo "Task for definition $(ECS_SERVICE_TASK_DEFINITION_ARN) has been started.\nLogs: https://console.aws.amazon.com/ecs/home?region=us-east-1$(HASHSIGN)/clusters/$(NAMESPACE)-$(ENV)/tasks/$(ECS_SERVICE_TASK_ID)/details"
CMD_ECS_SERVICE_SCALE = @$(ECS) scale --profile $(AWS_PROFILE) $(ENV)-$(NAMESPACE) $(ENV)-$(SVC) $(SCALE)
CMD_ECS_SERVICE_DESTROY = echo "Destroy $(SVC) is not implemented"

CMD_ECS_SERVICE_LOCAL_UP = $(ECS_CLI) local up --task-def-remote $(ECS_SERVICE_TASK_DEFINITION_ARN)
CMD_ECS_SERVICE_LOCAL_DOWN = $(ECS_CLI) local down --task-def-remote $(ECS_SERVICE_TASK_DEFINITION_ARN)

CMD_ECS_SERVICE_BIN = $(DOCKER) run -it --rm $(DOCKER_REGISTRY)/$(DOCKER_IMAGE_NAME):$(TAG) $(SVC)

ECS ?= $(DOCKER) run -v $(HOME)/.aws/:/root/.aws -i fabfuel/ecs-deploy:1.7.1 ecs
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
