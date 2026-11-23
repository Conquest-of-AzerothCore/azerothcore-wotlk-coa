/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "AscensionDummyFixes.h"
#include "ObjectAccessor.h"
#include "Player.h"
#include "ScriptMgr.h"
#include "Spell.h"
#include "SpellAuraEffects.h"
#include "SpellAuras.h"
#include "SpellInfo.h"
#include "SpellMgr.h"
#include "SpellScript.h"
#include <algorithm>
#include <array>

namespace
{
constexpr uint32 WARRIOR_EXECUTE_FLAG = 0x20000000;
constexpr uint32 STOCK_GLYPH_OF_EXECUTION = 58367;
constexpr uint32 GLYPH_OF_EXECUTION = 118525;
constexpr uint32 WARRIOR_ICON_SUDDEN_DEATH = 1989;

bool IsFamilySpell(SpellInfo const* info, uint32 family, uint32 flag0, uint32 flag1 = 0, uint32 flag2 = 0)
{
    return info && info->SpellFamilyName == family &&
        ((info->SpellFamilyFlags[0] & flag0) || (info->SpellFamilyFlags[1] & flag1) || (info->SpellFamilyFlags[2] & flag2));
}

constexpr std::array<uint32, 2> WEAKENED_SOUL = { 6788, 1106788 };

enum SoulRestorationHeals : uint8
{
    SOUL_RESTORATION_FOUR_HEALS = 0,
    SOUL_RESTORATION_PRIEST_HEALS = 1,
};

struct SoulRestorationRule
{
    uint32 Aura;
    bool OwnOnly;
    bool Milliseconds;
    SoulRestorationHeals Heals;
};

constexpr std::array<SoulRestorationRule, 3> SOUL_RESTORATIONS = {{
    { 84381, true, false, SOUL_RESTORATION_FOUR_HEALS },
    { 282213, false, false, SOUL_RESTORATION_FOUR_HEALS },
    { 1181290, false, true, SOUL_RESTORATION_PRIEST_HEALS },
}};

SoulRestorationRule const* SoulRestorationByAura(uint32 id)
{
    for (SoulRestorationRule const& rule : SOUL_RESTORATIONS)
        if (rule.Aura == id)
            return &rule;
    return nullptr;
}

bool IsSoulRestorationHeal(SpellInfo const* info, SoulRestorationHeals heals)
{
    if (heals == SOUL_RESTORATION_PRIEST_HEALS)
        return IsFamilySpell(info, SPELLFAMILY_PRIEST, 0x00000800 | 0x00001000);
    return IsFamilySpell(info, SPELLFAMILY_PALADIN, 0x80000000) ||
        IsFamilySpell(info, SPELLFAMILY_PRIEST, 0x00001000) ||
        IsFamilySpell(info, SPELLFAMILY_SHAMAN, 0x00000040) ||
        IsFamilySpell(info, SPELLFAMILY_DRUID, 0x00000020);
}

class spell_dummyfix_warrior_soul_restoration : public AuraScript
{
    PrepareAuraScript(spell_dummyfix_warrior_soul_restoration);

    bool Validate(SpellInfo const* info) override
    {
        return SoulRestorationByAura(info->Id) != nullptr;
    }

    bool CheckProc(ProcEventInfo& eventInfo)
    {
        SoulRestorationRule const* rule = SoulRestorationByAura(GetId());
        HealInfo* heal = eventInfo.GetHealInfo();
        return rule && heal && eventInfo.GetProcTarget() && !(eventInfo.GetTypeMask() & PROC_FLAG_DONE_PERIODIC) &&
            IsSoulRestorationHeal(eventInfo.GetSpellInfo(), rule->Heals);
    }

    void HandleProc(AuraEffect const* aurEff, ProcEventInfo& eventInfo)
    {
        PreventDefaultAction();
        SoulRestorationRule const* rule = SoulRestorationByAura(GetId());
        Unit* healed = eventInfo.GetProcTarget();
        if (!rule || !healed)
            return;
        int32 const cut = rule->Milliseconds ? std::abs(aurEff->GetAmount()) : aurEff->GetAmount() * IN_MILLISECONDS;
        if (cut <= 0)
            return;
        ObjectGuid const casterGuid = rule->OwnOnly ? GetTarget()->GetGUID() : ObjectGuid::Empty;
        for (uint32 id : WEAKENED_SOUL)
        {
            Aura* soul = healed->GetAura(id, casterGuid);
            if (!soul)
                continue;
            int32 const duration = soul->GetDuration() - cut;
            if (duration <= 0)
                soul->Remove();
            else
                soul->SetDuration(duration);
        }
    }

    void Register() override
    {
        DoCheckProc += AuraCheckProcFn(spell_dummyfix_warrior_soul_restoration::CheckProc);
        OnEffectProc += AuraEffectProcFn(spell_dummyfix_warrior_soul_restoration::HandleProc, EFFECT_0, SPELL_AURA_DUMMY);
    }
};

struct ElementalExecute
{
    uint32 FirstRank;
    uint32 Damage;
};

constexpr std::array<ElementalExecute, 6> ELEMENTAL_EXECUTES = {{
    { 913060, 913474 },
    { 913070, 913475 },
    { 913080, 913476 },
    { 913090, 913477 },
    { 913100, 913478 },
    { 913110, 913479 },
}};
constexpr uint32 ELEMENTAL_EXECUTE_RANKS = 10;
constexpr float ELEMENTAL_EXECUTE_PCT = 0.65f;

ElementalExecute const* ElementalExecuteBySpell(uint32 id)
{
    for (ElementalExecute const& rule : ELEMENTAL_EXECUTES)
        if (id >= rule.FirstRank && id < rule.FirstRank + ELEMENTAL_EXECUTE_RANKS)
            return &rule;
    return nullptr;
}

int32 GlyphOfExecutionRage(Unit const* caster)
{
    if (AuraEffect const* glyph = caster->GetAuraEffectOfRankedSpellOrTwin(STOCK_GLYPH_OF_EXECUTION, EFFECT_0))
        return glyph->GetAmount() * 10;
    if (AuraEffect const* glyph = caster->GetAuraEffect(GLYPH_OF_EXECUTION, EFFECT_0))
        return glyph->GetAmount() * 10;
    return 0;
}

class spell_dummyfix_warrior_elemental_execute : public SpellScript
{
    PrepareSpellScript(spell_dummyfix_warrior_elemental_execute);

