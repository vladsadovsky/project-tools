# Common settings for xproject-tools based 
#
# Input variables
#
# Output variables
#

cmake_minimum_required(VERSION 3.13...3.15 FATAL_ERROR)
if(CMAKE_INSTALL_PREFIX STREQUAL PROJECT_BINARY_DIR)
  message(FATAL_ERROR "Cannot install into binary build directory")
endif()
cmake_policy(VERSION 3.13)

set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/bin)
set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/lib)
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/lib)

set_property(GLOBAL PROPERTY USE_FOLDERS ON) 	# organize targets into folders for IDEs

set(CMAKE_MODULE_INSTALL_PATH share/${PROJECT_NAME}/CMake)

string(TOUPPER ${PROJECT_NAME} UPPER_PROJECT_NAME)
string(TOLOWER ${PROJECT_NAME} LOWER_PROJECT_NAME)

#To use with for the include directories path formation  
set(PROJECT_INCLUDE_NAME ${${UPPER_PROJECT_NAME}_INCLUDE_NAME})
if(NOT PROJECT_INCLUDE_NAME)
  set(PROJECT_INCLUDE_NAME ${LOWER_PROJECT_NAME})
endif()

# CMake modules 


# System wide CMake modules
find_package( PkgConfig )

include(GNUInstallDirs)
include(CMakeParseArguments)
include(defBuildType)
include(FindPkgConfig)
include(CheckLibraryExists)
include(CheckIncludeFiles)
include(CheckFunctionExists)

# Export compile commands by default, this is handy for clang-tidy
set( CMAKE_EXPORT_COMPILE_COMMANDS ON )

# Enable helpfull warnings and C++11 for all files
set( CMAKE_CXX_STANDARD 11 )
set( CMAKE_CXX_STANDARD_REQUIRED ON )

# Always use '-fPIC'/'-fPIE' option.
set( CMAKE_POSITION_INDEPENDENT_CODE ON )

# Compiler settings common for all subprojects

# Options impacting ABI must be common across the tree
add_compile_options( -Wall -Wextra -Wshadow -Wnon-virtual-dtor -Wunused -pedantic )

# The GStreamer package and version 
set(GST_REQUIRED 1.12.0)

