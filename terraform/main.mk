# Macroses
########################################################################################################################
SSH_PUBLIC_KEY ?= $(shell cat ~/.ssh/id_rsa.pub)
SSH_PUBLIC_KEY_BASE64 = $(shell echo "$(SSH_PUBLIC_KEY)" | $(BASE64))
EC2_KEY_PAIR_NAME ?= $(ENV)-$(NAMESPACE)
ENV_DIR ?= $(INFRA_DIR)/env/$(ENV)
OUTPUT_JSON_FILE = $(ENV_DIR)/.terraform/output.json

AWS_LIMITS ?= @ ( echo $(foreach item, $(shell echo $(AWS_LIMITS_LIST) | $(JQ) -e -r '. | to_entries[] | .key' ), \
"$$(if [ $(shell grep -c "+ resource \"$(item)\"" $(ENV_DIR)/.terraform/tfplan.txt) -lt $(shell echo $(AWS_LIMITS_LIST) | $(JQ) -r '.$(item)[].value') ]; \
then echo "\n\033[32m[OK]\033[0m $(item) limit"; \
else echo "\n\033[33m[WARNING]\033[0m $(item) limit (Value:$(shell echo $(AWS_LIMITS_LIST) | $(JQ) -r '.$(item)[].value')) exceeded! \
Current value:$(shell grep -c "+ resource \"$(item)\"" $(ENV_DIR)/.terraform/tfplan.txt) \
\033[33m To request a service quota increase:\033[0m \033[36m aws service-quotas request-service-quota-increase --service-code $(shell echo $(AWS_LIMITS_LIST) | $(JQ) -r '.$(item)[].service') --quota-code $(shell echo $(AWS_LIMITS_LIST) | $(JQ) -r '.$(item)[].quotacode') --desired-value <your_desired_value> \033[0m"; fi )") )

# Terraform Backend Config
TERRAFORM_STATE_KEY ?= $(ENV)/terraform.tfstate
TERRAFORM_STATE_PROFILE ?= $(AWS_PROFILE)
TERRAFORM_STATE_REGION ?= $(AWS_REGION)
TERRAFORM_STATE_BUCKET_NAME ?= $(NAMESPACE)-tf-state
CHECKOV ?= $(DOCKER) run --user "$(CURRENT_USER_ID):$(CURRENT_USERGROUP_ID)" -v $(ENV_DIR):/tf -i bridgecrew/checkov -d /tf -s
TFLINT ?= $(DOCKER) run --user "$(CURRENT_USER_ID):$(CURRENT_USERGROUP_ID)" --rm -v $(ENV_DIR):/data -t wata727/tflint
TFLOCK ?= $(DOCKER) run --rm --hostname=$(USER)-icmk-terraform -v $(ENV_DIR):/$(ENV_DIR) -v "$(ENV_DIR)/.terraform":/"$(ENV_DIR)/.terraform" -v "$(INFRA_DIR)":"$(INFRA_DIR)" -v $(HOME)/.aws/:/root/.aws:ro -w $(ENV_DIR) -e AWS_PROFILE=$(AWS_PROFILE) -e ENV=$(ENV) hazelops/tflock
TF_LOG_PATH ?= /$(ENV_DIR)/tflog.txt

TF_VERSION_MAJOR ?= $$(echo $(TERRAFORM_VERSION) | tr "." "\n" | head -n 1)
TERRAFORM_VERSION_VERIFICATION ?= $(shell echo $$(if [ "$(TF_VERSION_MAJOR)" -lt "1" ]; then echo "\033[33m[WARNING]\033[0m Your version of Terraform is out of date! The minimally compatible version: 1.0.0"; else echo "Terraform version: $(TERRAFORM_VERSION)"; fi))

terraform.compat:
	@echo $(TERRAFORM_VERSION_VERIFICATION)

TERRAFORM ?= $(DOCKER) run \
	--user "$(CURRENT_USER_ID)":"$(CURRENT_USERGROUP_ID)" \
	--rm \
	--hostname="$(USER)-icmk-terraform" \
	-v "$(ENV_DIR)":"$(ENV_DIR)" \
	-v "$(INFRA_DIR)":"$(INFRA_DIR)" \
	-v "$(HOME)/.aws/":"/.aws:ro" \
	-w "$(ENV_DIR)" \
	-e AWS_PROFILE="$(AWS_PROFILE)" $(AWS_MFA_ENV_VARS) \
	-e ENV="$(ENV)" \
	-e TF_LOG="$(TF_LOG_LEVEL)" \
	-e TF_LOG_PATH="$(TF_LOG_PATH)" \
	hashicorp/terraform:$(TERRAFORM_VERSION)

CMD_SAVE_OUTPUT_TO_SSM = $(AWS) ssm put-parameter --name "/$(ENV)/terraform-output" --type "SecureString" --tier "Intelligent-Tiering" --data-type "text" --overwrite --value "$$(cat $(OUTPUT_JSON_FILE) | $(BASE64))" > /dev/null && echo "\033[32m[OK]\033[0m Terraform output saved to ssm://$(ENV)/terraform-output" || (echo "\033[31m[ERROR]\033[0m Terraform output saving failed" && exit 1)

# Optional cmd to be used, because the branch related to TF v0.13 upgrade already have updated versions.tf files
CMD_TERRAFORM_MODULES_UPGRADE = $(shell find $(INFRA_DIR)/terraform -name '*.tf' | xargs -n1 dirname | uniq | xargs -n1 $(TERRAFORM) 0.13upgrade -yes)
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
CMD_TERRAFORM_INIT ?= @ cd $(ENV_DIR) && \
	cat $(ICMK_TEMPLATE_TERRAFORM_BACKEND_CONFIG) | $(GOMPLATE) > backend.tf && \
	cat $(ICMK_TEMPLATE_TERRAFORM_VARS) | $(GOMPLATE) > terraform.tfvars && \
	$(TERRAFORM) init -input=true

terraform.init: terraform.compat gomplate terraform
	$(CMD_TERRAFORM_INIT)

# TODO: Potentionally replace gomplate by terragrunt
# TODO:? Implement -target approach so we can deploy specific apps only
# TODO: generate env vars into tfvars in only one task

terraform.lock: terraform.init
	@ \
 	cd $(ENV_DIR) && \
 	$(TFLOCK)

# Re-initialization of the backend to TF v0.13 version format
terraform.reconfig:
	@ \
	cd $(ENV_DIR) && \
	$(TERRAFORM) init -input=true -reconfigure

# TF Apply / Deploy infrastructure
CMD_TERRAFORM_APPLY ?= @ cd $(ENV_DIR) && \
	$(TERRAFORM) apply -input=false $(ENV_DIR)/.terraform/tfplan && \
	$(TERRAFORM) output -json > $(ENV_DIR)/.terraform/output.json && \
	$(CMD_SAVE_OUTPUT_TO_SSM)

terraform.apply: terraform.plan
	$(CMD_TERRAFORM_APPLY)

## Test infrastructure with checkov
terraform.checkov: 
	@ echo "Testing with Checkov:"
	@ echo "--------------------"
	@ cd $(ENV_DIR)
	@ $(CHECKOV)

## Test infrastructure with tflint
terraform.tflint:  
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
terraform.destroy: ## Destroy infrastructure
	@ cd $(ENV_DIR) && \
	$(TERRAFORM) destroy

terraform.destroy-quiet: ## Destroy infrastructure without confirmation
	@ cd $(ENV_DIR) && \
	$(TERRAFORM) destroy -auto-approve || $(TERRAFORM) destroy -auto-approve
	@ echo "\n\033[36m[INFO] Please run: make secrets.delete or app.delete_secrets now\033[0m"

terraform.output-to-ssm: ## Manual upload output.json to AWS SSM. Output.json encoded in base64.
	@ cd $(ENV_DIR) && \
	$(CMD_SAVE_OUTPUT_TO_SSM)

## Terraform plan output for Github Action
CMD_TERRAFORM_PLAN ?= @ cd $(ENV_DIR) && \
	$(TERRAFORM) plan -out=$(ENV_DIR)/.terraform/tfplan -input=false && \
	$(TERRAFORM) show $(ENV_DIR)/.terraform/tfplan -input=false -no-color > $(ENV_DIR)/.terraform/tfplan.txt && \
	cat $(ICMK_TEMPLATE_TERRAFORM_TFPLAN) | $(GOMPLATE) > $(ENV_DIR)/.terraform/tfplan.md

terraform.plan: terraform.init 
	$(CMD_TERRAFORM_PLAN)


terraform.limits: terraform.plan
	@ $(AWS_LIMITS)

# Upgrading TF from v0.12 to v0.13
terraform.13upgrade:
	@ echo "Terraform upgrade to v0.13 :"
	@ echo "-----------------------------"
	@ $(CMD_TERRAFORM_MODULES_UPGRADE)

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
