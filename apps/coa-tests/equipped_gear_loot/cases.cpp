using namespace AscensionEquippedGearLoot;

ItemTemplate Gear(uint32 display, uint32 stat, uint32 type = INVTYPE_CHEST, uint32 level = 15)
{
    ItemTemplate item;
    item.DisplayInfoID = display;
    item.InventoryType = type;
    item.RequiredLevel = level;
    item.ItemStat[0] = {stat, 10};
    return item;
}

void Reset()
{
    objectMgr.items.clear();
    sCreatureDisplayInfoStore.rows.clear();
    sCreatureDisplayInfoExtraStore.rows.clear();
    presets.rows.clear();
    presets.overrides.clear();
    fixtureMap.creatures.clear();
    config = Config{};
    choice = 0;
    chanceResult = true;
    scriptMgr.calls = 0;
    LootTemplates_Creature.data = nullptr;
    LootTemplates_Item.data = nullptr;
    Configuration settings;
    settings.OnAfterConfigLoad(false);
}

void Index()
{
    Configuration settings;
    settings.OnStartup();
}

void Outfit(uint32 display, uint32 chest)
{
    sCreatureDisplayInfoStore.rows[display] = {display + 100};
    auto& extra = sCreatureDisplayInfoExtraStore.rows[display + 100];
    extra.NPCItemDisplay[3] = chest;
}

