# Macroses
########################################################################################################################
SSH_PUBLIC_KEY ?= $(shell cat ~/.ssh/id_rsa.pub)
EC2_KEY_PAIR_NAME ?= $(ENV)-$(NAMESPACE)
ENV_DIR ?= $(INFRA_DIR)/env/$(ENV)
TERRAFORM_VERSION ?= "0.12.29"

# Terraform Backend Config
TERRAFORM_STATE_KEY = $(ENV)/terraform.tfstate
TERRAFORM_STATE_PROFILE = $(AWS_PROFILE)
TERRAFORM_STATE_DYNAMODB_TABLE ?= tf-state-lock
TERRAFORM_STATE_BUCKET_NAME ?= $(NAMESPACE)-tf-state
CHECKOV ?= $(DOCKER) run -v $(ENV_DIR):/tf -i bridgecrew/checkov -d /tf -s
TFLINT ?= $(DOCKER) run --rm -v $(ENV_DIR):/data -t wata727/tflint
TERRAFORM ?= $(DOCKER) run --rm -v $(ENV_DIR):/$(ENV_DIR) -v "$(ENV_DIR)/.terraform":/"$(ENV_DIR)/.terraform" -v "$(INFRA_DIR)":"$(INFRA_DIR)" -v ~/.aws/:/root/.aws:ro -w $(ENV_DIR) -i -t -e AWS_PROFILE=$(AWS_PROFILE) -e ENV=$(ENV) hashicorp/terraform:$(TERRAFORM_VERSION)

# Tasks
########################################################################################################################
infra.init: terraform.init
infra.deploy: terraform.apply
infra.destroy: terraform.destroy
infra.checkov: terraform.checkov
infra.tflint: terraform.tflint

terraform.debug:
	@echo "\033[32m=== Terraform Environment Info ===\033[0m"
	@echo "\033[36mENV\033[0m: $(ENV)"
	@echo "\033[36mTF_VAR_ssh_public_key\033[0m: $(TF_VAR_ssh_public_key)"

# TODO: Potentionally replace gomplate by terragrunt
terraform.init: gomplate terraform
	@ \
 	cd $(ENV_DIR) && \
	cat $(ICMK_TEMPLATE_TERRAFORM_BACKEND_CONFIG) | $(GOMPLATE) > backend.tf && \
	cat $(ICMK_TEMPLATE_TERRAFORM_VARS) | $(GOMPLATE) > terraform.tfvars && \
	$(TERRAFORM) init -input=true

# TODO: Potentionally replace gomplate by terragrunt
# TODO:? Implement -target approach so we can deploy specific apps only
# TODO: generate env vars into tfvars in only one task
terraform.apply: terraform.init ## Deploy infrastructure
	@ cd $(ENV_DIR) && \
	$(TERRAFORM) plan -out=tfplan -input=false && \
	$(TERRAFORM) apply -input=false tfplan && \
	$(TERRAFORM) output -json > output.json

terraform.checkov: ## Test infrastructure with checkov
	@ echo "Testing with Checkov:"
	@ echo "--------------------"
	@ cd $(ENV_DIR)
	@ $(CHECKOV)

terraform.tflint:  ## Test infrastructure with tflint
	@ echo "Testing with TFLint:"
	@ echo "--------------------"
	@ cd $(ENV_DIR)
	@ $(TFLINT) && \
	echo "Test passed (OK)"

terraform.refresh: terraform.init ## Test infrastructure
	@ cd $(ENV_DIR) && \
	$(TERRAFORM) refresh

# TODO:? Potentionally replace gomplate by terragrunt
terraform.destroy: terraform confirm ## Destroy infrastructure
	@ cd $(ENV_DIR) && \
	$(TERRAFORM) destroy

env.use: terraform jq
	@ [ -e $(ENV_DIR) ] && \
	( \
		echo "Found $(ENV)" && \
		cd $(INFRA_DIR)/env/ && \
		[ -f $(ENV)/.terraform/terraform.tfstate ] &&  ( \
			mv $(ENV)/.terraform/terraform.tfstate $(ENV)/terraform.$(shell date +%s).bak.tfstate && \
			echo "Local state file backed up as $(ENV)/terraform.$(shell date +%s).bak.tfstate. Using $(ENV)" \
		) \
		|| echo "Local state file not found. Using $(ENV). You can run 'make infra.init'" \
	) \
	|| (\
		cd $(INFRA_DIR)/env/ && \
		ln -s $(ENV_BASE) $(ENV) && \
		echo "Created new $(ENV) from $(ENV_BASE)" \
	)

env.rm: terraform jq
	@ [ -e $(ENV_DIR) ] && ( \
		cd $(INFRA_DIR)/env/ && \
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
