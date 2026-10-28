file(GLOB_RECURSE sources_mod_manastorm_endless
  CONFIGURE_DEPENDS
  "${CMAKE_CURRENT_SOURCE_DIR}/src/*.cpp"
  "${CMAKE_CURRENT_SOURCE_DIR}/src/*.h")

set(ModuleSources
  ${ModuleSources}
  ${sources_mod_manastorm_endless}
  PARENT_SCOPE)
