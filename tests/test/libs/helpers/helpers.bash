function Create-AWS-Creds () {
  mkdir "${1}/.aws"
  cat << EOF > "${1}/.aws/credentials"
[${2}]
aws_access_key_id=XXXXXXXXXXXXXXXXXX
aws_secret_access_key=XXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
region=us-east-1
EOF
}

function Create-Makefile () {	
  export MAKEFILES="${1}/Makefile"
  cat << EOF > "${MAKEFILES}"
ROOT_DIR = $(pwd)/examples/simple
NAMESPACE = bats-test
ICMK_VERSION ?= master

include examples/simple/.infra/icmk/init.mk

TEST:
	${2}
EOF
}
