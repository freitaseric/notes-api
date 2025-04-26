# ==============================================================================
# Configuration Variables
# ==============================================================================

GOCMD = go
GOBUILD = $(GOCMD) build
GOTEST = $(GOCMD) test
GOCLEAN = $(GOCMD) clean
GOMOD = $(GOCMD) mod
BINARY_NAME = notes-api
# Where the binary will be placed. Ensure this directory exists or is created.
BINARY_PATH = bin
# Path to the main executable file.
MAIN_FILE = ./server.go
# Command for the migration tool.
MIGRATE_CMD = migrate

# Get dynamic build information
VERSION := $(shell git describe --tags --always --dirty 2>/dev/null | grep -oE '^v?[0-9]+' | sed 's/^v//' || echo "unknown")
COMMIT := $(shell git rev-parse HEAD)
BUILD_DATE := $(shell date -u +'%Y-%m-%dT%H:%M:%SZ')

# Linker flags to inject information into the code
LDFLAGS = -ldflags "-s -w \
	-X main.Version=$(VERSION) \
	-X main.Commit=$(COMMIT) \
	-X main.BuildDate=$(BUILD_DATE)"

# ==============================================================================
# Phony Targets - Do not create files with these names
# ==============================================================================

.PHONY: all build run test clean deps tidy migrate-up migrate-down migrate-status docker-build help

# ==============================================================================
# Main Targets
# ==============================================================================

# Default target - runs build
all: build

# Builds the web server binary
build: deps
	@echo "🛠️ Building binary: $(BINARY_NAME)..."
	@mkdir -p $(BINARY_PATH) # Create the bin directory if it doesn't exist
	$(GOBUILD) $(LDFLAGS) -o $(BINARY_PATH)/$(BINARY_NAME) $(MAIN_FILE)
	@echo "✅ Binary built at $(BINARY_PATH)/$(BINARY_NAME)"

# Runs the web server
run: build
	@echo "▶️ Running server: $(BINARY_NAME)..."
	./$(BINARY_PATH)/$(BINARY_NAME)

# Runs all tests in the project
test: deps
	@echo "🧪 Running tests..."
	$(GOTEST) -v -race ./... # -v: verbose, -race: data race detection
	$(GOTEST) -v -race -coverprofile=coverage.out ./...
	@echo "✅ Tests finished!"

# Cleans built binaries, cache files, and coverage
clean:
	@echo "🧹 Cleaning artifacts..."
	$(GOCLEAN) -cache -modcache
	@rm -rf $(BINARY_PATH) coverage.out
	@echo "✅ Cleaning finished!"

# Downloads Go module dependencies
deps:
	@echo "⬇️ Downloading dependencies..."
	$(GOMOD) download
	@echo "✅ Dependencies downloaded!"

# Removes unused dependencies and adds missing ones in go.mod
tidy:
	@echo "🧹 Tidying go.mod..."
	$(GOMOD) tidy
	@echo "✅ go.mod tidied!"

# ==============================================================================
# Database Migration Targets (using 'migrate' tool)
# ==============================================================================

# Applies all pending migrations upwards
migrate-up:
	@if [ -z "$(DB_URL)" ]; then \
		echo "Error: DB_URL not set. Please set the DB_URL environment variable."; \
		exit 1; \
	fi
	@echo "⬆️ Applying pending migrations..."
	@echo "Database URL: $(DB_URL)" # Be careful not to expose credentials in public logs!
	$(MIGRATE_CMD) -database "$(DB_URL)" -path migrations up
	@echo "✅ Migrations applied!"

# Reverts the last applied migration downwards
migrate-down:
	@if [ -z "$(DB_URL)" ]; then \
		echo "Error: DB_URL not set. Please set the DB_URL environment variable."; \
		exit 1; \
	fi
	@echo "⬇️ Reverting last migration..."
	@echo "Database URL: $(DB_URL)" # Be careful not to expose credentials in public logs!
	$(MIGRATE_CMD) -database "$(DB_URL)" -path migrations down 1
	@echo "✅ Last migration reverted!"

# Shows the current status of migrations
migrate-status:
	@if [ -z "$(DB_URL)" ]; then \
		echo "Error: DB_URL not set. Please set the DB_URL environment variable."; \
		exit 1; \
	fi
	@echo "📊 Migration status:"
	@echo "Database URL: $(DB_URL)" # Be careful not to expose credentials in public logs!
	$(MIGRATE_CMD) -database "$(DB_URL)" -path migrations status

# ==============================================================================
# Docker Targets 
# ==============================================================================

# Builds the Docker image
docker-build: build
	@echo "🐳 Building Docker image $(BINARY_NAME):$(VERSION)..."
	docker build -t $(BINARY_NAME):$(VERSION) .
	@echo "✅ Docker image built: $(BINARY_NAME):$(VERSION)"

# ==============================================================================
# Help
# ==============================================================================

# Displays help
help:
	@echo "Usage: make <target>"
	@echo ""
	@echo "Available targets:"
	@echo "  all           Builds the binary (default)."
	@echo "  build         Builds the web server binary."
	@echo "  run           Runs the web server locally."
	@echo "  test          Runs all unit and integration tests."
	@echo "  clean         Cleans built binaries, Go cache, and temporary files."
	@echo "  deps          Downloads Go module dependencies."
	@echo "  tidy          Organizes and cleans the go.mod file."
	@echo "  fmt           Formats Go code using gofmt."
	@echo "  lint          Runs the linter (golps)."
	@echo "  check         Runs fmt and lint."
	@echo "  migrate-up    Applies all pending DB migrations (requires DB_URL)."
	@echo "  migrate-down  Reverts the last applied DB migration (requires DB_URL)."
	@echo "  migrate-status Shows the current status of DB migrations (requires DB_URL)."
	@echo "  docker-build  Builds the server's Docker image."
	@echo "  help          Displays this message."
	@echo ""
	@echo "Useful variables (can be set in the environment or before make):"
	@echo "  DB_URL        Database connection URL for migrations (e.g., make migrate-up DB_URL=...)"
	@echo ""
	@echo "Build Info:"
	@echo "  Version: $(VERSION)"
	@echo "  Commit:  $(COMMIT)"
	@echo "  Date:    $(BUILD_DATE)"