/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */
#include "AscensionRunemasterTalents.h"
#include "Log.h"
#include "ObjectAccessor.h"
#include "Player.h"
#include "ScriptMgr.h"
#include "SpellAuras.h"
#include "SpellInfo.h"

namespace
{
bool IsEarthTattoo(uint32 id)
{
    return id == 801094 || (id >= 803754 && id <= 803758);
}

bool StonePetroglyphActive(Player* player)
{
    if (!player->IsAlive() || !player->HasAura(707157))
        return false;
    if (player->HasAura(801094, player->GetGUID()))
        return true;
    for (uint32 id = 803754; id <= 803758; ++id)
        if (player->HasAura(id, player->GetGUID()))
            return true;
    return false;
}

void SyncStonePetroglyph(Player* player)
{
    if (!StonePetroglyphActive(player))
        player->RemoveAurasDueToSpell(712310, player->GetGUID());
    else if (!player->HasAura(712310, player->GetGUID()))
        player->CastSpell(player, 712310, true);
}

constexpr uint32 SPELL_RUNIC_BREAKOUT = 705583;
constexpr uint32 SPELL_RUNIC_BREAKOUT_WINDOW = 520767;
constexpr uint32 SPELL_WAVEFORGED_WINDOW = 500469;

void OpenRunicBreakoutWindow(Player* player, Aura const* runeshroud, AuraRemoveMode mode)
{
    if (runeshroud->GetCasterGUID() != player->GetGUID() || mode == AURA_REMOVE_BY_DEATH || !player->IsAlive() ||
        !player->IsInWorld() || !player->HasAura(SPELL_RUNIC_BREAKOUT))
        return;
    player->CastSpell(player, SPELL_RUNIC_BREAKOUT_WINDOW, true);
}

void SyncRuneshroudOrWaveforged(Player* player)
{
    bool active = player->HasAura(500288, player->GetGUID()) ||
        player->HasAura(SPELL_WAVEFORGED_WINDOW, player->GetGUID()) ||
        player->HasAura(SPELL_RUNIC_BREAKOUT_WINDOW, player->GetGUID());
    if (!active)
        player->RemoveAurasDueToSpell(808089, player->GetGUID());
    else if (!player->HasAura(808089, player->GetGUID()))
        player->CastSpell(player, 808089, true);
}

constexpr uint32 SPELL_PERMAFROST_RUNE = 804060;
constexpr uint32 SPELL_PERMAFROST_MARKER = 807114;
constexpr uint32 SPELL_RUNESHROUD = 500288;
constexpr int32 PERMAFROST_PLAYER_DURATION = 8000;

void ApplyPermafrostAura(Unit* unit, Aura* aura)
{
    uint32 id = aura->GetId();
    if (id != SPELL_PERMAFROST_RUNE && id != SPELL_PERMAFROST_MARKER)
        return;
    if (unit->IsPlayer() && aura->GetMaxDuration() > PERMAFROST_PLAYER_DURATION)
    {
        aura->SetMaxDuration(PERMAFROST_PLAYER_DURATION);
        aura->SetDuration(PERMAFROST_PLAYER_DURATION);
    }
    if (id != SPELL_PERMAFROST_RUNE)
        return;
    Player* caster = ObjectAccessor::FindPlayer(aura->GetCasterGUID());
    if (!caster || caster->getClass() != CLASS_SPIRIT_MAGE || !caster->HasAura(SPELL_RUNESHROUD, caster->GetGUID()))
        return;
    uint32 remaining = caster->GetSpellCooldownDelay(SPELL_PERMAFROST_RUNE);
    if (remaining)
        caster->ModifySpellCooldown(SPELL_PERMAFROST_RUNE, -int32(remaining * 4 / 5));
}

constexpr uint32 SPELL_RUNIC_TEMPEST = 560036;
constexpr uint32 SPELL_RUNESHROUD_OR_WAVEFORGED = 808089;

void KeepRunicTempestMarker(Player* player)
{
    if (player->IsAlive() && player->IsInWorld() && player->HasAura(SPELL_RUNIC_TEMPEST, player->GetGUID()) &&
        !player->HasAura(SPELL_RUNESHROUD_OR_WAVEFORGED, player->GetGUID()))
        player->CastSpell(player, SPELL_RUNESHROUD_OR_WAVEFORGED, true);
}

class runemaster_runic_tempest_events : public UnitScript
{
public:
    runemaster_runic_tempest_events() : UnitScript("runemaster_runic_tempest_events", true,
        {UNITHOOK_ON_AURA_APPLY, UNITHOOK_ON_AURA_REMOVE}) { }

    void OnAuraApply(Unit* unit, Aura* aura) override
    {
        Player* player = unit ? unit->ToPlayer() : nullptr;
        if (player && aura && player->getClass() == CLASS_SPIRIT_MAGE && aura->GetId() == SPELL_RUNIC_TEMPEST)
            KeepRunicTempestMarker(player);
    }

    void OnAuraRemove(Unit* unit, AuraApplication* application, AuraRemoveMode) override
    {
        Player* player = unit ? unit->ToPlayer() : nullptr;
        if (!player || !application || player->getClass() != CLASS_SPIRIT_MAGE)
            return;
        uint32 id = application->GetBase()->GetId();
        if (id == SPELL_RUNIC_TEMPEST && player->IsInWorld())
            SyncRuneshroudOrWaveforged(player);
        else if (id != SPELL_RUNIC_TEMPEST && id != SPELL_RUNESHROUD_OR_WAVEFORGED)
            KeepRunicTempestMarker(player);
    }
};

class runemaster_talent_events : public UnitScript
{
public:
    runemaster_talent_events() : UnitScript("runemaster_talent_events", true,
        {UNITHOOK_ON_AURA_APPLY, UNITHOOK_ON_AURA_REMOVE}) { }

