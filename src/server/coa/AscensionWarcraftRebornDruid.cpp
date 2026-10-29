/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "AscensionWarcraftRebornDruid.h"
#include "GameTime.h"
#include "Player.h"
#include "ScriptMgr.h"
#include "SpellAuraEffects.h"
#include "SpellInfo.h"
#include "SpellMgr.h"
#include "SpellScript.h"
#include <algorithm>
#include <array>
#include <utility>

namespace AscensionWarcraftReborn
{
namespace
{
constexpr uint32 ECLIPSE_SOLAR = 1148517;
constexpr uint32 ECLIPSE_LUNAR = 1148518;
constexpr Milliseconds ECLIPSE_COOLDOWN = 30s;
constexpr uint32 STARFIRE_FLAG = 0x4;
constexpr uint32 WRATH_FLAG = 0x1;
constexpr uint32 PRIMAL_FURY_RAGE = 1116959;
constexpr uint32 PRIMAL_FURY_COMBO_POINT = 1116953;
constexpr std::array<uint32, 3> COMBO_POINT_ABILITIES = { 0x39000, 0x400, 0x40000 };
constexpr std::array<std::pair<uint32, uint32>, 7> TRANQUILITY_TICKS = { {
    { 1100740, 1144203 }, { 1108918, 1144205 }, { 1109862, 1144206 }, { 1109863, 1144207 },
    { 1126983, 1144208 }, { 1148446, 1148444 }, { 1148447, 1148445 } } };
constexpr std::array<uint32, 5> GIFT_OF_NATURE = { 1117104, 1124943, 1124944, 1124945, 1124946 };
constexpr std::array<uint32, 3> NATURAL_SHAPESHIFTER = { 1116833, 1116834, 1116835 };
constexpr std::array<uint32, 3> BRAMBLES = { 1116836, 1116839, 1116840 };
constexpr uint32 MOONFURY_RANK_1 = 1116896;
constexpr uint32 NATURES_REACH_RANK_2 = 1116820;
constexpr uint32 DRUID_SWIFTMEND = 0x2;
constexpr uint32 DRUID_AQUATIC_FORM = 0x20000000;
constexpr uint32 DRUID_STARSURGE = 0x80000;
constexpr std::array<uint32, 7> RAKE = { 1101822, 1101823, 1101824, 1109904, 1127003, 1148573, 1148574 };
constexpr std::array<uint32, 3> FERAL_INSTINCT = { 1116947, 1116948, 1116949 };

constexpr uint32 FERAL_SWIFTNESS_RANK_1 = 1117002;
constexpr uint32 FERAL_SWIFTNESS_RANK_2 = 1124866;
constexpr uint32 FERAL_SWIFTNESS_ENCHANT = 1324866;
constexpr std::array<uint32, 2> FERAL_SWIFTNESS_SPEED = { 1117001, 1124865 };
constexpr std::array<uint32, 2> FERAL_SWIFTNESS_DODGE = { 1124867, 1124864 };

template <std::size_t N>
bool Contains(std::array<uint32, N> const& ids, uint32 id)
{
    return std::find(ids.begin(), ids.end(), id) != ids.end();
}

class spell_ascension_reborn_primal_fury : public AuraScript
{
    PrepareAuraScript(spell_ascension_reborn_primal_fury);

    bool Validate(SpellInfo const*) override
    {
        return ValidateSpellInfo({ PRIMAL_FURY_RAGE, PRIMAL_FURY_COMBO_POINT });
    }

    static bool AwardsComboPoint(SpellInfo const* spellInfo)
    {
        if (!spellInfo || spellInfo->SpellFamilyName != SPELLFAMILY_DRUID)
            return false;
        for (uint8 part = 0; part < 3; ++part)
            if (spellInfo->SpellFamilyFlags[part] & COMBO_POINT_ABILITIES[part])
                return true;
        return false;
    }

    bool CheckProc(ProcEventInfo& eventInfo)
    {
        if (!(eventInfo.GetHitMask() & PROC_HIT_CRITICAL) || !eventInfo.GetActionTarget())
            return false;
        ShapeshiftForm const form = GetTarget()->GetShapeshiftForm();
        if (form == FORM_BEAR || form == FORM_DIREBEAR)
            return true;
        return form == FORM_CAT && AwardsComboPoint(eventInfo.GetSpellInfo());
    }

