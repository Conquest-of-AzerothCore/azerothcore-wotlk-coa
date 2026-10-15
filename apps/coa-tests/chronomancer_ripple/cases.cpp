int main()
{
    Unit caster, ally, enemy;
    ally.fixtureGuid = 2; enemy.fixtureGuid = 3;
    caster.AddAura(EternityWarper, &caster);
    Aura* channel = caster.AddAura(Ripple, &caster);
    aura_ascension_ripple_aeon ripple;
    ripple.fixtureTarget = &caster; ripple.fixtureAura = channel;
    for (auto [aeon, helper] : {std::pair{AeonRenewal, Renewal}, {AeonResilience, Resilience},
        {AeonProtection, Protection}, {AeonOblivion, Oblivion}})
    {
        caster.AddAura(aeon, &caster);
        ripple.Start(nullptr, AURA_EFFECT_HANDLE_REAL);
        assert(std::get<1>(caster.fixtureCasts.back()) == helper);
        caster.RemoveAurasDueToSpell(aeon, caster.GetGUID());
    }
    chronomancer_ripple_duration durations;
    channel->fixtureDuration = 4200;
    int32 duration = 5000;
    durations.OnCalcMaxDuration(caster.GetAura(Renewal), duration);
    assert(duration == 4200);
    aura_ascension_ripple_protection protection;
    protection.fixtureTarget = &ally;
    protection.fixtureAura = caster.AddAura(Protection, &ally);
    int32 shield = 150; bool recalc = true;
    protection.Amount(nullptr, shield, recalc);
    assert(shield == 450 && !recalc);
    DamageInfo hit;
    uint32 absorbed = 100;
    protection.Absorb(nullptr, hit, absorbed); assert(absorbed == 100);
    caster.fixturePhase = false;
    protection.Absorb(nullptr, hit, absorbed); assert(absorbed == 0);
    caster.fixturePhase = true;
    aura_ascension_ripple_resilience resilience;
    resilience.fixtureTarget = &ally;
    resilience.fixtureAura = caster.AddAura(Resilience, &ally);
    resilience.Absorb(nullptr, hit, absorbed); assert(absorbed == 300);
    absorbed = 120;
    resilience.Store(nullptr, hit, absorbed);
    Aura* saved = ally.GetAura(StaggerDebt, ally.GetGUID());
    assert(saved->GetEffect(EFFECT_1)->GetAmount() == 120 && saved->GetEffect(EFFECT_2)->GetAmount() == 5);
    for (DamageEffectType type : {DOT, HEAL, NODAMAGE})
    {
        hit.fixtureType = type;
        resilience.Absorb(nullptr, hit, absorbed); assert(absorbed == 0);
    }
    hit.fixtureType = SPELL_DIRECT_DAMAGE; hit.fixtureSchool = SPELL_SCHOOL_MASK_FIRE;
    resilience.Absorb(nullptr, hit, absorbed); assert(absorbed == 0);
    hit.fixtureSchool = SPELL_SCHOOL_MASK_NORMAL; caster.fixtureRange = false;
    resilience.Absorb(nullptr, hit, absorbed); assert(absorbed == 0);
    caster.fixtureRange = true;
    aura_ascension_ripple_debt debt;
    debt.fixtureTarget = &ally; debt.fixtureAura = saved;
    debt.Tick(nullptr);
    assert(ally.fixturePayments.back() == 24 && saved->GetEffect(EFFECT_1)->GetAmount() == 96);
    aura_ascension_ripple_debt loaded;
    loaded.fixtureTarget = &ally; loaded.fixtureAura = saved;
    loaded.Tick(nullptr);
    assert(ally.fixturePayments.back() == 24 && saved->GetEffect(EFFECT_1)->GetAmount() == 72);
    absorbed = 31; resilience.Store(nullptr, hit, absorbed);
    assert(saved->GetEffect(EFFECT_1)->GetAmount() == 103 && saved->GetEffect(EFFECT_2)->GetAmount() == 5);
    channel->Remove(); ripple.Stop(nullptr, AURA_EFFECT_HANDLE_REAL);
    assert(!caster.HasAura(Renewal) && !caster.HasAura(Resilience));
    protection.Absorb(nullptr, hit, absorbed); assert(absorbed == 0);
    protection.Cleanup(nullptr); assert(protection.fixtureAura->fixtureRemoved);
    resilience.Absorb(nullptr, hit, absorbed); assert(absorbed == 0);
    for (uint32 tick = 0; tick < 5; ++tick) loaded.Tick(nullptr);
    uint32 total = 0; for (uint32 value : ally.fixturePayments) total += value;
    assert(total == 151 && saved->GetEffect(EFFECT_1)->GetAmount() == 0);
    saved->GetEffect(EFFECT_1)->SetAmount(101);
    loaded.fixtureApplication.fixtureMode = AURA_REMOVE_BY_CANCEL;
    loaded.End(nullptr, AURA_EFFECT_HANDLE_REAL);
    assert(ally.fixturePayments.back() == 101);
    saved->GetEffect(EFFECT_1)->SetAmount(50);
    loaded.fixtureApplication.fixtureMode = AURA_REMOVE_BY_DEATH;
    loaded.End(nullptr, AURA_EFFECT_HANDLE_REAL);
    assert(saved->GetEffect(EFFECT_1)->GetAmount() == 50);
    chronomancer_expiry_events expiry;
    Aura* clasp = caster.AddAura(Clasp, &enemy);
    AuraApplication app; app.fixtureAura = clasp;
    caster.fixtureCasts.clear();
    expiry.OnAuraRemove(&enemy, &app, AURA_REMOVE_BY_EXPIRE); assert(caster.fixtureCasts.empty());
    caster.AddAura(EndOfTime, &caster);
    for (auto mode : {AURA_REMOVE_BY_CANCEL, AURA_REMOVE_BY_ENEMY_SPELL, AURA_REMOVE_BY_DEATH})
        expiry.OnAuraRemove(&enemy, &app, mode);
    assert(caster.fixtureCasts.empty());
    expiry.OnAuraRemove(&enemy, &app, AURA_REMOVE_BY_EXPIRE);
    assert(caster.fixtureCasts.size() == 1 && std::get<1>(caster.fixtureCasts[0]) == EndOfTimeRelease);
    chronomancer_ripple_metadata metadata;
    SpellInfo info; info.Id = Clasp; info.Effects[2].Effect = SPELL_EFFECT_APPLY_AURA;
    metadata.OnLoadSpellCustomAttr(&info); assert(info.Effects[2].Effect == 0);
    info.Id = Resilience; info.Effects[0].Effect = SPELL_EFFECT_APPLY_AREA_AURA_RAID;
    metadata.OnLoadSpellCustomAttr(&info);
    assert(info.Effects[0].Effect == SPELL_EFFECT_APPLY_AREA_AURA_RAID &&
        info.Effects[0].ApplyAuraName == SPELL_AURA_SCHOOL_ABSORB && info.Effects[0].TriggerSpell == 0);
    info.Id = StaggerDebt; metadata.OnLoadSpellCustomAttr(&info);
    assert(info.Effects[0].Amplitude == 1000 && info.Effects[1].ApplyAuraName == SPELL_AURA_DUMMY &&
        info.Effects[2].BasePoints == 5 && !info.ProcFlags);
}