    void OnAuraApply(Unit* unit, Aura* aura) override
    {
        if (unit && aura)
            ApplyPermafrostAura(unit, aura);
        Player* player = unit ? unit->ToPlayer() : nullptr;
        if (!player || player->getClass() != CLASS_SPIRIT_MAGE || !aura)
            return;
        uint32 id = aura->GetId();
        if (id == 707157 || id == 712310 || IsEarthTattoo(id))
            SyncStonePetroglyph(player);
        if (id == 500288 || id == SPELL_WAVEFORGED_WINDOW || id == SPELL_RUNIC_BREAKOUT_WINDOW)
            SyncRuneshroudOrWaveforged(player);
    }

    void OnAuraRemove(Unit* unit, AuraApplication* application, AuraRemoveMode mode) override
    {
        if (unit && application && application->GetBase()->GetId() == SPELL_PERMAFROST_RUNE)
            unit->RemoveAurasDueToSpell(SPELL_PERMAFROST_MARKER, application->GetBase()->GetCasterGUID());
        Player* player = unit ? unit->ToPlayer() : nullptr;
        if (!player || player->getClass() != CLASS_SPIRIT_MAGE || !application)
            return;
        Aura* aura = application->GetBase();
        uint32 id = aura->GetId();
        if (id == 707157 || IsEarthTattoo(id))
            SyncStonePetroglyph(player);
        if (id == 500288 && aura->GetCasterGUID() == player->GetGUID() && mode != AURA_REMOVE_BY_DEATH &&
            player->IsAlive() && player->IsInWorld() && player->HasAura(520054))
            player->CastSpell(player, 520768, true);
        if (id == SPELL_RUNESHROUD)
            OpenRunicBreakoutWindow(player, aura, mode);
        if (id == 500288 || id == SPELL_WAVEFORGED_WINDOW || id == SPELL_RUNIC_BREAKOUT_WINDOW)
            SyncRuneshroudOrWaveforged(player);
    }
};

class runemaster_marker_login : public PlayerScript
{
public:
    runemaster_marker_login() : PlayerScript("runemaster_marker_login", {PLAYERHOOK_ON_LOGIN}) { }

    void OnPlayerLogin(Player* player) override
    {
        if (player->getClass() != CLASS_SPIRIT_MAGE)
            return;
        SyncRuneshroudOrWaveforged(player);
        KeepRunicTempestMarker(player);
    }
};

constexpr uint32 SPELL_ADVANCED_MAGI = 804557;
constexpr int32 ASCENSION_SPELLMOD_BONUS_MULTIPLIER = 41;

void ApplyAdvancedMagiScaling(SpellInfo* info)
{
    flag96 const elementalBurstFamilyFlags(0, 0, 131072);
    SpellEffectInfo& scaling = info->Effects[EFFECT_1];
    if (scaling.IsAura(SPELL_AURA_ADD_PCT_MODIFIER) && scaling.MiscValue == ASCENSION_SPELLMOD_BONUS_MULTIPLIER &&
        scaling.SpellClassMask == elementalBurstFamilyFlags)
        scaling.MiscValue = SPELLMOD_BONUS_MULTIPLIER;
}

constexpr uint32 SPELL_ALTERATION_RANK_1 = 705619;

void ApplyAlterationWaterTattooScope(SpellInfo* info)
{
    flag96 const rankOneTattooFamilyFlags(4, 0, 16418);
    flag96 const waterTattooFamilyFlags(2097152, 0, 0);
    SpellEffectInfo& effectiveness = info->Effects[EFFECT_0];
    if (effectiveness.IsAura(SPELL_AURA_ADD_PCT_MODIFIER) && effectiveness.MiscValue == SPELLMOD_ALL_EFFECTS &&
        effectiveness.SpellClassMask == rankOneTattooFamilyFlags)
        effectiveness.SpellClassMask |= waterTattooFamilyFlags;
}

void ExposeRuneshroudOrWaveforgedMarker(SpellInfo* info)
{
    if (info->Id != SPELL_RUNESHROUD_OR_WAVEFORGED)
        return;
    if (!info->Effects[EFFECT_0].IsAura(SPELL_AURA_DUMMY))
    {
        LOG_ERROR("coa", "Skipped unexpected Runeshroud or Waveforged marker record {}", info->Id);
        return;
    }

    info->Attributes &= ~SPELL_ATTR0_PASSIVE;
}
}

void ApplyAscensionRunemasterTalentContracts(SpellInfo* info)
{
    if (info->Id == SPELL_ADVANCED_MAGI && info->SpellFamilyName == 38)
    {
        ApplyAdvancedMagiScaling(info);
        return;
    }
    if (info->Id == SPELL_ALTERATION_RANK_1 && info->SpellFamilyName == 38)
    {
        ApplyAlterationWaterTattooScope(info);
        return;
    }
    if (info->Id == SPELL_PERMAFROST_RUNE)
    {
        info->AuraInterruptFlags |= AURA_INTERRUPT_FLAG_TAKE_DAMAGE;
        return;
    }
    ExposeRuneshroudOrWaveforgedMarker(info);
    if (info->Id != 712310 || info->SpellFamilyName != 38)
        return;
    auto& effect = info->Effects[EFFECT_1];
    effect.Effect = SPELL_EFFECT_APPLY_AURA;
    effect.ApplyAuraName = SPELL_AURA_EFFECT_IMMUNITY;
    effect.MiscValue = SPELL_EFFECT_KNOCK_BACK_DEST;
    effect.BasePoints = 0;
    effect.DieSides = 0;
}

void AddSC_AscensionRunemasterTalents()
{
    new runemaster_talent_events();
    new runemaster_runic_tempest_events();
    new runemaster_marker_login();
}