    void HandleProc(AuraEffect const* aurEff, ProcEventInfo& eventInfo)
    {
        PreventDefaultAction();
        if (GetTarget()->GetShapeshiftForm() == FORM_CAT)
            GetTarget()->CastSpell(eventInfo.GetActionTarget(), PRIMAL_FURY_COMBO_POINT, true, nullptr, aurEff);
        else
            GetTarget()->CastSpell(GetTarget(), PRIMAL_FURY_RAGE, true, nullptr, aurEff);
    }

    void Register() override
    {
        DoCheckProc += AuraCheckProcFn(spell_ascension_reborn_primal_fury::CheckProc);
        OnEffectProc += AuraEffectProcFn(spell_ascension_reborn_primal_fury::HandleProc, EFFECT_0, SPELL_AURA_PROC_TRIGGER_SPELL);
    }
};

class spell_ascension_reborn_feral_swiftness : public AuraScript
{
    PrepareAuraScript(spell_ascension_reborn_feral_swiftness);

    bool Validate(SpellInfo const*) override
    {
        return ValidateSpellInfo({ FERAL_SWIFTNESS_SPEED[0], FERAL_SWIFTNESS_SPEED[1], FERAL_SWIFTNESS_DODGE[0],
            FERAL_SWIFTNESS_DODGE[1] });
    }

    void AfterApply(AuraEffect const* aurEff, AuraEffectHandleModes)
    {
        Player* player = GetTarget()->ToPlayer();
        if (!player)
            return;
        uint8 const rank = player->HasSpell(FERAL_SWIFTNESS_RANK_2) || player->HasAura(FERAL_SWIFTNESS_ENCHANT) ? 2 :
            player->HasSpell(FERAL_SWIFTNESS_RANK_1) ? 1 : 0;
        if (!rank)
            return;
        if (player->GetShapeshiftForm() == FORM_CAT)
            player->CastSpell(player, FERAL_SWIFTNESS_SPEED[rank - 1], true, nullptr, aurEff);
        player->CastSpell(player, FERAL_SWIFTNESS_DODGE[rank - 1], true, nullptr, aurEff);
    }

    void AfterRemove(AuraEffect const*, AuraEffectHandleModes)
    {
        for (uint32 spellId : FERAL_SWIFTNESS_SPEED)
            GetTarget()->RemoveAurasDueToSpell(spellId);
        for (uint32 spellId : FERAL_SWIFTNESS_DODGE)
            GetTarget()->RemoveAurasDueToSpell(spellId);
    }

    void Register() override
    {
        AfterEffectApply += AuraEffectApplyFn(spell_ascension_reborn_feral_swiftness::AfterApply, EFFECT_0, SPELL_AURA_MOD_SHAPESHIFT, AURA_EFFECT_HANDLE_REAL);
        AfterEffectRemove += AuraEffectRemoveFn(spell_ascension_reborn_feral_swiftness::AfterRemove, EFFECT_0, SPELL_AURA_MOD_SHAPESHIFT, AURA_EFFECT_HANDLE_REAL);
    }
};

class spell_ascension_reborn_eclipse : public AuraScript
{
    PrepareAuraScript(spell_ascension_reborn_eclipse);

    bool Validate(SpellInfo const*) override
    {
        return ValidateSpellInfo({ ECLIPSE_SOLAR, ECLIPSE_LUNAR });
    }

    bool InEclipse() const
    {
        return GetTarget()->HasAura(ECLIPSE_SOLAR) || GetTarget()->HasAura(ECLIPSE_LUNAR);
    }

    bool Ready(ProcEventInfo& eventInfo, uint32 spellFlag, Milliseconds readyAt) const
    {
        SpellInfo const* procSpell = eventInfo.GetSpellInfo();
        return procSpell && procSpell->SpellFamilyName == SPELLFAMILY_DRUID && (procSpell->SpellFamilyFlags[0] & spellFlag) &&
            GameTime::GetGameTimeMS() >= readyAt && !InEclipse();
    }

    bool CheckSolar(AuraEffect const*, ProcEventInfo& eventInfo)
    {
        return Ready(eventInfo, STARFIRE_FLAG, _solarReady);
    }

    bool CheckLunar(AuraEffect const*, ProcEventInfo& eventInfo)
    {
        return Ready(eventInfo, WRATH_FLAG, _lunarReady);
    }

    void Enter(AuraEffect const* aurEff, uint32 spellId, Milliseconds& readyAt)
    {
        PreventDefaultAction();
        readyAt = GameTime::GetGameTimeMS() + ECLIPSE_COOLDOWN;
        GetTarget()->CastSpell(GetTarget(), spellId, true, nullptr, aurEff);
    }

    void Solar(AuraEffect const* aurEff, ProcEventInfo&)
    {
        Enter(aurEff, ECLIPSE_SOLAR, _solarReady);
    }

