# Configures the build targets and options for a simple application 
#   common_application(<Name> [EXAMPLE] )
#
# Input:
# <NAME>_SOURCES for all compilation units
# <NAME>_HEADERS for all internal header files
# <NAME>_LINK_LIBRARIES for dependencies of name
# 
# Builds <Name> application and installs it.

include(stdCheckTargets)
include(CMakeParseArguments)

function(std_application Name)
  
  string(TOUPPER ${Name} NAME)
  string(TOLOWER ${Name} name)
  set(_sources ${${NAME}_SOURCES})
  set(_headers ${${NAME}_HEADERS})
  set(_libraries ${${NAME}_LINK_LIBRARIES})

  add_executable(${Name} ${_options} ${_headers} ${_sources})
  set_target_properties(${Name} PROPERTIES OUTPUT_NAME ${Name})
  set_target_properties(${Name} PROPERTIES FOLDER ${PROJECT_NAME})
  std_compile_options(${Name})
  #add_dependencies(${PROJECT_NAME}-all ${Name})
  target_link_libraries(${Name} ${_libraries})
  install(TARGETS ${Name} 
          EXPORT      project_apps_${Name}
          DESTINATION ${CMAKE_INSTALL_BINDIR}
          COMPONENT   (project_apps)
  std_check_targets(${Name})
endfunction()

