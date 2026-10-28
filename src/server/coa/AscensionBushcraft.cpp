/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "Creature.h"
#include "LootMgr.h"
#include "Map.h"
#include "Player.h"
#include "Random.h"
#include "ScriptMgr.h"

namespace
{
constexpr uint32 SKILL_BUSHCRAFT = 505;
constexpr uint32 ITEM_CRUDE_LEATHER = 2000155;
constexpr float CRUDE_LEATHER_SKINNING_CHANCE = 25.0f;

class bushcraft_crude_leather : public MiscScript
{
public:
    bushcraft_crude_leather() : MiscScript("bushcraft_crude_leather", {MISCHOOK_ON_AFTER_LOOT_TEMPLATE_PROCESS}) { }

    void OnAfterLootTemplateProcess(Loot* loot, LootTemplate const*, LootStore const& store, Player* skinner, bool,
        bool, uint16) override
    {
        if (!loot || !skinner || &store != &LootTemplates_Skinning || !skinner->HasSkill(SKILL_BUSHCRAFT) ||
            loot->items.size() >= MAX_NR_LOOT_ITEMS || !skinner->GetMap())
            return;

        Creature const* beast = skinner->GetMap()->GetCreature(loot->sourceWorldObjectGUID);
        if (!beast || beast->GetCreatureType() != CREATURE_TYPE_BEAST ||
            beast->GetCreatureTemplate()->GetRequiredLootSkill() != SKILL_SKINNING)
            return;

        if (roll_chance_f(CRUDE_LEATHER_SKINNING_CHANCE))
            loot->AddItem(LootStoreItem(ITEM_CRUDE_LEATHER, 0, 100.0f, false, LOOT_MODE_DEFAULT, 0, 1, 1));
    }
};
}

void AddSC_AscensionBushcraft()
{
    new bushcraft_crude_leather();
}
