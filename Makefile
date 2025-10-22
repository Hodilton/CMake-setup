# ============================
# Project Configuration
# ============================
PROJECT ?= default_project

# ============================
# Auto-detection of targets
# ============================
SIMPLE_SOURCES := $(wildcard src/*.cpp)
SIMPLE_TARGETS := $(basename $(notdir $(SIMPLE_SOURCES)))

SUBDIRS 		:= $(wildcard src/*/ .)
MULTI_TARGETS 	:= $(filter-out .,$(notdir $(patsubst %/,%,$(filter %/,$(SUBDIRS)))))

ALL_TARGETS 	:= $(sort $(SIMPLE_TARGETS) $(MULTI_TARGETS))
TARGET 			?= $(firstword $(ALL_TARGETS))

# ============================
# Build Configuration with persistence
# ============================
BUILD_TYPE 		?= debug
BUILD_DIR_BASE 	:= build
BIN_DIR_BASE 	:= bin

LAST_BUILD_FILE 	:= $(BUILD_DIR_BASE)/.last_build_type
LAST_TARGET_FILE 	:= $(BUILD_DIR_BASE)/.last_target

# Ensure build dir exists for last files
$(shell mkdir -p $(BUILD_DIR_BASE))

# Resolve effective target and build type (from last or default)
EFFECTIVE_TARGET := $(shell [ -f "$(LAST_TARGET_FILE)" ] && cat "$(LAST_TARGET_FILE)" || echo "$(TARGET)")
EFFECTIVE_BUILD_TYPE := $(shell [ -f "$(LAST_BUILD_FILE)" ] && cat "$(LAST_BUILD_FILE)" || echo "$(BUILD_TYPE)")

# ============================
# Output verbosity control
# ============================
VERBOSE ?= 0

# ============================
# Build Jobs
# ============================
ifeq ($(OS),Windows_NT)
    JOBS ?= 1
else
    JOBS ?= $(shell nproc 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null || echo 4)
endif

