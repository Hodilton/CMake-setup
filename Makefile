# ============================
# Project basics
# ============================
PROJECT ?= project1

# ============================
# Auto-detect all targets (single-file and multi-file)
# ============================
# Find all .cpp files in src/ root (single-file targets)
SIMPLE_SOURCES := $(wildcard src/*.cpp)
SIMPLE_TARGETS := $(basename $(notdir $(SIMPLE_SOURCES)))

# Find all subdirectories in src/ (potential multi-file projects)
SUBDIRS := $(wildcard src/*/)
MULTI_TARGETS := $(notdir $(patsubst src/%/,%,$(SUBDIRS)))

# Combine all targets
ALL_TARGETS := $(SIMPLE_TARGETS) $(MULTI_TARGETS)

# Set default target to first detected
TARGET ?= $(firstword $(ALL_TARGETS))

# ============================
# Build type and directories
# ============================
BUILD_TYPE ?= debug
BUILD_DIR_BASE = build
LAST_FILE = $(BUILD_DIR_BASE)/.last_build_type
LAST_TARGET = $(BUILD_DIR_BASE)/.last_target

# ============================
# Parallel build jobs
# ============================
ifeq ($(OS),Windows_NT)
    JOBS ?= 1
else
    JOBS ?= $(shell nproc 2>/dev/null || sysctl -n hw.ncpu)
endif