int main()
{
    Player owner;
    ObjectAccessor::players[owner.guid] = &owner;
    Reset();
    Creature caster;
    caster.data.unit_class = CLASS_MAGE;
    Outfit(1, 1000);
    objectMgr.items[100] = Gear(1000, ITEM_MOD_INTELLECT, INVTYPE_ROBE);
    objectMgr.items[101] = Gear(1000, ITEM_MOD_STRENGTH, INVTYPE_CHEST, 20);
    objectMgr.items[102] = Gear(1000, ITEM_MOD_INTELLECT, INVTYPE_CHEST, 21);
    objectMgr.items[103] = Gear(1000, ITEM_MOD_INTELLECT, INVTYPE_LEGS, 20);
    Index();
    Loot corpse;
    assert(corpse.FillLoot(0, LootTemplates_Creature, &owner, false, true, 1, &caster));
    assert(corpse.items.size() == 1 && corpse.items.front().itemid == 100);
    assert(corpse.unlootedCount == 1 && corpse.items.front().itemIndex == 0);
    assert(corpse.lootOwnerGUID == owner.guid && corpse.rights == std::vector<uint64>{owner.guid});
    assert(scriptMgr.calls == 1);

    Creature physical;
    Loot melee;
    melee.lootOwnerGUID = owner.guid;
    assert(AddLoot(&physical, melee, 1) && melee.items.front().itemid == 101);

    Reset();
    Outfit(1, 2000);
    Outfit(2, 2001);
    objectMgr.items[200] = Gear(2000, ITEM_MOD_STAMINA);
    objectMgr.items[201] = Gear(2001, ITEM_MOD_STAMINA);
    objectMgr.items[202] = Gear(2002, ITEM_MOD_STAMINA);
    Index();
    Creature alternative;
    alternative.display = 2;
    Loot second;
    second.lootOwnerGUID = owner.guid;
    assert(AddLoot(&alternative, second, 1) && second.items.front().itemid == 201);
    presets.rows[{alternative.entry, alternative.display}].items[3] = 2002;
    Loot presetLoot;
    presetLoot.lootOwnerGUID = owner.guid;
    assert(AddLoot(&alternative, presetLoot, 1) && presetLoot.items.front().itemid == 202);
    presets.rows[{alternative.entry, alternative.display}].items.fill(0);
    Loot invisible;
    assert(!AddLoot(&alternative, invisible, 1));
    presets.rows.clear();
    presets.overrides[alternative.GetGUID()].items[3] = 2002;
    Loot overrideLoot;
    overrideLoot.lootOwnerGUID = owner.guid;
    assert(AddLoot(&alternative, overrideLoot, 1) && overrideLoot.items.front().itemid == 202);

    Reset();
    Outfit(1, 3000);
    objectMgr.items[300] = Gear(3000, ITEM_MOD_INTELLECT);
    objectMgr.items[301] = Gear(3000, ITEM_MOD_STAMINA);
    objectMgr.items[302] = Gear(3000, ITEM_MOD_DEFENSE_SKILL_RATING);
    objectMgr.items[303] = Gear(3100, ITEM_MOD_STAMINA, INVTYPE_SHIELD);
    objectMgr.items[303].Class = ITEM_CLASS_ARMOR;
    objectMgr.items[399] = objectMgr.items[303];
    objectMgr.items[399].ItemLevel = 0;
    Creature defender;
    defender.weapons[1] = 399;
    defender.data.unit_class = CLASS_MAGE;
    Index();
    assert(CreatureRole(defender) == Role::Defender);
    assert(MatchingItem(3000, INVTYPE_CHEST, 20, Role::Defender, Loot{}) == 302);
    Loot shield;
    shield.lootOwnerGUID = owner.guid;
    assert(AddLoot(&defender, shield, 1) && shield.items.front().itemid == 303);

    Reset();
    objectMgr.items[400] = Gear(4000, ITEM_MOD_INTELLECT, INVTYPE_2HWEAPON);
    objectMgr.items[400].Class = ITEM_CLASS_WEAPON;
    objectMgr.items[400].SubClass = 10;
    objectMgr.items[401] = objectMgr.items[400];
    objectMgr.items[401].SubClass = 8;
    objectMgr.items[499] = objectMgr.items[400];
    objectMgr.items[499].ItemLevel = 0;
    caster.weapons[0] = 499;
    Index();
    Loot staff;
    staff.lootOwnerGUID = owner.guid;
    assert(AddLoot(&caster, staff, 1) && staff.items.front().itemid == 400);
    assert(!AddLoot(&caster, staff, 1) && staff.items.size() == 1);

    for (uint32 rejected = 0; rejected < 13; ++rejected)
    {
        Reset();
        Outfit(1, 5000);
        auto item = Gear(5000, ITEM_MOD_INTELLECT);
        if (rejected == 0) item.Quality = ITEM_QUALITY_RARE;
        if (rejected == 1) item.Bonding = BIND_WHEN_PICKED_UP;
        if (rejected == 2) item.Flags = ITEM_FLAG_DEPRECATED;
        if (rejected == 3) item.Flags = ITEM_FLAG_CONJURED;
        if (rejected == 4) item.StartQuest = 1;
        if (rejected == 5) item.RequiredSkill = 1;
        if (rejected == 6) item.RequiredSpell = 1;
        if (rejected == 7) item.RequiredHonorRank = 1;
        if (rejected == 8) item.RequiredReputationFaction = 1;
        if (rejected == 9) item.ItemLevel = 0;
        if (rejected == 10) item.RandomProperty = 1;
        if (rejected == 11) item.RandomSuffix = 1;
        if (rejected == 12) item.Name1 = "Monster - Shield, Stormwind Guard";
        objectMgr.items[500] = item;
        Index();
        Loot rejectedLoot;
        assert(!AddLoot(&physical, rejectedLoot, 1));
    }

    Reset();
    Outfit(1, 6000);
    objectMgr.items[600] = Gear(6000, ITEM_MOD_INTELLECT);
    Index();
    for (uint32 gate = 0; gate < 6; ++gate)
    {
        Creature excluded = caster;
        if (gate == 0) excluded.pet = true;
        if (gate == 1) excluded.summon = true;
        if (gate == 2) excluded.controlled = true;
        if (gate == 3) excluded.disabled = true;
        if (gate == 4) excluded.boss = true;
        if (gate == 5) excluded.level = 14;
        Loot none;
        assert(!AddLoot(&excluded, none, 1));
    }
    Loot none;
    assert(!AddLoot(nullptr, none, 1) && !AddLoot(&caster, none, 0));
    config.chance = 0;
    Configuration settings;
    settings.OnAfterConfigLoad(true);
    assert(!AddLoot(&caster, none, 1));
    config.chance = 1000;
    settings.OnAfterConfigLoad(true);
    assert(AddLoot(&caster, none, 1) && lastChance == 100);
    config.enabled = false;
    settings.OnAfterConfigLoad(true);
    Loot disabled;
    assert(!AddLoot(&caster, disabled, 1));
    config.enabled = true;
    config.coa = false;
    settings.OnAfterConfigLoad(true);
    assert(!AddLoot(&caster, disabled, 1));
    config.coa = true;
    config.chance = std::nanf("");
    settings.OnAfterConfigLoad(true);
    assert(!AddLoot(&caster, disabled, 1));
    config.chance = 100;
    settings.OnAfterConfigLoad(true);
    chanceResult = false;
    assert(!AddLoot(&caster, disabled, 1));
    chanceResult = true;

    Loot full;
    for (uint32 slot = 0; slot < MAX_NR_LOOT_ITEMS; ++slot)
        full.items.emplace_back(LootStoreItem(900, 0, 100, false, 1, 0, 1, 1));
    assert(!AddLoot(&caster, full, 1) && full.items.size() == MAX_NR_LOOT_ITEMS);

    Player nearby, distant;
    nearby.guid = 2;
    distant.guid = 3;
    distant.near = false;
    GroupReference third{&distant}, secondMember{&nearby, &third}, first{&owner, &secondMember};
    Group group{&first};
    owner.group = &group;
    Loot sharedLoot;
    assert(sharedLoot.FillLoot(0, LootTemplates_Creature, &owner, false, true, 1, &caster));
    assert(sharedLoot.roundRobinPlayer == owner.guid);
    assert(sharedLoot.rights == (std::vector<uint64>{owner.guid, nearby.guid}));
    assert(!sharedLoot.items.front().is_underthreshold);
    objectMgr.items[600].Quality = ITEM_QUALITY_NORMAL;
    Loot white;
    assert(white.FillLoot(0, LootTemplates_Creature, &owner, false, true, 1, &caster));
    assert(white.items.front().is_underthreshold);
    owner.group = nullptr;

    caster.sharedQuest = true;
    caster.sharedParticipants = {nearby.guid};
    fixtureMap.creatures[caster.GetGUID()] = &caster;
    ObjectAccessor::players[nearby.guid] = &nearby;
    Loot sharedQuestLoot;
    sharedQuestLoot.sourceWorldObjectGUID = caster.GetGUID();
    assert(sharedQuestLoot.FillLoot(0, LootTemplates_Creature, &owner, false, true, 1, &caster));
    assert(sharedQuestLoot.sharedQuestLoot && sharedQuestLoot.items.size() == 1);
    assert(sharedQuestLoot.quest_items.empty() && sharedQuestLoot.unlootedCount == 1);
    assert(sharedQuestLoot.rights == std::vector<uint64>{owner.guid});
    assert(sharedQuestLoot.PlayerQuestItems.contains(nearby.guid));
    caster.sharedQuest = false;

    Loot other;
    assert(!other.FillLoot(0, LootTemplates_Item, &owner, false, true, 1, &caster));
    assert(!other.FillLoot(0, LootTemplates_Skinning, &owner, false, true, 1, &caster));
    assert(!other.FillLoot(0, LootTemplates_Creature, nullptr, false, true, 1, &caster));
    LootTemplate normal;
    normal.existing = 600;
    LootTemplates_Creature.data = &normal;
    Loot combined;
    assert(combined.FillLoot(1, LootTemplates_Creature, &owner, false, false, 1, &caster));
    assert(combined.items.size() == 1 && combined.unlootedCount == 1);
    objectMgr.items[600].RequiredLevel = 0;
    objectMgr.items[600].ItemLevel = 30;
    assert(GearLevel(objectMgr.items[600]) == 25);
    assert(!AddLoot(&caster, other, 1));

    Reset();
    objectMgr.items[700] = Gear(7000, ITEM_MOD_INTELLECT, INVTYPE_ROBE);
    objectMgr.items[701] = Gear(7000, ITEM_MOD_INTELLECT);
    objectMgr.items[702] = Gear(7000, ITEM_MOD_INTELLECT, INVTYPE_LEGS);
    objectMgr.items[703] = Gear(7001, ITEM_MOD_INTELLECT);
    objectMgr.items[704] = Gear(7000, ITEM_MOD_INTELLECT);
    objectMgr.items[704].SubClass = 4;
    objectMgr.items[705] = Gear(7002, ITEM_MOD_INTELLECT);
    objectMgr.items[706] = Gear(7002, ITEM_MOD_INTELLECT);
    objectMgr.items[707] = Gear(7000, ITEM_MOD_INTELLECT);
    objectMgr.items[708] = Gear(7900, ITEM_MOD_INTELLECT);
    objectMgr.items[709] = Gear(7900, ITEM_MOD_INTELLECT);
    std::unordered_map<uint32, uint32> mappings{{700, 70}, {701, 71}, {705, 72}, {709, 70}};
    std::unordered_map<uint32, uint32> sources{{70, 700}, {71, 701}};
    AscensionItemAppearanceAliases::AddAliases(mappings, sources);
    assert(mappings.at(700) == 70 && mappings.at(701) == 71);
    assert(mappings.at(707) == 70);
    assert(!mappings.contains(702) && !mappings.contains(703) && !mappings.contains(704));
    assert(!mappings.contains(706));
    assert(!mappings.contains(708));
    auto const firstAliases = mappings;
    AscensionItemAppearanceAliases::AddAliases(mappings, sources);
    assert(mappings == firstAliases);
}
