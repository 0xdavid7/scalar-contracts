.PHONY: test test-all test-verbose test-files clean

test:
	@if [ -n "$(filter-out test,$(MAKECMDGOALS))" ]; then \
		file=$(filter-out test,$(MAKECMDGOALS)); \
		echo "Testing $$file.t.sol:"; \
		forge test --match-path test/$$file.t.sol -vvvv; \
	else \
		forge test; \
	fi

%:
	@:

test-all:
	forge test --match-path "test/*.t.sol"

test-verbose:
	forge test --match-path "test/*.t.sol" -vvvv

test-files:
	@if [ -z "$(files)" ]; then \
		echo "Usage: make test-files files='Foo Bar Baz'"; \
		echo "Example: make test-files files='Foo Bar'"; \
		exit 1; \
	fi
	@for file in $(files); do \
		echo "\nTesting $$file.t.sol:"; \
		forge test --match-path test/$$file.t.sol -vvvv; \
	done

# Clean the build artifacts
clean:
	forge clean
