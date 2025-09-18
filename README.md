# C++ Project Template
This is a C++ project template that automatically detects and builds executable targets from your source files. It uses CMake with presets and a Makefile wrapper for easy building and running.
## Features
- **Automatic target detection**: Automatically finds and builds:
  - Single `.cpp` files in `src/` directory
  - Multi-file projects in subdirectories of `src/`
- **Smart build system**: Uses CMake presets with debug and release configurations
- **Easy execution**: Run your programs with simple commands
- **Cross-platform**: Works on Linux, macOS, and Windows (with WSL)

## Example Project Structure
```
project/
├── src/                  # Source code directory
│   ├── *.cpp              # Single-file executables
│   └── project_name/       # Multi-file project directories
│       ├── main.cpp         # Entry point (or project_name.cpp)
│       └── .cpp/.h          # Additional source files
├── CMakeLists.txt        # CMake configuration
├── CMakePresets.json     # CMake presets (debug/release)
├── Makefile              # Main build interface
└── README.md             # This file
```
## Requirements
- CMake 3.23 or higher
- GCC/G++ or Clang compiler
- Make (or mingw32-make on Windows)
- Ninja (optional, for alternative generator)
## Getting Started
### Building Projects
```bash
# Build the first detected target
make

# Build specific target
make target_name

# Build in debug mode (default)
make debug

# Build in release mode
make release

# Show all auto-detected targets
make detect
```
### Running Projects
```bash
# Run the last built target
make run

# Rebuild and run (clean build)
make rerun
```
### Cleaning and Maintenance
```bash
# Clean build directories
make clean

# Rebuild current target
make rebuild

# Refresh and run (rebuild only if needed)
make refresh
```
## How Target Detection Works 
### Single-File Targets 
- Any `.cpp` file in `src/ directory` becomes an executable
- Example: `src/hello.cpp` → executable named `hello`
### Multi-File Targets 
- Each subdirectory in `src/` can be a multi-file project
- Must have one of these entry points:
  - `main.cpp`
  - `{subdirectory_name}.cpp`
         
- All `.cpp` files in the subdirectory are compiled together
### Build Configurations 
Debug Build (default) 
- Compiles with `-g -O0` for debugging
- Enables all warnings (`-Wall -Wextra -Wpedantic`)
- Defines `DEBUG_MODE` macro
### Release Build 
- Compiles with `-O3` for optimization
- Defines `NDEBUG` macro
- Enables warnings for code quality
## Examples 
### Single-File Project 
Create `src/hello.cpp`:
```cpp
#include <iostream>
int main() {
    std::cout << "Hello World!" << std::endl;
    return 0;
}
```
Build and run:
```bash
make hello
make run
```
### Multi-File Project
Create directory structure:
```
src/
└── calculator/
    ├── main.cpp
    ├── calculator.h
    └── calculator.cpp
```
Build and run:
```bash
make calculator
make run
```
## Environment Variables
You can customize behavior with these variables:
```bash
# Set specific target
make TARGET=hello build

# Set build type
make BUILD_TYPE=release build

# Set parallel jobs (default: number of CPU cores)
make JOBS=4 build

# Set project name
make PROJECT=my_project build
```
## CMake Presets
The project uses CMake presets for consistent builds: 
- debug: Debug build with full debugging info
- release: Optimized release build

Configure manually with:
```bash
cmake --preset debug
cmake --build --preset debug --target target_name
```