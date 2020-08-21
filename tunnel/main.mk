# Macroses
########################################################################################################################
SSH_CONFIG ?= $(INFRA_DIR)/env/$(ENV)/ssh.config

CMD_BASTION_SSH_TUNNEL_CONFIG_CREATE = echo $(shell $(AWS) ssm get-parameter --name "/$(ENV)/terraform-output" --with-decryption | $(JQ) -r '.Parameter.Value' | $(BASE64) -d | $(JQ) -r '.ssh_forward_config.value[]' > $(SSH_CONFIG)) && echo "$(HASHSIGN) SSH Tunnel Config \n$(HASHSIGN) Use the Forward ports to connect to remote instances (localhost:<PORT>)\n-----" && cat $(SSH_CONFIG)

# Bastion commands are stored in SSM now, so user without admin permissions won't be able to connect
CMD_BASTION_SSH_TUNNEL_UP = $(shell $(AWS) ssm get-parameter --name "/$(ENV)/terraform-output" --with-decryption | $(JQ) -r '.Parameter.Value' | $(BASE64) -d | $(JQ) -r '.cmd.value.tunnel.up') -F $(SSH_CONFIG)
CMD_BASTION_SSH_TUNNEL_DOWN = $(shell $(AWS) ssm get-parameter --name "/$(ENV)/terraform-output" --with-decryption | $(JQ) -r '.Parameter.Value' | $(BASE64) -d | $(JQ) -r '.cmd.value.tunnel.down') -F $(SSH_CONFIG) && echo "SSH tunnel disabled"
CMD_BASTION_SSH_TUNNEL_STATUS = $(shell $(AWS) ssm get-parameter --name "/$(ENV)/terraform-output" --with-decryption | $(JQ) -r '.Parameter.Value' | $(BASE64) -d | $(JQ) -r '.cmd.value.tunnel.status') -F $(SSH_CONFIG) && echo "SSH tunnel is up with the following config:\n-----" && cat $(SSH_CONFIG)


# Tasks
########################################################################################################################
tunnel: tunnel.up
tunnel.up: tunnel.config
	@$(CMD_BASTION_SSH_TUNNEL_UP)

tunnel.down:
	@$(CMD_BASTION_SSH_TUNNEL_DOWN)

tunnel.status:
	@$(CMD_BASTION_SSH_TUNNEL_STATUS)

tunnel.config:
	@$(CMD_BASTION_SSH_TUNNEL_CONFIG_CREATE)

# Dependencies
########################################################################################################################
