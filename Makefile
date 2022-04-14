PLATFORM_MACOS = macOS

default: test

test:
	xcodebuild test \
		-scheme vapor-routing \
		-destination platform="$(PLATFORM_MACOS)"

test-linux:
	docker run \
		--rm \
		-v "$(PWD):$(PWD)" \
		-w "$(PWD)" \
		swift:5.3 \
		bash -c 'make test-swift'

test-swift:
	swift test \
		--enable-test-discovery \
		--parallel

format:
	swift format --in-place --recursive \
		./Package.swift ./Sources ./Tests
	find . -type f -name '*.md' -print0 | xargs -0 perl -pi -e 's/ +$$//'

.PHONY: format test