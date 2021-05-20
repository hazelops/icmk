NAMESPACE = nutcorp
ICMK_VERSION ?= master

include .infra/icmk/init.mk

deploy: infra.deploy app.deploy
destroy: infra.destroy
secrets: app.secrets ingest.secrets

# Infrastructure
infra: terraform.init terraform.apply
terraform.test: terraform.checkov terraform.tflint

###################################################################################################
# Services
app: app.image app.push app.deploy
app.image: docker
	$(CMD_SERVICE_DOCKER_BUILD)
app.push: docker ecr.login
	$(CMD_SERVICE_DOCKER_PUSH)
app.deploy: ecs jq ## Deploy service
	$(CMD_SERVICE_DEPLOY)
app.scale: ecs ## Change scale (`make app.scale SCALE=n`)
	$(CMD_SERVICE_SCALE)
app.destroy: confirm
	$(CMD_SERVICE_DESTROY)
app.secrets:
	$(CMD_SERVICE_SECRETS_PUSH)
app.up:
	$(CMD_SERVICE_LOCAL_UP)
app.down:
	$(CMD_SERVICE_LOCAL_DOWN)
app.purge-cache:
	$(CMD_ECR_DOCKER_PURGE_CACHE)
