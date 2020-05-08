# Macroses
########################################################################################################################
SSH_PUBLIC_KEY ?= $(shell cat ~/.ssh/id_rsa.pub)
EC2_KEY_PAIR_NAME ?= $(ENV)-$(NAMESPACE)

# Terraform Backend Config
TERRAFORM_STATE_KEY = $(ENV)/terraform.tfstate
TERRAFORM_STATE_PROFILE = $(AWS_PROFILE)
TERRAFORM_STATE_DYNAMODB_TABLE ?= tf-state-lock
TERRAFORM_STATE_BUCKET_NAME ?= $(AWS_ACCOUNT)-tf-state
CHECKOV ?= $(DOCKER) run -v $(PWD)/.infra/env/$(ENV):/tf -i bridgecrew/checkov -d /tf
TERRAFORM ?= $(shell which terraform)
#TERRAFORM ?= $(DOCKER) run -w /terraform -v $(PWD)/:/terraform -i hashicorp/terraform:0.12.21 init

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

# TODO: Potentionally replace gomplate by terragrunt
terraform.init: gomplate terraform
	@ \
 	cd .infra/env/$(ENV) && \
	cat backend.tf.gotmpl | $(GOMPLATE) > backend.tf && \
	cat terraform.tfvars.gotmpl | $(GOMPLATE) > terraform.tfvars && \
	$(TERRAFORM) init -input=true

# TODO: Potentionally replace gomplate by terragrunt
# TODO:? Implement -target approach so we can deploy specific apps only
# TODO: generate env vars into tfvars in only one task
terraform.apply: terraform.init terraform ## Deploy infrastructure
	@ cd .infra/env/$(ENV) && \
	$(TERRAFORM) plan -out=tfplan -input=false && \
	$(TERRAFORM) apply -input=false tfplan && \
	$(TERRAFORM) output -json > output.json

terraform.test: terraform.init terraform ## Test infrastructure
	$(CHECKOV)
	@ cd .infra/env/$(ENV) && \
	$(TERRAFORM) validate ./ && \
	$(TERRAFORM) plan -input=false
	@ $(CHECKOV)

terraform.refresh: terraform.init terraform ## Test infrastructure
	@ cd .infra/env/$(ENV) && \
	$(TERRAFORM) refresh

# TODO:? Potentionally replace gomplate by terragrunt
terraform.destroy: terraform confirm ## Destroy infrastructure
	@ cd .infra/env/$(ENV) && \
	$(TERRAFORM) destroy

env.use: terraform jq
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

env.rm: terraform jq
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