# ============================
# Color Definitions (Easy to customize)
# ============================
# COLOR1=Cyan COLOR2=Green COLOR3=Yellow COLOR4=Blue COLOR5=Red NC=No Color
COLOR1 := \033[0;36m
COLOR2 := \033[0;32m
COLOR3 := \033[1;33m
COLOR4 := \033[0;34m
COLOR5 := \033[0;31m
NC     := \033[0m

# ============================
# Phony targets
# ============================
.PHONY: help all build debug release run clean rerun rebuild refresh detect $(ALL_TARGETS)

# ============================
# Default target
# ============================
all: help

# ============================
# Target detection
# ============================
detect:
	@echo "$(COLOR1)=== Auto-detected Targets ===$(NC)"
	@echo "$(COLOR3)Single-file targets:$(NC)"
	@if [ -n "$(SIMPLE_TARGETS)" ]; then \
		for target in $(SIMPLE_TARGETS); do \
			echo "  $(COLOR2)$$target$(NC) (from src/$$target.cpp)"; \
		done; \
	else \
		echo "  $(COLOR5)None found$(NC)"; \
	fi
	@echo "$(COLOR3)Multi-file targets:$(NC)"
	@if [ -n "$(MULTI_TARGETS)" ]; then \
		for target in $(MULTI_TARGETS); do \
			echo "  $(COLOR2)$$target$(NC) (from src/$$target/)"; \
		done; \
	else \
		echo "  $(COLOR5)None found$(NC)"; \
	fi
	@echo "$(COLOR3)All available targets:$(NC)"
	@if [ -n "$(ALL_TARGETS)" ]; then \
		for target in $(ALL_TARGETS); do \
			echo "  $$target"; \
		done; \
	else \
		echo "  $(COLOR5)No targets found$(NC)"; \
	fi
	@echo "$(COLOR1)============================$(NC)"

# ============================
# Individual targets
# ============================
$(ALL_TARGETS):
	@$(MAKE) --no-print-directory TARGET=$@ build

# ============================
# Build configuration
# ============================
debug:
	@$(MAKE) --no-print-directory BUILD_TYPE=debug build

release:
	@$(MAKE) --no-print-directory BUILD_TYPE=release build

build:
ifeq ($(TARGET),)
	$(error No target specified and none auto-detected. Run 'make detect' to see available targets.)
endif
	@echo "$(COLOR1)[ BUILD ]$(NC) Target: $(COLOR2)$(TARGET)$(NC) | Mode: $(COLOR3)$(BUILD_TYPE)$(NC)"
	@mkdir -p $(BIN_DIR_BASE)/$(BUILD_TYPE)
	@if [ "$(VERBOSE)" = "1" ]; then \
		cmake --preset $(BUILD_TYPE) -DPROJECT_NAME=$(PROJECT); \
	else \
		cmake --preset $(BUILD_TYPE) -DPROJECT_NAME=$(PROJECT) >/dev/null 2>&1; \
	fi
	@if [ "$(VERBOSE)" = "1" ]; then \
		cmake --build --preset $(BUILD_TYPE) --target $(TARGET) -- -j$(JOBS); \
	else \
		cmake --build --preset $(BUILD_TYPE) --target $(TARGET) -- -j$(JOBS) --quiet; \
	fi
	@echo "$(BUILD_TYPE)" > "$(LAST_BUILD_FILE)"
	@echo "$(TARGET)" > "$(LAST_TARGET_FILE)"
	@echo "$(COLOR2)[ DONE  ]$(NC) Built target $(COLOR2)$(TARGET)$(NC) in $(COLOR3)$(BUILD_TYPE)$(NC) mode"

# ============================
# Run targets
# ============================
run:
	@if [ "$(TARGET)" = "$(firstword $(ALL_TARGETS))" ] && [ -n "$(EFFECTIVE_TARGET)" ]; then \
		bt=$$( [ -f "$(LAST_BUILD_FILE)" ] && cat "$(LAST_BUILD_FILE)" || echo "$(BUILD_TYPE)" ); \
		tgt="$(EFFECTIVE_TARGET)"; \
	else \
		bt="$(BUILD_TYPE)"; \
		tgt="$(TARGET)"; \
	fi; \
	bin_path="$(BIN_DIR_BASE)/$$bt/$$tgt"; \
	if [ ! -x "$$bin_path" ]; then \
		echo "$(COLOR5)[ INFO  ]$(NC) Binary not found for $$tgt ($$bt). Building..."; \
		$(MAKE) --no-print-directory BUILD_TYPE=$$bt TARGET=$$tgt VERBOSE=$(VERBOSE) build; \
		bin_path="$(BIN_DIR_BASE)/$$bt/$$tgt"; \
	fi; \
	echo "$(COLOR4)[ RUN   ]$(NC) Target: $(COLOR2)$$tgt$(NC) | Mode: $(COLOR3)$$bt$(NC)"; \
	"$$bin_path"

refresh:
	@if [ "$(TARGET)" = "$(firstword $(ALL_TARGETS))" ] && [ -n "$(EFFECTIVE_TARGET)" ]; then \
		bt=$$( [ -f "$(LAST_BUILD_FILE)" ] && cat "$(LAST_BUILD_FILE)" || echo "$(BUILD_TYPE)" ); \
		tgt="$(EFFECTIVE_TARGET)"; \
	else \
		bt="$(BUILD_TYPE)"; \
		tgt="$(TARGET)"; \
	fi; \
	echo "$(COLOR1)[ REFRESH ]$(NC) Target: $(COLOR2)$$tgt$(NC) | Mode: $(COLOR3)$$bt$(NC)"; \
	$(MAKE) --no-print-directory BUILD_TYPE=$$bt TARGET=$$tgt VERBOSE=$(VERBOSE) build; \
	$(MAKE) --no-print-directory BUILD_TYPE=$$bt TARGET=$$tgt VERBOSE=$(VERBOSE) run

# ============================
# Clean and rebuild
# ============================
clean:
	@echo "$(COLOR3)[ CLEAN ]$(NC) Removing build and bin directories"
	@rm -rf $(BUILD_DIR_BASE)/ $(BIN_DIR_BASE)/
	@echo "$(COLOR2)[ DONE  ]$(NC) Clean completed"

rebuild:
	@$(MAKE) --no-print-directory clean
	@$(MAKE) --no-print-directory BUILD_TYPE=$(BUILD_TYPE) TARGET=$(TARGET) VERBOSE=$(VERBOSE) build

rerun:
	@$(MAKE) --no-print-directory clean
	@$(MAKE) --no-print-directory BUILD_TYPE=$(BUILD_TYPE) TARGET=$(TARGET) VERBOSE=$(VERBOSE) build
	@$(MAKE) --no-print-directory BUILD_TYPE=$(BUILD_TYPE) TARGET=$(TARGET) VERBOSE=$(VERBOSE) run

# ============================
# Distribution
# ============================
dist: clean
	@echo "$(COLOR1)[ DIST  ]$(NC) Creating distribution archive"
	@tar -czf $(PROJECT)-$(BUILD_TYPE).tar.gz --exclude='.git' --exclude='build' --exclude='bin' \
		src CMakeLists.txt Makefile CMakePresets.json
	@echo "$(COLOR2)[ DONE  ]$(NC) Archive created: $(PROJECT)-$(BUILD_TYPE).tar.gz"

# ============================
# Help
# ============================
help:
	@echo "$(COLOR1)┌──────────────────────────────────────────────────────────$(NC)"
	@echo "$(COLOR1)│ Usage: make [TARGET] [BUILD_TYPE] [VARIABLE] <command> $(NC)"
	@echo "$(COLOR1)├──────────────────────────────────────────────────────────$(NC)"
	@echo "$(COLOR1)│ Commands:$(NC)"
	@echo "$(COLOR1)│  help          - Show this help (default) $(NC)"
	@echo "$(COLOR1)│  detect        - List all detected targets $(NC)"
	@echo "$(COLOR1)│  build         - Build current target $(NC)"
	@echo "$(COLOR1)│  debug         - Build in debug mode $(NC)"
	@echo "$(COLOR1)│  release       - Build in release mode $(NC)"
	@echo "$(COLOR1)│  run           - Run built target $(NC)"
	@echo "$(COLOR1)│  refresh       - Rebuild and run last target $(NC)"
	@echo "$(COLOR1)│  clean         - Remove build artifacts $(NC)"
	@echo "$(COLOR1)│  rebuild       - Clean and rebuild $(NC)"
	@echo "$(COLOR1)│  rerun         - Clean, build, and run $(NC)"
	@echo "$(COLOR1)│  dist          - Create distribution archive $(NC)"
	@echo "$(COLOR1)├──────────────────────────────────────────────────────────$(NC)"
	@echo "$(COLOR1)│ Variables: $(NC)"
	@echo "$(COLOR1)│  TARGET        - Target to work with (default: $(TARGET)) $(NC)"
	@echo "$(COLOR1)│  BUILD_TYPE    - Build type (debug/release) (default: $(BUILD_TYPE)) $(NC)"
	@echo "$(COLOR1)│  JOBS          - Parallel jobs (default: $(JOBS)) $(NC)"
	@echo "$(COLOR1)│  PROJECT       - Project name (default: $(PROJECT)) $(NC)"
	@echo "$(COLOR1)│  VERBOSE       - Verbose output (0=quiet, 1=verbose) (default: $(VERBOSE)) $(NC)"
	@echo "$(COLOR1)└──────────────────────────────────────────────────────────$(NC)"