    void Lunar(AuraEffect const* aurEff, ProcEventInfo&)
    {
        Enter(aurEff, ECLIPSE_LUNAR, _lunarReady);
    }

    void Register() override
    {
        DoCheckEffectProc += AuraCheckEffectProcFn(spell_ascension_reborn_eclipse::CheckSolar, EFFECT_0, SPELL_AURA_DUMMY);
        DoCheckEffectProc += AuraCheckEffectProcFn(spell_ascension_reborn_eclipse::CheckLunar, EFFECT_1, SPELL_AURA_DUMMY);
        OnEffectProc += AuraEffectProcFn(spell_ascension_reborn_eclipse::Solar, EFFECT_0, SPELL_AURA_DUMMY);
        OnEffectProc += AuraEffectProcFn(spell_ascension_reborn_eclipse::Lunar, EFFECT_1, SPELL_AURA_DUMMY);
    }

    Milliseconds _solarReady = 0ms;
    Milliseconds _lunarReady = 0ms;
};
}
}

void ApplyAscensionWarcraftRebornDruidContracts(SpellInfo* spellInfo)
{
    using namespace AscensionWarcraftReborn;
    if (!spellInfo)
        return;

    for (auto const& [parentId, tickId] : TRANQUILITY_TICKS)
    {
        if (spellInfo->Id != tickId)
            continue;
        SpellInfo const* parent = sSpellMgr->GetSpellInfo(parentId);
        if (parent && spellInfo->Effects[EFFECT_0].Effect == SPELL_EFFECT_HEAL)
        {
            spellInfo->Effects[EFFECT_0].BasePoints = parent->Effects[EFFECT_0].BasePoints;
            spellInfo->Effects[EFFECT_0].RealPointsPerLevel = parent->Effects[EFFECT_0].RealPointsPerLevel;
        }
    }

    if (Contains(GIFT_OF_NATURE, spellInfo->Id) && spellInfo->Effects[EFFECT_0].MiscValue == SPELLMOD_DAMAGE)
        spellInfo->Effects[EFFECT_0].SpellClassMask[1] |= DRUID_SWIFTMEND;

    if (Contains(NATURAL_SHAPESHIFTER, spellInfo->Id) && spellInfo->Effects[EFFECT_0].MiscValue == SPELLMOD_COST)
        spellInfo->Effects[EFFECT_0].SpellClassMask[0] |= DRUID_AQUATIC_FORM;

    if (Contains(BRAMBLES, spellInfo->Id) && spellInfo->Effects[EFFECT_0].MiscValue == SPELLMOD_DAMAGE &&
        spellInfo->Effects[EFFECT_1].MiscValue == SPELLMOD_DOT)
        spellInfo->Effects[EFFECT_1].BasePoints = spellInfo->Effects[EFFECT_0].BasePoints;

    if (spellInfo->Id == MOONFURY_RANK_1 && spellInfo->Effects[EFFECT_0].MiscValue == SPELLMOD_DAMAGE)
        spellInfo->Effects[EFFECT_0].SpellClassMask[2] |= DRUID_STARSURGE;

    if (spellInfo->Id == NATURES_REACH_RANK_2 && spellInfo->Effects[EFFECT_1].MiscValue == SPELLMOD_THREAT)
        spellInfo->Effects[EFFECT_1].SpellClassMask[2] |= DRUID_STARSURGE;

    if (Contains(RAKE, spellInfo->Id))
        spellInfo->AttributesCu |= SPELL_ATTR0_CU_IGNORE_ARMOR;

    if (Contains(FERAL_INSTINCT, spellInfo->Id) && spellInfo->Effects[EFFECT_1].ApplyAuraName == SPELL_AURA_ADD_PCT_MODIFIER &&
        spellInfo->Effects[EFFECT_1].MiscValue == SPELLMOD_DAMAGE && !spellInfo->Effects[EFFECT_2].Effect)
    {
        SpellEffectInfo& periodic = spellInfo->Effects[EFFECT_2];
        periodic = spellInfo->Effects[EFFECT_1];
        periodic.EffectIndex = EFFECT_2;
        periodic.MiscValue = SPELLMOD_DOT;
    }
}

void AddAscensionWarcraftRebornDruidScripts()
{
    using namespace AscensionWarcraftReborn;
    RegisterSpellScript(spell_ascension_reborn_eclipse);
    RegisterSpellScript(spell_ascension_reborn_primal_fury);
    RegisterSpellScript(spell_ascension_reborn_feral_swiftness);
}
