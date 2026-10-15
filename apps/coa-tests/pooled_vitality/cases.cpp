int main()
{
    using namespace AscensionBloodmage;
    Player player;
    player.auras[PooledVitalityTalent] = {};
    player.auras[VitalityForLater] = {};
    SpellInfo info;
    Spell spell{&player, &info};
    bloodmage_vitality_casts events;
    auto ready = [&] { player.auras[PooledVitality] = {player.guid, 10}; spell.values.clear(); };
    auto prepare = [&] { events.CanPrepare(&spell, nullptr, nullptr); };
    auto finish = [&]
    {
        events.OnSpellBeforeEffects(&spell, &player, &info);
        events.OnSpellCast(&spell, &player, &info, false);
    };
    info.PowerType = POWER_HEALTH;
    spell.m_powerCost = 30;
    for (bool bypass : {true, false})
    {
        player.cheat = bypass;
        spell.values.clear();
        spell.TakePower();
        events.OnSpellCast(&spell, &player, &info, false);
        assert(player.health == (bypass ? 500u : 470u));
        assert(player.HasAura(PooledVitality) == !bypass);
    }
    assert(player.GetAura(PooledVitality, player.guid)->stacks == 1);
    events.OnSpellCast(&spell, &player, &info, false);
    assert(player.GetAura(PooledVitality, player.guid)->stacks == 1);
    for (int i = 0; i < 15; ++i)
    {
        spell.values.clear();
        spell.TakePower();
        events.OnSpellCast(&spell, &player, &info, false);
    }
    assert(player.GetAura(PooledVitality, player.guid)->stacks == 10);
    player.health = 500;
    for (int guard = 0; guard < 3; ++guard)
    {
        spell.values.clear();
        spell.m_CastItem = guard == 0;
        spell.m_triggeredByAuraSpell = guard == 1;
        spell.m_powerCost = guard == 2 ? 0 : 30;
        spell.TakePower();
        assert(!spell.GetScriptValue(PooledVitality));
    }
    spell.m_CastItem = spell.m_triggeredByAuraSpell = false;
    info.PowerType = POWER_RAGE;
    ready(); prepare();
    assert(spell.GetScriptValue(PooledVitalityTalent) == Mend && player.HasAura(PooledVitality));
    manager.rows[info.Id] = info;
    int32 castTime = 2500;
    player.ApplySpellMod(info.Id, SPELLMOD_CASTING_TIME, castTime, &spell);
    assert(castTime == 0);
    SpellCastResult result = SPELL_CAST_OK;
    player.auras[PooledVitality].stacks = 9;
    events.OnSpellCheckCast(&spell, false, result);
    assert(result == SPELL_FAILED_CASTER_AURASTATE);
    ready(); prepare();
    player.casts.clear(); finish(); finish();
    assert(!player.HasAura(PooledVitality) && player.casts.size() == 1);
    assert(std::get<1>(player.casts[0]) == VitalityHeal);
    castTime = 2000;
    player.ApplySpellMod(info.Id, SPELLMOD_CASTING_TIME, castTime, &spell);
    assert(castTime == 0);
    events.OnSpellHitResult(&spell, &player, SPELL_MISS_NONE, 0, 301, true);
    events.OnSpellHitResult(&spell, &player, SPELL_MISS_NONE, 0, 301, true);
    assert(player.casts.size() == 2 && std::get<2>(player.casts.back()) == 150);
    for (uint32 guard : {CursedFormCheck, CursedForm})
    {
        ready(); player.auras[guard] = {}; prepare();
        assert(!spell.GetScriptValue(PooledVitalityTalent)); player.auras.erase(guard);
    }
    ready(); player.auras[PooledVitality].caster = 99; prepare();
    assert(!spell.GetScriptValue(PooledVitalityTalent));
    ready(); spell.triggered = true; prepare();
    assert(!spell.GetScriptValue(PooledVitalityTalent)); spell.triggered = false;
    ready(); player.cls = CLASS_MAGE; prepare();
    assert(!spell.GetScriptValue(PooledVitalityTalent)); player.cls = CLASS_SON_OF_ARUGAL;
    ready(); player.auras.erase(PooledVitalityTalent); prepare();
    assert(!spell.GetScriptValue(PooledVitalityTalent)); player.auras[PooledVitalityTalent] = {};
    for (uint32 id : {504129u, 801952u, 804195u, 573299u, 705734u})
    {
        info.Id = id; manager.rows[id] = info; ready(); prepare();
        uint32 cost = 500;
        player.ApplySpellMod(id, SPELLMOD_COST, cost, &spell);
        assert(cost == ((id == 504129 || id == 801952 || id == 804195) ? 0u : 500u));
        float radius = 10;
        player.ApplySpellMod(id, SPELLMOD_RADIUS, radius, &spell);
        assert(radius == (id == 504129 ? 15.0f : 10.0f));
        int32 duration = 12000, summons = 2, cooldown = 180000;
        player.ApplySpellMod(id, SPELLMOD_DURATION, duration, &spell);
        player.m_spellModTakingSpell = &spell;
        player.ApplySpellMod(id, SPELLMOD_EFFECT1, summons);
        player.m_spellModTakingSpell = nullptr;
        player.ApplySpellMod(id, SPELLMOD_COOLDOWN, cooldown, &spell);
        assert(duration == (id == 573299 ? 17000 : 12000));
        assert(summons == (id == 573299 ? 3 : 2));
        assert(cooldown == (id == 705734 ? 120000 : 180000));
        cost = 500; player.ApplySpellMod(id, SPELLMOD_COST, cost);
        assert(cost == 500);
    }
    assert(GetEmpowerment(504086) == Mend && GetEmpowerment(504282) == CrimsonTide);
    assert(GetEmpowerment(572898) == Heartbreak && GetEmpowerment(806932) == Bloodbolt);
    assert(GetEmpowerment(573357) == AnimatedBlood && GetEmpowerment(573328) == None);
    bloodmage_vitality_scaling scaling;
    SpellInfo helper; helper.Id = VitalityHeal; helper.Effects[0].Effect = SPELL_EFFECT_HEAL;
    float base = 123;
    scaling.ModifySpellEffectBaseValue(&player, &helper, 0, base);
    assert(base == 273);
    helper.Id = 42;
    scaling.ModifySpellEffectBaseValue(&player, &helper, 0, base);
    assert(base == 273);
    Unit ally, enemy, secondary;
    spell_ascension_bloodmage_empowered hit;
    hit.spell = &spell; hit.hit = &enemy; hit.initial = &enemy; hit.damage = 70;
    info.Id = 804685; ready(); prepare();
    hit.ModifyHit(); assert(hit.damage == 140);
    hit.hit = &secondary; hit.damage = 70;
    hit.ModifyHit(); assert(hit.damage == 70);
    info.Id = 801952; ready(); prepare();
    hit.hit = &ally; hit.heal = 500; hit.ModifyHit();
    assert(hit.heal == 750);
    info.Id = 520314; info.Effects[1].TriggerSpell = HeartbreakBuff;
    spell.values.clear(); hit.effectValue = 95; player.casts.clear();
    hit.HeartbreakPower(EFFECT_1); assert(hit.prevented && player.casts.empty());
    ready(); prepare(); hit.HeartbreakPower(EFFECT_1); hit.HeartbreakPower(EFFECT_1);
    assert(player.casts.size() == 2 && std::get<0>(player.casts[0]) == &player &&
        std::get<1>(player.casts[0]) == HeartbreakBuff && std::get<2>(player.casts[0]) == 95);
}
