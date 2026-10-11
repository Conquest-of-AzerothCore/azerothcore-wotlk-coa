CollectSourceFiles(${CMAKE_CURRENT_SOURCE_DIR} COA_SOURCES)

add_library(coa-interface INTERFACE)
target_include_directories(coa-interface INTERFACE ${CMAKE_CURRENT_SOURCE_DIR})
target_link_libraries(coa-interface INTERFACE game-interface)

add_library(coa STATIC ${COA_SOURCES})
target_link_libraries(coa PRIVATE acore-core-interface mysql PUBLIC coa-interface)
set_target_properties(coa PROPERTIES FOLDER "server")

if(USE_COREPCH AND CMAKE_CXX_COMPILER_ID MATCHES "Clang" AND NOT MSVC)
  set_target_properties(coa PROPERTIES PRECOMPILE_HEADERS_REUSE_FROM game)
endif()

get_target_property(COA_BOOST_INCLUDE_DIRS boost INTERFACE_INCLUDE_DIRECTORIES)
find_path(COA_PROPERTY_TREE_INCLUDE_DIR
  NAMES boost/property_tree/json_parser.hpp
  HINTS ${COA_BOOST_INCLUDE_DIRS}
  NO_DEFAULT_PATH)
if(NOT COA_PROPERTY_TREE_INCLUDE_DIR)
  message(FATAL_ERROR
    "CoA requires Boost.PropertyTree headers. Install boost-property-tree for your vcpkg triplet, "
    "or provide a complete Boost installation.")
endif()

set(COA_CONFIG_FILE_LIST "")
foreach(COA_CONFIG coa_bugreport.conf.dist coa.conf.dist wildcard.conf.dist)
  CopyModuleConfig("${CMAKE_CURRENT_SOURCE_DIR}/conf/${COA_CONFIG}" coa)
  string(REGEX REPLACE "\\.dist$" "" COA_CONFIG_FILE ${COA_CONFIG})
  string(APPEND COA_CONFIG_FILE_LIST "${COA_CONFIG_FILE},")
endforeach()

if(UNIX)
  install(CODE "file(REMOVE \"\$ENV{DESTDIR}${CONF_DIR}/modules/mod_ascension_compat.conf.dist\")")
elseif(WIN32)
  install(CODE "file(REMOVE \"\$ENV{DESTDIR}${CMAKE_INSTALL_PREFIX}/configs/modules/mod_ascension_compat.conf.dist\")")
endif()

set(COA_SQL_DIRECTORY mod-ascension)
set_property(GLOBAL PROPERTY COA_SQL_DIRECTORY ${COA_SQL_DIRECTORY})
target_compile_options(coa-interface
  INTERFACE
    -DCOA_CONFIG_FILE_LIST=$<1:"${COA_CONFIG_FILE_LIST}">
    -DCOA_DATABASE_MODULE_LIST=$<1:"${COA_SQL_DIRECTORY},">)
