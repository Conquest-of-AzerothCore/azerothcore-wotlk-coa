int main()
{
    InitPool();
    std::vector<LootStoreItem> values;
    for (auto const& pair : manager.items)
        values.push_back({pair.first});
    std::list<LootStoreItem*> entries;
    for (auto& value : values)
        entries.push_back(&value);
    adventurer_cache_loot script;
    Player player;
    Loot loot;
    assert(script.OnBeforeLootEqualChanced(nullptr, entries, loot, LootTemplates_Item));
    assert(script.OnBeforeLootEqualChanced(&player, entries, loot, otherStore));
    player.item.entry = 123;
    assert(script.OnBeforeLootEqualChanced(&player, entries, loot, LootTemplates_Item));
    player.item.entry = AdventurerCache;
    loot.containerGUID = 999;
    assert(script.OnBeforeLootEqualChanced(&player, entries, loot, LootTemplates_Item));
    loot.containerGUID = 7;
    assert(loot.awarded.empty());
    for (uint32 level : {1, 10, 16, 30, 45, 60, 80})
        for (uint32 skill : {0, 1, 2, 3, 4})
        {
            player.level = level;
            player.armorSkill = skill;
            std::array<bool, 4> seen{};
            for (firstRoll = 0; firstRoll < 4; ++firstRoll)
                for (secondRoll = 0; secondRoll < 2000; secondRoll += 997)
                {
                    rolls = 0;
                    auto count = loot.awarded.size();
                    assert(!script.OnBeforeLootEqualChanced(&player, entries, loot, LootTemplates_Item));
                    assert(loot.awarded.size() == count + 1);
                    auto item = manager.GetItemTemplate(loot.awarded.back());
                    if (item->Class == ITEM_CLASS_TRADE_GOODS)
                    {
                        seen[Material] = true;
                        assert(item->ItemLevel <= level + 5);
                    }
                    else
                    {
                        assert(item->RequiredLevel <= level);
                        if (item->Class == ITEM_CLASS_ARMOR)
                        {
                            seen[Armor] = true;
                            assert(!item->GetSkill() || item->GetSkill() == skill);
                            assert(item->quality >= 1 && item->quality <= 3);
                        }
                        else if (item->IsPotion())
                            seen[Potion] = true;
                        else
                        {
                            assert(item->SubClass == ITEM_SUBCLASS_FOOD);
                            seen[Food] = true;
                        }
                    }
                }
            assert(seen[Food] && seen[Potion] && seen[Material]);
            if (level >= 16 && skill)
                assert(seen[Armor]);
        }
    auto count = loot.awarded.size();
    assert(!script.OnBeforeLootEqualChanced(&player, {}, loot, LootTemplates_Item));
    assert(loot.awarded.size() == count);
    item_ascension_adventurer_cache use;
    assert(use.OnUse(&player, &player.item, {}));
    assert(player.opened == 1 && player.acknowledgements == 1);
    player.alive = false;
    assert(use.OnUse(&player, &player.item, {}) && player.opened == 1);
    player.alive = true;
    player.combat = true;
    assert(use.OnUse(&player, &player.item, {}) && player.opened == 1);
    player.item.entry = 123;
    assert(!use.OnUse(&player, &player.item, {}));
    for (CacheItems entry : {AdventurerSatchel, AdventurerRareCache})
    {
        Player recipient;
        recipient.item.entry = entry;
        assert(use.OnUse(&recipient, &recipient.item, {}));
        assert(recipient.opened == 1 && recipient.acknowledgements == 1);
        Loot reward;
        assert(!script.OnBeforeLootEqualChanced(&recipient, entries, reward, LootTemplates_Item));
        assert(reward.awarded.size() == 1);
        auto item = manager.GetItemTemplate(reward.awarded.front());
        assert(item->RequiredLevel <= recipient.level);
        recipient.combat = true;
        assert(use.OnUse(&recipient, &recipient.item, {}) && recipient.opened == 1);
        recipient.combat = false;
        recipient.alive = false;
        assert(use.OnUse(&recipient, &recipient.item, {}) && recipient.opened == 1);
    }
}
