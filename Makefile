# Thin wrapper around the Gradle build. Gradle stays the build tool; this file only gives
# agents and humans one entry point (setup, dev, gates) and picks a JDK 21+ automatically.

.DEFAULT_GOAL := help

JAVA_HOME := $(shell tools/harness/java-home.sh)
export JAVA_HOME

GRADLE := ./gradlew --console=plain -I tools/harness/test-summary.gradle

# Optional test filter, for example: make test TESTS=org.traccar.protocol.Gt06ProtocolDecoderTest
TESTS ?=

.PHONY: help setup hooks dev build test lint check-fast check db-up db-down clean

help: ## List the targets
	@grep -E '^[a-zA-Z_-]+:.*## ' $(MAKEFILE_LIST) | awk -F ':.*## ' '{printf "  %-12s %s\n", $$1, $$2}'

setup: hooks ## Install git hooks and build the server (target/tracker-server.jar, target/lib/)
	$(GRADLE) assemble

hooks: ## Point git at the hooks in .githooks (pre-push runs make check-fast)
	git config core.hooksPath .githooks

dev: ## Build and run the server locally with debug.xml (H2 in target/, web on :8082)
	$(GRADLE) assemble
	@if [ -d traccar-web/simple ]; then \
		"$(JAVA_HOME)/bin/java" -jar target/tracker-server.jar debug.xml; \
	else \
		echo "traccar-web/simple is missing (submodule not checked out): API only, no web UI. See docs/local-dev.md."; \
		mkdir -p target/web; \
		CONFIG_USE_ENVIRONMENT_VARIABLES=true WEB_PATH=./target/web \
			"$(JAVA_HOME)/bin/java" -jar target/tracker-server.jar debug.xml; \
	fi

build: ## Compile and package the server without running checks
	$(GRADLE) assemble

test: ## Run unit tests (TESTS=<class or pattern> to run a subset)
	$(GRADLE) test --rerun $(if $(TESTS),--tests '$(TESTS)')

lint: ## Run Checkstyle on main and test sources
	$(GRADLE) checkstyleMain checkstyleTest

check-fast: ## Fast gate: Checkstyle and unit tests, offline once dependencies are cached
	$(GRADLE) checkstyleMain checkstyleTest test --rerun

check: ## Full gate: what CI runs (./gradlew build = assemble + Checkstyle + tests)
	$(GRADLE) build test --rerun

db-up: ## Start optional PostgreSQL and MySQL from compose.yaml (H2 needs nothing)
	docker compose up -d

db-down: ## Stop the optional databases (data volumes are kept)
	docker compose down

clean: ## Delete build output, including the local H2 database in target/
	$(GRADLE) clean
	rm -rf target