    bool Validate(SpellInfo const* info) override
    {
        ElementalExecute const* rule = ElementalExecuteBySpell(info->Id);
        return rule && ValidateSpellInfo({ rule->Damage });
    }

    void SendMiss(SpellMissInfo missInfo)
    {
        ElementalExecute const* rule = ElementalExecuteBySpell(GetSpellInfo()->Id);
        if (missInfo == SPELL_MISS_NONE || !rule)
            return;
        if (Unit* target = GetHitUnit())
            GetCaster()->SendSpellMiss(target, rule->Damage, missInfo);
    }

    void HandleEffect(SpellEffIndex effIndex)
    {
        Unit* caster = GetCaster();
        Unit* target = GetHitUnit();
        ElementalExecute const* rule = ElementalExecuteBySpell(GetSpellInfo()->Id);
        if (!target || !rule)
            return;
        SpellInfo const* spellInfo = GetSpellInfo();
        int32 rageUsed = std::min<int32>(300 - spellInfo->CalcPowerCost(caster, SpellSchoolMask(spellInfo->SchoolMask)),
            caster->GetPower(POWER_RAGE));
        int32 newRage = std::max<int32>(0, caster->GetPower(POWER_RAGE) - rageUsed);
        AuraEffect* suddenDeath = caster->GetAuraEffect(SPELL_AURA_PROC_TRIGGER_SPELL, SPELLFAMILY_GENERIC,
            WARRIOR_ICON_SUDDEN_DEATH, EFFECT_0);
        if (!suddenDeath)
            suddenDeath = caster->GetAuraEffect(SPELL_AURA_PROC_TRIGGER_SPELL, SPELLFAMILY_WARRIOR,
                WARRIOR_ICON_SUDDEN_DEATH, EFFECT_0);
        if (suddenDeath)
            newRage = std::max(newRage, suddenDeath->GetSpellInfo()->Effects[EFFECT_1].CalcValue() * 10);
        caster->SetPower(POWER_RAGE, uint32(newRage));
        rageUsed += GlyphOfExecutionRage(caster);

        SpellSchoolMask const magic = SpellSchoolMask(spellInfo->GetSchoolMask() & ~SPELL_SCHOOL_MASK_NORMAL);
        float const power = caster->GetTotalAttackPowerValue(BASE_ATTACK) +
            float(magic ? caster->SpellBaseDamageBonusDone(magic) : 0);
        int32 bp = int32(ELEMENTAL_EXECUTE_PCT * (GetEffectValue() + power * 0.3f +
            rageUsed * spellInfo->Effects[effIndex].DamageMultiplier));
        caster->CastCustomSpell(target, rule->Damage, &bp, nullptr, nullptr, true, nullptr, nullptr,
            GetOriginalCaster() ? GetOriginalCaster()->GetGUID() : caster->GetGUID());
    }

    void Register() override
    {
        BeforeHit += BeforeSpellHitFn(spell_dummyfix_warrior_elemental_execute::SendMiss);
        OnEffectHitTarget += SpellEffectFn(spell_dummyfix_warrior_elemental_execute::HandleEffect, EFFECT_0,
            SPELL_EFFECT_DUMMY);
    }
};

class spell_dummyfix_warrior_stock_glyph_of_execution : public AuraScript
{
    PrepareAuraScript(spell_dummyfix_warrior_stock_glyph_of_execution);

    void CalcAmount(AuraEffect const* , int32& amount, bool& )
    {
        if (AuraEffect const* classless = GetUnitOwner()->GetAuraEffect(GLYPH_OF_EXECUTION, EFFECT_0))
            amount = classless->GetAmount();
    }

    void AfterApply(AuraEffect const* , AuraEffectHandleModes )
    {
        AuraEffect const* classless = GetTarget()->GetAuraEffect(GLYPH_OF_EXECUTION, EFFECT_0);
        AuraEffect* stock = GetEffect(EFFECT_0);
        if (classless && stock && stock->GetAmount() != classless->GetAmount())
            stock->ChangeAmount(classless->GetAmount(), false);
    }

    void Register() override
    {
        DoEffectCalcAmount += AuraEffectCalcAmountFn(spell_dummyfix_warrior_stock_glyph_of_execution::CalcAmount, EFFECT_0,
            SPELL_AURA_DUMMY);
        AfterEffectApply += AuraEffectApplyFn(spell_dummyfix_warrior_stock_glyph_of_execution::AfterApply, EFFECT_0,
            SPELL_AURA_DUMMY, AURA_EFFECT_HANDLE_REAL);
    }
};

class dummyfix_warrior_execute_crit : public AllSpellScript
{
public:
    dummyfix_warrior_execute_crit() : AllSpellScript("dummyfix_warrior_execute_crit", { ALLSPELLHOOK_ON_CRIT_CHANCE }) { }

    void OnSpellCritChance(Spell* spell, Unit* target, float& chance) override
    {
        SpellInfo const* info = spell->GetSpellInfo();
        Unit* caster = spell->GetOriginalCaster() ? spell->GetOriginalCaster() : spell->GetCaster();
        if (!target || !caster || !IsFamilySpell(info, SPELLFAMILY_WARRIOR, WARRIOR_EXECUTE_FLAG) ||
            !info->HasEffect(SPELL_EFFECT_SCHOOL_DAMAGE) || !target->HealthBelowPct(20))
            return;
        if (AuraEffect const* glyph = caster->GetAuraEffect(GLYPH_OF_EXECUTION, EFFECT_1))
            chance += float(glyph->GetAmount());
    }
};

constexpr uint32 BUILT_UP_THIRST_BUFF = 271777;

class spell_dummyfix_warrior_built_up_thirst : public AuraScript
{
    PrepareAuraScript(spell_dummyfix_warrior_built_up_thirst);

