# Thin wrapper around Alire + gprbuild so the common flows are one word.  Every
# target runs through `alr` (so the tempus/aunit/gnatprove dependencies
# resolve).  The example and tests build in two profiles selected with -XMODE
# (sml-ada convention): release (-O3) and debug (-O0).

EX := -P example/example.gpr

.PHONY: all build test features prove format example release debug run clean help

all: build

## build       Build the library
build:
	alr build

## test        Build and run the AUnit suite in both modes (per-test output)
test:
	alr exec -- gprbuild -p -j0 -XMODE=debug -P tests/test_fasti.gpr
	alr exec -- tests/bin/debug/test_runner
	alr exec -- gprbuild -p -j0 -XMODE=release -P tests/test_fasti.gpr
	alr exec -- tests/bin/release/test_runner

## features    Build and run the Gherkin features in both modes.  fabula
##             exits 0 for a missing path or an empty file, so the summary
##             line, not the exit status alone, is what says every
##             scenario passed
features:
	alr exec -- gprbuild -p -j0 -XMODE=debug -P tests/test_fasti.gpr
	alr exec -- gprbuild -p -j0 -XMODE=release -P tests/test_fasti.gpr
	@for mode in debug release; do \
	  out=$$(alr exec -- tests/bin/$$mode/fasti_features tests/features) || \
	    { printf '%s\n' "$$out"; exit 1; }; \
	  printf '%s\n' "$$out" | \
	    grep -qE '^[1-9][0-9]* Scenarios? \([0-9]+ passed\)$$' || \
	    { printf '%s\n' "$$out"; \
	      echo "features: $$mode: a scenario did not pass"; exit 1; }; \
	done; echo 'features: every scenario passed in both modes'

## prove       Run the SPARK proof (same flags as CI)
prove:
	alr exec -- gnatprove -P proof/proof.gpr -j0 --level=2 --checks-as-errors=on \
	  --warnings=error

## format      Check formatting (per project, explicit files; no warnings)
format:
	alr exec -- gnatformat -P fasti.gpr --check $$(git ls-files 'src/*.ad[sb]')
	alr exec -- gnatformat -P tests/test_fasti.gpr --check $$(git ls-files 'tests/src/*.ad[sb]')
	alr exec -- gnatformat -P example/example.gpr --check $$(git ls-files 'example/src/*.ad[sb]')
	alr exec -- gnatformat -P proof/proof.gpr --check $$(git ls-files 'proof/src/*.ad[sb]')

## example     Build the example both ways
example: release debug

## release     Build the example (-O3)
release:
	alr exec -- gprbuild -p -XMODE=release $(EX)

## debug       Build the example (-O0)
debug:
	alr exec -- gprbuild -p -XMODE=debug $(EX)

## run         Build and run the release example
run: release
	./example/bin/release/next_expirations

## clean       Remove all build artifacts
clean:
	-alr exec -- gprclean -XMODE=release $(EX)
	-alr exec -- gprclean -XMODE=debug $(EX)
	alr clean

## help        List targets
help:
	@grep -E '^## ' $(MAKEFILE_LIST) | sed 's/^## /  /'
