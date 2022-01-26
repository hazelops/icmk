# This file should contain variables used in current module
##################################################################
# Main variables
ENV_BASE = dev
OWNER ?= hazelops
NPM_TOKEN ?= nil
BUSYBOX_VERSION ?= 1.31.1
# This is a workaround for syntax highlighters that break on a "Comment" symbol.
HASHSIGN = \#
SLASHSIGN = /

# For unit tests
BATS_BIN_PATH = tests/test/libs/bats/bin
