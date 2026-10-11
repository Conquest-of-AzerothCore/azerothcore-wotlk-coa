#
# This file is part of the AzerothCore Project. See AUTHORS file for Copyright information
#
# This file is free software; as a special exception the author gives
# unlimited permission to copy and/or distribute it, with or without
# modifications, as long as this notice is preserved.
#
# This program is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY, to the extent permitted by law; without even the
# implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
#

# Package overloads - Linux
if(CMAKE_SYSTEM_NAME MATCHES "Linux")
  if (NOT NOJEM)
    set(JEMALLOC_LIBRARY "jemalloc")
    message(STATUS "UNIX: Using jemalloc")
  endif()
endif()

# set default configuration directory
if( NOT CONF_DIR )
  set(CONF_DIR ${CMAKE_INSTALL_PREFIX}/etc)
  message(STATUS "UNIX: Using default configuration directory")
endif()

# set default library directory
if( NOT LIBSDIR )
  set(LIBSDIR ${CMAKE_INSTALL_PREFIX}/lib)
  message(STATUS "UNIX: Using default library directory")
endif()

# configure uninstaller
configure_file(
  "${CMAKE_SOURCE_DIR}/src/cmake/platform/cmake_uninstall.in.cmake"
  "${CMAKE_BINARY_DIR}/cmake_uninstall.cmake"
  @ONLY
)
message(STATUS "UNIX: Configuring uninstall target")

# create uninstaller target (allows for using "make uninstall")
add_custom_target(uninstall
  "${CMAKE_COMMAND}" -P "${CMAKE_BINARY_DIR}/cmake_uninstall.cmake"
)
message(STATUS "UNIX: Created uninstall target")

if(APPLE AND CMAKE_GENERATOR MATCHES "Ninja|Makefiles" AND EXISTS "/usr/bin/libtool")
  foreach(ARCHIVE_LANGUAGE C CXX)
    if(NOT DEFINED CACHE{CMAKE_${ARCHIVE_LANGUAGE}_CREATE_STATIC_LIBRARY})
      set(CMAKE_${ARCHIVE_LANGUAGE}_CREATE_STATIC_LIBRARY
        "<CMAKE_COMMAND> -E rm -f <TARGET>"
        "/usr/bin/libtool -static -no_warning_for_no_symbols -o <TARGET> <LINK_FLAGS> <OBJECTS>")
    endif()
  endforeach()
  message(STATUS "UNIX: Creating static libraries with libtool")
endif()

message(STATUS "UNIX: Detected compiler: ${CMAKE_C_COMPILER}")
if(CMAKE_C_COMPILER MATCHES "gcc" OR CMAKE_C_COMPILER_ID STREQUAL "GNU")
  include(${CMAKE_SOURCE_DIR}/src/cmake/compiler/gcc/settings.cmake)
elseif(CMAKE_C_COMPILER MATCHES "icc")
  include(${CMAKE_SOURCE_DIR}/src/cmake/compiler/icc/settings.cmake)
elseif(CMAKE_C_COMPILER MATCHES "clang" OR CMAKE_C_COMPILER_ID MATCHES "Clang")
  include(${CMAKE_SOURCE_DIR}/src/cmake/compiler/clang/settings.cmake)
endif()
