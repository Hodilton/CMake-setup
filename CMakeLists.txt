cmake_minimum_required(VERSION 3.23)

# =====================================
# Project
# =====================================
if(NOT DEFINED PROJECT_NAME)
    set(PROJECT_NAME "default_project")
endif()
project(${PROJECT_NAME} LANGUAGES CXX)

# =====================================
# C++ standard
# =====================================
set(CPP_STANDARD 23 CACHE STRING "C++ standard to use")
set(CMAKE_CXX_STANDARD ${CPP_STANDARD})
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

# =====================================
# Source files
# =====================================
file(GLOB_RECURSE SOURCES "src/*.cpp")

# =====================================
# Executable target
# =====================================
add_executable(${PROJECT_NAME} ${SOURCES})

# =====================================
# Threads library
# =====================================
find_package(Threads REQUIRED)
target_link_libraries(${PROJECT_NAME} PRIVATE Threads::Threads)

# =====================================
# Build type flags
# =====================================
if(CMAKE_BUILD_TYPE STREQUAL "debug")
    target_compile_definitions(${PROJECT_NAME} PRIVATE DEBUG_MODE)
    target_compile_options(${PROJECT_NAME} PRIVATE -g -O0 -Wall -Wextra -Wpedantic -Wshadow -Wformat=2)
elseif(CMAKE_BUILD_TYPE STREQUAL "release")
    target_compile_options(${PROJECT_NAME} PRIVATE -O3 -DNDEBUG -Wall -Wextra -Wpedantic)
endif()

# =====================================
# Information messages
# =====================================
message(STATUS "Project: ${PROJECT_NAME}")
message(STATUS "Build type: ${CMAKE_BUILD_TYPE}")
message(STATUS "C++ standard: ${CMAKE_CXX_STANDARD}")
message(STATUS "Sources: ${SOURCES}")
