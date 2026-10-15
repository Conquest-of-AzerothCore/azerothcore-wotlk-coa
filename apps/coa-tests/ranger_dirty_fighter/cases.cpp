void Player::CastSpell(Unit* target, uint32 id, bool triggeredCast)
{
    assert(target == this && triggeredCast && id == 681787);
    casts.push_back(id); AddAura(id, this);
    aura_ascension_playing_dirty ready;
    ready.fixtureTarget = ready.fixtureCaster = this;
    ready.Apply(nullptr, 1);
}
void Unit::RemoveAurasDueToSpell(uint32 id, ObjectGuid owner)
{
    if (!auras.erase({id, owner})) return;
    if (id == 681787)
    {
        aura_ascension_playing_dirty ready;
        ready.fixtureTarget = this; ready.fixtureCaster = world.at(owner);
        ready.Clear(nullptr, 1);
    }
    if (id == 806978)
    {
        aura_ascension_dirty_fighter talent;
        talent.fixtureTarget = this; talent.fixtureCaster = world.at(owner);
        talent.Clear(nullptr, 1);
    }
}
int main()
{
    Player player, other; player.guid = ObjectGuid(1); other.guid = ObjectGuid(2);
    Unit enemy; enemy.guid = ObjectGuid(3);
    world[player.guid] = &player; world[other.guid] = &other;
    std::vector<uint32> ranks{803108, 503099, 503100, 503101, 503102, 503103, 503104, 503105};
    for (uint32 id : ranks) { player.spells[id] = false; manager.roots[id] = 803108; }
    manager.roots[800000] = 802036;
    ranger_dirty_fighter_casts events;
    auto hit = [&](uint32 id, bool critical = true, uint8 miss = 0, bool triggered = false)
    {
        Spell spell; spell.caster = &player; spell.info.Id = id; spell.info.SpellFamilyName = 27; spell.triggered = triggered;
        events.OnSpellHitResult(&spell, &enemy, miss, 100, 0, critical);
        events.OnSpellHitResult(&spell, &enemy, miss, 100, 0, critical);
    };
    hit(802036); assert(!player.HasAura(684329));
    player.AddAura(806978, &player);
    hit(802036, false); hit(802036, true, 1); hit(802036, true, 0, true); hit(42);
    assert(!player.HasAura(684329));
    hit(802036); assert(player.GetAura(684329, player.guid)->GetStackAmount() == 1);
    player.RemoveAurasDueToSpell(684329, player.guid);
    hit(800000); assert(player.GetAura(684329, player.guid)->GetStackAmount() == 1);
    hit(503105); assert(!player.HasAura(684329) && player.HasAura(681787));
    for (uint32 id : ranks) assert(player.GetTemporarySpellReplacement(id) == 681235);
    assert(player.spells.at(681235));
    Spell punch; punch.caster = &player; punch.info.Id = 681235; punch.info.SpellFamilyName = 27;
    assert(events.CanPrepare(&punch, nullptr, nullptr));
    SpellCastResult result = 0; events.OnSpellCheckCast(&punch, true, result); assert(!result);
    events.OnSpellBeforeEffects(&punch, &player, &punch.info);
    assert(!player.HasAura(681787) && !player.spells.contains(681235));
    for (uint32 id : ranks) assert(player.GetTemporarySpellReplacement(id) == id);
    assert(!events.CanPrepare(&punch, nullptr, nullptr));
    events.OnSpellCheckCast(&punch, false, result); assert(result == SPELL_FAILED_CASTER_AURASTATE);
    player.spells[681235] = false;
    hit(803108); hit(802036);
    other.AddAura(681787, &player);
    player.RemoveAurasDueToSpell(681787, player.guid);
    assert(player.spells.contains(681235) && player.HasAura(681787, other.guid));
    assert(!events.CanPrepare(&punch, nullptr, nullptr));
    player.inactive.insert(681235); hit(803108); hit(802036);
    for (uint32 id : ranks) assert(player.GetTemporarySpellReplacement(id) == id);
    player.RemoveAurasDueToSpell(681787, player.guid); player.inactive.clear();
    hit(803108); hit(802036); hit(803108);
    assert(player.HasAura(681787) && player.HasAura(684329));
    player.RemoveAurasDueToSpell(806978, player.guid);
    assert(!player.HasAura(681787, player.guid) && !player.HasAura(684329));
    for (uint32 id : ranks) assert(player.GetTemporarySpellReplacement(id) == id);
    player.AddAura(806978, &player); player.cls = 20; hit(803108); hit(802036);
    assert(!player.HasAura(681787, player.guid)); player.cls = 21;
    player.CastSpell(&player, 681787, true); player.alive = false;
    assert(!events.CanPrepare(&punch, nullptr, nullptr)); player.alive = true; player.inWorld = false;
    assert(!events.CanPrepare(&punch, nullptr, nullptr)); player.inWorld = true;
    ranger_dirty_fighter_contracts metadata; SpellInfo info; info.Id = 681787; info.SpellFamilyName = 27;
    metadata.OnLoadSpellCustomAttr(&info); assert(info.AttributesCu == SPELL_ATTR0_CU_AURA_CANNOT_BE_SAVED);
}
