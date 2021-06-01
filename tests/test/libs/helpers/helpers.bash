# It's kind of a mock function for creating aws credential profile 
# in specified place. It should be used in test cases like:
# $> create_aws_creds <specific path>
function create_aws_creds () {
  mkdir "${1}/.aws"
  cat << EOF > "${1}/.aws/credentials"
[${2}]
aws_access_key_id=XXXXXXXXXXXXXXXXXX
aws_secret_access_key=XXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
region=us-east-1
EOF
}

# Function allows developer to create test target with custom rules
# in specified folder 
# $> create_makefile <path> <custom rule or rules>
function create_makefile () {
  TARGET_NAME="${3:-TEST}"	
  export MAKEFILES="${1}/Makefile"
  cat << EOF > "${MAKEFILES}"
SHELL := bash
ROOT_DIR = $(pwd)/examples/simple
NAMESPACE = bats-test
include examples/simple/.infra/icmk/init.mk

${TARGET_NAME}:
	${2}
EOF
}
