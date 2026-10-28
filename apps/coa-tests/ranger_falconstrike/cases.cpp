int main()
{
    Player player;
    player.guid = {1};
    player.cls = CLASS_RANGER;
    player.spells[500074] = 0;
    player.auras[573060] = {573060, player.guid};
    uint32 levels[] = {11, 18, 25, 32, 39, 46, 53, 60};
    for (std::size_t i = 0; i < Falconstrikes.size(); ++i)
        manager.spells[Falconstrikes[i]].SpellLevel = levels[i];
    ranger_falconstrike_lifecycle lifecycle;
    ranger_falconstrike_casts casts;
    spell_ascension_ranger_falconstrike ability;
    ability.caster = &player;
    assert(ability.CheckReady() != SPELL_CAST_OK);
    lifecycle.OnPlayerLogin(&player);
    assert(player.spells.size() == 2 && player.HasActiveSpell(806345));
    Spell spell;
    SpellInfo info;
    info.SpellFamilyName = 27;
    info.SpellFamilyFlags[1] = 1;
    for (int i = 0; i < 3; ++i)
    {
        casts.OnSpellCast(&spell, &player, &info, false);
        assert(player.GetTemporarySpellReplacement(500074) == 500074);
        assert(player.HasActiveSpell(806345));
    }
    spell.triggered = true;
    casts.OnSpellCast(&spell, &player, &info, false);
    assert(player.GetAura(573248, player.guid)->stacks == 3);
    spell.triggered = false;
    casts.OnSpellCast(&spell, &player, &info, false);
    assert(!player.HasAura(573248));
    assert(player.GetAura(573338, player.guid)->duration == 15000);
    assert(player.GetTemporarySpellReplacement(500074) == 806345 && player.spells.at(806345) == 1);
    assert(ability.CheckReady() == SPELL_CAST_OK);
    info.SpellFamilyFlags[1] = 4194304;
    casts.OnSpellCast(&spell, &player, &info, false);
    assert(!player.HasAura(573338) && player.HasActiveSpell(806345));
    assert(player.GetTemporarySpellReplacement(500074) == 500074);
    assert(ability.CheckReady() != SPELL_CAST_OK);
    info.SpellFamilyFlags[1] = 0;
    info.SpellFamilyFlags[2] = 1;
    casts.OnSpellCast(&spell, &player, &info, false);
    assert(player.GetAura(573338, player.guid)->duration == 60000);
    assert(player.GetTemporarySpellReplacement(500074) == 806345);
    player.auras.erase(573338);
    lifecycle.OnPlayerUpdate(&player, 1);
    assert(player.GetTemporarySpellReplacement(500074) == 500074 && player.HasActiveSpell(806345));
    for (std::size_t i = 0; i < Falconstrikes.size(); ++i)
    {
        player.level = levels[i];
        casts.OnSpellCast(&spell, &player, &info, false);
        assert(player.GetTemporarySpellReplacement(500074) == Falconstrikes[i]);
        assert(player.spells.size() == 2);
    }
    player.level = 10;
    lifecycle.OnPlayerUpdate(&player, 1);
    assert(player.GetTemporarySpellReplacement(500074) == 806345 && !player.HasActiveSpell(806443));
    player.spells[806345] = 0;
    player.auras.erase(573060);
    lifecycle.OnPlayerUpdate(&player, 1);
    assert(!player.HasAura(573338) && player.GetTemporarySpellReplacement(500074) == 500074);
    assert(player.spells.at(806345) == 0);
    player.auras[573060] = {573060, player.guid};
    player.spells[806345] = -1;
    casts.OnSpellCast(&spell, &player, &info, false);
    assert(player.spells.at(806345) == -1 && player.GetTemporarySpellReplacement(500074) == 500074);
    player.spells.erase(806345);
    lifecycle.OnPlayerUpdate(&player, 1);
    assert(player.GetTemporarySpellReplacement(500074) == 806345);
    player.alive = false;
    assert(ability.CheckReady() != SPELL_CAST_OK);
    lifecycle.OnPlayerUpdate(&player, 1);
    assert(player.GetTemporarySpellReplacement(500074) == 500074);
    player.alive = true;
    player.cls = CLASS_MAGE;
    auto count = player.casts.size();
    casts.OnSpellCast(&spell, &player, &info, false);
    assert(player.casts.size() == count && ability.CheckReady() != SPELL_CAST_OK);
    player.cls = CLASS_RANGER;
    for (uint32 rank : Falconstrikes)
    {
        int amount = 0;
        for (auto const& rule : AscensionCompatData::ResourceGainRules)
            if (MatchesGainRule(&player, rank, rule) && rule.ResourceSpellId == 804329 &&
                rule.Event == AscensionCompatData::ResourceGainEvent::Cast)
                amount += rule.Amount;
        assert(amount == (rank == 806345 ? 2 : 1));
    }
}
