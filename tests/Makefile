# For unit tests
TESTS_PATH = tests
BATS_BIN_PATH = $(TESTS_PATH)/test/libs/bats/bin
BATS = $(BATS_BIN_PATH)/bats

# For unit tests using
CMD_RUN_BATS_TESTS_REPORT = cd ../ && $(BATS) \
	--report-formatter junit \
	--formatter pretty -o ./$(TESTS_PATH) $(TESTS_PATH)/*.bats

CMD_RUN_BATS_TESTS = cd ../ && $(BATS) \
	--formatter pretty -o ./ $(TESTS_PATH)/*.bats


test: unit-test
report: unit-test-report

# Aliases for a better Runner Experience
tests: test
reports: report

# Run unit tests
unit-test:
	@$(CMD_RUN_BATS_TESTS)

unit-test-report:
	@$(CMD_RUN_BATS_TESTS_REPORT)
