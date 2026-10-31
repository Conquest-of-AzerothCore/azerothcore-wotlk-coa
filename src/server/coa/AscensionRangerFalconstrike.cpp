/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */
#include "Player.h"
#include "ScriptMgr.h"
#include "Spell.h"
#include "SpellAuras.h"
#include "SpellMgr.h"
#include "SpellScript.h"
#include "TemporarySummon.h"
#include <array>

namespace
{
enum FalconstrikeSpells : uint32
{
    SPELL_FALCONSTRIKE_TALENT = 573060,
    SPELL_FALCONSTRIKE_COUNTER = 573248,
    SPELL_FALCONSTRIKE_READY = 573338,
    SPELL_FALCONSTRIKE_SUMMON = 520588
};

constexpr std::array<uint32, 7> QuickShots = {500074, 572727, 572728, 572729, 572730, 572731, 572732};
constexpr std::array<uint32, 8> Falconstrikes = {806345, 806437, 806438, 806439, 806440, 806441, 806442, 806443};

bool FalconstrikeReady(Player* player)
{
    return player && player->getClass() == CLASS_RANGER && player->IsAlive() && player->IsInWorld() &&
        player->HasAura(SPELL_FALCONSTRIKE_TALENT) &&
        player->HasAura(SPELL_FALCONSTRIKE_READY, player->GetGUID());
}

void SyncFalconstrike(Player* player)
{
    if (player->getClass() != CLASS_RANGER)
        return;
    if (!player->HasAura(SPELL_FALCONSTRIKE_TALENT))
    {
        for (uint32 rank : Falconstrikes)
            if (player->GetSpellMap().find(rank) != player->GetSpellMap().end())
                player->removeSpell(rank, SPEC_MASK_ALL, true);
        player->RemoveAurasDueToSpell(SPELL_FALCONSTRIKE_COUNTER, player->GetGUID());
        player->RemoveAurasDueToSpell(SPELL_FALCONSTRIKE_READY, player->GetGUID());
        for (uint32 quick : QuickShots)
            player->SetTemporarySpellReplacement(quick, 0);
        return;
    }
    uint32 replacement = Falconstrikes.front();
    for (uint32 rank : Falconstrikes)
        if (SpellInfo const* info = sSpellMgr->GetSpellInfo(rank); info && info->SpellLevel <= player->GetLevel())
            replacement = rank;
    bool ready = FalconstrikeReady(player);
    if (ready && player->GetSpellMap().find(replacement) == player->GetSpellMap().end())
        player->learnSpell(replacement, true);
    for (uint32 rank : Falconstrikes)
        if (rank != replacement && player->GetSpellMap().find(rank) != player->GetSpellMap().end())
            player->removeSpell(rank, SPEC_MASK_ALL, true);
    for (uint32 quick : QuickShots)
    {
        if (ready && player->HasActiveSpell(quick) && player->HasActiveSpell(replacement))
            player->SetTemporarySpellReplacement(quick, replacement);
        else
            player->SetTemporarySpellReplacement(quick, 0);
    }
}

class ranger_falconstrike_casts : public AllSpellScript
{
public:
    ranger_falconstrike_casts() : AllSpellScript("ranger_falconstrike_casts", {ALLSPELLHOOK_ON_CAST}) { }

    void OnSpellCast(Spell* spell, Unit* caster, SpellInfo const* info, bool) override
    {
        Player* player = caster ? caster->ToPlayer() : nullptr;
        if (!player || player->getClass() != CLASS_RANGER || info->SpellFamilyName != 27 || spell->IsTriggered() ||
            !player->IsAlive() || !player->IsInWorld() || !player->HasAura(SPELL_FALCONSTRIKE_TALENT))
            return;
        if (info->SpellFamilyFlags[1] & 4194304)
        {
            player->RemoveAurasDueToSpell(SPELL_FALCONSTRIKE_READY, player->GetGUID());
            player->RemoveAurasDueToSpell(SPELL_FALCONSTRIKE_COUNTER, player->GetGUID());
        }
        else if (info->SpellFamilyFlags[2] & 1)
        {
            player->CastSpell(player, SPELL_FALCONSTRIKE_READY, true);
            player->RemoveAurasDueToSpell(SPELL_FALCONSTRIKE_COUNTER, player->GetGUID());
        }
        else if ((info->SpellFamilyFlags[1] & 1) && !FalconstrikeReady(player))
        {
            player->CastSpell(player, SPELL_FALCONSTRIKE_COUNTER, true);
            Aura const* counter = player->GetAura(SPELL_FALCONSTRIKE_COUNTER, player->GetGUID());
            if (counter && uint32(counter->GetStackAmount()) + 1 >= counter->GetSpellInfo()->CalcMaxAuraStacks(player))
            {
                int32 remaining = counter->GetDuration();
                player->CastSpell(player, SPELL_FALCONSTRIKE_READY, true);
                if (Aura* aura = player->GetAura(SPELL_FALCONSTRIKE_READY, player->GetGUID()))
                    aura->SetDuration(remaining);
                player->RemoveAurasDueToSpell(SPELL_FALCONSTRIKE_COUNTER, player->GetGUID());
            }
        }
        SyncFalconstrike(player);
    }
};

class spell_ascension_ranger_falconstrike : public SpellScript
{
    PrepareSpellScript(spell_ascension_ranger_falconstrike);

    SpellCastResult CheckReady()
    {
        return FalconstrikeReady(GetCaster()->ToPlayer()) ? SPELL_CAST_OK : SPELL_FAILED_CANT_DO_THAT_RIGHT_NOW;
    }

    void Register() override
    {
        OnCheckCast += SpellCheckCastFn(spell_ascension_ranger_falconstrike::CheckReady);
    }
};

class ranger_falconstrike_lifecycle : public PlayerScript
{
public:
    ranger_falconstrike_lifecycle() : PlayerScript("ranger_falconstrike_lifecycle",
        {PLAYERHOOK_ON_LOGIN, PLAYERHOOK_ON_UPDATE}) { }

    void OnPlayerLogin(Player* player) override { SyncFalconstrike(player); }
    void OnPlayerUpdate(Player* player, uint32) override { SyncFalconstrike(player); }
};

class ranger_falconstrike_summon : public AllSpellScript
{
public:
    ranger_falconstrike_summon() : AllSpellScript("ranger_falconstrike_summon", {ALLSPELLHOOK_ON_GUARDIAN_SUMMONED}) { }

    void OnGuardianSummoned(Spell* spell, TempSummon* summon) override
    {
        if (spell->GetSpellInfo()->Id == SPELL_FALCONSTRIKE_SUMMON && summon)
            summon->SetReactState(REACT_DEFENSIVE);
    }
};
}

void AddSC_AscensionRangerFalconstrike()
{
    new ranger_falconstrike_casts();
    new ranger_falconstrike_lifecycle();
    new ranger_falconstrike_summon();
    RegisterSpellScript(spell_ascension_ranger_falconstrike);
}
