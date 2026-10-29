/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "AscensionRulesets.h"
#include "Config.h"
#include "LocalLevelScaling.h"
#include "Map.h"
#include "Player.h"
#include "ScriptMgr.h"
#include "SpellScript.h"
#include <atomic>
#include <vector>

namespace
{
enum RulesetSpells : uint32
{
    SPELL_SELECT_WAR_MODE = 84420,
    SPELL_SELECT_HIGH_RISK = 84421,
    SPELL_SELECT_PVE = 84422,
    SPELL_HIGH_RISK = 1004019,
    SPELL_WAR_MODE = 1004119,
    SPELL_PVE = 9931032,
    SPELL_MERCENARY = 9930874
};

std::atomic<bool> pvpRulesetsDisableLevelScaling{false};
std::vector<AscensionRulesets::Guard> rulesetGuards;

bool InPvPRuleset(Player const* player)
{
    return player->HasAura(SPELL_HIGH_RISK) || (player->HasAura(SPELL_WAR_MODE) && !player->HasAura(SPELL_PVE));
}

bool RulesetBlocksLevelScaling(Player const* player)
{
    if (!pvpRulesetsDisableLevelScaling.load(std::memory_order_relaxed))
        return false;

    Map const* map = player->FindMap();
    return map && !map->Instanceable() && InPvPRuleset(player);
}

void SyncRulesetPvP(Player* player)
{
    if (InPvPRuleset(player))
    {
        player->SetPlayerFlag(PLAYER_FLAGS_IN_PVP);
        player->UpdatePvP(true, true);
    }
    else if (player->HasAura(SPELL_PVE) && player->HasPlayerFlag(PLAYER_FLAGS_IN_PVP))
    {
        player->RemovePlayerFlag(PLAYER_FLAGS_IN_PVP);
        player->UpdatePvP(false);
    }
}

void RefreshMercenariesFor(Player* viewer)
{
    if (Map* map = viewer->FindMap())
        map->DoForAllPlayers([viewer](Player* mercenary)
        {
            if (mercenary == viewer || !mercenary->HasAura(SPELL_MERCENARY))
                return;
            mercenary->ForceValuesUpdateAtIndex(UNIT_FIELD_FACTIONTEMPLATE);
            for (Unit* controlled : mercenary->m_Controlled)
                if (controlled->GetOwnerGUID() == mercenary->GetGUID())
                    controlled->ForceValuesUpdateAtIndex(UNIT_FIELD_FACTIONTEMPLATE);
        });
}

AscensionRulesets::Ruleset SelectedRuleset(uint32 selectionId)
{
    if (selectionId == SPELL_SELECT_HIGH_RISK)
        return AscensionRulesets::Ruleset::HighRisk;
    if (selectionId == SPELL_SELECT_PVE)
        return AscensionRulesets::Ruleset::PvE;
    return AscensionRulesets::Ruleset::WarMode;
}

void ApplyRuleset(Player* player, uint32 selectionId)
{
    if (!AscensionRulesets::CanApply(player, SelectedRuleset(selectionId)))
        return;
    bool const blockedBefore = RulesetBlocksLevelScaling(player);
    player->RemoveAurasDueToSpell(SPELL_HIGH_RISK);
    player->RemoveAurasDueToSpell(SPELL_WAR_MODE);
    player->RemoveAurasDueToSpell(SPELL_PVE);
    player->RemoveAurasDueToSpell(SPELL_MERCENARY);
    if (selectionId == SPELL_SELECT_HIGH_RISK)
        player->CastSpell(player, SPELL_HIGH_RISK, true);
    else if (selectionId == SPELL_SELECT_PVE)
        player->CastSpell(player, SPELL_PVE, true);
    else
        player->CastSpell(player, SPELL_WAR_MODE, true);
    player->ForceValuesUpdateAtIndex(UNIT_FIELD_BYTES_2);
    SyncRulesetPvP(player);
    RefreshMercenariesFor(player);

    if (player->IsInWorld() && RulesetBlocksLevelScaling(player) != blockedBefore &&
        !LocalLevelScaling::NotifyScalingChanged(player))
        player->RefreshQuestLogQueries();
}

uint32 SelectionSpell(AscensionRulesets::Ruleset ruleset)
{
    switch (ruleset)
    {
        case AscensionRulesets::Ruleset::HighRisk:
            return SPELL_SELECT_HIGH_RISK;
        case AscensionRulesets::Ruleset::PvE:
            return SPELL_SELECT_PVE;
        default:
            return SPELL_SELECT_WAR_MODE;
    }
}

uint32 RulesetAura(AscensionRulesets::Ruleset ruleset)
{
    switch (ruleset)
    {
        case AscensionRulesets::Ruleset::HighRisk:
            return SPELL_HIGH_RISK;
        case AscensionRulesets::Ruleset::PvE:
            return SPELL_PVE;
        default:
            return SPELL_WAR_MODE;
    }
}

class spell_ascension_ruleset_select : public SpellScript
{
    PrepareSpellScript(spell_ascension_ruleset_select);

