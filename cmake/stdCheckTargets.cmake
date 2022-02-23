# Add standard check targets (clangcheck,cppcheck, cpplint) to the given target.
#
# CMake options:
#  - STD_ENABLE_STATIC_TESTS to enable the checks

option(STD_ENABLE_STATIC_TESTS "Enable static code analysis test targets" OFF)

include(GetSourceFilesFromTarget)
include(stdClangCheck)
include(stdCPPCheck)
include(stdCPPLint)

function(std_check_targets _name)
  if(NOT STD_ENABLE_STATIC_TESTS)
    return()
  endif()

  get_source_files(${_name})
  if(NOT ${_name}_FILES)
    return()
  endif()

  std_clangcheck(${_name} FILES ${${_name}_FILES})
  std_cppcheck(${_name} FILES ${${_name}_FILES}
    POSSIBLE_ERROR FAIL_ON_WARNINGS)
  std_cpplint(${_name} FILES ${${_name}_FILES} CATEGORY_FILTER_OUT readability/streams)
endfunction()
