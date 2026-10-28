if(NOT MODULE_MOD-COA-LEGENDARY-ITEMS STREQUAL "disabled")
    set_property(GLOBAL APPEND PROPERTY ACORE_MODULE_TEST_INCLUDES
        "${CMAKE_SOURCE_DIR}/modules/mod-coa-legendary-items/src")
    set_property(GLOBAL APPEND PROPERTY ACORE_MODULE_TEST_SOURCES
        "${CMAKE_SOURCE_DIR}/modules/mod-coa-legendary-items/tests/CoALegendaryRulesTest.cpp")
endif()