    uint8 _points = 0;

    bool Validate(SpellInfo const* ) override
    {
        return ValidateSpellInfo({ BUILT_UP_THIRST_BUFF });
    }

    bool CheckProc(ProcEventInfo& eventInfo)
    {
        SpellInfo const* info = eventInfo.GetSpellInfo();
        Player* player = GetTarget()->ToPlayer();
        if (!info || !player || !info->NeedsComboPoints())
            return false;
        _points = player->GetComboPoints();
        return _points > 0;
    }

    void HandleProc(AuraEffect const* aurEff, ProcEventInfo& )
    {
        PreventDefaultAction();
        int32 bp = int32(GetSpellInfo()->Effects[EFFECT_0].PointsPerComboPoint * _points);
        if (bp > 0)
            GetTarget()->CastCustomSpell(GetTarget(), BUILT_UP_THIRST_BUFF, &bp, nullptr, nullptr, true, nullptr, aurEff);
    }

    void Register() override
    {
        DoCheckProc += AuraCheckProcFn(spell_dummyfix_warrior_built_up_thirst::CheckProc);
        OnEffectProc += AuraEffectProcFn(spell_dummyfix_warrior_built_up_thirst::HandleProc, EFFECT_0, SPELL_AURA_DUMMY);
    }
};

constexpr uint32 ELECTRIFIED_GRASP = 273059;

class spell_dummyfix_warrior_lightning_blast : public SpellScript
{
    PrepareSpellScript(spell_dummyfix_warrior_lightning_blast);

    bool Slows()
    {
        Unit* caster = GetOriginalCaster() ? GetOriginalCaster() : GetCaster();
        return caster && caster->HasAura(ELECTRIFIED_GRASP);
    }

    void HandleSlow(SpellEffIndex effIndex)
    {
        if (!Slows())
            PreventHitDefaultEffect(effIndex);
    }

    void Register() override
    {
        OnEffectLaunch += SpellEffectFn(spell_dummyfix_warrior_lightning_blast::HandleSlow, EFFECT_2, SPELL_EFFECT_TRIGGER_SPELL);
        OnEffectLaunchTarget += SpellEffectFn(spell_dummyfix_warrior_lightning_blast::HandleSlow, EFFECT_2,
            SPELL_EFFECT_TRIGGER_SPELL);
        OnEffectHitTarget += SpellEffectFn(spell_dummyfix_warrior_lightning_blast::HandleSlow, EFFECT_2,
            SPELL_EFFECT_TRIGGER_SPELL);
    }
};
constexpr std::array<uint32, 2> MASTERY_OF_THE_TIDE = { 274948, 1574368 };
constexpr uint32 SHAMAN_RIPTIDE_FLAG2 = 0x00000010;

class spell_dummyfix_warrior_mastery_of_the_tide : public SpellScript
{
    PrepareSpellScript(spell_dummyfix_warrior_mastery_of_the_tide);

    bool _first = true;
    uint32 _riptide = 0;
    int32 _duration = 0;
    ObjectGuid _target;

    void RecordRiptide(SpellMissInfo missInfo)
    {
        if (!_first || missInfo != SPELL_MISS_NONE)
            return;
        _first = false;
        Unit* caster = GetCaster();
        Unit* target = GetHitUnit();
        if (!target || std::none_of(MASTERY_OF_THE_TIDE.begin(), MASTERY_OF_THE_TIDE.end(),
            [caster](uint32 id) { return caster->HasAura(id); }))
            return;
        if (AuraEffect const* riptide = target->GetAuraEffect(SPELL_AURA_PERIODIC_HEAL, SPELLFAMILY_SHAMAN, 0, 0,
            SHAMAN_RIPTIDE_FLAG2, caster->GetGUID()))
        {
            _riptide = riptide->GetId();
            _duration = riptide->GetBase()->GetDuration();
            _target = target->GetGUID();
        }
    }

    void RestoreRiptide()
    {
        if (!_riptide || GetHitUnit() == nullptr || GetHitUnit()->GetGUID() != _target)
            return;
        Unit* caster = GetCaster();
        Unit* target = GetHitUnit();
        uint32 const riptide = _riptide;
        _riptide = 0;
        if (target->HasAura(riptide, caster->GetGUID()))
            return;
        if (Aura* restored = caster->AddAura(riptide, target))
            if (_duration > 0)
                restored->SetDuration(_duration);
    }

    void Register() override
    {
        BeforeHit += BeforeSpellHitFn(spell_dummyfix_warrior_mastery_of_the_tide::RecordRiptide);
        AfterHit += SpellHitFn(spell_dummyfix_warrior_mastery_of_the_tide::RestoreRiptide);
    }
};

struct AbjurersWardRule
{
    uint32 Aura;
    std::array<uint32, 2> Spells;
};

constexpr std::array<AbjurersWardRule, 4> ABJURERS_WARDS = {{
    { 284716, { 11129, 1111129 } },
    { 982572, { 11129, 1111129 } },
    { 284752, { 11958, 1111958 } },
    { 982605, { 11958, 1111958 } },
}};

class spell_dummyfix_warrior_abjurers_ward : public AuraScript
{
    PrepareAuraScript(spell_dummyfix_warrior_abjurers_ward);

