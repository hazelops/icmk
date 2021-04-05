load 'test/libs/bats-support/load'
load 'test/libs/bats-assert/load'
load 'test/libs/helpers/helpers'

# pre-actions before test cases running
setup () {
  # create a temporary folder
  export TEMP_DIR="/tmp/$(date +%s)"
  mkdir "${TEMP_DIR}"
  # create AWS creds stub
  export test_aws_profile_name="bats_profile"
  Create-AWS-Creds "${TEMP_DIR}" "${test_aws_profile_name}"
}

# post-actions after tests complete
teardown () {
  # clean-up after tests
  rm -rf ${TEMP_DIR}
}

@test "Testig AWS docker container: should be successful" {
  # Create temp Makefie
  Create-Makefile "${TEMP_DIR}" "@\$(AWS) \$(arg1)"
  # Run TEST target 
  run make TEST \
      arg1="configure list-profiles" \
      HOME=${TEMP_DIR} \
      AWS_PROFILE=${test_aws_profile_name} \
  # compare result with expected values    
  assert_success
  assert_line "${test_aws_profile_name}"
}

@test "Testig TERRAFORM docker container: should be successful" {
  TERRAFORM_VERSION="0.13.5"
  Create-Makefile "${TEMP_DIR}" "@\$(TERRAFORM) \$(arg1)"
  run make TEST \
      arg1="-v" \
      HOME=${TEMP_DIR} \
      AWS_PROFILE="${test_aws_profile_name}" \
      TERRAFORM_VERSION="${TERRAFORM_VERSION}"
  assert_success
  assert_line "Terraform v${TERRAFORM_VERSION}"
  refute_line -p "The config profile"
}

@test "Testig JQ docker container: should be successful" {
  Create-Makefile "${TEMP_DIR}" "@echo \$(arg1) | \$(JQ) \$(arg2)"
  run make TEST \
      arg1="'{\"foo\":\"barzone\"}'" \
      arg2="-r '.foo'"
  assert_success
  assert_line "barzone"
}

@test "Testig CUT docker container: should be successful" {
  Create-Makefile "${TEMP_DIR}" "@echo \$(arg1) | \$(CUT) \$(arg2)"
  run make TEST \
      arg1="123:4562020:789" \
      arg2="-d ':' -f 2" 
  assert_success
  assert_line "4562020"
}

@test "Testig REV docker container: should be successful" {
  Create-Makefile "${TEMP_DIR}" "@echo \$(arg1) | \$(REV)"
  run make TEST \
      arg1="BATS is awesome" 
  assert_success
  assert_line "emosewa si STAB"
}

@test "Testig BASE64 docker container: should be successful" {
  Create-Makefile "${TEMP_DIR}" "@echo \$(arg1) | \$(BASE64) \$(arg2)"
  run make TEST \
      arg1="QkFUUyBpcyBoYW5keQo=" \
      arg2="-d" 
  assert_success
  assert_line "BATS is handy"
}

@test "Testig AWK docker container: should be successful" {
  Create-Makefile "${TEMP_DIR}" "@echo \$(arg1) | \$(AWK) \$(arg2)"
  run make TEST \
      arg1="foo barzone" \
      arg2="'{print}'" 
  assert_success
  assert_line "foo barzone"
}

@test "Testig GOMPLATE docker container: should be successful" {
  Create-Makefile "${TEMP_DIR}" "@\$(GOMPLATE) \$(arg1)"
  run make TEST \
      arg1="-i 'answer is {{ mul 6 7 }}'" 
  assert_success
  assert_line "answer is 42"
}
