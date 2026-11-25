/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "AscensionBattlegroundCombat.h"
#include "AscensionBattlegroundBrackets.h"
#include "Battleground.h"
#include "Map.h"
#include "Player.h"
#include "Unit.h"

namespace AscensionBattlegroundCombat
{
    uint8 SharedTopLevel(Unit const* self, Unit const* other)
    {
        if (!self || !other || !self->IsControlledByPlayer() || !other->IsControlledByPlayer())
            return 0;

        Map const* map = self->FindMap();
        if (!map || !map->IsBattleground() || other->FindMap() != map)
            return 0;

        Player const* selfPlayer = self->GetCharmerOrOwnerPlayerOrPlayerItself();
        Player const* otherPlayer = other->GetCharmerOrOwnerPlayerOrPlayerItself();
        if (!selfPlayer || !otherPlayer)
            return 0;

        Battleground const* battleground = selfPlayer->GetBattleground();
        if (!battleground || battleground->isArena() || battleground != otherPlayer->GetBattleground() ||
            battleground->GetMapId() != map->GetId())
            return 0;

        return static_cast<uint8>(
            AscensionBattlegroundBrackets::WidenedMaxLevel(battleground->GetMapId(), battleground->GetBracketId()));
    }

    uint8 StealthDetectionLevel(Unit const* detector, Unit const* stealthed)
    {
        return SharedTopLevel(detector, stealthed) ? stealthed->GetLevel() : 0;
    }
}