    void AfterAbsorb(AuraEffect* , DamageInfo& , uint32& absorbAmount)
    {
        Player* player = GetTarget()->ToPlayer();
        if (!player || !absorbAmount)
            return;
        for (AbjurersWardRule const& rule : ABJURERS_WARDS)
            if (AuraEffect const* effect = player->GetAuraEffect(rule.Aura, EFFECT_0))
                for (uint32 spell : rule.Spells)
                    if (player->HasSpellCooldown(spell))
                        player->ModifySpellCooldown(spell, effect->GetAmount());
    }

    void Register() override
    {
        AfterEffectAbsorb += AuraEffectAbsorbFn(spell_dummyfix_warrior_abjurers_ward::AfterAbsorb, EFFECT_0);
    }
};

constexpr uint32 ARMOR_OF_FAITH_HEAL = 98900;

class spell_dummyfix_warrior_armor_of_faith_buff : public AuraScript
{
    PrepareAuraScript(spell_dummyfix_warrior_armor_of_faith_buff);

    bool Validate(SpellInfo const* ) override
    {
        return ValidateSpellInfo({ ARMOR_OF_FAITH_HEAL });
    }

    bool _healed = false;

    bool CheckProc(ProcEventInfo& eventInfo)
    {
        DamageInfo* damage = eventInfo.GetDamageInfo();
        return damage && damage->GetDamage() && GetTarget()->IsAlive();
    }

    void Heal(AuraEffect const* aurEff)
    {
        if (_healed)
            return;
        _healed = true;
        int32 amount = aurEff->GetAmount();
        Unit* healer = GetCaster() ? GetCaster() : GetTarget();
        if (amount <= 0 || !GetTarget()->IsAlive())
            return;
        SpellCastResult const result = healer->CastCustomSpell(GetTarget(), ARMOR_OF_FAITH_HEAL, &amount, nullptr, nullptr,
            true, nullptr, aurEff);
        if (result != SPELL_CAST_OK)
            LOG_ERROR("scripts.coa", "Armor of Faith {}: heal {} on {} refused ({})", GetId(), ARMOR_OF_FAITH_HEAL,
                GetTarget()->GetGUID().ToString(), uint32(result));
    }

    void HandleProc(AuraEffect const* aurEff, ProcEventInfo& )
    {
        PreventDefaultAction();
        Heal(aurEff);
    }

    void AfterRemove(AuraEffect const* aurEff, AuraEffectHandleModes )
    {
        if (GetTargetApplication()->GetRemoveMode() == AURA_REMOVE_BY_DEFAULT)
            Heal(aurEff);
    }

    void Register() override
    {
        DoCheckProc += AuraCheckProcFn(spell_dummyfix_warrior_armor_of_faith_buff::CheckProc);
        OnEffectProc += AuraEffectProcFn(spell_dummyfix_warrior_armor_of_faith_buff::HandleProc, EFFECT_0, SPELL_AURA_DUMMY);
        AfterEffectRemove += AuraEffectRemoveFn(spell_dummyfix_warrior_armor_of_faith_buff::AfterRemove, EFFECT_0,
            SPELL_AURA_DUMMY, AURA_EFFECT_HANDLE_REAL);
    }
};

struct FlashOfAdrenalineRule
{
    uint32 Aura;
    uint32 Reset;
};

constexpr std::array<FlashOfAdrenalineRule, 2> FLASHES_OF_ADRENALINE = {{
    { 84453, 84454 },
    { 282309, 282310 },
}};

class spell_dummyfix_warrior_adrenaline_rush : public AuraScript
{
    PrepareAuraScript(spell_dummyfix_warrior_adrenaline_rush);

    void AfterRemove(AuraEffect const* , AuraEffectHandleModes )
    {
        if (GetTargetApplication()->GetRemoveMode() != AURA_REMOVE_BY_EXPIRE)
            return;
        Unit* target = GetTarget();
        for (FlashOfAdrenalineRule const& rule : FLASHES_OF_ADRENALINE)
            if (target->HasAura(rule.Aura))
            {
                target->CastSpell(target, rule.Reset, true);
                return;
            }
    }

    void Register() override
    {
        AfterEffectRemove += AuraEffectRemoveFn(spell_dummyfix_warrior_adrenaline_rush::AfterRemove, EFFECT_0, SPELL_AURA_ANY,
            AURA_EFFECT_HANDLE_REAL);
    }
};
constexpr uint32 BIG_ONE_STACKS = 414000;
constexpr uint32 BIG_ONE_BUFF = 414001;

class spell_dummyfix_warrior_here_comes_the_big_one : public AuraScript
{
    PrepareAuraScript(spell_dummyfix_warrior_here_comes_the_big_one);

    bool Validate(SpellInfo const* ) override
    {
        return ValidateSpellInfo({ BIG_ONE_STACKS, BIG_ONE_BUFF });
    }

    void HandleProc(AuraEffect const* aurEff, ProcEventInfo& )
    {
        PreventDefaultAction();
        Unit* target = GetTarget();
        Aura* stacks = target->GetAura(BIG_ONE_STACKS);
        if (stacks && stacks->GetStackAmount() >= 3)
        {
            stacks->Remove();
            target->CastSpell(target, BIG_ONE_BUFF, true, nullptr, aurEff);
        }
        else
            target->CastSpell(target, BIG_ONE_STACKS, true, nullptr, aurEff);
    }

    void PreventSecond(AuraEffect const* , ProcEventInfo& )
    {
        PreventDefaultAction();
    }

