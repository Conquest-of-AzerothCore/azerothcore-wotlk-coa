int main()
{
    Player reaper;
    reaper.cls = CLASS_REAPER;
    reaper.health = 349;
    reaper.auras[705436] = {};
    manager.rows[707454].Effects[0].value = 25;
    assert(reaper.GetUnitDodgeChance() == 32);
    reaper.health = 350;
    assert(reaper.GetUnitDodgeChance() == 7);
    reaper.health = 349;
    reaper.cls = CLASS_MAGE;
    assert(reaper.GetUnitDodgeChance() == 7);
    reaper.cls = CLASS_REAPER;
    Unit attacker;
    ProcEventInfo event;
    event.actor = &attacker; event.target = &reaper;
    aura_ascension_spiritual_reflexes reflexes;
    reflexes.fixtureOwner = &reaper;
    assert(reflexes.CheckProc(event)); reflexes.Harvest(nullptr, event);
    assert(reaper.casts.size() == 1 && std::get<0>(reaper.casts[0]) == &attacker &&
        std::get<1>(reaper.casts[0]) == 573050);
    for (uint32 mask : {PROC_HIT_NORMAL, PROC_HIT_PARRY, PROC_HIT_BLOCK})
    {
        event.hit = mask; reflexes.Harvest(nullptr, event);
    }
    event.hit = PROC_HIT_DODGE; reaper.health = 350; reflexes.Harvest(nullptr, event);
    reaper.health = 349; attacker.alive = false; reflexes.Harvest(nullptr, event);
    assert(reaper.casts.size() == 1);

    Player primal;
    primal.cls = CLASS_WILDWALKER;
    primal.auras[680406] = {};
    primal.level = 34;
    aura_ascension_mountain_threshold threshold;
    threshold.fixtureOwner = &primal;
    threshold.Changed(nullptr, AURA_EFFECT_HANDLE_REAL);
    for (uint8 count = 2; count <= 5; ++count)
    {
        threshold.stacks = count;
        threshold.Changed(nullptr, AURA_EFFECT_HANDLE_CHANGE_AMOUNT);
        assert(primal.casts.empty());
    }
    primal.level = 40;
    threshold.stacks = 3;
    threshold.Changed(nullptr, AURA_EFFECT_HANDLE_CHANGE_AMOUNT);
    threshold.stacks = 5;
    threshold.Changed(nullptr, AURA_EFFECT_HANDLE_CHANGE_AMOUNT);
    assert(primal.casts.size() == 1 && std::get<1>(primal.casts[0]) == 680472);
    threshold.Changed(nullptr, AURA_EFFECT_HANDLE_CHANGE_AMOUNT);
    assert(primal.casts.size() == 1 && std::get<1>(primal.casts[0]) == 680472);
    aura_ascension_mountain_threshold loaded;
    loaded.fixtureOwner = &primal; loaded.stacks = 5;
    loaded.Changed(nullptr, AURA_EFFECT_HANDLE_REAL);
    loaded.Changed(nullptr, AURA_EFFECT_HANDLE_CHANGE_AMOUNT);
    assert(primal.casts.size() == 1);
    loaded.stacks = 3; loaded.Changed(nullptr, AURA_EFFECT_HANDLE_CHANGE_AMOUNT);
    loaded.stacks = 5; loaded.caster = 99; loaded.Changed(nullptr, AURA_EFFECT_HANDLE_CHANGE_AMOUNT);
    assert(primal.casts.size() == 1);
    loaded.stacks = 3; loaded.caster = 1; loaded.Changed(nullptr, AURA_EFFECT_HANDLE_CHANGE_AMOUNT);
    primal.auras.erase(680406); loaded.stacks = 5; loaded.Changed(nullptr, AURA_EFFECT_HANDLE_CHANGE_AMOUNT);
    assert(primal.casts.size() == 1);
    DamageInfo damage; SpellInfo rush;
    rush.SpellFamilyName = 37; rush.SpellFamilyFlags[0] = 16384; damage.info = &rush;
    attacker.alive = true; event.actor = &primal; event.target = &attacker; event.damage = &damage;
    aura_ascension_blessed_by_earth earth; earth.fixtureOwner = &primal;
    assert(earth.CheckProc(event)); earth.Gain(nullptr, event);
    rush.SpellFamilyFlags = {0, 0, 256}; assert(earth.CheckProc(event));
    rush.SpellFamilyFlags = {0, 0, 0}; assert(!earth.CheckProc(event));
    rush.SpellFamilyFlags[0] = 16384; damage.amount = 0; assert(!earth.CheckProc(event));
    damage.amount = 10; event.actor = &attacker; assert(!earth.CheckProc(event));
    SpellInfo resource; resource.Id = 806068; resource.SpellFamilyName = 37;
    resource.Effects[2].Effect = SPELL_EFFECT_TRIGGER_SPELL;
    mountain_talent_metadata metadata; metadata.OnLoadSpellCustomAttr(&resource);
    assert(resource.Effects[2].Effect == 0);
}
