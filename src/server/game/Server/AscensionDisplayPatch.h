#pragma once

#include <cstdint>

class Player;

namespace AscensionDisplayPatch
{
void ResendSkillLineAbilityRows(Player* player, uint32 spellId = 0);
}