    void Register() override
    {
        OnEffectProc += AuraEffectProcFn(spell_dummyfix_warrior_here_comes_the_big_one::HandleProc, EFFECT_0,
            SPELL_AURA_PROC_TRIGGER_SPELL);
        OnEffectProc += AuraEffectProcFn(spell_dummyfix_warrior_here_comes_the_big_one::PreventSecond, EFFECT_1,
            SPELL_AURA_PROC_TRIGGER_SPELL);
    }
};

constexpr std::array<uint32, 2> UNSTOPPABLE_FORCE = { 283222, 911167 };
constexpr uint32 WARRIOR_SLAM_FLAG0 = 0x00200000;
constexpr uint64 INCAPACITATED_MECHANICS = (1ULL << MECHANIC_STUN) | (1ULL << MECHANIC_ROOT) | (1ULL << MECHANIC_SAPPED) |
    (1ULL << MECHANIC_KNOCKOUT) | (1ULL << MECHANIC_POLYMORPH) | (1ULL << MECHANIC_SLEEP) | (1ULL << MECHANIC_FREEZE) |
    (1ULL << MECHANIC_SHACKLE) | (1ULL << MECHANIC_HORROR) | (1ULL << MECHANIC_BANISH);

class dummyfix_warrior_unstoppable_force : public AllSpellScript
{
public:
    dummyfix_warrior_unstoppable_force() : AllSpellScript("dummyfix_warrior_unstoppable_force", { ALLSPELLHOOK_ON_CRIT_CHANCE }) { }

    void OnSpellCritChance(Spell* spell, Unit* target, float& chance) override
    {
        Unit* caster = spell->GetOriginalCaster() ? spell->GetOriginalCaster() : spell->GetCaster();
        if (!target || !caster || !IsFamilySpell(spell->GetSpellInfo(), SPELLFAMILY_WARRIOR, WARRIOR_SLAM_FLAG0))
            return;
        if (std::none_of(UNSTOPPABLE_FORCE.begin(), UNSTOPPABLE_FORCE.end(), [caster](uint32 id) { return caster->HasAura(id); }))
            return;
        if (target->HasAuraType(SPELL_AURA_MOD_ROOT) || target->HasAuraType(SPELL_AURA_MOD_STUN) ||
            target->HasAuraWithMechanic(INCAPACITATED_MECHANICS))
            chance = 100.0f;
    }
};

struct WeaponMasteryRule
{
    uint32 Talent;
    uint32 Passive;
};

constexpr std::array<WeaponMasteryRule, 2> TWO_HANDED_MASTERIES = {{
    { 29623, 829623 },
    { 829633, 829634 },
}};

bool WieldsSingleTwoHander(Player const* player)
{
    Item const* main = player->GetItemByPos(INVENTORY_SLOT_BAG_0, EQUIPMENT_SLOT_MAINHAND);
    Item const* off = player->GetItemByPos(INVENTORY_SLOT_BAG_0, EQUIPMENT_SLOT_OFFHAND);
    return main && !off && main->GetTemplate()->InventoryType == INVTYPE_2HWEAPON;
}

void RefreshTwoHandedMastery(Player* player)
{
    bool const single = WieldsSingleTwoHander(player);
    for (WeaponMasteryRule const& rule : TWO_HANDED_MASTERIES)
    {
        bool const wanted = single && player->HasAura(rule.Talent);
        if (wanted && !player->HasAura(rule.Passive))
            player->CastSpell(player, rule.Passive, true);
        else if (!wanted && player->HasAura(rule.Passive))
            player->RemoveAurasDueToSpell(rule.Passive);
    }
}

class spell_dummyfix_warrior_two_handed_mastery : public AuraScript
{
    PrepareAuraScript(spell_dummyfix_warrior_two_handed_mastery);

    void HandleChange(AuraEffect const* , AuraEffectHandleModes )
    {
        if (Player* player = GetTarget()->ToPlayer())
            RefreshTwoHandedMastery(player);
    }

    void Register() override
    {
        AfterEffectApply += AuraEffectApplyFn(spell_dummyfix_warrior_two_handed_mastery::HandleChange, EFFECT_2, SPELL_AURA_DUMMY,
            AURA_EFFECT_HANDLE_REAL);
        AfterEffectRemove += AuraEffectRemoveFn(spell_dummyfix_warrior_two_handed_mastery::HandleChange, EFFECT_2,
            SPELL_AURA_DUMMY, AURA_EFFECT_HANDLE_REAL);
    }
};

class dummyfix_warrior_weapon_hooks : public PlayerScript
{
public:
    dummyfix_warrior_weapon_hooks() : PlayerScript("dummyfix_warrior_weapon_hooks", { PLAYERHOOK_ON_AFTER_SET_VISIBLE_ITEM_SLOT }) { }

    void OnPlayerAfterSetVisibleItemSlot(Player* player, uint8 slot, Item* ) override
    {
        if (player && (slot == EQUIPMENT_SLOT_MAINHAND || slot == EQUIPMENT_SLOT_OFFHAND))
            RefreshTwoHandedMastery(player);
    }
};

constexpr uint32 TRAUMATIC_WOUNDS = 273713;
constexpr uint32 TRAUMATIC_WOUNDS_EXTEND = 273717;
constexpr uint32 TRAUMATIC_WOUNDS_ENERGY = 273721;

class spell_dummyfix_warrior_traumatic_wounds : public AuraScript
{
    PrepareAuraScript(spell_dummyfix_warrior_traumatic_wounds);

    bool Validate(SpellInfo const* ) override
    {
        return ValidateSpellInfo({ TRAUMATIC_WOUNDS_EXTEND });
    }

    bool CheckProc(ProcEventInfo& eventInfo)
    {
        SpellInfo const* info = eventInfo.GetSpellInfo();
        DamageInfo* damage = eventInfo.GetDamageInfo();
        if (!info || !damage || !damage->GetDamage() || !eventInfo.GetActionTarget())
            return false;
        return IsFamilySpell(info, SPELLFAMILY_DRUID, 0x00008000 | 0x00010000, 0x00000400, 0x00040000) ||
            IsFamilySpell(info, SPELLFAMILY_WARRIOR, 0, 0x00000400);
    }

    void HandleProc(AuraEffect const* aurEff, ProcEventInfo& eventInfo)
    {
        PreventDefaultAction();
        GetTarget()->CastSpell(eventInfo.GetActionTarget(), TRAUMATIC_WOUNDS_EXTEND, true, nullptr, aurEff);
    }

