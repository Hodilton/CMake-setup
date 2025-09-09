# ============================
# Project basics
# ============================
PROJECT ?= project1
EXECUTABLE = $(PROJECT)

# ============================
# Build type and directories
# ============================
BUILD_TYPE ?= debug
BUILD_DIR_BASE = build
LAST_FILE = $(BUILD_DIR_BASE)/.last_build_type

# ============================
# Parallel build jobs for Linux/macOS/Windows
# ============================
ifeq ($(OS),Windows_NT)
    JOBS ?= 1
else
    JOBS ?= $(shell nproc 2>/dev/null || sysctl -n hw.ncpu)
endif

# ============================
# Colors for output
# ============================
GREEN  = \033[0;32m
YELLOW = \033[1;33m
RED    = \033[0;31m
NC     = \033[0m

.PHONY: help all build debug release run clean rerun rebuild refresh install uninstall sysinstall sysuninstall dist

# ============================
# Help target
# ============================
help:
	@printf "${YELLOW}Usage: make <target> [VARIABLE=value]${NC}\n\n"
	@printf "${GREEN}Build targets:${NC}\n"
	@printf "  build      - Build current project with selected BUILD_TYPE\n"
	@printf "  debug      - Build in debug mode\n"
	@printf "  release    - Build in release mode\n\n"
	@printf "${GREEN}Run targets:${NC}\n"
	@printf "  run        - Run last built binary (debug/release)\n"
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
	@printf "${GREEN}Extra variables:${NC}\n"
	@printf "  PROJECT=<name>  - Set project name (default: $(PROJECT))\n"
	@printf "  BUILD_TYPE=<debug/release> - Build type (default: $(BUILD_TYPE))\n"
	@printf "  JOBS=<N>       - Parallel build jobs (default: all cores)\n"

# ============================
# Build targets
# ============================
all: build

build:
	@printf "${YELLOW}=== [$(PROJECT)] Building $(BUILD_TYPE) ===${NC}\n"
	@cmake --preset $(BUILD_TYPE) -DPROJECT_NAME=$(PROJECT)
	@cmake --build --preset $(BUILD_TYPE) -- -j$(JOBS)
	@echo $(BUILD_TYPE) > $(LAST_FILE)
	@printf "${GREEN}=== [$(PROJECT)] Build finished ===${NC}\n"

debug:
	@$(MAKE) --no-print-directory BUILD_TYPE=debug build

release:
	@$(MAKE) --no-print-directory BUILD_TYPE=release build

# ============================
# Run / refresh
# ============================
run:
	@bt=$$( [ -f $(LAST_FILE) ] && cat $(LAST_FILE) || echo $(BUILD_TYPE) ); \
	bin_path="$(BUILD_DIR_BASE)/$$bt/$(EXECUTABLE)"; \
	if [ ! -x "$$bin_path" ]; then \
	  printf "${RED}Binary not found for $$bt. Building...${NC}\n"; \
	  $(MAKE) --no-print-directory BUILD_TYPE=$$bt build; \
	fi; \
	printf "${YELLOW}=== [$(PROJECT)] Running $$bt build ===${NC}\n"; \
	"$$bin_path"

refresh:
	@bt=$$( [ -f $(LAST_FILE) ] && cat $(LAST_FILE) || echo $(BUILD_TYPE) ); \
	bin_path="$(BUILD_DIR_BASE)/$$bt/$(EXECUTABLE)"; \
	if $(MAKE) --no-print-directory -s BUILD_TYPE=$$bt build > /dev/null 2>&1; then \
	  printf "${YELLOW}=== [$(PROJECT)] Running $$bt build ===${NC}\n"; \
	  "$$bin_path"; \
	else \
	  printf "${RED}Build failed. Showing errors:${NC}\n"; \
	  $(MAKE) --no-print-directory BUILD_TYPE=$$bt build; \
	fi

# ============================
# Clean / Rebuild targets
# ============================
clean:
	@rm -rf $(BUILD_DIR_BASE) $(BIN_DIR)

rerun:
	@bt=$$( [ -f $(LAST_FILE) ] && cat $(LAST_FILE) || echo $(BUILD_TYPE) ); \
	$(MAKE) --no-print-directory clean; \
	$(MAKE) --no-print-directory BUILD_TYPE=$$bt build; \
	$(MAKE) --no-print-directory BUILD_TYPE=$$bt run

rebuild:
	@$(MAKE) --no-print-directory clean
	@$(MAKE) --no-print-directory BUILD_TYPE=$(BUILD_TYPE) build

# ============================
# Install / Uninstall targets
# ============================
BIN_DIR = bin

install: build
	@mkdir -p $(BIN_DIR)/$(BUILD_TYPE)
	@cp $(BUILD_DIR_BASE)/$(BUILD_TYPE)/$(EXECUTABLE) $(BIN_DIR)/$(BUILD_TYPE)/
	@printf "${GREEN}=== [$(PROJECT)] Installed locally to $(BIN_DIR)/$(BUILD_TYPE)/$(EXECUTABLE) ===${NC}\n"

uninstall:
	@rm -rf $(BIN_DIR)/$(BUILD_TYPE)
	@printf "${RED}=== [$(PROJECT)] Removed local $(BIN_DIR)/$(BUILD_TYPE) ===${NC}\n"

sysinstall: build
	@sudo cp $(BUILD_DIR_BASE)/$(BUILD_TYPE)/$(EXECUTABLE) /usr/local/bin/
	@printf "${GREEN}=== [$(PROJECT)] Installed system-wide to /usr/local/bin/$(EXECUTABLE) ===${NC}\n"

sysuninstall:
	@sudo rm -f /usr/local/bin/$(EXECUTABLE)
	@printf "${RED}=== [$(PROJECT)] Removed system-wide /usr/local/bin/$(EXECUTABLE) ===${NC}\n"

# ============================
# Distribution
# ============================
dist: clean
	@tar -czf $(PROJECT).tar.gz src CMakeLists.txt Makefile CMakePresets.json
	@printf "${GREEN}=== [$(PROJECT)] Created archive $(PROJECT).tar.gz ===${NC}\n"
