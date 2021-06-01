load 'test/libs/bats-support/load'
load 'test/libs/bats-assert/load'
load 'test/libs/helpers/helpers'

# Pre-actions before test cases running
setup () {
  export AWS_REGION="us-east-1"
  export ENV="test"
  export test_aws_profile_name="bats_profile"
  export AWS_PROFILE="${test_aws_profile_name}"
    
  # Create a temporary folder
  export BATS_TEMP_DIR="/tmp/$(date +%s)"
  mkdir "${BATS_TEMP_DIR}"
  # Create AWS creds stub
  create_aws_creds "${BATS_TEMP_DIR}" "${test_aws_profile_name}"
}

# Post-actions after tests complete
teardown () {
  # Clean-up after tests
  rm -rf ${BATS_TEMP_DIR}
}

@test "Testing AWS docker container: should be successful" {
  # Arguments initialization (inputs)
  export arg1="configure list-profiles"
  export HOME=${BATS_TEMP_DIR}
  export AWS_PROFILE=${test_aws_profile_name}
  
  # Create temp Makefie
  create_makefile "${BATS_TEMP_DIR}" \
    '@$(AWS) $(arg1)'
  # Run TEST target 
  run make TEST

  # Compare result with expected values (outputs)   
  assert_success
  assert_line "${test_aws_profile_name}"
}

# @test "Testing TERRAFORM docker container: should be successful" {
#   export TERRAFORM_VERSION="0.13.5"
#   export arg1="-v"
#   export HOME="${BATS_TEMP_DIR}"
#   export AWS_PROFILE="${test_aws_profile_name}"

#   create_makefile "${BATS_TEMP_DIR}" \
#     '@$(TERRAFORM) $(arg1)'
#   run make TEST

#   assert_success
#   assert_line "Terraform v${TERRAFORM_VERSION}"
#   refute_line -p "The config profile"
# }

# @test "Testing JQ docker container: should be successful" {
#   export arg1="'{\"foo\":\"barzone\"}'"
#   export arg2="-r '.foo'"
  
#   create_makefile "${BATS_TEMP_DIR}" \
#     '@echo $(arg1) | $(JQ) $(arg2)'
#   run make TEST 

#   assert_success
#   assert_line "barzone"
# }

# @test "Testing CUT docker container: should be successful" {
#   export arg1="123:4562020:789" 
#   export arg2="-d ':' -f 2" 

#   create_makefile "${BATS_TEMP_DIR}" \
#     '@echo $(arg1) | $(CUT) $(arg2)'
#   run make TEST 

#   assert_success
#   assert_line "4562020"
# }

# @test "Testing REV docker container: should be successful" {
#   export arg1="BATS is awesome"

#   create_makefile "${BATS_TEMP_DIR}" \
#     '@echo $(arg1) | $(REV)'
#   run make TEST
      
#   assert_success
#   assert_line "emosewa si STAB"
# }

# @test "Testing BASE64 docker container: should be successful" {
#   export arg1="QkFUUyBpcyBoYW5keQo="
#   export arg2="-d"

#   create_makefile "${BATS_TEMP_DIR}" \
#     '@echo $(arg1) | $(BASE64) $(arg2)'
#   run make TEST

#   assert_success
#   assert_line "BATS is handy"
# }

# @test "Testing AWK docker container: should be successful" {
#   export arg1="foo barzone"
#   export arg2="'{print}'"

#   create_makefile "${BATS_TEMP_DIR}" \
#     '@echo $(arg1) | $(AWK) $(arg2)'

#   run make TEST

#   assert_success
#   assert_line "foo barzone"
# }

# @test "Testing GOMPLATE docker container: should be successful" {
#   export arg1="-i 'answer is {{ mul 6 7 }}'"
#   create_makefile "${BATS_TEMP_DIR}" \
#     '@$(GOMPLATE) $(arg1)'
#   run make TEST
       
#   assert_success
#   assert_line "answer is 42"
# }

# ####### NEW tests
# @test "Testing 'Ensure ENV is set': should be failed" {
#   create_makefile "${BATS_TEMP_DIR}" \
#     ''
#   unset ENV
#   run make -s
       
#   assert_failure
#   assert_line -p "Please set ENV via 'export ENV=<env_name>' or use direnv"
# }

# @test "Testing SVC macros: should be successful" {
#   export TARGET_NAME="svc-bats.push"
#   create_makefile "${BATS_TEMP_DIR}" \
#     '@echo $(SVC)' "${TARGET_NAME}"
#   run make -s "${TARGET_NAME}"
       
#   assert_success
#   assert_output "svc-bats"

#   export TARGET_NAME="folder-1/svc-bats.push"
#   create_makefile "${BATS_TEMP_DIR}" \
#     '@echo $(SVC)' "${TARGET_NAME}"
#   run make -s "${TARGET_NAME}"
       
#   assert_success
#   assert_output "svc-bats"
# }

# @test "Testing PROJECT_SUB_DIR macros: should be successful" {
#   export TARGET_NAME="svc-bats.push"
#   create_makefile "${BATS_TEMP_DIR}" \
#     '@echo $(PROJECT_SUB_DIR)' "${TARGET_NAME}"
#   run make -s "${TARGET_NAME}"
       
#   assert_success
#   assert_output ""
  
#   export TARGET_NAME="folder-1/svc-bats.push"
#   create_makefile "${BATS_TEMP_DIR}" \
#     '@echo $(PROJECT_SUB_DIR)' "${TARGET_NAME}"
#   run make -s "${TARGET_NAME}"
       
#   assert_success
#   assert_output "folder-1/"
# }

@test "Testing PROJECT_PATH_ABS macros: should be successful" {
  export TARGET_NAME="svc-bats.push"
  export PROJECT_SUB_DIR=""
  export CURRENT_DIR="/home/user"
  function cd () {
    # if [[ "${1}" == "projects/${PROJECT_SUB_DIR}${SVC}" ]]; then 
    #   export CURRENT_DIR="${CURRENT_DIR}/projects/${PROJECT_SUB_DIR}${SVC}"
    # fi
    # export CURRENT_DIR="${CURRENT_DIR}/${1}"
    # echo $CURRENT_DIR
    echo "df"
  }
  export -f cd
  
  #cd
  #echo $CURRENT_DIR
  function pwd () {
    #if [[ "${1}" == "-P" ]];then 
    #  sleep 5
    echo "test"
    #fi 
  }
  export -f pwd
  create_makefile "${BATS_TEMP_DIR}" \
    '@echo $(PROJECT_PATH_ABS)' "${TARGET_NAME}"
  
  run make -s "${TARGET_NAME}"
  # run abc

  assert_success
  assert_output "d"
  
  # export TARGET_NAME="folder-1/svc-bats.push"
  # create_makefile "${BATS_TEMP_DIR}" \
  #   '@echo $(PROJECT_PATH_ABS)' "${TARGET_NAME}"
  # run make -s "${TARGET_NAME}"
       
  # assert_success
  # assert_output "folder-1/"
}
