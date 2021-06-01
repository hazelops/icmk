# BATS framework
BATS is a [TAP](https://testanything.org/)-compliant testing framework for Bash.  It provides a simple
way to verify that the UNIX programs you write behave as expected.

Full comprehensive information about BATS you can find in [bats-core](https://github.com/bats-core/bats-core) repository and on [https://bats-core.readthedocs.io/en/latest/](https://bats-core.readthedocs.io/en/latest/) site.

# Unit tests using BATS framework
## Overview
Due the fact that `ICMK` framework uses `make` GNU  and `bash` language, with some assumptions we can use BATS for testing make targets and macroses.

In this case `make <target name>` can be considered like a function which is tested with BATS framework.

All tests-related stuff is placed in `./tests` folder. Where:
 - `test/libs` - contains helpers and custom functions for using in test cases 
 - `*.bats` files - contains test cases code for covering icmk related targets and macroses, where each file contains test cases with common features.

## How to write tests
Each .bats file has 3 regular parts:
1. Function sourcing - here helpers functions are loaded
```bash
load 'test/libs/bats-support/load'
load 'test/libs/bats-assert/load'
load 'test/libs/helpers/helpers'
```

2. Pre- and post-test hooks - are executed before and after each test case respectively.
```bash
# pre-actions before test cases running
setup () {
  # create a temporary folder
  export BATS_TEMP_DIR="/tmp/$(date +%s)"
  mkdir "${BATS_TEMP_DIR}"
  # create AWS creds stub
  export test_aws_profile_name="bats_profile"
  create_aws_creds "${BATS_TEMP_DIR}" "${test_aws_profile_name}"
}

# post-actions after tests complete
teardown () {
  # clean-up after tests
  rm -rf ${BATS_TEMP_DIR}
}

```

3. Test cases itselfs - allows creating mock Makefile with TEST target and specific rules and arguments.
```bash
@test "Test case description" {
  # arguments initialization (inputs)
  export arg1="configure list-profiles"
  export HOME=${BATS_TEMP_DIR}
  export AWS_PROFILE=${test_aws_profile_name}

  # create makefile in "${BATS_TEMP_DIR}" path with specific rule (second argument)
  # mandatory, a rules can be different, it's flexible to implement with a few arguments or without them    
  create_makefile "${BATS_TEMP_DIR}" \
    '@$(AWS) $(arg1)' 

  # Any stubs and mocks functions for regular tools replacement and emulation
  # optional part
  ls() {
    # code
  }
  export -f ls
  docker() {
    # code  
  }
  export -f docker

  # Run TEST target with definition of arguments and variables overriding (if it's needed)
  # mandatory, 
  run make TEST

  # compare result with expected values: can be assert_success, assert_failure, assert_line and so on ... 
  # assert functions can be invoked many times, each from new line   
  assert_success # check the 0 exit code, otherwise it fails test
  assert_line "${test_aws_profile_name}" # check the output contains specified line, otherwise it fails test
}

```

So for test writing we need to know:
- what do we plan to test? target or macros?
- how does this target or macros works? 
- do we need to use stubs or mocks for test case? - in test case definition it's optional part

To create tests you need:
1. Copy `./tests/test/templates/template.bats` file to `./tests` folder and rename it.
2. (Optional) Add additional code to `setup` or `teardown` functions.
3. In `@test` construction replace `<DESCRIPTION>` with real definition of the test case
4. In `@test` construction export all respective variables which are used as arguments in rule.
5. In `@test` construction specify proper rule and arguments in `create_makefile` function.
6. (Optional) In `@test` construction write additional stubs and mocks at once after `create_makefile` function.
7. Leave relevant `assert_*` functions for checking test result. All exist functions are here [https://github.com/ztombol/bats-assert](https://github.com/ztombol/bats-assert)

## How to run test
For running tests without junit report please do following:
```bash
cd tests
make test
```

On the other hand to run unit tests with junit report please do following:
```bash
cd tests
make report
```
Where `report.xml` file will be written to `tests` directory.

## How to write libraries as libs (helpers)
Any function you defined as library you can use anywhere in `.bats` file (setup, teardown functions and test cases itselfs)

To create such function you need to make change to `./tests/test/libs/helpers/helpers.bash` file where you should add function with proper comments.
