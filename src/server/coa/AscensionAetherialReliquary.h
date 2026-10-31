/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#ifndef ASCENSION_AETHERIAL_RELIQUARY_H
#define ASCENSION_AETHERIAL_RELIQUARY_H

#include "AscensionAetherialReliquaryPolicy.h"

class Player;

namespace AetherialReliquary
{
enum class CaptureReason
{
    RealmCap
};

[[nodiscard]] bool IsAtCaptureLevel(Player const* player, CaptureReason reason);
bool CaptureBuffs(Player* player, CaptureReason reason);
[[nodiscard]] StoredBuffs GetStored(Player const* player);
bool RestoreBuffs(Player* player);
}

#endif
