cmake_minimum_required(VERSION 3.28)

# =====================================
# Project Configuration
# =====================================
if(NOT DEFINED PROJECT_NAME)
    set(PROJECT_NAME "default_project")
endif()
project(${PROJECT_NAME} 
    VERSION 1.0.0
    DESCRIPTION "Default C++ project"
    LANGUAGES CXX
)

# =====================================
# Global Configuration
# =====================================
set(CMAKE_CXX_STANDARD 23)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

# Output binaries to bin/<lowercase-build-type>
string(TOLOWER "${CMAKE_BUILD_TYPE}" CMAKE_BUILD_TYPE_LOWER)
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_SOURCE_DIR}/bin/${CMAKE_BUILD_TYPE_LOWER})

# =====================================
# Compiler Options
# =====================================
function(setup_target_compile_options TARGET_NAME)
    set(DEBUG_OPTIONS 
        $<$<CONFIG:Debug>:
            -g
            -O0
            -Wall
            -Wextra
            -Wpedantic
            -Wshadow
            -Wformat=2
            -Wconversion
            -Wsign-conversion
        >
    )
    
    set(RELEASE_OPTIONS
        $<$<CONFIG:Release>:
            -O3
            -DNDEBUG
            -flto
            -Wall
            -Wextra
            -Wpedantic
        >
    )
    
    target_compile_options(${TARGET_NAME} PRIVATE 
        ${DEBUG_OPTIONS}
        ${RELEASE_OPTIONS}
    )
endfunction()

# =====================================
# Find Required Packages
# =====================================
find_package(Threads REQUIRED)

# =====================================
# Helper Function for Target Setup
# =====================================
function(setup_target TARGET_NAME)
    target_link_libraries(${TARGET_NAME} PRIVATE Threads::Threads)
    
    # Set compile options
    setup_target_compile_options(${TARGET_NAME})
    
    # Add build type specific definitions
    if(CMAKE_BUILD_TYPE STREQUAL "Debug")
        target_compile_definitions(${TARGET_NAME} PRIVATE DEBUG_MODE)
    elseif(CMAKE_BUILD_TYPE STREQUAL "Release")
        target_compile_definitions(${TARGET_NAME} PRIVATE NDEBUG)
    endif()
    
    # Set C++ standard for this target
    set_target_properties(${TARGET_NAME} PROPERTIES
        CXX_STANDARD 23
        CXX_STANDARD_REQUIRED ON
        CXX_EXTENSIONS OFF
    )
endfunction()

# =====================================
# Auto-detect and create targets
# =====================================

# Find all single .cpp files in src/ root
file(GLOB SIMPLE_SOURCES LIST_DIRECTORIES false "src/*.cpp")

foreach(SRC_FILE ${SIMPLE_SOURCES})
    get_filename_component(TARGET_NAME ${SRC_FILE} NAME_WE)
    get_filename_component(FULL_PATH ${SRC_FILE} ABSOLUTE)
    
    if(NOT TARGET ${TARGET_NAME})
        add_executable(${TARGET_NAME} ${FULL_PATH})
        setup_target(${TARGET_NAME})
        
        message(STATUS "Added single-file target: ${TARGET_NAME}")
    endif()
endforeach()

# =====================================
# Auto-detect multi-file projects
# =====================================
file(GLOB SUBDIRS LIST_DIRECTORIES true "src/*")

foreach(DIR ${SUBDIRS})
    if(IS_DIRECTORY ${DIR})
        get_filename_component(DIR_NAME ${DIR} NAME)
        
        # Find all .cpp files in this subdirectory
        file(GLOB_RECURSE PROJECT_SOURCES "src/${DIR_NAME}/*.cpp")
        
        if(PROJECT_SOURCES)
            if(NOT TARGET ${DIR_NAME})
                add_executable(${DIR_NAME} ${PROJECT_SOURCES})
                
                # Include the subdirectory
                target_include_directories(${DIR_NAME} PRIVATE "src/${DIR_NAME}")
                
                setup_target(${DIR_NAME})
                
                message(STATUS "Added multi-file target: ${DIR_NAME}")
            endif()
        endif()
    endif()
endforeach()

# =====================================
# Validation and Information
# =====================================
if(NOT EXISTS "${CMAKE_SOURCE_DIR}/src")
    message(WARNING "src/ directory does not exist. No targets will be created.")
endif()

message(STATUS "Project: ${PROJECT_NAME}")
message(STATUS "Build type: ${CMAKE_BUILD_TYPE}")
message(STATUS "C++ standard: ${CMAKE_CXX_STANDARD}")