    bool Validate(SpellInfo const*) override
    {
        return ValidateSpellInfo({SPELL_HIGH_RISK, SPELL_WAR_MODE, SPELL_PVE});
    }

    bool Load() override { return GetCaster()->ToPlayer() != nullptr; }

    SpellCastResult CheckCast()
    {
        Player* player = GetCaster()->ToPlayer();
        if (!player || !player->HasPlayerFlag(PLAYER_FLAGS_RESTING))
            return SPELL_FAILED_NOT_HERE;
        return AscensionRulesets::CanApply(player, SelectedRuleset(GetSpellInfo()->Id)) ?
            SPELL_CAST_OK : SPELL_FAILED_CANT_DO_THAT_RIGHT_NOW;
    }

    void Select(SpellEffIndex)
    {
        Player* player = GetCaster()->ToPlayer();
        uint32 id = GetSpellInfo()->Id;
        if (!player || (id != SPELL_SELECT_WAR_MODE && id != SPELL_SELECT_HIGH_RISK && id != SPELL_SELECT_PVE))
            return;

        ApplyRuleset(player, id);
    }

    void Register() override
    {
        OnCheckCast += SpellCheckCastFn(spell_ascension_ruleset_select::CheckCast);
        OnEffectHit += SpellEffectFn(spell_ascension_ruleset_select::Select, EFFECT_0, SPELL_EFFECT_DUMMY);
    }
};

class ruleset_aura_metadata : public GlobalScript
{
public:
    ruleset_aura_metadata() : GlobalScript("ruleset_aura_metadata", {GLOBALHOOK_ON_LOAD_SPELL_CUSTOM_ATTR}) { }

    void OnLoadSpellCustomAttr(SpellInfo* info) override
    {
        if (info->Id == SPELL_HIGH_RISK || info->Id == SPELL_WAR_MODE || info->Id == SPELL_PVE)
            info->AttributesEx3 |= SPELL_ATTR3_ALLOW_AURA_WHILE_DEAD;
    }
};

class ruleset_level_scaling_configuration : public WorldScript
{
public:
    ruleset_level_scaling_configuration()
        : WorldScript("ruleset_level_scaling_configuration", {WORLDHOOK_ON_AFTER_CONFIG_LOAD}) { }

    void OnAfterConfigLoad(bool) override
    {
        pvpRulesetsDisableLevelScaling.store(
            sConfigMgr->GetOption<bool>("CoA.Ruleset.DisableLevelScaling", false), std::memory_order_relaxed);
    }
};

class ruleset_player_spells : public PlayerScript
{
public:
    ruleset_player_spells()
        : PlayerScript("ruleset_player_spells", {PLAYERHOOK_ON_LOGIN, PLAYERHOOK_ON_MAP_CHANGED}) { }

    void OnPlayerMapChanged(Player* player) override
    {
        SyncRulesetPvP(player);
        if (pvpRulesetsDisableLevelScaling.load(std::memory_order_relaxed) && InPvPRuleset(player))
            player->RefreshQuestLogQueries();
    }

    void OnPlayerLogin(Player* player) override
    {
        for (uint32 id : {SPELL_SELECT_WAR_MODE, SPELL_SELECT_HIGH_RISK, SPELL_SELECT_PVE})
            if (!player->HasSpell(id))
                player->learnSpell(id, false);

        if (player->HasAura(SPELL_PVE))
            player->RemoveAurasDueToSpell(SPELL_WAR_MODE);

        if (!sConfigMgr->GetOption<bool>("CoA.RulesetLoginDefault", true))
            return;

        if (!player->IsInWorld())
            return;

        bool const noRuleset = !player->HasAura(SPELL_HIGH_RISK) && !player->HasAura(SPELL_WAR_MODE) &&
            !player->HasAura(SPELL_PVE);
        if (noRuleset)
            ApplyRuleset(player, SPELL_SELECT_PVE);
        else
            SyncRulesetPvP(player);
    }
};
}

void AscensionRulesets::RegisterGuard(Guard guard)
{
    if (guard)
        rulesetGuards.push_back(guard);
}

bool AscensionRulesets::CanApply(Player* player, Ruleset ruleset)
{
    if (!player)
        return false;
    for (Guard guard : rulesetGuards)
        if (!guard(player, ruleset))
            return false;
    return true;
}

void AscensionRulesets::Apply(Player* player, Ruleset ruleset)
{
    ApplyRuleset(player, SelectionSpell(ruleset));
}

bool AscensionRulesets::Has(Player* player, Ruleset ruleset)
{
    return player->HasAura(RulesetAura(ruleset));
}

void AddSC_AscensionRulesets()
{
    LocalLevelScaling::RulesetBlocksOwner.store(&RulesetBlocksLevelScaling, std::memory_order_relaxed);
    RegisterSpellScript(spell_ascension_ruleset_select);
    new ruleset_aura_metadata();
    new ruleset_level_scaling_configuration();
    new ruleset_player_spells();
}
