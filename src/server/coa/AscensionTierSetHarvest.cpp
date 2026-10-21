/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */
#include "CellImpl.h"
#include "Creature.h"
#include "GridNotifiers.h"
#include "GridNotifiersImpl.h"
#include "Player.h"
#include "ScriptMgr.h"
#include "SpellInfo.h"
#include "SpellMgr.h"
#include <array>
#include <list>

namespace
{

constexpr float TIER_SET_HARVEST_RADIUS = 40.0f;

constexpr std::array<uint32, 7> TIER_SET_HARVEST_BONUSES = {823711, 823717, 823719, 823727, 823731, 823739, 823741};

uint32 HarvestBuff(uint32 bonusId)
{
    SpellInfo const* bonus = sSpellMgr->GetSpellInfo(bonusId);
    return bonus ? bonus->Effects[EFFECT_0].TriggerSpell : 0;
}

class unit_ascension_tier_set_harvest : public UnitScript
{
public:
    unit_ascension_tier_set_harvest() : UnitScript("unit_ascension_tier_set_harvest", true, {UNITHOOK_ON_UNIT_DEATH}) { }

    void OnUnitDeath(Unit* unit, Unit*) override
    {
        Creature* dead = unit->ToCreature();
        if (!dead || dead->IsControlledByPlayer() || dead->IsCritter())
            return;

        std::list<Player*> players;
        Acore::AnyPlayerInObjectRangeCheck check(dead, TIER_SET_HARVEST_RADIUS);
        Acore::PlayerListSearcher<Acore::AnyPlayerInObjectRangeCheck> searcher(dead, players, check);
        Cell::VisitObjects(dead, searcher, TIER_SET_HARVEST_RADIUS);

        for (Player* player : players)
        {
            if (dead->IsFriendlyTo(player))
                continue;

            for (uint32 bonusId : TIER_SET_HARVEST_BONUSES)
                if (player->HasAura(bonusId))
                    if (uint32 buff = HarvestBuff(bonusId))
                        player->CastSpell(player, buff, true);
        }
    }
};
}

void AddSC_AscensionTierSetHarvest()
{
    new unit_ascension_tier_set_harvest();
}
