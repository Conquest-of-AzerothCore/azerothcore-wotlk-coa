set_property(GLOBAL APPEND PROPERTY ACORE_MODULE_TEST_INCLUDES
    "${CMAKE_SOURCE_DIR}/modules/mod-coa-pet-battles/src")
file(GLOB COA_PET_BATTLES_ENGINE_SOURCES CONFIGURE_DEPENDS
    "${CMAKE_SOURCE_DIR}/modules/mod-coa-pet-battles/src/Engine/*.cpp")
file(GLOB COA_PET_BATTLES_STORE_SOURCES CONFIGURE_DEPENDS
    "${CMAKE_SOURCE_DIR}/modules/mod-coa-pet-battles/src/Store/Journal.cpp"
    "${CMAKE_SOURCE_DIR}/modules/mod-coa-pet-battles/src/Store/JournalSql.cpp"
    "${CMAKE_SOURCE_DIR}/modules/mod-coa-pet-battles/src/Store/AccountRefs.cpp"
    "${CMAKE_SOURCE_DIR}/modules/mod-coa-pet-battles/src/Store/LearnQueue.cpp"
    "${CMAKE_SOURCE_DIR}/modules/mod-coa-pet-battles/src/Protocol/AddonMessage.cpp"
    "${CMAKE_SOURCE_DIR}/modules/mod-coa-pet-battles/src/Protocol/WireText.cpp"
    "${CMAKE_SOURCE_DIR}/modules/mod-coa-pet-battles/src/Protocol/JournalMessages.cpp"
    "${CMAKE_SOURCE_DIR}/modules/mod-coa-pet-battles/src/Battle/Scheduler.cpp"
    "${CMAKE_SOURCE_DIR}/modules/mod-coa-pet-battles/src/Battle/PetScale.cpp"
    "${CMAKE_SOURCE_DIR}/modules/mod-coa-pet-battles/src/Battle/Battles.cpp"
    "${CMAKE_SOURCE_DIR}/modules/mod-coa-pet-battles/src/Wild/Wild.cpp")
file(GLOB COA_PET_BATTLES_TEST_SOURCES CONFIGURE_DEPENDS
    "${CMAKE_SOURCE_DIR}/modules/mod-coa-pet-battles/tests/*.cpp")
set_property(GLOBAL APPEND PROPERTY ACORE_MODULE_TEST_SOURCES
    "${CMAKE_SOURCE_DIR}/modules/mod-coa-pet-battles/src/PetBattleData.cpp"
    ${COA_PET_BATTLES_ENGINE_SOURCES}
    ${COA_PET_BATTLES_STORE_SOURCES}
    ${COA_PET_BATTLES_TEST_SOURCES})
