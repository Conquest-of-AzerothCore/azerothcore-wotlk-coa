namespace
{
bool PreparePrestigeReset(Player* player, AscensionPrestigeReset::Plan& plan, std::string& error)
{
    if (!Applies(player) || !player->IsInWorld() || !player->FindMap() || !player->IsAlive() ||
        player->IsInCombat() || player->InBattleground() || player->InArena() ||
        player->IsBeingTeleported() || !Area52Build::CanSwitchSpecialization(player))
    {
        error = "Your active build is not ready for Prestige.";
        return false;
    }
    auto const* saved = player->FindPlayerSettings(ActiveSlotSetting);
    auto const build = saved && !saved->empty() ? (*saved)[0].value : 0;
    if (build >= SpecializationSpells.size() || !player->HasSpell(SpecializationSpells[build]))
    {
        error = "Your active build specialization is not unlocked.";
        return false;
    }
    if (!Validate(Data, player->GetLevel(), {}, {}))
    {
        error = "Your active build could not be prepared for Prestige.";
        return false;
    }
    plan.Build = build;
    return AscensionMysticEnchant::PreparePrestigeReset(player, plan.Enchants, error);
}

bool ResetPrestigeSpecialization(Player* player, AscensionPrestigeReset::Plan const& plan,
    AscensionPrestigeReset::Result& result, std::string& error)
{
    AscensionPrestigeReset::Plan current;
    if (!PreparePrestigeReset(player, current, error))
        return false;
    if (current.Build != plan.Build || current.Enchants != plan.Enchants)
    {
        error = "Your active specialization changed. Reopen Prestige and try again.";
        return false;
    }
    auto const count = KnownEntries(player).size();
    if (!Apply(player, {}, false, true))
    {
        error = "Your active build could not be reset.";
        return false;
    }
    result.Abilities = std::uint32_t(count);
    result.Enchants = AscensionMysticEnchant::ResetPrestigeSpecialization(player);
    for (auto const& [spell, learned] : player->GetSpellMap())
        if (!learned->specMask && learned->State != PLAYERSPELL_REMOVED && ClassSpells.contains(spell))
            if (auto const* info = sSpellMgr->GetSpellInfo(spell); info && info->SpellLevel > 1)
                learned->State = PLAYERSPELL_REMOVED;
    Area52Build::PauseAutoLearnForReset(player);
    StoreValues(player, ActiveBuildSetting, {});
    for (auto suffix : {".entries", ".active_build", ".ranks", ".bars"})
        StoreValues(player, SlotSetting(plan.Build, suffix), {});
    if (auto* pending = player->CustomData.Get<PendingBars>(PendingBarsKey))
        pending->Buttons.clear();
    Area52Build::RestoreSpecialization(player);
    SendArea52Advancement(player);
    SendArea52Specialization(player);
    return true;
}

AscensionPrestigeReset::Handler const PrestigeResetHandler{
    Applies, PreparePrestigeReset, ResetPrestigeSpecialization
};
}