    void Register() override
    {
        DoCheckProc += AuraCheckProcFn(spell_dummyfix_warrior_traumatic_wounds::CheckProc);
        OnEffectProc += AuraEffectProcFn(spell_dummyfix_warrior_traumatic_wounds::HandleProc, EFFECT_0, SPELL_AURA_DUMMY);
    }
};

class spell_dummyfix_warrior_traumatic_rake : public AuraScript
{
    PrepareAuraScript(spell_dummyfix_warrior_traumatic_rake);

    void HandleTick(AuraEffect const* aurEff)
    {
        Unit* caster = GetCaster();
        if (caster && caster->HasAura(TRAUMATIC_WOUNDS))
            caster->CastSpell(caster, TRAUMATIC_WOUNDS_ENERGY, true, nullptr, aurEff);
    }

    void Register() override
    {
        OnEffectPeriodic += AuraEffectPeriodicFn(spell_dummyfix_warrior_traumatic_rake::HandleTick, EFFECT_ALL,
            SPELL_AURA_PERIODIC_DAMAGE);
    }
};
constexpr uint32 THROW_WEAPON_ENCHANT = 84466;
constexpr uint32 THROW_WEAPON = 84467;

class spell_dummyfix_warrior_throw_weapon : public AuraScript
{
    PrepareAuraScript(spell_dummyfix_warrior_throw_weapon);

    bool _taught = false;

    bool Validate(SpellInfo const* ) override
    {
        return ValidateSpellInfo({ THROW_WEAPON });
    }

    void HandleApply(AuraEffect const* , AuraEffectHandleModes )
    {
        Player* player = GetTarget()->ToPlayer();
        if (!player || player->HasSpell(THROW_WEAPON))
            return;
        player->learnSpell(THROW_WEAPON, true);
        _taught = true;
    }

    void HandleRemove(AuraEffect const* , AuraEffectHandleModes )
    {
        Player* player = GetTarget()->ToPlayer();
        if (!player || !_taught)
            return;
        _taught = false;
        player->removeSpell(THROW_WEAPON, SPEC_MASK_ALL, true);
    }

    void Register() override
    {
        AfterEffectApply += AuraEffectApplyFn(spell_dummyfix_warrior_throw_weapon::HandleApply, EFFECT_0, SPELL_AURA_DUMMY,
            AURA_EFFECT_HANDLE_REAL);
        AfterEffectRemove += AuraEffectRemoveFn(spell_dummyfix_warrior_throw_weapon::HandleRemove, EFFECT_0, SPELL_AURA_DUMMY,
            AURA_EFFECT_HANDLE_REAL);
    }
};

constexpr uint32 TITANIC_POWER = 986138;

class spell_dummyfix_warrior_titanic_power_removal : public AuraScript
{
    PrepareAuraScript(spell_dummyfix_warrior_titanic_power_removal);

    void HandleRemove(AuraEffect const* , AuraEffectHandleModes )
    {
        if (GetTargetApplication()->GetRemoveMode() == AURA_REMOVE_BY_EXPIRE)
            GetTarget()->RemoveAurasDueToSpell(TITANIC_POWER);
    }

    void Register() override
    {
        AfterEffectRemove += AuraEffectRemoveFn(spell_dummyfix_warrior_titanic_power_removal::HandleRemove, EFFECT_0,
            SPELL_AURA_DUMMY, AURA_EFFECT_HANDLE_REAL);
    }
};

constexpr std::array<uint32, 2> BLUNT_FORCE_TRAUMA = { 283510, 987149 };

class spell_dummyfix_warrior_damage_shield : public SpellScript
{
    PrepareSpellScript(spell_dummyfix_warrior_damage_shield);

    void HandleDamage(SpellEffIndex )
    {
        Unit* target = GetHitUnit();
        if (!target)
            return;
        for (uint32 id : BLUNT_FORCE_TRAUMA)
            if (AuraEffect const* bleed = target->GetAuraEffect(id, EFFECT_1, GetCaster()->GetGUID()))
            {
                int32 damage = GetHitDamage();
                SetHitDamage(AddPct(damage, bleed->GetAmount()));
                return;
            }
    }

    void Register() override
    {
        OnEffectHitTarget += SpellEffectFn(spell_dummyfix_warrior_damage_shield::HandleDamage, EFFECT_0, SPELL_EFFECT_SCHOOL_DAMAGE);
    }
};
class spell_dummyfix_warrior_shockwave_damage : public SpellScript
{
    PrepareSpellScript(spell_dummyfix_warrior_shockwave_damage);

    void HandleDamage(SpellEffIndex )
    {
        Unit* caster = GetCaster();
        SpellInfo const* info = GetSpellInfo();
        for (uint8 i = 0; i < MAX_SPELL_EFFECTS; ++i)
        {
            if (info->Effects[i].Effect != SPELL_EFFECT_DUMMY)
                continue;
            int32 const pct = caster->CalculateSpellDamage(GetHitUnit(), info, i);
            if (pct > 0)
                SetEffectValue(GetEffectValue() + int32(CalculatePct(caster->GetTotalAttackPowerValue(BASE_ATTACK), pct)));
            return;
        }
    }

    void Register() override
    {
        OnEffectLaunchTarget += SpellEffectFn(spell_dummyfix_warrior_shockwave_damage::HandleDamage, EFFECT_ALL,
            SPELL_EFFECT_SCHOOL_DAMAGE);
    }
};

constexpr uint32 SEISMIC_SHOCKWAVE_BUFF = 282303;
constexpr uint8 SEISMIC_SHOCKWAVE_STACKS = 3;

class spell_dummyfix_warrior_shockwave : public SpellScript
{
    PrepareSpellScript(spell_dummyfix_warrior_shockwave);

    bool _seismic = false;