# ============================
# Colors
# ============================
GREEN  = \033[0;32m
YELLOW = \033[1;33m
RED    = \033[0;31m
BLUE   = \033[0;34m
NC     = \033[0m

.PHONY: help all build debug release run clean rerun rebuild refresh install uninstall sysinstall sysuninstall dist detect $(ALL_TARGETS)

# ============================
# Default target
# ============================
all: build

# ============================
# Auto-generated targets for ALL detected projects
# ============================
$(ALL_TARGETS):
	@$(MAKE) --no-print-directory TARGET=$@ build

# ============================
# Detect target - show all auto-found targets
# ============================
detect:
	@printf "${BLUE}=== Auto-detected targets ===${NC}\n"
	@printf "${YELLOW}Single-file targets:${NC}\n"
	@if [ -z "$(SIMPLE_TARGETS)" ]; then \
		printf "  ${RED}None found${NC}\n"; \
	else \
		$(foreach t,$(SIMPLE_TARGETS),printf "  ${GREEN}$(t)${NC} (from src/$(t).cpp)\n";) \
	fi
	@printf "${YELLOW}Multi-file targets:${NC}\n"
	@if [ -z "$(MULTI_TARGETS)" ]; then \
		printf "  ${RED}None found${NC}\n"; \
	else \
		$(foreach t,$(MULTI_TARGETS),printf "  ${GREEN}$(t)${NC} (from src/$(t)/)\n";) \
	fi
	@printf "${YELLOW}All available targets:${NC}\n"
	@if [ -z "$(ALL_TARGETS)" ]; then \
		printf "  ${RED}No targets found${NC}\n"; \
	else \
		$(foreach t,$(ALL_TARGETS),printf "  $(t)\n";) \
	fi
	@printf "${BLUE}============================${NC}\n"

# ============================
# Build target
# ============================
build:
	@printf "${YELLOW}=== [$(TARGET)] Building $(BUILD_TYPE) ===${NC}\n"
	@cmake --preset $(BUILD_TYPE) -DPROJECT_NAME=$(PROJECT)
	@cmake --build --preset $(BUILD_TYPE) --target $(TARGET) -- -j$(JOBS)
	@echo $(BUILD_TYPE) > $(LAST_FILE)
	@echo $(TARGET) > $(LAST_TARGET)
	@printf "${GREEN}=== [$(TARGET)] Build finished ===${NC}\n"

debug:
	@$(MAKE) --no-print-directory BUILD_TYPE=debug build

release:
	@$(MAKE) --no-print-directory BUILD_TYPE=release build

# ============================
# Run target
# ============================
run:
	@bt=$$( [ -f $(LAST_FILE) ] && cat $(LAST_FILE) || echo $(BUILD_TYPE) ); \
	tgt=$$( [ -f $(LAST_TARGET) ] && cat $(LAST_TARGET) || echo $(TARGET) ); \
	bin_path="$(BUILD_DIR_BASE)/$$bt/$$tgt"; \
	if [ ! -x "$$bin_path" ]; then \
	  printf "${RED}Binary not found for $$tgt ($$bt). Building...${NC}\n"; \
	  $(MAKE) --no-print-directory BUILD_TYPE=$$bt TARGET=$$tgt build; \
	fi; \
	printf "${YELLOW}=== [$$tgt] Running $$bt build ===${NC}\n"; \
	"$$bin_path"

# ============================
# Refresh target
# ============================
refresh:
	@bt=$$( [ -f $(LAST_FILE) ] && cat $(LAST_FILE) || echo $(BUILD_TYPE) ); \
	tgt=$$( [ -f $(LAST_TARGET) ] && cat $(LAST_TARGET) || echo $(TARGET) ); \
	bin_path="$(BUILD_DIR_BASE)/$$bt/$$tgt"; \
	if $(MAKE) --no-print-directory -s BUILD_TYPE=$$bt TARGET=$$tgt build > /dev/null 2>&1; then \
	  printf "${YELLOW}=== [$$tgt] Running $$bt build ===${NC}\n"; \
	  "$$bin_path"; \
	else \
	  printf "${RED}Build failed. Showing errors:${NC}\n"; \
	  $(MAKE) --no-print-directory BUILD_TYPE=$$bt TARGET=$$tgt build; \
	fi

# ============================
# Clean / Rebuild
# ============================
clean:
	@rm -rf $(BUILD_DIR_BASE)

rerun:
	@bt=$$( [ -f $(LAST_FILE) ] && cat $(LAST_FILE) || echo $(BUILD_TYPE) ); \
	tgt=$$( [ -f $(LAST_TARGET) ] && cat $(LAST_TARGET) || echo $(TARGET) ); \
	$(MAKE) --no-print-directory clean; \
	$(MAKE) --no-print-directory BUILD_TYPE=$$bt TARGET=$$tgt build; \
	$(MAKE) --no-print-directory BUILD_TYPE=$$bt TARGET=$$tgt run

rebuild:
	@$(MAKE) --no-print-directory clean
	@$(MAKE) --no-print-directory BUILD_TYPE=$(BUILD_TYPE) TARGET=$(TARGET) build

# ============================
# Install / Uninstall
# ============================
BIN_DIR = bin

install: build
	@mkdir -p $(BIN_DIR)/$(BUILD_TYPE)
	@cp $(BUILD_DIR_BASE)/$(BUILD_TYPE)/$(TARGET) $(BIN_DIR)/$(BUILD_TYPE)/
	@printf "${GREEN}=== [$(TARGET)] Installed locally to $(BIN_DIR)/$(BUILD_TYPE)/$(TARGET) ===${NC}\n"

uninstall:
	@rm -f $(BIN_DIR)/$(BUILD_TYPE)/$(TARGET)
	@printf "${RED}=== [$(TARGET)] Removed from $(BIN_DIR)/$(BUILD_TYPE)/ ===${NC}\n"
	@if [ -d "$(BIN_DIR)/$(BUILD_TYPE)" ] && [ -z "$$(ls -A $(BIN_DIR)/$(BUILD_TYPE))" ]; then \
		rmdir "$(BIN_DIR)/$(BUILD_TYPE)"; \
		printf "${YELLOW}=== Removed empty directory $(BIN_DIR)/$(BUILD_TYPE)/ ===${NC}\n"; \
	fi
	@if [ -d "$(BIN_DIR)" ] && [ -z "$$(ls -A $(BIN_DIR))" ]; then \
		rmdir "$(BIN_DIR)"; \
		printf "${YELLOW}=== Removed empty directory $(BIN_DIR)/ ===${NC}\n"; \
	fi

sysinstall: build
	@sudo cp $(BUILD_DIR_BASE)/$(BUILD_TYPE)/$(TARGET) /usr/local/bin/
	@printf "${GREEN}=== [$(TARGET)] Installed system-wide to /usr/local/bin/$(TARGET) ===${NC}\n"

sysuninstall:
	@sudo rm -f /usr/local/bin/$(TARGET)
	@printf "${RED}=== [$(TARGET)] Removed system-wide /usr/local/bin/$(TARGET) ===${NC}\n"

# ============================
# Distribution
# ============================
dist: clean
	@tar -czf $(PROJECT).tar.gz src CMakeLists.txt Makefile CMakePresets.json
	@printf "${GREEN}=== [$(PROJECT)] Created archive $(PROJECT).tar.gz ===${NC}\n"

# ============================
# Help
# ============================
help:
	@printf "${YELLOW}Usage: make <target> [VARIABLE=value]${NC}\n\n"
	@printf "${GREEN}Auto-detected targets:${NC}\n"
	@$(foreach t,$(ALL_TARGETS),printf "  $(t)\n";)
	@printf "\n${GREEN}Build targets:${NC}\n"
	@printf "  build      - Build current target with selected BUILD_TYPE\n"
	@printf "  debug      - Build in debug mode\n"
	@printf "  release    - Build in release mode\n"
	@printf "  detect     - Show all auto-detected targets with details\n\n"
	@printf "${GREEN}Run targets:${NC}\n"
	@printf "  run        - Run last built binary\n"
	@printf "  refresh    - Rebuild only if needed and run\n\n"
	@printf "${GREEN}Clean / Rebuild:${NC}\n"
	@printf "  clean      - Remove build directories\n"
	@printf "  rerun      - Clean, rebuild, run\n"
	@printf "  rebuild    - Clean and rebuild\n\n"
	@printf "${GREEN}Install / Uninstall:${NC}\n"
	@printf "  install      - Install locally to $(BIN_DIR)/\n"
	@printf "  uninstall    - Remove local install\n"
	@printf "  sysinstall   - Install system-wide (/usr/local/bin)\n"
	@printf "  sysuninstall - Remove system-wide install\n\n"
	@printf "${GREEN}Distribution:${NC}\n"
	@printf "  dist       - Create .tar.gz archive of source\n\n"
	@printf "${GREEN}Variables:${NC}\n"
	@printf "  TARGET=<name>     - Target to build/run (default: $(TARGET))\n"
	@printf "  BUILD_TYPE=<debug/release> - Build type (default: $(BUILD_TYPE))\n"
	@printf "  JOBS=<N>          - Parallel build jobs (default: all cores)\n"
