void Unit::RemoveAurasDueToSpell(uint32 id, ObjectGuid casterGuid)
{
    auto it = auras.find(id);
    if (it == auras.end() || it->second.caster != casterGuid) return;
    Aura saved = it->second; auras.erase(it);
    if (id == SPELL_DECOY_WINDOW)
    {
        aura_ascension_decoy_window hook; hook.caster = world.at(casterGuid); hook.fixtureTarget = this; hook.aura = &saved;
        hook.Clear(nullptr, 1);
    }
    if (id == SPELL_OUTMANEUVER)
    {
        aura_ascension_outmaneuver_mark hook; hook.caster = world.at(casterGuid); hook.fixtureTarget = this; hook.aura = &saved;
        hook.Clear(nullptr, 1);
    }
}
TempSummon* Player::SummonCreature(uint32 entry, Position const& pos, TempSummonType type, uint32 duration)
{
    assert(type == TEMPSUMMON_MANUAL_DESPAWN && duration == 0);
    if (failSummon) return nullptr;
    auto decoy = std::make_unique<TempSummon>();
    decoy->entry = entry; decoy->position = pos; decoy->guid = {1000 + ++summons}; decoy->owner = this; decoy->map = map;
    decoy->ai = std::make_unique<npc_ascension_outmaneuver_decoy>(decoy.get());
    map->creatures[decoy->guid] = decoy.get();
    world[decoy->guid] = decoy.get();
    decoy->ai->IsSummonedBy(this);
    auto result = decoy.get(); creatures.push_back(std::move(decoy)); return result;
}
int main()
{
    Map map, differentMap;
    Player player, other; player.cls = CLASS_RANGER; player.guid = {1}; other.guid = {2};
    player.map = &map; other.map = &map; player.spells[SPELL_OUTMANEUVER] = 0;
    Unit enemy; enemy.guid = {3}; enemy.map = &map;
    world[player.guid] = &player; world[other.guid] = &other; world[enemy.guid] = &enemy;
    player.position = {10, 0, 0, 0}; enemy.position = {40, 0, 0, 0};
    spell_ascension_outmaneuver cast; cast.caster = &player; cast.hit = &enemy; cast.fixtureDestination = {38, 0, 0, 0};
    auto start = [&]()
    {
        player.teleporting = false; enemy.alive = true;
        cast.ClearPrevious(); cast.hitAura = player.AddAura(SPELL_OUTMANEUVER, &enemy);
        assert(cast.Check() == SPELL_CAST_OK); cast.Begin();
        return FindDecoy(&player, player.GetAura(SPELL_DECOY_WINDOW, player.guid));
    };
    auto decoy = start();
    assert(decoy && decoy->position == enemy.position && decoy->position != player.position);
    assert(player.teleportDestination == cast.fixtureDestination && decoy->motion.idle);
    assert(player.GetTemporarySpellReplacement(SPELL_OUTMANEUVER) == SPELL_DECOY_STRIKE);
    decoy->ai->UpdateAI(1000); assert(!decoy->removed);
    player.teleporting = false; player.position = cast.fixtureDestination;
    enemy.position = {80, 0, 0, 0};
    assert(ManeuverTarget(&player) == &enemy && decoy->position.x == 40);
    Spell strike; strike.caster = &player; strike.info.Id = SPELL_DECOY_STRIKE; strike.info.SpellFamilyName = 27;
    ranger_decoy_target targetHook;
    assert(targetHook.CanPrepare(&strike, nullptr, nullptr) && strike.m_targets.target == &enemy);
    aura_ascension_outmaneuver_mark mark; mark.caster = &player; mark.fixtureTarget = &enemy;
    mark.aura = enemy.GetAura(SPELL_OUTMANEUVER, player.guid);
    ProcEventInfo hit; hit.actor = &player; hit.victim = &enemy;
    for (uint32 mask : {8u, 32u})
    {
        hit.mask = mask; assert(mark.Check(hit));
        for (int n = 0; n < 25; ++n) mark.Stack(nullptr, hit);
        assert(mark.aura->stacks == 20);
    }
    hit.mask = 64; assert(!mark.Check(hit)); hit.mask = 8;
    hit.actor = &other; assert(!mark.Check(hit)); hit.actor = &player;
    hit.damage.damage = 0; assert(!mark.Check(hit)); hit.damage.damage = 100;
    hit.info = &strike.info; assert(!mark.Check(hit)); hit.info = nullptr;
    spell_ascension_decoy_strike finish; finish.caster = &player; finish.Record();
    enemy.alive = false; enemy.RemoveAurasDueToSpell(SPELL_OUTMANEUVER, player.guid);
    assert(player.GetAura(SPELL_DECOY_WINDOW, player.guid));
    finish.Return();
    assert(player.teleportDestination.x == 40 && decoy->removed && !player.spells.contains(SPELL_DECOY_STRIKE));
    assert(!player.GetAura(SPELL_DECOY_WINDOW, player.guid));
    auto teleports = player.teleports; finish.Return(); assert(player.teleports == teleports);
    decoy = start(); player.teleporting = false;
    enemy.RemoveAurasDueToSpell(SPELL_OUTMANEUVER, player.guid);
    assert(decoy->removed && !player.GetAura(SPELL_DECOY_WINDOW, player.guid));
    decoy = start(); player.teleporting = false;
    player.RemoveAurasDueToSpell(SPELL_DECOY_WINDOW, player.guid);
    assert(decoy->removed && !enemy.HasAura(SPELL_OUTMANEUVER, player.guid));
    decoy = start(); player.teleporting = false; decoy->alive = false; decoy->ai->JustDied(&other);
    assert(!player.GetAura(SPELL_DECOY_WINDOW, player.guid));
    decoy = start(); player.teleporting = false; player.map = &differentMap; decoy->ai->UpdateAI(250);
    assert(decoy->removed && !player.GetAura(SPELL_DECOY_WINDOW, player.guid)); player.map = &map;
    decoy = start(); player.teleporting = false; player.spells.erase(SPELL_OUTMANEUVER); decoy->ai->UpdateAI(250);
    assert(decoy->removed && !player.GetAura(SPELL_DECOY_WINDOW, player.guid)); player.spells[SPELL_OUTMANEUVER] = 0;
    player.failSummon = true; assert(!start() && !enemy.HasAura(SPELL_OUTMANEUVER, player.guid)); player.failSummon = false;
    player.spells[SPELL_DECOY_STRIKE] = -1; assert(!start());
    assert(player.spells.at(SPELL_DECOY_STRIKE) == -1); player.spells[SPELL_DECOY_STRIKE] = 0;
    decoy = start(); player.teleporting = false; player.RemoveAurasDueToSpell(SPELL_DECOY_WINDOW, player.guid);
    assert(decoy->removed && player.spells.at(SPELL_DECOY_STRIKE) == 0);
    for (bool* invalid : {&player.teleporting, &player.flight, &player.transport, &player.vehicle})
    {
        *invalid = true; assert(cast.Check() != SPELL_CAST_OK); *invalid = false;
    }
    player.alive = false; assert(cast.Check() != SPELL_CAST_OK); player.alive = true;
    player.cls = CLASS_CHRONOMANCER; assert(cast.Check() != SPELL_CAST_OK); player.cls = CLASS_RANGER;
    ranger_decoy_contracts metadata; SpellInfo info; info.Id = SPELL_DECOY_WINDOW; info.SpellFamilyName = 27;
    info.AttributesCu = SPELL_ATTR0_CU_FORCE_AURA_SAVING; metadata.OnLoadSpellCustomAttr(&info);
    assert(info.AttributesCu == SPELL_ATTR0_CU_AURA_CANNOT_BE_SAVED);
}
