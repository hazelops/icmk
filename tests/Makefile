# For unit tests
TESTS_PATH = tests
BATS_BIN_PATH = $(TESTS_PATH)/test/libs/bats/bin
BATS = $(BATS_BIN_PATH)/bats

# For unit tests using
CMD_RUB_BATS_TESTS_REPORT = cd ../ && $(BATS) \
	--report-formatter junit \
	--formatter pretty -o ./$(TESTS_PATH) $(TESTS_PATH)/*.bats

CMD_RUB_BATS_TESTS = cd ../ &&  bats \
	--formatter pretty -o ./ $(TESTS_PATH)/*.bats

# Run unit tests
unit-test:
	@$(CMD_RUB_BATS_TESTS)

unit-test-report:
	@$(CMD_RUB_BATS_TESTS_REPORT)
