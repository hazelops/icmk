# Macroses
########################################################################################################################
SSH_PUBLIC_KEY ?= $(shell cat ~/.ssh/id_rsa.pub)
EC2_KEY_PAIR_NAME ?= $(ENV)-$(NAMESPACE)
ENV_DIR ?= $(INFRA_DIR)/env/$(ENV)
OUTPUT_JSON_FILE = $(INFRA_DIR)/env/$(ENV)/output.json
TERRAFORM_VERSION ?= "0.12.29"

# Terraform Backend Config
TERRAFORM_STATE_KEY = $(ENV)/terraform.tfstate
TERRAFORM_STATE_PROFILE = $(AWS_PROFILE)
TERRAFORM_STATE_DYNAMODB_TABLE ?= tf-state-lock
TERRAFORM_STATE_BUCKET_NAME ?= $(NAMESPACE)-tf-state
CHECKOV ?= $(DOCKER) run -v $(ENV_DIR):/tf -i bridgecrew/checkov -d /tf -s
TFLINT ?= $(DOCKER) run --rm -v $(ENV_DIR):/data -t wata727/tflint
TERRAFORM ?= $(DOCKER) run --rm -v $(ENV_DIR):/$(ENV_DIR) -v "$(ENV_DIR)/.terraform":/"$(ENV_DIR)/.terraform" -v "$(INFRA_DIR)":"$(INFRA_DIR)" -v ~/.aws/:/root/.aws:ro -w $(ENV_DIR) -e AWS_PROFILE=$(AWS_PROFILE) -e ENV=$(ENV) hashicorp/terraform:$(TERRAFORM_VERSION)

CMD_SAVE_OUTPUT_TO_SSM = $(AWS) --profile "$(AWS_PROFILE)" ssm put-parameter --name "/$(ENV)/terraform-output" --type "SecureString" --tier "Intelligent-Tiering" --data-type "text" --overwrite --value "$$(cat $(OUTPUT_JSON_FILE) | $(BASE64))" > /dev/null && echo "\033[32m[OK]\033[0m Terraform output saved to ssm://$(ENV)/terraform-output" || echo "\033[31m[ERROR]\033[0m Terraform output saving failed"

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
terraform.apply: terraform.plan ## Deploy infrastructure
	@ cd $(ENV_DIR) && \
	$(TERRAFORM) apply -input=false tfplan && \
	$(TERRAFORM) output -json > output.json	&& \
	$(CMD_SAVE_OUTPUT_TO_SSM)

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

terraform.get: terraform.init ## Test infrastructure
	@ cd $(ENV_DIR) && \
	$(TERRAFORM) get --update

# TODO:? Potentionally replace gomplate by terragrunt
terraform.destroy: terraform confirm ## Destroy infrastructure
	@ cd $(ENV_DIR) && \
	$(TERRAFORM) destroy

terraform.destroy-quiet: ## Destroy infrastructure without confirmation
	@ cd $(ENV_DIR) && \
	$(TERRAFORM) destroy -auto-approve -force || $(TERRAFORM) destroy -auto-approve -force

terraform.output-to-ssm: ## Manual upload output.json to AWS SSM. Output.json encoded in base64.
	@ cd $(ENV_DIR) && \
	$(CMD_SAVE_OUTPUT_TO_SSM)

terraform.plan: terraform.init ## Terraform plan output for Github Action
	@ cd $(ENV_DIR) && \
	$(TERRAFORM) plan -out=tfplan -input=false && \
	$(TERRAFORM) show tfplan -input=false -no-color > $(ENV_DIR)/tfplan.txt && \
	cat $(ICMK_TEMPLATE_TERRAFORM_TFPLAN) | $(GOMPLATE) > $(ENV_DIR)/tfplan.md

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
