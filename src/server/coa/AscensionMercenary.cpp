/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "DBCStores.h"
#include "Map.h"
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
constexpr uint32 MERCENARY_FACTION_TEMPLATE = 1163;
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

void SetMercenaryFaction(Player* player, uint32 factionTemplate)
{
    player->SetFaction(factionTemplate);
    for (Unit* controlled : player->m_Controlled)
        if (controlled->GetOwnerGUID() == player->GetGUID())
            controlled->SetFaction(factionTemplate);
}

uint32 RaceFaction(Player const* player)
{
    ChrRacesEntry const* race = sChrRacesStore.LookupEntry(player->getRace(true));
    return race ? race->FactionID : 0;
}

ReputationRank RaceReactionTo(Player const* player, Unit const* target)
{
    FactionTemplateEntry const* own = sFactionTemplateStore.LookupEntry(RaceFaction(player));
    FactionTemplateEntry const* other = target->GetFactionTemplateEntry();
    if (!own || !other)
        return REP_NEUTRAL;
    if (FactionEntry const* faction = sFactionStore.LookupEntry(other->faction))
        if (faction->CanHaveReputation())
            return player->GetReputationRank(faction->ID);
    if (own->IsFriendlyTo(*other))
        return REP_FRIENDLY;
    if (own->IsHostileTo(*other))
        return REP_HOSTILE;
    return REP_NEUTRAL;
}

bool InMercenaryWar(Player const* player)
{
    return player->HasAura(SPELL_MERCENARY) || IsPvPRuleset(player);
}

bool ShowsFreeForAllTo(Player const* player, Player const* viewer)
{
    if (!player || !viewer || player->HasAura(SPELL_MERCENARY) || !IsPvPRuleset(player) ||
        player->pvpInfo.IsInNoPvPArea || player->IsGameMaster())
        return false;
    return viewer == player || viewer->HasAura(SPELL_MERCENARY);
}

void RefreshRulesetPlayersFor(Player* mercenary)
{
    if (Map* map = mercenary->FindMap())
        map->DoForAllPlayers([mercenary](Player* player)
        {
            if (player != mercenary && IsPvPRuleset(player))
                player->ForceValuesUpdateAtIndex(UNIT_FIELD_BYTES_2);
        });
}

void SetMercenaryFreeForAll(Player* player)
{
    if (player->pvpInfo.IsInNoPvPArea || player->IsGameMaster() || player->IsFFAPvP())
        return;

    player->SetByteFlag(UNIT_FIELD_BYTES_2, 1, UNIT_BYTE2_FLAG_FFA_PVP);
    for (Unit* controlled : player->m_Controlled)
        if (controlled->GetOwnerGUID() == player->GetGUID())
            controlled->SetByteFlag(UNIT_FIELD_BYTES_2, 1, UNIT_BYTE2_FLAG_FFA_PVP);
}

class spell_ascension_mercenary_aura : public AuraScript
{
    PrepareAuraScript(spell_ascension_mercenary_aura);

    void HandleApply(AuraEffect const*, AuraEffectHandleModes)
    {
        if (Player* player = GetTarget()->ToPlayer())
        {
            SetMercenaryFaction(player, MERCENARY_FACTION_TEMPLATE);
            SetMercenaryFreeForAll(player);
            RefreshRulesetPlayersFor(player);
        }
    }

    void HandleRemove(AuraEffect const*, AuraEffectHandleModes)
    {
        if (Player* player = GetTarget()->ToPlayer())
        {
            player->SetFactionForRace(player->getRace(true));
            SetMercenaryFaction(player, player->GetFaction());
            player->UpdateFFAPvPState(true);
            RefreshRulesetPlayersFor(player);
        }
    }

    void Register() override
    {
        AfterEffectApply += AuraEffectApplyFn(spell_ascension_mercenary_aura::HandleApply, EFFECT_0,
                                              SPELL_AURA_PERIODIC_DUMMY, AURA_EFFECT_HANDLE_REAL);
        AfterEffectRemove += AuraEffectRemoveFn(spell_ascension_mercenary_aura::HandleRemove, EFFECT_0,
                                                SPELL_AURA_PERIODIC_DUMMY, AURA_EFFECT_HANDLE_REAL);
    }
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
        if (first && !second && first->HasAura(SPELL_MERCENARY))
        {
            reaction = RaceReactionTo(first, target);
            return false;
        }
        if (second && !first && second->HasAura(SPELL_MERCENARY))
        {
            reaction = RaceReactionTo(second, unit);
            return false;
        }
        if (!first || !second || first == second)
            return true;

        bool const firstMercenary = first->HasAura(SPELL_MERCENARY);
        bool const secondMercenary = second->HasAura(SPELL_MERCENARY);
        if (!firstMercenary && !secondMercenary)
            return true;

        if ((firstMercenary && InMercenaryWar(second)) || (secondMercenary && InMercenaryWar(first)))
            reaction = REP_HOSTILE;
        else
            reaction = firstMercenary ? RaceReactionTo(first, target) : RaceReactionTo(second, unit);
        return false;
    }
};

class ascension_mercenary_view : public UnitScript
{
public:
    ascension_mercenary_view() : UnitScript("ascension_mercenary_view", true, {UNITHOOK_ON_PATCH_VALUES_UPDATE}) { }

    void OnPatchValuesUpdate(Unit const* unit, ByteBuffer& data, BuildValuesCachePosPointers& pos, Player* target) override
    {
        if (pos.UnitFieldFactionTemplatePos >= 0 && unit && target)
        {
            Player const* owner = unit->GetCharmerOrOwnerPlayerOrPlayerItself();
            if (owner && owner->HasAura(SPELL_MERCENARY) && (unit == target || !InMercenaryWar(target)))
                data.put(pos.UnitFieldFactionTemplatePos, RaceFaction(owner));
        }
        if (pos.UnitFieldBytes2Pos < 0 || !unit || !ShowsFreeForAllTo(unit->ToPlayer(), target))
            return;
        uint32 const bytes = data.read<uint32>(pos.UnitFieldBytes2Pos);
        data.put(pos.UnitFieldBytes2Pos, bytes | (uint32(UNIT_BYTE2_FLAG_FFA_PVP) << 8));
    }
};

class ascension_mercenary_player : public PlayerScript
{
public:
    ascension_mercenary_player()
        : PlayerScript("ascension_mercenary_player", {PLAYERHOOK_ON_LOGIN, PLAYERHOOK_ON_LEVEL_CHANGED,
                                                      PLAYERHOOK_ON_PVP_KILL, PLAYERHOOK_ON_FFA_PVP_STATE_UPDATE})
    {
    }

    void OnPlayerLogin(Player* player) override { LearnSpells(player); }

    void OnPlayerLevelChanged(Player* player, uint8) override { LearnSpells(player); }

    void OnPlayerFfaPvpStateUpdate(Player* player, bool result) override
    {
        if (!result && player && player->HasAura(SPELL_MERCENARY))
            SetMercenaryFreeForAll(player);
    }

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
    RegisterSpellAndAuraScriptPair(spell_ascension_mercenary, spell_ascension_mercenary_aura);
    RegisterSpellScript(spell_ascension_mercenary_loyalty);
    new ascension_mercenary_reaction();
    new ascension_mercenary_view();
    new ascension_mercenary_player();
}
