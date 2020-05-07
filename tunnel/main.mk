
# Macroses
########################################################################################################################

SSH_CONFIG ?= .infra/env/$(ENV)/ssh.config

CMD_BASTION_SSH_TUNNEL_PROFILE = echo $(shell cat .infra/env/$(ENV)/output.json | $(JQ) -r '.ssh_forward_profile.value[]' > $(SSH_CONFIG)) && echo "\# SSH Tunnel Config \n\# Use the Forward ports to connect to remote instances (localhost:<PORT>)\n-----" && cat $(SSH_CONFIG)

# TODO: Bastion commands need to be stored in SSM, so user without admin permissions will be able to connect
CMD_BASTION_SSH_TUNNEL_UP = $(shell cat .infra/env/$(ENV)/output.json | $(JQ) -r '.cmd.value.tunnel.up') -F $(SSH_CONFIG)
CMD_BASTION_SSH_TUNNEL_DOWN = $(shell cat .infra/env/$(ENV)/output.json | $(JQ) -r '.cmd.value.tunnel.down') -F $(SSH_CONFIG) && echo "SSH tunnel disabled"
CMD_BASTION_SSH_TUNNEL_STATUS = $(shell cat .infra/env/$(ENV)/output.json | $(JQ) -r '.cmd.value.tunnel.status') -F $(SSH_CONFIG) && echo "SSH tunnel is up with the following config:\n-----" && cat $(SSH_CONFIG)


# Tasks
########################################################################################################################
tunnel: tunnel.up
tunnel.up: tunnel.status
	@$(CMD_BASTION_SSH_TUNNEL_UP)

tunnel.down:
	@$(CMD_BASTION_SSH_TUNNEL_DOWN)

tunnel.status:
	@$(CMD_BASTION_SSH_TUNNEL_STATUS)

tunnel.profile:
	@$(CMD_BASTION_SSH_TUNNEL_PROFILE)

# Dependencies
########################################################################################################################
