# Macroses
########################################################################################################################
TF_VAR_ssh_public_key ?= $(shell cat ~/.ssh/id_rsa.pub)

# Terraform Backend Config
TERRAFORM_STATE_KEY = $(ENV)/terraform.tfstate
TERRAFORM_STATE_PROFILE = $(AWS_PROFILE)
TERRAFORM_STATE_DYNAMODB_TABLE ?= tf-state-lock
TERRAFORM_STATE_BUCKET_NAME ?= $(AWS_ACCOUNT)-tf-state
CHECKOV ?= docker run -v $(PWD)/.infra/env/$(ENV):/tf -i bridgecrew/checkov -d /tf
TERRAFORM ?= $(shell which terraform)
#TERRAFORM ?= docker run -w /terraform -v $(PWD)/:/terraform -i hashicorp/terraform:0.12.21 init

ENVSUBST ?= docker run \
	-e TERRAFORM_STATE_BUCKET_NAME=$(TERRAFORM_STATE_BUCKET_NAME) \
	-e TERRAFORM_STATE_KEY=$(TERRAFORM_STATE_KEY) \
	-e TERRAFORM_STATE_REGION=$(TERRAFORM_STATE_REGION) \
	-e TERRAFORM_STATE_PROFILE=$(TERRAFORM_STATE_PROFILE) \
	-e TERRAFORM_STATE_DYNAMODB_TABLE=$(TERRAFORM_STATE_DYNAMODB_TABLE) \
	-i widerplan/envsubst

# Tasks
########################################################################################################################
infra.init: terraform.init
infra.deploy: terraform.apply
infra.destroy: terraform.destroy
infra.test: terraform.test

terraform.debug:
	@echo "\033[32m=== Terraform Environment Info ===\033[0m"
	@echo "\033[36mENV\033[0m: $(ENV)"
	@echo "\033[36mTF_VAR_ssh_public_key\033[0m: $(TF_VAR_ssh_public_key)"

# TODO: Potentionally replace envsubst by terragrunt
terraform.init: envsubst terraform
	@ cd .infra/env/$(ENV) && \
	cat backend.tf.tmpl | $(ENVSUBST) > backend.tf && \
	$(TERRAFORM) init -input=true


# TODO: Potentionally replace envsubst by terragrunt
# TODO:? Implement -target approach so we can deploy specific apps only
terraform.apply: terraform.init terraform ## Deploy infrastructure
	@ cd .infra/env/$(ENV) && \
	TF_VAR_env="$(ENV)" \
	TF_VAR_aws_profile="$(AWS_PROFILE)" \
	TF_VAR_aws_region="$(AWS_REGION)" \
	TF_VAR_ec2_key_pair_name="$(ENV)-$(NAMESPACE)" \
	TF_VAR_docker_image_tag="$(TAG)" \
	TF_VAR_ssh_public_key="$(TF_VAR_ssh_public_key)" \
	TF_VAR_docker_registry="$(DOCKER_REGISTRY)" \
	$(TERRAFORM) plan -out=tfplan -input=false && \
	$(TERRAFORM) apply -input=false tfplan && \
	$(TERRAFORM) output -json > output.json

terraform.test: terraform.init terraform ## Test infrastructure
	$(CHECKOV)
	@ cd .infra/env/$(ENV) && \
	$(TERRAFORM) validate ./ && \
	TF_VAR_env="$(ENV)" \
	TF_VAR_aws_profile="$(AWS_PROFILE)" \
	TF_VAR_aws_region="$(AWS_REGION)" \
	TF_VAR_ec2_key_pair_name="$(NAMESPACE)-$(ENV)" \
	TF_VAR_docker_image_tag="$(TAG)" \
	TF_VAR_ssh_public_key="$(TF_VAR_ssh_public_key)" \
	TF_VAR_docker_registry="$(DOCKER_REGISTRY)" \
	$(TERRAFORM) plan -input=false
	@ $(CHECKOV)


# TODO:? Potentionally replace envsubst by terragrunt
terraform.destroy: terraform confirm ## Destroy infrastructure
	@ cd .infra/env/$(ENV) && \
	TF_VAR_env="$(ENV)" \
	TF_VAR_aws_profile="$(AWS_PROFILE)" \
	TF_VAR_aws_region="$(AWS_REGION)" \
	TF_VAR_ec2_key_pair_name="$(NAMESPACE)-$(ENV)" \
	TF_VAR_docker_image_tag="$(TAG)" \
	TF_VAR_ssh_public_key="$(TF_VAR_ssh_public_key)" \
	TF_VAR_docker_registry="$(DOCKER_REGISTRY)" \
	$(TERRAFORM) destroy

env.use: envsubst terraform jq
	@ [ -e .infra/env/$(ENV) ] && \
	( \
		echo "Found $(ENV)" && \
		cd .infra/env/ && \
		[ -f $(ENV)/.terraform/terraform.tfstate ] &&  ( \
			mv $(ENV)/.terraform/terraform.tfstate $(ENV)/terraform.$(shell date +%s).bak.tfstate && \
			echo "Local state file backed up as $(ENV)/terraform.$(shell date +%s).bak.tfstate. Using $(ENV)" \
		) \
		|| echo "Local state file not found. Using $(ENV). You can run 'make infra.init'" \
	) \
	|| (\
		cd .infra/env/ && \
		ln -s $(ENV_BASE) $(ENV) && \
		echo "Created new $(ENV) from $(ENV_BASE)" \
	)

env.rm: envsubst terraform jq
	@ [ -e .infra/env/$(ENV) ] && ( \
		cd .infra/env/ && \
		[ -f $(ENV)/.terraform/terraform.tfstate ] && ( \
			mv $(ENV)/.terraform/terraform.tfstate $(ENV)/terraform.$(ENV).$(shell date +%s).bak.tfstate \
		) || echo "No local state file found." && \
		unlink $(ENV) && \
		echo "Deleted $(ENV)" \
	) || echo "No $(ENV) found. Can't de-init"


# Dependencies
########################################################################################################################
# Ensures terraform is installed
terraform:
ifeq (, $(TERRAFORM))
	$(error "terraform is not installed or incorrectly configured.")
endif
