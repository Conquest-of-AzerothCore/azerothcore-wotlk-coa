#ifndef COA_PET_BATTLE_PRESENT_PACKETS_H
#define COA_PET_BATTLE_PRESENT_PACKETS_H

#include <cstdint>

class Player;
class Unit;
struct CreatureTemplate;

namespace CoAPetBattles::Present
{
    void SendVisualCast(Unit* caster, Unit* target, uint32_t spell);
    void SendVisualAura(Unit* target, uint32_t spell, bool on);
    void SendCreatureRecord(Player* player, CreatureTemplate const& creature, uint32_t entry, uint32_t display);
}

#endif
