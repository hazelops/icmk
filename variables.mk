# This file should contain variables used in current module
##################################################################
# Main variables
ENV_BASE = dev
NPM_TOKEN ?= nil
BUSYBOX_VERSION ?= 1.31.1
# This is a workaround for syntax highlighters that break on a "Comment" symbol.
HASHSIGN = \#
SLASHSIGN = /
ECS_DEPLOY_SHA ?= sha256:acca364f44b8cbc01401baf53a39324cd23c11257c3ab66ca52261f85e69f60d

# For unit tests
BATS_BIN_PATH = tests/test/libs/bats/bin
