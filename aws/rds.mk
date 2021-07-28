# This file contains AWS RDS related logic
##################################################################
# Macroses
########################################################################################################################
# Default value for RDS CLUSTER Identifier
RDS_DB_CLUSTER_IDENTIFIER ?= $(ENV)-$(RDS_DB_SUFFIX)

# It gets a current DB Writer instance Identifier
CMD_RDS_DB_CLUSTER_WR_INSTANCE_IDENTIFIER = $$($(AWS) rds describe-db-clusters --db-cluster-identifier $(RDS_DB_CLUSTER_IDENTIFIER) | $(JQ) -r --arg DB_ID $(RDS_DB_CLUSTER_IDENTIFIER) '.DBClusters[] | select(contains({DBClusterIdentifier: $$DB_ID})) | .DBClusterMembers[] | select(contains({IsClusterWriter: true})) | .DBInstanceIdentifier')

# It enables Failover mechanism and stories instance identifier
CMD_RDS_DB_CLUSTER_WR_INSTANCE_IDENTIFIER_PREVIOUS = $(eval CMD_RDS_DB_CLUSTER_WR_INSTANCE_IDENTIFIER_PREVIOUS := $(shell $(AWS) rds failover-db-cluster --db-cluster-identifier $(RDS_DB_CLUSTER_IDENTIFIER) | $(JQ) -r '.DBCluster.DBClusterMembers[] | select(contains({IsClusterWriter: true})) | .DBInstanceIdentifier'))$(CMD_RDS_DB_CLUSTER_WR_INSTANCE_IDENTIFIER_PREVIOUS)

# Simple loop for looking for Writer instance switching
CMD_RDS_DB_CLUSTER_FAILOVER = WAIT_TIME=0; SUCCESS_FLAG=0; printf "%s" "Getting new Primary DB instance."; while [ $$WAIT_TIME -lt $$(($(RDS_FAILOVER_TIMEOUT) * 60)) ]; do if [ $(CMD_RDS_DB_CLUSTER_WR_INSTANCE_IDENTIFIER_PREVIOUS) != $(CMD_RDS_DB_CLUSTER_WR_INSTANCE_IDENTIFIER) ]; then echo "\n\n\033[32m[OK]\033[0m The Primary DB instance has been changed to '$(CMD_RDS_DB_CLUSTER_WR_INSTANCE_IDENTIFIER)'.\n"; SUCCESS_FLAG=1; break; else printf "%s" "."; WAIT_TIME=$$(expr $$WAIT_TIME + $(RDS_FAILOVER_LOOP_TIMEOUT)); sleep $(RDS_FAILOVER_LOOP_TIMEOUT); fi; done; if [ $$SUCCESS_FLAG -ne 1 ]; then echo "\n\033[31m[ERROR]\033[0m Something went wrong during RDS Failover process."; exit 1; fi

# Notification before main logic invocation
CMD_RDS_DB_CLUSTER_FAILOVER_RUN = @ echo "\nFailover process within '$(RDS_DB_CLUSTER_IDENTIFIER)' RDS cluster has been started. \nThe Primary DB instance was '$(CMD_RDS_DB_CLUSTER_WR_INSTANCE_IDENTIFIER_PREVIOUS)'.\n" && $(CMD_RDS_DB_CLUSTER_FAILOVER)

# RDS DB Writer instance reboot
CMD_RDS_DB_CLUSTER_WR_INSTANCE_START_REBOOT = $$($(AWS) rds reboot-db-instance --db-instance-identifier $(CMD_RDS_DB_CLUSTER_WR_INSTANCE_IDENTIFIER))
# RDS DB wait instance available
CMD_RDS_DB_CLUSTER_WR_INSTANCE_AVAILABLE = $$($(AWS) rds wait db-instance-available --db-instance-identifier $(CMD_RDS_DB_CLUSTER_WR_INSTANCE_IDENTIFIER))
