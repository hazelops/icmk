# This file should contain variables used in current module
##################################################################
# main variables
TERRAFORM_VERSION ?= "0.12.29"

TERRAFORM_AWS_PROVIDER_VERSION ?= "~> 3.0"

IZE_ENABLED ?= false
# AWS_LIMITS_LIST contains name of aws resources like we see in terraform plan output (example: aws_s3_bucket)
# AWS resources have the following properties: limit value, name of aws service and quota code for raising a request.
# If you need to check one more service limit - please just add a new service info to this json list 
AWS_LIMITS_LIST ?= $$(echo "{ \
\"aws_s3_bucket\":[ \
	{\"value\":\"100\", \"service\":\"s3\", \"quotacode\":\"L-DC2B2D3D\"}], \
\"aws_route53_health_check\":[ \
	{\"value\":\"200\", \"service\":\"route53\", \"quotacode\":\"L-ACB674F3\"}], \
\"aws_dynamodb_table\":[ \
	{\"value\":\"256\", \"service\":\"dynamodb\", \"quotacode\":\"L-F98FE922\"}], \
\"aws_eip\":[ \
	{\"value\":\"5\", \"service\":\"vpc\", \"quotacode\":\"L-2AFB9258\"}] \
}")
TERRAFORM_STATE_DYNAMODB_TABLE ?= tf-state-lock
TF_LOG_LEVEL ?= 
