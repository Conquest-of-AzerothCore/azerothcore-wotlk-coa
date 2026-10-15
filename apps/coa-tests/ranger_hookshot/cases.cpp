void Unit::RemoveAurasDueToSpell(uint32 id, ObjectGuid owner)
{
    auto it = auras.find({id, owner});
    if (it == auras.end()) return;
    Aura saved = it->second;
    auras.erase(it);
    if (id == 803857)
    {
        aura_ascension_hookshot_ready ready;
        ready.fixtureTarget = this; ready.fixtureCaster = world.at(owner); ready.fixtureAura = &saved;
        ready.Clear(nullptr, 1);
    }
}
int main()
{
    Player player, other; player.guid = ObjectGuid(1); other.guid = ObjectGuid(2);
    Unit enemy, second; enemy.guid = ObjectGuid(3); second.guid = ObjectGuid(4);
    for (Unit* unit : {static_cast<Unit*>(&player), static_cast<Unit*>(&other), &enemy, &second})
        world[unit->guid] = unit;
    spell_ascension_hookshot latch; latch.fixtureCaster = &player; latch.fixtureTarget = &enemy;
    assert(latch.Load());
    ranger_hookshot_casts events;
    Spell followup; followup.caster = &player; followup.info.Id = 803852; followup.info.SpellFamilyName = 27;
    for (uint32 rank : {800360u, 802394u, 802395u, 802396u, 802397u, 802398u})
    {
        player.spells[rank] = false; latch.fixtureInfo.Id = rank;
        enemy.bleeding = false; latch.Latch(1);
        assert(latch.prevented && !player.HasAura(803857, player.guid));
        enemy.bleeding = true; latch.Latch(1);
        assert(HookTarget(&player) == &enemy && player.spells.at(803852));
        assert(player.GetTemporarySpellReplacement(rank) == 803852);
        assert(player.session.packets.back() == std::vector<uint32>({rank, 803852}));
        enemy.bleeding = false;
        for (Unit* selected : {static_cast<Unit*>(nullptr), &second, static_cast<Unit*>(&player)})
        {
            followup.m_targets.unit = selected;
            assert(events.CanPrepare(&followup, nullptr, nullptr) && followup.m_targets.unit == &enemy);
        }
        for (bool* valid : {&player.alive, &player.inWorld, &enemy.alive, &enemy.phase})
        {
            *valid = false; assert(!events.CanPrepare(&followup, nullptr, nullptr)); *valid = true;
        }
        player.inactive.insert(rank); assert(!events.CanPrepare(&followup, nullptr, nullptr)); player.inactive.clear();
        enemy.friendly = true; assert(!events.CanPrepare(&followup, nullptr, nullptr)); enemy.friendly = false;
        world.erase(enemy.guid); assert(!events.CanPrepare(&followup, nullptr, nullptr)); world[enemy.guid] = &enemy;
        SpellCastResult result = 0; events.OnSpellCheckCast(&followup, true, result); assert(!result);
        events.OnSpellBeforeEffects(&followup, &player, &followup.info);
        assert(!player.spells.contains(803852) && player.GetTemporarySpellReplacement(rank) == rank);
        assert(!events.CanPrepare(&followup, nullptr, nullptr));
        events.OnSpellCheckCast(&followup, false, result); assert(result == SPELL_FAILED_BAD_TARGETS);
    }
    enemy.bleeding = true; latch.fixtureInfo.Id = 800360; latch.Latch(1);
    latch.fixtureInfo.Id = 802398; latch.fixtureTarget = &second; second.bleeding = true; latch.Latch(1);
    assert(player.GetTemporarySpellReplacement(800360) == 800360 && HookTarget(&player) == &second);
    player.RemoveAurasDueToSpell(803857, player.guid);
    assert(!player.spells.contains(803852));
    player.spells[803852] = false; latch.Latch(1);
    other.AddAura(803857, &player);
    player.RemoveAurasDueToSpell(803857, player.guid);
    assert(player.spells.contains(803852) && player.HasAura(803857, other.guid));
    player.inactive.insert(803852); latch.Latch(1);
    assert(!player.HasAura(803857, player.guid) && player.spells.contains(803852));
    player.inactive.clear(); player.cls = 20; assert(!latch.Load()); player.cls = 21;
    ranger_hookshot_contracts metadata; SpellInfo info; info.Id = 803857; info.SpellFamilyName = 27;
    metadata.OnLoadSpellCustomAttr(&info); assert(info.AttributesCu == SPELL_ATTR0_CU_AURA_CANNOT_BE_SAVED);
}