    bool Load() override
    {
        Aura const* buff = GetCaster()->GetAura(SEISMIC_SHOCKWAVE_BUFF);
        _seismic = buff && buff->GetStackAmount() >= SEISMIC_SHOCKWAVE_STACKS;
        return true;
    }

    void HandleWave(SpellEffIndex effIndex)
    {
        if ((effIndex == EFFECT_1) != _seismic)
            PreventHitDefaultEffect(effIndex);
    }

    void Register() override
    {
        for (SpellEffIndex i : { EFFECT_0, EFFECT_1 })
        {
            OnEffectLaunch += SpellEffectFn(spell_dummyfix_warrior_shockwave::HandleWave, i, SPELL_EFFECT_TRIGGER_SPELL);
            OnEffectLaunchTarget += SpellEffectFn(spell_dummyfix_warrior_shockwave::HandleWave, i, SPELL_EFFECT_TRIGGER_SPELL);
            OnEffectHit += SpellEffectFn(spell_dummyfix_warrior_shockwave::HandleWave, i, SPELL_EFFECT_TRIGGER_SPELL);
            OnEffectHitTarget += SpellEffectFn(spell_dummyfix_warrior_shockwave::HandleWave, i, SPELL_EFFECT_TRIGGER_SPELL);
        }
    }
};

constexpr int32 EXECUTING_DISEMBOWEL_MONSTER_PCT = 30;

class spell_dummyfix_warrior_executing_disembowel : public SpellScript
{
    PrepareSpellScript(spell_dummyfix_warrior_executing_disembowel);

    void HandleDamage(SpellEffIndex )
    {
        Unit* target = GetHitUnit();
        if (!target || target->IsPlayer() || target->IsControlledByPlayer())
            return;
        int32 damage = GetHitDamage();
        SetHitDamage(AddPct(damage, EXECUTING_DISEMBOWEL_MONSTER_PCT));
    }

    void Register() override
    {
        OnEffectHitTarget += SpellEffectFn(spell_dummyfix_warrior_executing_disembowel::HandleDamage, EFFECT_0,
            SPELL_EFFECT_SCHOOL_DAMAGE);
    }
};

constexpr uint32 DEMOLISH = 954092;

class spell_dummyfix_warrior_demolishing_strike : public SpellScript
{
    PrepareSpellScript(spell_dummyfix_warrior_demolishing_strike);

    bool Validate(SpellInfo const* ) override
    {
        return ValidateSpellInfo({ DEMOLISH });
    }

    void HandleDummy(SpellEffIndex )
    {
        Unit* target = GetHitUnit();
        if (!target)
            return;
        if (Aura* demolish = target->GetAura(DEMOLISH, GetCaster()->GetGUID()))
            demolish->RefreshDuration();
        else
            GetCaster()->CastSpell(target, DEMOLISH, true);
    }

    void Register() override
    {
        OnEffectHitTarget += SpellEffectFn(spell_dummyfix_warrior_demolishing_strike::HandleDummy, EFFECT_0, SPELL_EFFECT_DUMMY);
    }
};

constexpr int32 DEVASTATING_POUND_PCT_PER_LACERATE = 5;
constexpr uint32 DRUID_LACERATE_FLAG1 = 0x00000100;

class spell_dummyfix_warrior_devastating_pound : public SpellScript
{
    PrepareSpellScript(spell_dummyfix_warrior_devastating_pound);

    void HandleHit()
    {
        Unit* target = GetHitUnit();
        if (!target || GetHitDamage() <= 0)
            return;
        AuraEffect const* lacerate = target->GetAuraEffect(SPELL_AURA_PERIODIC_DAMAGE, SPELLFAMILY_DRUID, 0,
            DRUID_LACERATE_FLAG1, 0, GetCaster()->GetGUID());
        if (!lacerate)
            return;
        int32 damage = GetHitDamage();
        SetHitDamage(AddPct(damage, DEVASTATING_POUND_PCT_PER_LACERATE * lacerate->GetBase()->GetStackAmount()));
    }

    void Register() override
    {
        OnHit += SpellHitFn(spell_dummyfix_warrior_devastating_pound::HandleHit);
    }
};

constexpr uint32 CONCUSSION_BLOW = 12809;
constexpr std::array<uint32, 6> CONCUSSION_BLOW_STORMHAMMER = { 977929, 978019, 978020, 978021, 978022, 978023 };

class spell_dummyfix_warrior_stormhammer : public AuraScript
{
    PrepareAuraScript(spell_dummyfix_warrior_stormhammer);

    uint32 _taught = 0;

    void HandleApply(AuraEffect const* , AuraEffectHandleModes )
    {
        Player* player = GetTarget()->ToPlayer();
        if (!player || !player->HasSpell(CONCUSSION_BLOW))
            return;
        uint32 rank = 0;
        for (uint32 id : CONCUSSION_BLOW_STORMHAMMER)
            if (SpellInfo const* info = sSpellMgr->GetSpellInfo(id))
                if (info->SpellLevel <= player->GetLevel())
                    rank = id;
        if (!rank || player->HasSpell(rank))
            return;
        player->learnSpell(rank, true);
        _taught = rank;
    }

    void HandleRemove(AuraEffect const* , AuraEffectHandleModes )
    {
        Player* player = GetTarget()->ToPlayer();
        if (!player || !_taught)
            return;
        player->removeSpell(_taught, SPEC_MASK_ALL, true);
        _taught = 0;
    }

    void Register() override
    {
        AfterEffectApply += AuraEffectApplyFn(spell_dummyfix_warrior_stormhammer::HandleApply, EFFECT_2, SPELL_AURA_DUMMY,
            AURA_EFFECT_HANDLE_REAL);
        AfterEffectRemove += AuraEffectRemoveFn(spell_dummyfix_warrior_stormhammer::HandleRemove, EFFECT_2, SPELL_AURA_DUMMY,
            AURA_EFFECT_HANDLE_REAL);
    }
};

constexpr uint32 SWEEPING_SWINGS = 912326;
constexpr uint32 CRITICAL_SWINGS = 912328;

class spell_dummyfix_warrior_sweeping_strikes : public AuraScript
{
    PrepareAuraScript(spell_dummyfix_warrior_sweeping_strikes);

