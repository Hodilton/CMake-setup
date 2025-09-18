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
# Threads library
# =====================================
find_package(Threads REQUIRED)

# =====================================
# Auto-detect and create targets
# =====================================

# Find all single .cpp files in src/ root
file(GLOB SIMPLE_SOURCES "src/*.cpp")

# Create executables for simple single-file targets
foreach(SRC_FILE ${SIMPLE_SOURCES})
    # Get filename without path and extension
    get_filename_component(TARGET_NAME ${SRC_FILE} NAME_WE)
    
    # Create executable
    add_executable(${TARGET_NAME} ${SRC_FILE})
    
    # Link threads
    target_link_libraries(${TARGET_NAME} PRIVATE Threads::Threads)
    
    # Apply compilation flags
    if(CMAKE_BUILD_TYPE STREQUAL "Debug")
        target_compile_definitions(${TARGET_NAME} PRIVATE DEBUG_MODE)
        target_compile_options(${TARGET_NAME} PRIVATE -g -O0 -Wall -Wextra -Wpedantic -Wshadow -Wformat=2)
    elseif(CMAKE_BUILD_TYPE STREQUAL "Release")
        target_compile_options(${TARGET_NAME} PRIVATE -O3 -DNDEBUG -Wall -Wextra -Wpedantic)
    endif()
endforeach()

# =====================================
# Auto-detect multi-file projects (subdirectories in src/)
# =====================================
file(GLOB SUBDIRS RELATIVE ${CMAKE_CURRENT_SOURCE_DIR}/src ${CMAKE_CURRENT_SOURCE_DIR}/src/*)
foreach(SUBDIR ${SUBDIRS})
    if(IS_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/src/${SUBDIR})
        # Look for main.cpp or ${SUBDIR}.cpp as entry point
        set(MAIN_FILE "")
        if(EXISTS ${CMAKE_CURRENT_SOURCE_DIR}/src/${SUBDIR}/main.cpp)
            set(MAIN_FILE ${CMAKE_CURRENT_SOURCE_DIR}/src/${SUBDIR}/main.cpp)
        elseif(EXISTS ${CMAKE_CURRENT_SOURCE_DIR}/src/${SUBDIR}/${SUBDIR}.cpp)
            set(MAIN_FILE ${CMAKE_CURRENT_SOURCE_DIR}/src/${SUBDIR}/${SUBDIR}.cpp)
        endif()
        
        if(MAIN_FILE)
            # Find all .cpp files in this subdirectory
            file(GLOB_RECURSE PROJECT_SOURCES "src/${SUBDIR}/*.cpp")
            
            # Create executable
            add_executable(${SUBDIR} ${PROJECT_SOURCES})
            
            # Include directories
            target_include_directories(${SUBDIR} PRIVATE src/${SUBDIR})
            
            # Link threads
            target_link_libraries(${SUBDIR} PRIVATE Threads::Threads)
            
            # Apply compilation flags
            if(CMAKE_BUILD_TYPE STREQUAL "Debug")
                target_compile_definitions(${SUBDIR} PRIVATE DEBUG_MODE)
                target_compile_options(${SUBDIR} PRIVATE -g -O0 -Wall -Wextra -Wpedantic -Wshadow -Wformat=2)
            elseif(CMAKE_BUILD_TYPE STREQUAL "Release")
                target_compile_options(${SUBDIR} PRIVATE -O3 -DNDEBUG -Wall -Wextra -Wpedantic)
            endif()
        endif()
    endif()
endforeach()

# =====================================
# Information messages
# =====================================
message(STATUS "Project: ${PROJECT_NAME}")
message(STATUS "Build type: ${CMAKE_BUILD_TYPE}")
message(STATUS "C++ standard: ${CMAKE_CXX_STANDARD}")