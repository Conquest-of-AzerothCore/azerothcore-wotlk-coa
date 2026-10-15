/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "Player.h"
#include "ScriptMgr.h"
#include "SpellAuras.h"
#include "SpellScript.h"

namespace
{
enum MercenarySpells : uint32
{
    SPELL_HIGH_RISK = 1004019,
    SPELL_WAR_MODE = 1004119,
    SPELL_PVE = 9931032,
    SPELL_MERCENARY = 9930874,
    SPELL_MERCENARY_CRIMINAL = 9930862,
    SPELL_FOR_THE_HORDE = 101100,
    SPELL_FOR_THE_ALLIANCE = 101101
};

constexpr uint8 MERCENARY_MIN_LEVEL = 20;
constexpr int32 MERCENARY_CRIMINAL_DURATION = 8 * MINUTE * IN_MILLISECONDS;

bool IsPvPRuleset(Unit const* unit)
{
    return unit->HasAura(SPELL_HIGH_RISK) || (unit->HasAura(SPELL_WAR_MODE) && !unit->HasAura(SPELL_PVE));
}

class spell_ascension_mercenary : public SpellScript
{
    PrepareSpellScript(spell_ascension_mercenary);

    bool Load() override { return GetCaster()->ToPlayer() != nullptr; }

    SpellCastResult CheckCast()
    {
        Player* player = GetCaster()->ToPlayer();
        if (!player || player->GetLevel() < MERCENARY_MIN_LEVEL)
            return SPELL_FAILED_LEVEL_REQUIREMENT;

        return IsPvPRuleset(player) ? SPELL_CAST_OK : SPELL_FAILED_NOT_HERE;
    }

    void Register() override { OnCheckCast += SpellCheckCastFn(spell_ascension_mercenary::CheckCast); }
};

class spell_ascension_mercenary_loyalty : public SpellScript
{
    PrepareSpellScript(spell_ascension_mercenary_loyalty);

    bool Load() override { return GetCaster()->ToPlayer() != nullptr; }

    SpellCastResult CheckCast()
    {
        Player* player = GetCaster()->ToPlayer();
        return player && player->HasPlayerFlag(PLAYER_FLAGS_RESTING) ? SPELL_CAST_OK : SPELL_FAILED_NOT_HERE;
    }

    void RemoveMercenary(SpellEffIndex)
    {
        GetCaster()->RemoveAurasDueToSpell(SPELL_MERCENARY);
    }

    void Register() override
    {
        OnCheckCast += SpellCheckCastFn(spell_ascension_mercenary_loyalty::CheckCast);
        OnEffectHitTarget += SpellEffectFn(spell_ascension_mercenary_loyalty::RemoveMercenary, EFFECT_0,
                                           SPELL_EFFECT_APPLY_AURA);
    }
};

class ascension_mercenary_reaction : public UnitScript
{
public:
    ascension_mercenary_reaction() : UnitScript("ascension_mercenary_reaction", true, {UNITHOOK_IF_NORMAL_REACTION}) { }

    bool IfNormalReaction(Unit const* unit, Unit const* target, ReputationRank& reaction) override
    {
        if (!unit || !target)
            return true;

        Player const* first = unit->GetCharmerOrOwnerPlayerOrPlayerItself();
        Player const* second = target->GetCharmerOrOwnerPlayerOrPlayerItself();
        if (!first || !second || first == second)
            return true;

        auto isTarget = [](Player const* player) { return player->HasAura(SPELL_MERCENARY) || IsPvPRuleset(player); };
        if ((first->HasAura(SPELL_MERCENARY) && isTarget(second)) ||
            (second->HasAura(SPELL_MERCENARY) && isTarget(first)))
        {
            reaction = REP_HOSTILE;
            return false;
        }
        return true;
    }
};

class ascension_mercenary_player : public PlayerScript
{
public:
    ascension_mercenary_player()
        : PlayerScript("ascension_mercenary_player", {PLAYERHOOK_ON_LOGIN, PLAYERHOOK_ON_LEVEL_CHANGED,
                                                      PLAYERHOOK_ON_PVP_KILL})
    {
    }

    void OnPlayerLogin(Player* player) override { LearnSpells(player); }

    void OnPlayerLevelChanged(Player* player, uint8) override { LearnSpells(player); }

    void OnPlayerPVPKill(Player* killer, Player* killed) override
    {
        if (!killer || !killed || !killer->HasAura(SPELL_MERCENARY) || killer->GetTeamId() != killed->GetTeamId())
            return;

        killer->CastSpell(killer, SPELL_MERCENARY_CRIMINAL, true);
        if (Aura* aura = killer->GetAura(SPELL_MERCENARY_CRIMINAL))
        {
            aura->SetMaxDuration(MERCENARY_CRIMINAL_DURATION);
            aura->SetDuration(MERCENARY_CRIMINAL_DURATION);
        }
    }

private:
    static void LearnSpells(Player* player)
    {
        if (!player || player->GetLevel() < MERCENARY_MIN_LEVEL)
            return;

        uint32 const loyalty = player->GetTeamId() == TEAM_ALLIANCE ? SPELL_FOR_THE_ALLIANCE : SPELL_FOR_THE_HORDE;
        for (uint32 id : {uint32(SPELL_MERCENARY), loyalty})
            if (!player->HasSpell(id))
                player->learnSpell(id, false);
    }
};
}

void AddSC_AscensionMercenary()
{
    RegisterSpellScript(spell_ascension_mercenary);
    RegisterSpellScript(spell_ascension_mercenary_loyalty);
    new ascension_mercenary_reaction();
    new ascension_mercenary_player();
}
