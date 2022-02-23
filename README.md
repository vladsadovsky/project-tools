# project-tools

Common submodule with shared settings for the development tools. Mounted in the root of each repository
to enable consistent references.

/bin - commonly used bash scripts

/cmake - shared CMake macros

/conf
    /dotfiles - config files, like .flake8
    /python - python configuration files, like pylintrc
    /vscode - shared Visual Code settings
	/ cpp - CPP tooling

/doc  - short important documents (git workflow) and documentation elements, like PNG files


## Adding 
    git submodule init
    git submodule add git@github.com:project/project-tools.git project-tools

## Usage 

### Using CMake with shared module 

The repository project-tools contains shared CMake modules and collection of find scripts in a root level directory cmake.
Projects, relying on project-tools frameworks are recommended to include the common tools repository:

### As a git submodule

In your project source dir, do:

    git submodule add ssh://github.com/yourproject/project-tools.git project-tools

And include it in the top-level CMakeLists.txt as follows:

    list(APPEND CMAKE_MODULE_PATH ${CMAKE_SOURCE_DIR}/project-tools/cmake)
    include(pcommon)
