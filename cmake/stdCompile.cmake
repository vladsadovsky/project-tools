
#
# Defines the std_compile_options() function to apply compiler flags and
# features for the given target.
#
# CMake options:
# * STD_WARN_DEPRECATED: Enable compiler deprecation warnings, default ON
# * STD_ENABLE_CXX11_STDLIB: Enable C++11 stdlib, default OFF
# * STD_DISABLE_WERROR: Disable -Werror flags, default OFF
# * STD_ENABLE_CXX11_ABI: Enable C++11 ABI for gcc 5 or later, default ON,
#   can be set to OFF with env variable CMAKE_STD_USE_CXX03_ABI
#
# Input Variables
# * STD_MINIMUM_GCC_VERSION check for a minimum gcc version, default 4.8
#
# Output Variables
# * CMAKE_COMPILER_IS_CLANG for clang
# * CMAKE_COMPILER_IS_GCC for gcc
# * GCC_COMPILER_VERSION The compiler version if gcc is used

# Necessary only once
if(COMPILER_DONE)
  return()
endif()
set(COMPILER_DONE ON)

# Compiler name
if(CMAKE_CXX_COMPILER_ID STREQUAL "Clang")
  set(CMAKE_COMPILER_IS_CLANG ON)
elseif(CMAKE_COMPILER_IS_GNUCXX)
  set(CMAKE_COMPILER_IS_GCC ON)
endif()

option(STD_WARN_DEPRECATED "Enable compiler deprecation warnings" ON)
option(STD_ENABLE_CXX11_STDLIB "Enable C++11 stdlib" OFF)
option(STD_DISABLE_WERROR "Disable -Werror flag" OFF)
option(STD_ENABLE_CXX11_ABI "Enable C++11 ABI for gcc 5 or later" ON)

set(CMAKE_CXX_STANDARD 11)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

if(STD_WARN_DEPRECATED)
  add_definitions(-DWARN_DEPRECATED) # projects have to pick this one up
endif()

# https://cmake.org/cmake/help/v3.1/prop_gbl/CMAKE_CXX_KNOWN_FEATURES.html
set(STD_CXX_FEATURES
  cxx_alias_templates cxx_nullptr cxx_override cxx_final cxx_noexcept)

function(compiler_dumpversion OUTPUT_VERSION)
  execute_process(COMMAND
    ${CMAKE_CXX_COMPILER} ${CMAKE_CXX_COMPILER_ARG1} -dumpversion
    OUTPUT_VARIABLE DUMP_COMPILER_VERSION OUTPUT_STRIP_TRAILING_WHITESPACE
  )
  string(REGEX REPLACE "([0-9])\\.([0-9])(\\.[0-9])?" "\\1.\\2"
    DUMP_COMPILER_VERSION "${DUMP_COMPILER_VERSION}")

  set(${OUTPUT_VERSION} ${DUMP_COMPILER_VERSION} PARENT_SCOPE)
endfunction()

if(CMAKE_COMPILER_IS_GCC OR CMAKE_COMPILER_IS_CLANG)
  compiler_dumpversion(GCC_COMPILER_VERSION)
  if(NOT STD_MINIMUM_GCC_VERSION)
    set(STD_MINIMUM_GCC_VERSION 4.8)
  endif()
  if(CMAKE_COMPILER_IS_GCC)
    if(GCC_COMPILER_VERSION VERSION_LESS STD_MINIMUM_GCC_VERSION)
      message(FATAL_ERROR "Using gcc ${GCC_COMPILER_VERSION}, need at least ${STD_MINIMUM_GCC_VERSION}")
    endif()
    if(NOT STD_ENABLE_CXX11_ABI)
      # http://stackoverflow.com/questions/30668560
      add_definitions("-D_GLIBCXX_USE_CXX11_ABI=0")
    endif()
  endif()

  set(STD_C_FLAGS
    -Wall -Wextra -Winvalid-pch -Winit-self -Wno-unknown-pragmas -Wshadow)
  set(STD_CXX_FLAGS
    -Wnon-virtual-dtor -Wsign-promo -Wvla -fno-strict-aliasing)

  if(NOT STD_DISABLE_WERROR)
    list(APPEND STD_C_FLAGS -Werror)
  endif()

  if(CMAKE_COMPILER_IS_CLANG)
    list(APPEND STD_C_FLAGS
      -Qunused-arguments -ferror-limit=5 -ftemplate-depth-1024 -Wheader-hygiene)
    if(STD_ENABLE_CXX11_STDLIB)
      list(APPEND STD_CXX_FLAGS -stdlib=libc++)
    endif()
  else()
    if(GCC_COMPILER_VERSION VERSION_GREATER 4.5)
      list(APPEND STD_C_FLAGS -fmax-errors=5)
    endif()
  endif()

  list(APPEND STD_CXX_FLAGS_RELEASE -Wuninitialized)

else()
  message(FATAL_ERROR "Unknown/unsupported compiler ${CMAKE_CXX_COMPILER_ID}")
endif()

set(STD_C_FLAGS_RELWITHDEBINFO -DNDEBUG)
set(STD_CXX_FLAGS_RELWITHDEBINFO -DNDEBUG)

list(APPEND STD_CXX_FLAGS ${STD_C_FLAGS})

function(std_compile_options Name)
  get_target_property(__type ${Name} TYPE)
  set(__visibility PUBLIC)
  if(__type STREQUAL INTERFACE_LIBRARY)
    set(__interface 1)
    set(__visibility INTERFACE)
  endif()
  target_compile_features(${Name} ${__visibility} ${STD_CXX_FEATURES})
  if(NOT __interface)
    target_compile_options(${Name} PRIVATE
      "$<$<AND:$<COMPILE_LANGUAGE:CXX>,$<CONFIG:Debug>>:${STD_CXX_FLAGS_DEBUG}>"
      "$<$<AND:$<COMPILE_LANGUAGE:CXX>,$<CONFIG:RelWithDebInfo>>:${STD_CXX_FLAGS_RELWITHDEBINFO}>"
      "$<$<AND:$<COMPILE_LANGUAGE:CXX>,$<CONFIG:Release>>:${STD_CXX_FLAGS_RELEASE}>"
      "$<$<COMPILE_LANGUAGE:CXX>:${STD_CXX_FLAGS}>"
      "$<$<AND:$<COMPILE_LANGUAGE:C>,$<CONFIG:Debug>>:${STD_C_FLAGS_DEBUG}>"
      "$<$<AND:$<COMPILE_LANGUAGE:C>,$<CONFIG:RelWithDebInfo>>:${STD_C_FLAGS_RELWITHDEBINFO}>"
      "$<$<AND:$<COMPILE_LANGUAGE:C>,$<CONFIG:Release>>:${STD_C_FLAGS_RELEASE}>"
      "$<$<COMPILE_LANGUAGE:C>:${STD_C_FLAGS}>"
    )
    if(CMAKE_COMPILER_IS_GCC)
      set_target_properties(${Name} PROPERTIES LINK_FLAGS "-Wl,--no-as-needed")
    endif()
  endif()
endfunction()
