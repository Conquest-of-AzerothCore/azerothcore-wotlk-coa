int main()
{
    ResourceService service;
    for (auto const& row : AscensionCompatData::ResourceCostRules)
    {
        if (row.ClassId != 16)
            continue;
        for (uint32 id : {row.FirstSpellId, row.LastSpellId})
            for (bool conduit : {false, true})
            {
                Player player;
                player.AddAura(803102, &player)->m_stackAmount = 100;
                if (conduit)
                    player.AddAura(803790, &player);
                Spell spell{&player};spell.info.Id = id;
                SpellCastResult result = SPELL_CAST_OK;
                service.CheckCast(&spell, result);assert(result == SPELL_CAST_OK);
                service.OnSpellCast(&spell);
                int32 expected = conduit || row.Consumption == AscensionCompatData::ResourceConsumption::None ? 100 :
                    row.Consumption == AscensionCompatData::ResourceConsumption::All ? 0 : 100-row.Amount;
                assert(player.Count(803102) == expected);
                player.RemoveAurasDueToSpell(803102);
                result = SPELL_CAST_OK;
                service.CheckCast(&spell, result);assert(result == SPELL_FAILED_NO_POWER);
            }
    }
    Player owner, foreign;
    owner.AddAura(803102, &owner)->m_stackAmount = 100;
    owner.AddAura(803790, &owner);
    ModifyAscensionAuraStacks(&owner, &owner, 803102, -20);assert(owner.Count(803102) == 100);
    ModifyAscensionAuraStacks(&foreign, &owner, 803102, -20);assert(owner.Count(803102) == 80);
    ModifyAscensionAuraStacks(&owner, &owner, 803102, 10);assert(owner.Count(803102) == 90);
    owner.AddAura(800098, &owner);
    ModifyAscensionAuraStacks(&owner, &owner, 803102, 10);assert(owner.Count(803102) == 90);
    owner.RemoveAurasDueToSpell(803790);
    ModifyAscensionAuraStacks(&owner, &owner, 803102, -20);assert(owner.Count(803102) == 70);
    owner.AddAura(803790, &owner);owner.cls = 14;
    ModifyAscensionAuraStacks(&owner, &owner, 803102, -20);assert(owner.Count(803102) == 50);
    owner.AddAura(800058, &owner)->m_stackAmount = 6;owner.cls = 16;
    ModifyAscensionAuraStacks(&owner, &owner, 800058, -2);assert(owner.Count(800058) == 4);
}
