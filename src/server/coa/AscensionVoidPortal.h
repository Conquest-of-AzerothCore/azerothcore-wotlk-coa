/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#ifndef ASCENSION_VOID_PORTAL_H
#define ASCENSION_VOID_PORTAL_H

#include "AscensionVoidPortalCycle.h"

namespace Ascension::VoidPortal
{
void ForceSpawnForTest(std::uint32_t groupId, std::uint32_t spawnId);
void ForceProximityRollForTest(bool success);
std::uint32_t ActiveGroupForTest();
}

#endif
