/*
 * Copyright (C) 2016+ AzerothCore <www.azerothcore-wotlk.org>, released under GNU AGPL v3 license: https://github.com/azerothcore/azerothcore-wotlk/blob/master/LICENSE-AGPL3
 */

#include "Chat.h"
#include "ChatCommand.h"
#include "CommandScript.h"
#include "Player.h"

using namespace Acore::ChatCommands;

class coa_hit_chance_commandscript : public CommandScript
{
public:
    coa_hit_chance_commandscript() : CommandScript("coa_hit_chance_commandscript") { }

    ChatCommandTable GetCommands() const override
    {
        static ChatCommandTable commandTable =
        {
            { "hitchance", HandleHitChance, SEC_PLAYER, Console::No },
        };
        return commandTable;
    }

    static bool HandleHitChance(ChatHandler* handler)
    {
        Player* player = handler->GetPlayer();
        if (!player)
            return false;

        auto report = [handler](char const* label, float total, float rating)
        {
            handler->PSendSysMessage("{} hit chance: {:.2f}% ({:.2f}% from rating, {:.2f}% from auras)", label, total,
                rating, total - rating);
        };
        report("Melee", player->m_modMeleeHitChance, player->GetRatingBonusValue(CR_HIT_MELEE));
        report("Ranged", player->m_modRangedHitChance, player->GetRatingBonusValue(CR_HIT_RANGED));
        report("Spell", player->m_modSpellHitChance, player->GetRatingBonusValue(CR_HIT_SPELL));
        return true;
    }
};

void AddSC_CoAHitChance()
{
    new coa_hit_chance_commandscript();
}