    void HandleApply(AuraEffect const* , AuraEffectHandleModes )
    {
        Unit* target = GetTarget();
        if (target->HasAura(SWEEPING_SWINGS))
            if (Aura* swings = target->AddAura(CRITICAL_SWINGS, target))
                swings->SetDuration(GetAura()->GetDuration());
    }

    void HandleRemove(AuraEffect const* , AuraEffectHandleModes )
    {
        GetTarget()->RemoveAurasDueToSpell(CRITICAL_SWINGS);
    }

    void Register() override
    {
        AfterEffectApply += AuraEffectApplyFn(spell_dummyfix_warrior_sweeping_strikes::HandleApply, EFFECT_0, SPELL_AURA_ANY,
            AURA_EFFECT_HANDLE_REAL);
        AfterEffectRemove += AuraEffectRemoveFn(spell_dummyfix_warrior_sweeping_strikes::HandleRemove, EFFECT_0, SPELL_AURA_ANY,
            AURA_EFFECT_HANDLE_REAL);
    }
};

constexpr uint32 DEADLY_LEAP = 955076;
constexpr int32 DEADLY_LEAP_PCT = 30;
constexpr std::array<uint32, 3> HEROIC_LEAPS = { 6544, 254570, 606544 };

class spell_dummyfix_warrior_heroic_leap_damage : public SpellScript
{
    PrepareSpellScript(spell_dummyfix_warrior_heroic_leap_damage);

    void HandleHit()
    {
        Unit* target = GetHitUnit();
        AuraEffect const* leap = GetCaster()->GetAuraEffect(DEADLY_LEAP, EFFECT_1);
        if (!target || !leap || GetHitDamage() <= 0 || !target->HealthBelowPct(leap->GetAmount()))
            return;
        int32 damage = GetHitDamage();
        SetHitDamage(AddPct(damage, DEADLY_LEAP_PCT));
    }

    void HandleAfterHit()
    {
        Player* player = GetCaster()->ToPlayer();
        Unit* target = GetHitUnit();
        if (!player || !target || target->IsAlive() || !player->HasAura(DEADLY_LEAP))
            return;
        for (uint32 id : HEROIC_LEAPS)
            if (player->HasSpellCooldown(id))
                player->RemoveSpellCooldown(id, true);
    }

    void Register() override
    {
        OnHit += SpellHitFn(spell_dummyfix_warrior_heroic_leap_damage::HandleHit);
        AfterHit += SpellHitFn(spell_dummyfix_warrior_heroic_leap_damage::HandleAfterHit);
    }
};
}

void ApplyAscensionDummyFixWarriorContracts(SpellInfo* spellInfo)
{
    if (!spellInfo)
        return;

    switch (spellInfo->Id)
    {
        case BUILT_UP_THIRST_BUFF:
            if (!spellInfo->ProcCharges)
                spellInfo->ProcCharges = 1;
            break;
        case 1158387:
            if (spellInfo->Effects[EFFECT_0].ApplyAuraName == SPELL_AURA_DUMMY)
            {
                spellInfo->Effects[EFFECT_0].ApplyAuraName = SPELL_AURA_ADD_FLAT_MODIFIER;
                spellInfo->Effects[EFFECT_0].BasePoints = 0;
                spellInfo->Effects[EFFECT_0].DieSides = 1;
            }
            break;
        default:
            break;
    }
}

void AddAscensionDummyFixWarriorScripts()
{
    RegisterSpellScript(spell_dummyfix_warrior_soul_restoration);
    RegisterSpellScript(spell_dummyfix_warrior_elemental_execute);
    RegisterSpellScript(spell_dummyfix_warrior_built_up_thirst);
    RegisterSpellScript(spell_dummyfix_warrior_lightning_blast);
    new dummyfix_warrior_execute_crit();
    RegisterSpellScript(spell_dummyfix_warrior_mastery_of_the_tide);
    RegisterSpellScript(spell_dummyfix_warrior_abjurers_ward);
    RegisterSpellScript(spell_dummyfix_warrior_armor_of_faith_buff);
    RegisterSpellScript(spell_dummyfix_warrior_adrenaline_rush);
    new dummyfix_warrior_unstoppable_force();
    RegisterSpellScript(spell_dummyfix_warrior_two_handed_mastery);
    new dummyfix_warrior_weapon_hooks();
    RegisterSpellScript(spell_dummyfix_warrior_traumatic_wounds);
    RegisterSpellScript(spell_dummyfix_warrior_traumatic_rake);
    RegisterSpellScript(spell_dummyfix_warrior_throw_weapon);
    RegisterSpellScript(spell_dummyfix_warrior_titanic_power_removal);
    RegisterSpellScript(spell_dummyfix_warrior_damage_shield);
    RegisterSpellScript(spell_dummyfix_warrior_shockwave_damage);
    RegisterSpellScript(spell_dummyfix_warrior_shockwave);
    RegisterSpellScript(spell_dummyfix_warrior_here_comes_the_big_one);
    RegisterSpellScript(spell_dummyfix_warrior_stock_glyph_of_execution);
    RegisterSpellScript(spell_dummyfix_warrior_executing_disembowel);
    RegisterSpellScript(spell_dummyfix_warrior_demolishing_strike);
    RegisterSpellScript(spell_dummyfix_warrior_devastating_pound);
    RegisterSpellScript(spell_dummyfix_warrior_stormhammer);
    RegisterSpellScript(spell_dummyfix_warrior_sweeping_strikes);
    RegisterSpellScript(spell_dummyfix_warrior_heroic_leap_damage);
}
