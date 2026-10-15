// mod-coa-prestige: public API for other modules (mod-coa-challenges).
//
// "Prestiged" is the aura the client checks in C_Player:IsPrestiged()
// (HasAura(9930831)). The aura is SPELL_AURA_DUMMY, so it carries no mechanical
// experience effect: a consumer applies the bonus itself (ExperienceBonusPercent)
// and skips it while a Resolute / NO_BONUS_EXPERIENCE challenge is active.
// mod-coa-challenges owns that application.

#ifndef COA_PRESTIGE_API_H
#define COA_PRESTIGE_API_H

#include "Define.h"

class Player;

namespace CoAPrestige
{
    // Aura the client treats as "prestiged" (C_Player:IsPrestiged()).
    constexpr uint32 PRESTIGE_AURA = 9930831;

    // Whether the character is in an active prestige cycle: it carries the
    // prestige aura and is below the required level.
    bool IsActive(Player* player);

    // Total experience, in percent, while a prestige cycle is active
    // (CoAPrestige.ExperienceBonusPercent; 300 = 3x). A consumer applies
    // amount * ExperienceBonusPercent() / 100.
    uint32 ExperienceBonusPercent();

    // The level a character must reach to activate (and complete) Prestige Mode.
    uint32 RequiredLevel();

    // Extra experience, in percent, for the quest and battleground-end awards of the
    // Prestige daily the character is holding while in that content. The daily's kill
    // and profession bonus comes from its own aura (84783/84784/84788); this covers the
    // sources the aura cannot reach. The value is read from the aura itself, so it stays
    // in step with the DBC. 0 when no matching daily is held. A consumer applies
    // amount * (100 + value) / 100.
    uint32 DailyExperienceBonusPercent(Player* player, uint8 xpSource);

    // Hands the character a Prestige daily exactly as a prestige does: granted when it is
    // not held and not delivered today, with its aura set up for the current content.
    // questId 0 means the daily of the day (the one whose game event is active); a
    // specific id (80954/80955/80956) forces that daily, for the GM test command.
    // Returns the quest id given or 0.
    uint32 GrantPrestigeDaily(Player* player, uint32 questId = 0);
}

#endif // COA_PRESTIGE_API_H
