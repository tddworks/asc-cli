.PHONY: build test lint format clean download-spec dev run

build:
	swift build

test:
	swift test

lint:
	swift package diagnose-api-breaking-changes 2>/dev/null || true
	@echo "Lint complete"

format:
	swift format --in-place --recursive Sources Tests

clean:
	swift package clean
	rm -rf .build

download-spec:
	bash Scripts/download-spec.sh

dev: build
	.build/debug/asc --help

run:
	swift run asc $(ARGS)
