/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "AscensionDummyFixes.h"
#include "AllCreatureScript.h"
#include "CellImpl.h"
#include "Containers.h"
#include "DBCStores.h"
#include "GameTime.h"
#include "GridNotifiers.h"
#include "GridNotifiersImpl.h"
#include "Item.h"
#include "ObjectAccessor.h"
#include "Player.h"
#include "ScriptMgr.h"
#include "Spell.h"
#include "SpellAuraEffects.h"
#include "SpellAuras.h"
#include "SpellInfo.h"
#include "SpellMgr.h"
#include "SpellScript.h"
#include "Totem.h"
#include "UnitScript.h"
#include <algorithm>
#include <array>
#include <cstring>
#include <list>

namespace
{
constexpr uint32 SHAMAN_WINDFURY_ATTACK_FLAG = 0x00800000;
constexpr uint32 SHAMAN_RIPTIDE_FLAG2 = 0x00000010;

constexpr uint32 MAGICAL_QUICKNESS = 830822;
constexpr uint32 PHYSICAL_QUICKNESS = 840822;

class spell_dummyfix_shaman_mental_quickness : public AuraScript
{
    PrepareAuraScript(spell_dummyfix_shaman_mental_quickness);

    bool Validate(SpellInfo const* ) override
    {
        return ValidateSpellInfo({ MAGICAL_QUICKNESS, PHYSICAL_QUICKNESS });
    }

    bool CheckProc(ProcEventInfo& eventInfo)
    {
        DamageInfo* damage = eventInfo.GetDamageInfo();
        return damage && damage->GetDamage() && !(eventInfo.GetTypeMask() & PROC_FLAG_DONE_PERIODIC);
    }

    void HandleProc(AuraEffect const* aurEff, ProcEventInfo& eventInfo)
    {
        PreventDefaultAction();
        Unit* owner = GetTarget();
        bool const physical = eventInfo.GetDamageInfo()->GetSchoolMask() & SPELL_SCHOOL_MASK_NORMAL;
        uint32 const buff = physical ? MAGICAL_QUICKNESS : PHYSICAL_QUICKNESS;
        owner->RemoveAurasDueToSpell(physical ? PHYSICAL_QUICKNESS : MAGICAL_QUICKNESS, owner->GetGUID());
        int32 amount = aurEff->GetAmount();
        owner->CastCustomSpell(owner, buff, &amount, nullptr, nullptr, true, nullptr, aurEff);
    }

    void Register() override
    {
        DoCheckProc += AuraCheckProcFn(spell_dummyfix_shaman_mental_quickness::CheckProc);
        OnEffectProc += AuraEffectProcFn(spell_dummyfix_shaman_mental_quickness::HandleProc, EFFECT_0, SPELL_AURA_DUMMY);
    }
};

struct ShatterRule
{
    uint32 Spell;
    SummonSlot Slot;
    uint32 Release;
    bool Shatter;
};

constexpr std::array<ShatterRule, 3> SHATTERS = {{
    { 92487, SUMMON_SLOT_TOTEM_FIRE, 92276, true },
    { 92488, SUMMON_SLOT_TOTEM_EARTH, 92277, true },
    { 1588516, SUMMON_SLOT_TOTEM_FIRE, 1588517, false },
}};

ShatterRule const* ShatterBySpell(uint32 id)
{
    for (ShatterRule const& rule : SHATTERS)
        if (rule.Spell == id)
            return &rule;
    return nullptr;
}

constexpr Milliseconds SHATTER_DELAY = 1500ms;

class spell_dummyfix_shaman_totemic_shatter : public SpellScript
{
    PrepareSpellScript(spell_dummyfix_shaman_totemic_shatter);

    bool Validate(SpellInfo const* info) override
    {
        ShatterRule const* rule = ShatterBySpell(info->Id);
        return rule && ValidateSpellInfo({ rule->Release });
    }

    Creature* ActiveTotem()
    {
        ShatterRule const* rule = ShatterBySpell(GetSpellInfo()->Id);
        Unit* caster = GetCaster();
        if (!rule || !caster || !caster->m_SummonSlot[rule->Slot])
            return nullptr;
        Creature* totem = ObjectAccessor::GetCreature(*caster, caster->m_SummonSlot[rule->Slot]);
        return totem && totem->IsTotem() && totem->IsAlive() ? totem : nullptr;
    }

    SpellCastResult CheckCast()
    {
        return ActiveTotem() ? SPELL_CAST_OK : SPELL_FAILED_BAD_TARGETS;
    }

    void HandleDummy(SpellEffIndex )
    {
        ShatterRule const* rule = ShatterBySpell(GetSpellInfo()->Id);
        Creature* totem = ActiveTotem();
        if (!rule || !totem)
            return;
        if (!rule->Shatter)
        {
            GetCaster()->CastSpell(totem, rule->Release, true);
            return;
        }
        totem->CastSpell(totem, rule->Release, true, nullptr, nullptr, GetCaster()->GetGUID());
        if (Totem* summon = totem->ToTotem())
            summon->UnSummon(SHATTER_DELAY);
    }

    void Register() override
    {
        OnCheckCast += SpellCheckCastFn(spell_dummyfix_shaman_totemic_shatter::CheckCast);
        OnEffectHit += SpellEffectFn(spell_dummyfix_shaman_totemic_shatter::HandleDummy, EFFECT_0, SPELL_EFFECT_DUMMY);
    }
};

constexpr uint32 RAGING_RIPTIDE_HEAL = 278191;

bool HasOwnRiptide(Unit const* unit, ObjectGuid caster)
{
    return unit->GetAuraEffect(SPELL_AURA_PERIODIC_HEAL, SPELLFAMILY_SHAMAN, 0, 0, SHAMAN_RIPTIDE_FLAG2, caster) != nullptr;
}

class spell_dummyfix_shaman_raging_riptide : public AuraScript
{
    PrepareAuraScript(spell_dummyfix_shaman_raging_riptide);

    bool Validate(SpellInfo const* ) override
    {
        return ValidateSpellInfo({ RAGING_RIPTIDE_HEAL });
    }

    bool CheckProc(ProcEventInfo& eventInfo)
    {
        SpellInfo const* info = eventInfo.GetSpellInfo();
        return info && info->HasEffect(SPELL_EFFECT_PERSISTENT_AREA_AURA);
    }

    void HandleProc(AuraEffect const* aurEff, ProcEventInfo& )
    {
        PreventDefaultAction();
        GetTarget()->CastSpell(GetTarget(), RAGING_RIPTIDE_HEAL, true, nullptr, aurEff);
    }

    void Register() override
    {
        DoCheckProc += AuraCheckProcFn(spell_dummyfix_shaman_raging_riptide::CheckProc);
        OnEffectProc += AuraEffectProcFn(spell_dummyfix_shaman_raging_riptide::HandleProc, EFFECT_0, SPELL_AURA_DUMMY);
    }
};

class spell_dummyfix_shaman_raging_riptide_heal : public SpellScript
{
    PrepareSpellScript(spell_dummyfix_shaman_raging_riptide_heal);

    void FilterTargets(std::list<WorldObject*>& targets)
    {
        ObjectGuid const caster = GetCaster()->GetGUID();
        targets.remove_if([caster](WorldObject* object)
        {
            Unit* unit = object->ToUnit();
            return !unit || !HasOwnRiptide(unit, caster);
        });
    }

    void Register() override
    {
        OnObjectAreaTargetSelect += SpellObjectAreaTargetSelectFn(spell_dummyfix_shaman_raging_riptide_heal::FilterTargets,
            EFFECT_0, TARGET_UNIT_SRC_AREA_ALLY);
    }
};

class spell_dummyfix_shaman_rising_winds : public AuraScript
{
    PrepareAuraScript(spell_dummyfix_shaman_rising_winds);

    bool CheckProc(ProcEventInfo& eventInfo)
    {
        SpellInfo const* info = eventInfo.GetSpellInfo();
        Spell const* spell = eventInfo.GetProcSpell();
        return info && spell && spell->GetTriggeredByAuraSpellInfo() && info->SpellFamilyName == SPELLFAMILY_SHAMAN &&
            (info->SpellFamilyFlags[0] & SHAMAN_WINDFURY_ATTACK_FLAG);
    }

    void HandleProc(AuraEffect const* , ProcEventInfo& eventInfo)
    {
        PreventDefaultAction();
        Unit* owner = GetTarget();
        uint32 const windfury = eventInfo.GetProcSpell()->GetTriggeredByAuraSpellInfo()->Id;
        auto const range = owner->GetAppliedAuras().equal_range(windfury);
        for (auto itr = range.first; itr != range.second; ++itr)
            itr->second->GetBase()->ResetProcCooldown();
        Remove();
    }

    void Register() override
    {
        DoCheckProc += AuraCheckProcFn(spell_dummyfix_shaman_rising_winds::CheckProc);
        OnEffectProc += AuraEffectProcFn(spell_dummyfix_shaman_rising_winds::HandleProc, EFFECT_0, SPELL_AURA_DUMMY);
    }
};

constexpr uint32 SHAMAN_FIRE_NOVA_FLAG1 = 0x00040000;
constexpr uint32 PURGE = 370;
constexpr uint32 BY_FIRE_BE_PURGED_ICD = 281348;
constexpr Milliseconds BY_FIRE_BE_PURGED_ENCHANT_ICD = 30s;
constexpr Milliseconds BY_FIRE_BE_PURGED_BLAST_WINDOW = 1s;

class spell_dummyfix_shaman_by_fire_be_purged : public AuraScript
{
    PrepareAuraScript(spell_dummyfix_shaman_by_fire_be_purged);

    Spell const* _blast = nullptr;
    TimePoint _blastAt = TimePoint::min();
    TimePoint _ready = TimePoint::min();

    bool Validate(SpellInfo const* ) override
    {
        return ValidateSpellInfo({ PURGE, BY_FIRE_BE_PURGED_ICD });
    }

    bool CheckProc(ProcEventInfo& eventInfo)
    {
        SpellInfo const* info = eventInfo.GetSpellInfo();
        Spell const* spell = eventInfo.GetProcSpell();
        Unit* target = eventInfo.GetProcTarget();
        if (!info || !spell || !target || !target->IsAlive() || info->SpellFamilyName != SPELLFAMILY_SHAMAN ||
            !(info->SpellFamilyFlags[1] & SHAMAN_FIRE_NOVA_FLAG1))
            return false;
        TimePoint const now = std::chrono::steady_clock::now();
        if (spell == _blast && now - _blastAt < BY_FIRE_BE_PURGED_BLAST_WINDOW)
            return true;
        if (now < _ready)
            return false;
        _blast = spell;
        _blastAt = now;
        Milliseconds icd = BY_FIRE_BE_PURGED_ENCHANT_ICD;
        if (GetId() != 81100)
            if (SpellInfo const* icdInfo = sSpellMgr->GetSpellInfo(BY_FIRE_BE_PURGED_ICD))
                icd = Milliseconds(icdInfo->GetMaxDuration());
        _ready = now + icd;
        return true;
    }

    void HandleProc(AuraEffect const* aurEff, ProcEventInfo& eventInfo)
    {
        PreventDefaultAction();
        GetTarget()->CastSpell(eventInfo.GetProcTarget(), PURGE, true, nullptr, aurEff);
    }

    void Register() override
    {
        DoCheckProc += AuraCheckProcFn(spell_dummyfix_shaman_by_fire_be_purged::CheckProc);
        OnEffectProc += AuraEffectProcFn(spell_dummyfix_shaman_by_fire_be_purged::HandleProc, EFFECT_0, SPELL_AURA_DUMMY);
    }
};

constexpr uint32 SHAMAN_LAVA_BURST_FLAG1 = 0x00001000;
constexpr uint32 SHAMAN_ELEMENTAL_BLAST_FLAG2 = 0x20000000;
constexpr std::array<uint32, 3> ELEMENTAL_LORD_BUFFS = { 276579, 276580, 276581 };

class spell_dummyfix_shaman_elemental_lord : public AuraScript
{
    PrepareAuraScript(spell_dummyfix_shaman_elemental_lord);

    bool Validate(SpellInfo const* ) override
    {
        return ValidateSpellInfo({ ELEMENTAL_LORD_BUFFS[0], ELEMENTAL_LORD_BUFFS[1], ELEMENTAL_LORD_BUFFS[2] });
    }

    bool CheckProc(ProcEventInfo& eventInfo)
    {
        SpellInfo const* info = eventInfo.GetSpellInfo();
        DamageInfo* damage = eventInfo.GetDamageInfo();
        return info && damage && damage->GetDamage() && info->SpellFamilyName == SPELLFAMILY_SHAMAN &&
            ((info->SpellFamilyFlags[1] & SHAMAN_LAVA_BURST_FLAG1) || (info->SpellFamilyFlags[2] & SHAMAN_ELEMENTAL_BLAST_FLAG2));
    }

    void HandleProc(AuraEffect const* aurEff, ProcEventInfo& )
    {
        PreventDefaultAction();
        uint32 const buff = ELEMENTAL_LORD_BUFFS[urand(0, ELEMENTAL_LORD_BUFFS.size() - 1)];
        GetTarget()->CastSpell(GetTarget(), buff, true, nullptr, aurEff);
    }

    void PreventSecond(AuraEffect const* , ProcEventInfo& )
    {
        PreventDefaultAction();
    }

    void Register() override
    {
        DoCheckProc += AuraCheckProcFn(spell_dummyfix_shaman_elemental_lord::CheckProc);
        OnEffectProc += AuraEffectProcFn(spell_dummyfix_shaman_elemental_lord::HandleProc, EFFECT_0, SPELL_AURA_DUMMY);
        OnEffectProc += AuraEffectProcFn(spell_dummyfix_shaman_elemental_lord::PreventSecond, EFFECT_1, SPELL_AURA_DUMMY);
    }
};

constexpr uint32 SHAMAN_LESSER_HEALING_WAVE_FLAG = 0x00000080;
constexpr uint32 FRUGAL_DISPOSITION_HOT = 282095;
constexpr uint32 INDULGENT_DISPOSITION = 282096;

class spell_dummyfix_shaman_frugal_disposition : public AuraScript
{
    PrepareAuraScript(spell_dummyfix_shaman_frugal_disposition);

    bool Validate(SpellInfo const* ) override
    {
        return ValidateSpellInfo({ FRUGAL_DISPOSITION_HOT, INDULGENT_DISPOSITION });
    }

    bool CheckProc(ProcEventInfo& eventInfo)
    {
        SpellInfo const* info = eventInfo.GetSpellInfo();
        HealInfo* heal = eventInfo.GetHealInfo();
        return info && heal && heal->GetHeal() && eventInfo.GetProcTarget() && info->SpellFamilyName == SPELLFAMILY_SHAMAN &&
            (info->SpellFamilyFlags[0] & SHAMAN_LESSER_HEALING_WAVE_FLAG);
    }

    void HandleProc(AuraEffect const* aurEff, ProcEventInfo& eventInfo)
    {
        PreventDefaultAction();
        Unit* healer = GetTarget();
        Unit* target = eventInfo.GetProcTarget();
        HealInfo* heal = eventInfo.GetHealInfo();
        uint32 const overheal = heal->GetHeal() - heal->GetEffectiveHeal();
        if (!overheal)
        {
            if (target->GetHealth() < target->GetMaxHealth())
                healer->CastSpell(healer, INDULGENT_DISPOSITION, true, nullptr, aurEff);
            return;
        }
        SpellInfo const* hot = sSpellMgr->GetSpellInfo(FRUGAL_DISPOSITION_HOT);
        int32 const ticks = hot->Effects[EFFECT_0].Amplitude ? hot->GetMaxDuration() / hot->Effects[EFFECT_0].Amplitude : 1;
        int32 const share = GetId() == 81513 ? 50 : 75;
        int32 amount = int32(CalculatePct(overheal, share)) / std::max(ticks, 1);
        if (amount <= 0)
            return;
        healer->CastCustomSpell(target, FRUGAL_DISPOSITION_HOT, &amount, nullptr, nullptr, true, nullptr, aurEff);
    }

    void Register() override
    {
        DoCheckProc += AuraCheckProcFn(spell_dummyfix_shaman_frugal_disposition::CheckProc);
        OnEffectProc += AuraEffectProcFn(spell_dummyfix_shaman_frugal_disposition::HandleProc, EFFECT_0, SPELL_AURA_DUMMY);
    }
};

constexpr uint32 SHAMAN_FERAL_SPIRIT_FLAG1 = 0x00010000;
constexpr uint32 SHAMAN_STORMSTRIKE_FLAG1 = 0x00000010;
constexpr uint32 SHAMAN_LAVA_LASH_FLAG2 = 0x00000004;
constexpr std::array<uint32, 2> PACK_ALPHA_SUMMONS = { 51533, 285959 };

struct PackAlphaRule
{
    uint32 Aura;
    uint32 Buff;
    int32 ExtendMs;
    int32 CooldownMs;
};

constexpr std::array<PackAlphaRule, 2> PACK_ALPHAS = {{
    { 281402, 281404, 1000, 3000 },
    { 81139, 954221, 1500, 5000 },
}};

PackAlphaRule const* PackAlphaByAura(uint32 id)
{
    for (PackAlphaRule const& rule : PACK_ALPHAS)
        if (rule.Aura == id)
            return &rule;
    return nullptr;
}

class spell_dummyfix_shaman_pack_alpha : public AuraScript
{
    PrepareAuraScript(spell_dummyfix_shaman_pack_alpha);

    bool Validate(SpellInfo const* info) override
    {
        PackAlphaRule const* rule = PackAlphaByAura(info->Id);
        return rule && ValidateSpellInfo({ rule->Buff });
    }

    static bool IsSummon(SpellInfo const* info)
    {
        return info->SpellFamilyName == SPELLFAMILY_SHAMAN && (info->SpellFamilyFlags[1] & SHAMAN_FERAL_SPIRIT_FLAG1) &&
            info->HasEffect(SPELL_EFFECT_SUMMON);
    }

    static bool IsStrike(SpellInfo const* info)
    {
        return info->SpellFamilyName == SPELLFAMILY_SHAMAN &&
            ((info->SpellFamilyFlags[1] & SHAMAN_STORMSTRIKE_FLAG1) || (info->SpellFamilyFlags[2] & SHAMAN_LAVA_LASH_FLAG2));
    }

    bool CheckProc(ProcEventInfo& eventInfo)
    {
        SpellInfo const* info = eventInfo.GetSpellInfo();
        if (!info)
            return false;
        if (eventInfo.GetSpellPhaseMask() & PROC_SPELL_PHASE_CAST)
            return IsSummon(info);
        DamageInfo* damage = eventInfo.GetDamageInfo();
        return damage && damage->GetDamage() && IsStrike(info);
    }

    void HandleProc(AuraEffect const* aurEff, ProcEventInfo& eventInfo)
    {
        PreventDefaultAction();
        PackAlphaRule const* rule = PackAlphaByAura(GetId());
        Unit* owner = GetTarget();
        if (!rule)
            return;
        if (eventInfo.GetSpellPhaseMask() & PROC_SPELL_PHASE_CAST)
        {
            owner->CastSpell(owner, rule->Buff, true, nullptr, aurEff);
            return;
        }
        uint32 const now = GameTime::GetGameTimeMS().count();
        if (now == _lastStrikeMs)
            return;
        _lastStrikeMs = now;
        if (Aura* buff = owner->GetAura(rule->Buff, owner->GetGUID()))
        {
            buff->SetMaxDuration(buff->GetMaxDuration() + rule->ExtendMs);
            buff->SetDuration(buff->GetDuration() + rule->ExtendMs);
        }
        if (Player* player = owner->ToPlayer())
            for (uint32 summon : PACK_ALPHA_SUMMONS)
                player->ModifySpellCooldown(summon, -rule->CooldownMs);
    }

    void Register() override
    {
        DoCheckProc += AuraCheckProcFn(spell_dummyfix_shaman_pack_alpha::CheckProc);
        OnEffectProc += AuraEffectProcFn(spell_dummyfix_shaman_pack_alpha::HandleProc, EFFECT_0, SPELL_AURA_DUMMY);
    }

    uint32 _lastStrikeMs = 0;
};

constexpr uint32 SACRED_RITES = 81395;
constexpr uint32 PALADIN_CONSECRATION_FLAG = 0x00000020;

int32 SacredRitesPct(Unit* attacker, Unit* target, SpellInfo const* info)
{
    if (!attacker || !target || !info || !(info->GetSchoolMask() & SPELL_SCHOOL_MASK_HOLY))
        return 0;
    AuraEffect const* rites = attacker->GetAuraEffect(SACRED_RITES, EFFECT_0);
    if (!rites)
        return 0;
    return target->GetAuraEffect(SPELL_AURA_PERIODIC_DAMAGE, SPELLFAMILY_PALADIN, PALADIN_CONSECRATION_FLAG, 0, 0,
        attacker->GetGUID()) ? rites->GetAmount() : 0;
}

constexpr uint32 DOWN_FOR_THE_COUNT = 81263;
constexpr std::array<uint32, 2> KILLING_SPREE_HITS = { 57841, 57842 };

bool BleedingOrPoisoned(Unit* target)
{
    if (target->HasAuraWithMechanic(1 << MECHANIC_BLEED))
        return true;
    for (auto const& [id, app] : target->GetAppliedAuras())
        if (app->GetBase()->GetSpellInfo()->Dispel == DISPEL_POISON)
            return true;
    return false;
}

int32 DownForTheCountPct(Unit* attacker, Unit* target, SpellInfo const* info)
{
    if (!attacker || !target || !info ||
        std::find(KILLING_SPREE_HITS.begin(), KILLING_SPREE_HITS.end(), info->Id) == KILLING_SPREE_HITS.end())
        return 0;
    AuraEffect const* count = attacker->GetAuraEffect(DOWN_FOR_THE_COUNT, EFFECT_0);
    return count && BleedingOrPoisoned(target) ? count->GetAmount() : 0;
}

constexpr uint32 SHAMAN_LIGHTNING_BOLT_FLAG = 0x1;
constexpr uint32 SHAMAN_CHAIN_LIGHTNING_FLAG = 0x2;
constexpr uint32 OVERLOAD_LIGHTNING_BOLT = 45284;
constexpr uint32 OVERLOAD_CHAIN_LIGHTNING = 45297;

class spell_dummyfix_shaman_lightning_mastery : public AuraScript
{
    PrepareAuraScript(spell_dummyfix_shaman_lightning_mastery);

    bool Validate(SpellInfo const* ) override
    {
        return ValidateSpellInfo({ OVERLOAD_LIGHTNING_BOLT, OVERLOAD_CHAIN_LIGHTNING });
    }

    bool CheckProc(ProcEventInfo& eventInfo)
    {
        SpellInfo const* info = eventInfo.GetSpellInfo();
        DamageInfo* damage = eventInfo.GetDamageInfo();
        return info && damage && damage->GetDamage() >= 2 && eventInfo.GetActionTarget() &&
            info->SpellFamilyName == SPELLFAMILY_SHAMAN &&
            (info->SpellFamilyFlags[0] & (SHAMAN_LIGHTNING_BOLT_FLAG | SHAMAN_CHAIN_LIGHTNING_FLAG));
    }

    void HandleProc(AuraEffect const* aurEff, ProcEventInfo& eventInfo)
    {
        PreventDefaultAction();
        SpellInfo const* info = eventInfo.GetSpellInfo();
        uint32 const spell = (info->SpellFamilyFlags[0] & SHAMAN_CHAIN_LIGHTNING_FLAG) ? OVERLOAD_CHAIN_LIGHTNING :
            OVERLOAD_LIGHTNING_BOLT;
        int32 const damage = int32(eventInfo.GetDamageInfo()->GetDamage() / 2);
        GetTarget()->CastCustomSpell(spell, SPELLVALUE_BASE_POINT0, damage, eventInfo.GetActionTarget(), true, nullptr,
            aurEff);
    }

    void Register() override
    {
        DoCheckProc += AuraCheckProcFn(spell_dummyfix_shaman_lightning_mastery::CheckProc);
        OnEffectProc += AuraEffectProcFn(spell_dummyfix_shaman_lightning_mastery::HandleProc, EFFECT_0, SPELL_AURA_DUMMY);
    }
};

constexpr uint32 WEAPON_COMMAND_BUFF = 954058;

class spell_dummyfix_shaman_weapon_command : public AuraScript
{
    PrepareAuraScript(spell_dummyfix_shaman_weapon_command);

    bool Validate(SpellInfo const* ) override
    {
        return ValidateSpellInfo({ WEAPON_COMMAND_BUFF });
    }

    static bool Qualifies(Player* player)
    {
        ShapeshiftForm const form = player->GetShapeshiftForm();
        if (form == FORM_CAT || form == FORM_BEAR || form == FORM_DIREBEAR || player->CanTitanGrip())
            return false;
        Item* main = player->GetItemByPos(INVENTORY_SLOT_BAG_0, EQUIPMENT_SLOT_MAINHAND);
        Item* off = player->GetItemByPos(INVENTORY_SLOT_BAG_0, EQUIPMENT_SLOT_OFFHAND);
        return main && main->GetTemplate()->InventoryType == INVTYPE_2HWEAPON && !off;
    }

    void Sync(AuraEffect const* aurEff)
    {
        Player* player = GetTarget()->ToPlayer();
        if (!player)
            return;
        bool const has = player->HasAura(WEAPON_COMMAND_BUFF, player->GetGUID());
        if (Qualifies(player) && !has)
            player->CastSpell(player, WEAPON_COMMAND_BUFF, true, nullptr, aurEff);
        else if (!Qualifies(player) && has)
            player->RemoveAurasDueToSpell(WEAPON_COMMAND_BUFF, player->GetGUID());
    }

    void HandlePeriodic(AuraEffect const* aurEff)
    {
        Sync(aurEff);
    }

    void HandleApply(AuraEffect const* aurEff, AuraEffectHandleModes )
    {
        Sync(aurEff);
    }

    void HandleRemove(AuraEffect const* , AuraEffectHandleModes )
    {
        GetTarget()->RemoveAurasDueToSpell(WEAPON_COMMAND_BUFF, GetTarget()->GetGUID());
    }

    void Register() override
    {
        OnEffectPeriodic += AuraEffectPeriodicFn(spell_dummyfix_shaman_weapon_command::HandlePeriodic, EFFECT_2,
            SPELL_AURA_PERIODIC_DUMMY);
        AfterEffectApply += AuraEffectApplyFn(spell_dummyfix_shaman_weapon_command::HandleApply, EFFECT_2,
            SPELL_AURA_PERIODIC_DUMMY, AURA_EFFECT_HANDLE_REAL);
        AfterEffectRemove += AuraEffectRemoveFn(spell_dummyfix_shaman_weapon_command::HandleRemove, EFFECT_2,
            SPELL_AURA_PERIODIC_DUMMY, AURA_EFFECT_HANDLE_REAL);
    }
};

constexpr uint32 TIDECALLERS_BOON_PASSIVE = 271821;
constexpr uint32 TIDECALLERS_BOON_DEBUFF = 271814;
constexpr uint8 TIDECALLERS_BOON_STACKS = 3;

class spell_dummyfix_shaman_tidecallers_boon : public AuraScript
{
    PrepareAuraScript(spell_dummyfix_shaman_tidecallers_boon);

    bool Validate(SpellInfo const* ) override
    {
        return ValidateSpellInfo({ TIDECALLERS_BOON_PASSIVE, TIDECALLERS_BOON_DEBUFF });
    }

    void HandleApply(AuraEffect const* aurEff, AuraEffectHandleModes )
    {
        GetTarget()->CastSpell(GetTarget(), TIDECALLERS_BOON_PASSIVE, true, nullptr, aurEff);
    }

    void HandleRemove(AuraEffect const* , AuraEffectHandleModes )
    {
        GetTarget()->RemoveAurasDueToSpell(TIDECALLERS_BOON_PASSIVE, GetTarget()->GetGUID());
    }

    void HandleProc(AuraEffect const* aurEff, ProcEventInfo& eventInfo)
    {
        PreventDefaultAction();
        Unit* target = eventInfo.GetProcTarget();
        if (!target)
            return;
        GetTarget()->CastSpell(target, TIDECALLERS_BOON_DEBUFF, true, nullptr, aurEff);
        if (Aura* boon = target->GetAura(TIDECALLERS_BOON_DEBUFF, GetTarget()->GetGUID()))
            boon->SetStackAmount(TIDECALLERS_BOON_STACKS);
    }

    void Register() override
    {
        OnEffectProc += AuraEffectProcFn(spell_dummyfix_shaman_tidecallers_boon::HandleProc, EFFECT_0, SPELL_AURA_DUMMY);
        AfterEffectApply += AuraEffectApplyFn(spell_dummyfix_shaman_tidecallers_boon::HandleApply, EFFECT_0,
            SPELL_AURA_DUMMY, AURA_EFFECT_HANDLE_REAL);
        AfterEffectRemove += AuraEffectRemoveFn(spell_dummyfix_shaman_tidecallers_boon::HandleRemove, EFFECT_0,
            SPELL_AURA_DUMMY, AURA_EFFECT_HANDLE_REAL);
    }
};

constexpr std::array<uint32, 2> STORMSTRIKE_CHAINS = { 17364, 1117364 };

class spell_dummyfix_shaman_converging_elements : public AuraScript
{
    PrepareAuraScript(spell_dummyfix_shaman_converging_elements);

    bool CheckProc(ProcEventInfo& eventInfo)
    {
        SpellInfo const* info = eventInfo.GetSpellInfo();
        return info && info->SpellFamilyName == SPELLFAMILY_SHAMAN && (info->SpellFamilyFlags[1] & SHAMAN_STORMSTRIKE_FLAG1);
    }

    void HandleProc(AuraEffect const* , ProcEventInfo& )
    {
        PreventDefaultAction();
        if (Player* player = GetTarget()->ToPlayer())
            for (uint32 first : STORMSTRIKE_CHAINS)
                for (SpellInfo const* rank = sSpellMgr->GetSpellInfo(first); rank; rank = rank->GetNextRankSpell())
                    if (player->HasSpellCooldown(rank->Id))
                        player->RemoveSpellCooldown(rank->Id, true);
        Remove();
    }

    void PreventSecond(AuraEffect const* , ProcEventInfo& )
    {
        PreventDefaultAction();
    }

    void Register() override
    {
        DoCheckProc += AuraCheckProcFn(spell_dummyfix_shaman_converging_elements::CheckProc);
        OnEffectProc += AuraEffectProcFn(spell_dummyfix_shaman_converging_elements::HandleProc, EFFECT_0,
            SPELL_AURA_PROC_TRIGGER_SPELL);
        OnEffectProc += AuraEffectProcFn(spell_dummyfix_shaman_converging_elements::PreventSecond, EFFECT_1,
            SPELL_AURA_PROC_TRIGGER_SPELL);
    }
};

constexpr uint32 SHAMAN_FLAME_SHOCK_FLAG = 0x10000000;
constexpr int32 FLAME_NOVA_EXPLOSION_PCT = -50;
constexpr float FLAME_NOVA_SEARCH_YARDS = 40.0f;
thread_local bool FlameNovaExploding = false;

class spell_dummyfix_shaman_flame_nova : public AuraScript
{
    PrepareAuraScript(spell_dummyfix_shaman_flame_nova);

    Spell const* _blast = nullptr;
    uint32 _blastMs = 0;

    bool CheckProc(ProcEventInfo& eventInfo)
    {
        SpellInfo const* info = eventInfo.GetSpellInfo();
        Spell const* spell = eventInfo.GetProcSpell();
        uint32 const now = uint32(GameTime::GetGameTimeMS().count());
        if (FlameNovaExploding || !info || !spell || (spell == _blast && now == _blastMs) ||
            info->SpellFamilyName != SPELLFAMILY_SHAMAN || !(info->SpellFamilyFlags[1] & SHAMAN_FIRE_NOVA_FLAG1) ||
            !info->HasEffect(SPELL_EFFECT_SCHOOL_DAMAGE))
            return false;
        _blast = spell;
        _blastMs = now;
        return true;
    }

    void HandleProc(AuraEffect const* aurEff, ProcEventInfo& eventInfo)
    {
        PreventDefaultAction();
        Unit* owner = GetTarget();
        uint32 const blast = eventInfo.GetSpellInfo()->Id;
        uint32 const limit = GetSpellInfo()->MaxAffectedTargets ? GetSpellInfo()->MaxAffectedTargets : 4;
        std::list<Unit*> enemies;
        Acore::AnyUnfriendlyUnitInObjectRangeCheck check(owner, owner, FLAME_NOVA_SEARCH_YARDS);
        Acore::UnitListSearcher<Acore::AnyUnfriendlyUnitInObjectRangeCheck> searcher(owner, enemies, check);
        Cell::VisitObjects(owner, searcher, FLAME_NOVA_SEARCH_YARDS);
        ObjectGuid const ownerGuid = owner->GetGUID();
        enemies.remove_if([ownerGuid](Unit* unit)
        {
            return !unit->IsAlive() || !unit->GetAuraEffect(SPELL_AURA_PERIODIC_DAMAGE, SPELLFAMILY_SHAMAN,
                SHAMAN_FLAME_SHOCK_FLAG, 0, 0, ownerGuid);
        });
        if (enemies.size() > limit)
            Acore::Containers::RandomResize(enemies, limit);
        FlameNovaExploding = true;
        for (Unit* enemy : enemies)
            owner->CastSpell(enemy, blast, true, nullptr, aurEff);
        FlameNovaExploding = false;
    }

    void Register() override
    {
        DoCheckProc += AuraCheckProcFn(spell_dummyfix_shaman_flame_nova::CheckProc);
        OnEffectProc += AuraEffectProcFn(spell_dummyfix_shaman_flame_nova::HandleProc, EFFECT_0, SPELL_AURA_DUMMY);
    }
};

struct ImbueStrike
{
    uint32 Spell;
    WeaponAttackType Hand;
    char const* Imbue;
    bool PrimaryOnly;
};

constexpr std::array<ImbueStrike, 14> IMBUE_STRIKES = {{
    { 273561, OFF_ATTACK, "Frostbrand", false },
    { 860103, OFF_ATTACK, "Frostbrand", false },
    { 1572175, OFF_ATTACK, "Frostbrand", false },
    { 271579, BASE_ATTACK, "Flametongue", true },
    { 417699, BASE_ATTACK, "Flametongue", true },
    { 276116, OFF_ATTACK, "Rockbiter", false },
    { 984202, OFF_ATTACK, "Rockbiter", false },
    { 1576497, OFF_ATTACK, "Rockbiter", false },
    { 907120, OFF_ATTACK, "Windfury", false },
    { 907870, OFF_ATTACK, "Windfury", false },
    { 907080, OFF_ATTACK, "Windfury", false },
    { 907862, OFF_ATTACK, "Windfury", false },
    { 907100, OFF_ATTACK, "Windfury", false },
    { 300452, OFF_ATTACK, "Flametongue", false },
}};

ImbueStrike const* ImbueStrikeBySpell(uint32 id)
{
    for (ImbueStrike const& rule : IMBUE_STRIKES)
        if (rule.Spell == id)
            return &rule;
    return nullptr;
}

bool HasImbue(Item const* weapon, char const* imbue)
{
    if (!weapon)
        return false;
    uint32 const enchant = weapon->GetEnchantmentId(TEMP_ENCHANTMENT_SLOT);
    SpellItemEnchantmentEntry const* entry = enchant ? sSpellItemEnchantmentStore.LookupEntry(enchant) : nullptr;
    return entry && entry->description[0] && std::strstr(entry->description[0], imbue);
}

class spell_dummyfix_shaman_imbue_strike : public SpellScript
{
    PrepareSpellScript(spell_dummyfix_shaman_imbue_strike);

    bool Load() override
    {
        return GetCaster()->IsPlayer() && ImbueStrikeBySpell(GetSpellInfo()->Id);
    }

    void HandleHit()
    {
        ImbueStrike const* rule = ImbueStrikeBySpell(GetSpellInfo()->Id);
        Player* caster = GetCaster()->ToPlayer();
        int32 damage = GetHitDamage();
        if (!rule || damage <= 0 || (rule->PrimaryOnly && GetHitUnit() != GetExplTargetUnit()))
            return;
        if (!HasImbue(caster->GetWeaponForAttack(rule->Hand, true), rule->Imbue))
            return;
        AddPct(damage, GetSpellInfo()->Effects[EFFECT_1].CalcValue(caster));
        SetHitDamage(damage);
    }

    void Register() override
    {
        OnHit += SpellHitFn(spell_dummyfix_shaman_imbue_strike::HandleHit);
    }
};

struct LearnWith
{
    uint32 Aura;
    uint32 Required;
    uint32 Taught;
};

constexpr std::array<LearnWith, 3> LEARN_WITH = {{
    { 983523, 61295, 983524 },
    { 417700, 60103, 417699 },
    { 982650, 1680, 982651 },
}};

LearnWith const* LearnWithByAura(uint32 id)
{
    for (LearnWith const& rule : LEARN_WITH)
        if (rule.Aura == id)
            return &rule;
    return nullptr;
}

bool KnowsAnyRank(Player const* player, uint32 spell)
{
    SpellInfo const* required = sSpellMgr->GetSpellInfo(spell);
    if (!required || !required->SpellName[0])
        return false;
    for (auto const& [id, known] : player->GetSpellMap())
    {
        if (known->State == PLAYERSPELL_REMOVED || !known->IsInSpec(player->GetActiveSpec()))
            continue;
        SpellInfo const* info = sSpellMgr->GetSpellInfo(id);
        if (info && info->SpellName[0] && !std::strcmp(info->SpellName[0], required->SpellName[0]))
            return true;
    }
    return false;
}

class spell_dummyfix_shaman_learn_with : public AuraScript
{
    PrepareAuraScript(spell_dummyfix_shaman_learn_with);

    bool _taught = false;

    bool Validate(SpellInfo const* info) override
    {
        LearnWith const* rule = LearnWithByAura(info->Id);
        return rule && ValidateSpellInfo({ rule->Required, rule->Taught });
    }

    void HandleApply(AuraEffect const* , AuraEffectHandleModes )
    {
        LearnWith const* rule = LearnWithByAura(GetId());
        Player* player = GetTarget()->ToPlayer();
        if (!rule || !player || player->HasSpell(rule->Taught) || !KnowsAnyRank(player, rule->Required))
            return;
        player->learnSpell(rule->Taught, true);
        _taught = true;
    }

    void HandleRemove(AuraEffect const* , AuraEffectHandleModes )
    {
        LearnWith const* rule = LearnWithByAura(GetId());
        Player* player = GetTarget()->ToPlayer();
        if (!rule || !player || !_taught)
            return;
        _taught = false;
        player->removeSpell(rule->Taught, SPEC_MASK_ALL, true);
    }

    void Register() override
    {
        AfterEffectApply += AuraEffectApplyFn(spell_dummyfix_shaman_learn_with::HandleApply, EFFECT_0, SPELL_AURA_DUMMY,
            AURA_EFFECT_HANDLE_REAL);
        AfterEffectRemove += AuraEffectRemoveFn(spell_dummyfix_shaman_learn_with::HandleRemove, EFFECT_0, SPELL_AURA_DUMMY,
            AURA_EFFECT_HANDLE_REAL);
    }
};

constexpr std::array<uint32, 2> TOTEM_MASTER_FIRE = { 81445, 281999 };

class dummyfix_shaman_creature_hooks : public AllCreatureScript
{
public:
    dummyfix_shaman_creature_hooks() : AllCreatureScript("dummyfix_shaman_creature_hooks") { }

    void OnCreatureAddWorld(Creature* creature) override
    {
        if (!creature->IsTotem())
            return;
        Totem* totem = creature->ToTotem();
        if (!totem || !totem->m_Properties || totem->m_Properties->Slot != SUMMON_SLOT_TOTEM_FIRE)
            return;
        totem->m_Events.AddEventAtOffset([totem]()
        {
            Unit* owner = totem->GetSummonerUnit();
            if (!owner)
                return;
            for (uint32 id : TOTEM_MASTER_FIRE)
                if (AuraEffect const* master = owner->GetAuraEffect(id, EFFECT_0))
                {
                    uint32 const health = std::max<uint32>(1, CalculatePct(owner->GetMaxHealth(), master->GetAmount()));
                    totem->SetCreateHealth(health);
                    totem->SetMaxHealth(health);
                    totem->SetHealth(health);
                    return;
                }
        }, 1ms);
    }
};

constexpr uint32 SHAMAN_EARTH_SHOCK_FLAG = 0x00100000;
constexpr uint32 SHAMAN_FROST_SHOCK_FLAG = 0x80000000;

class spell_dummyfix_shaman_echoing_power : public AuraScript
{
    PrepareAuraScript(spell_dummyfix_shaman_echoing_power);

    bool Validate(SpellInfo const* ) override
    {
        return ValidateSpellInfo({ 285511, 285512, 285514 });
    }

    static uint32 Boon(SpellInfo const* info)
    {
        if (!info || info->SpellFamilyName != SPELLFAMILY_SHAMAN)
            return 0;
        if (info->SpellFamilyFlags[0] & SHAMAN_EARTH_SHOCK_FLAG)
            return 285512;
        if (info->SpellFamilyFlags[0] & SHAMAN_FROST_SHOCK_FLAG)
            return 285511;
        if (info->SpellFamilyFlags[0] & SHAMAN_FLAME_SHOCK_FLAG)
            return 285514;
        return 0;
    }

    bool CheckProc(ProcEventInfo& eventInfo)
    {
        return Boon(eventInfo.GetSpellInfo()) != 0;
    }

    void HandleBoon(AuraEffect const* aurEff, ProcEventInfo& eventInfo)
    {
        PreventDefaultAction();
        GetTarget()->CastSpell(GetTarget(), Boon(eventInfo.GetSpellInfo()), true, nullptr, aurEff);
    }

    void HandleDebuff(AuraEffect const* , ProcEventInfo& eventInfo)
    {
        if (Boon(eventInfo.GetSpellInfo()) != 285511)
            PreventDefaultAction();
    }

    void Register() override
    {
        DoCheckProc += AuraCheckProcFn(spell_dummyfix_shaman_echoing_power::CheckProc);
        OnEffectProc += AuraEffectProcFn(spell_dummyfix_shaman_echoing_power::HandleBoon, EFFECT_1, SPELL_AURA_DUMMY);
        OnEffectProc += AuraEffectProcFn(spell_dummyfix_shaman_echoing_power::HandleDebuff, EFFECT_2,
            SPELL_AURA_PROC_TRIGGER_SPELL);
    }
};

constexpr std::array<uint32, 10> RIPTIDES = { 61295, 61310, 300910, 300911, 300912, 300913, 300914, 61299, 61300, 61301 };

class spell_dummyfix_shaman_low_tide : public SpellScript
{
    PrepareSpellScript(spell_dummyfix_shaman_low_tide);

    void HandleMarker(SpellEffIndex effIndex)
    {
        PreventHitDefaultEffect(effIndex);
        Player* caster = GetCaster()->ToPlayer();
        Unit* target = GetHitUnit();
        if (!caster || !target)
            return;
        SpellInfo const* best = nullptr;
        for (uint32 id : RIPTIDES)
            if (caster->HasSpell(id))
                if (SpellInfo const* info = sSpellMgr->GetSpellInfo(id))
                    if (!best || info->SpellLevel > best->SpellLevel)
                        best = info;
        if (best)
            caster->CastSpell(target, best->Id, true);
    }

    void Register() override
    {
        OnEffectHitTarget += SpellEffectFn(spell_dummyfix_shaman_low_tide::HandleMarker, EFFECT_1, SPELL_EFFECT_APPLY_AURA);
    }
};

constexpr uint32 MAELSTROM_WEAPON = 53817;

class spell_dummyfix_shaman_mechanical_arm : public SpellScript
{
    PrepareSpellScript(spell_dummyfix_shaman_mechanical_arm);

    bool Validate(SpellInfo const* ) override
    {
        return ValidateSpellInfo({ MAELSTROM_WEAPON });
    }

    void HandleMarker(SpellEffIndex effIndex)
    {
        PreventHitDefaultEffect(effIndex);
        GetCaster()->CastSpell(GetCaster(), MAELSTROM_WEAPON, true);
    }

    void Register() override
    {
        OnEffectHitTarget += SpellEffectFn(spell_dummyfix_shaman_mechanical_arm::HandleMarker, EFFECT_0,
            SPELL_EFFECT_APPLY_AURA);
    }
};

constexpr std::array<uint32, 5> FLURRY_TALENT = { 1116284, 1116283, 1116282, 1116281, 1116256 };

class spell_dummyfix_shaman_electric_surge : public AuraScript
{
    PrepareAuraScript(spell_dummyfix_shaman_electric_surge);

    bool CheckProc(ProcEventInfo& eventInfo)
    {
        SpellInfo const* info = eventInfo.GetSpellInfo();
        return info && info->SpellFamilyName == SPELLFAMILY_SHAMAN &&
            (info->SpellFamilyFlags[0] & (SHAMAN_LIGHTNING_BOLT_FLAG | SHAMAN_CHAIN_LIGHTNING_FLAG));
    }

    void HandleProc(AuraEffect const* aurEff, ProcEventInfo& )
    {
        PreventDefaultAction();
        Player* player = GetTarget()->ToPlayer();
        if (!player)
            return;
        for (uint32 rank : FLURRY_TALENT)
            if (player->HasSpell(rank))
            {
                if (SpellInfo const* talent = sSpellMgr->GetSpellInfo(rank))
                    if (uint32 const buff = talent->Effects[EFFECT_0].TriggerSpell)
                        player->CastSpell(player, buff, true, nullptr, aurEff);
                return;
            }
    }

    void Register() override
    {
        DoCheckProc += AuraCheckProcFn(spell_dummyfix_shaman_electric_surge::CheckProc);
        OnEffectProc += AuraEffectProcFn(spell_dummyfix_shaman_electric_surge::HandleProc, EFFECT_0, SPELL_AURA_DUMMY);
    }
};

constexpr uint32 EXPLODING_STORM = 978613;
constexpr uint32 FIRE_WATCH_BUFF = 978615;
constexpr uint32 HUNTER_TRAP_EFFECT_FLAG0 = 0x00000004;
constexpr uint32 HUNTER_IMMOLATION_TRAP_FLAG2 = 0x00020000;

class spell_dummyfix_shaman_fire_watch : public AuraScript
{
    PrepareAuraScript(spell_dummyfix_shaman_fire_watch);

    bool Validate(SpellInfo const* ) override
    {
        return ValidateSpellInfo({ EXPLODING_STORM, FIRE_WATCH_BUFF });
    }

    static bool IsTrap(SpellInfo const* info)
    {
        return info->SpellFamilyName == SPELLFAMILY_HUNTER &&
            ((info->SpellFamilyFlags[0] & HUNTER_TRAP_EFFECT_FLAG0) || (info->SpellFamilyFlags[2] & HUNTER_IMMOLATION_TRAP_FLAG2));
    }

    static bool IsStrike(SpellInfo const* info)
    {
        return info->SpellFamilyName == SPELLFAMILY_SHAMAN &&
            ((info->SpellFamilyFlags[1] & SHAMAN_STORMSTRIKE_FLAG1) || (info->SpellFamilyFlags[2] & SHAMAN_LAVA_LASH_FLAG2));
    }

    static bool IsFlametongueAttack(SpellInfo const* info)
    {
        return info->SpellName[0] && !std::strcmp(info->SpellName[0], "Flametongue Attack");
    }

    bool CheckProc(ProcEventInfo& eventInfo)
    {
        SpellInfo const* info = eventInfo.GetSpellInfo();
        DamageInfo* damage = eventInfo.GetDamageInfo();
        return info && damage && damage->GetDamage() && (IsTrap(info) || IsStrike(info) || IsFlametongueAttack(info));
    }

    void HandleTrapCooldown(AuraEffect const* , ProcEventInfo& eventInfo)
    {
        if (!IsFlametongueAttack(eventInfo.GetSpellInfo()))
            PreventDefaultAction();
    }

    void HandleBuffs(AuraEffect const* aurEff, ProcEventInfo& eventInfo)
    {
        PreventDefaultAction();
        SpellInfo const* info = eventInfo.GetSpellInfo();
        if (IsStrike(info))
            GetTarget()->CastSpell(GetTarget(), EXPLODING_STORM, true, nullptr, aurEff);
        else if (IsTrap(info))
            GetTarget()->CastSpell(GetTarget(), FIRE_WATCH_BUFF, true, nullptr, aurEff);
    }

    void Register() override
    {
        DoCheckProc += AuraCheckProcFn(spell_dummyfix_shaman_fire_watch::CheckProc);
        OnEffectProc += AuraEffectProcFn(spell_dummyfix_shaman_fire_watch::HandleTrapCooldown, EFFECT_0,
            SPELL_AURA_PROC_TRIGGER_SPELL);
        OnEffectProc += AuraEffectProcFn(spell_dummyfix_shaman_fire_watch::HandleBuffs, EFFECT_1, SPELL_AURA_DUMMY);
    }
};

constexpr uint32 TIDAL_FORCE_STACKS = 1155166;

class spell_dummyfix_shaman_tidal_force : public AuraScript
{
    PrepareAuraScript(spell_dummyfix_shaman_tidal_force);

    bool Validate(SpellInfo const* ) override
    {
        return ValidateSpellInfo({ TIDAL_FORCE_STACKS });
    }

    void HandleApply(AuraEffect const* aurEff, AuraEffectHandleModes )
    {
        Unit* target = GetTarget();
        target->CastSpell(target, TIDAL_FORCE_STACKS, true, nullptr, aurEff);
        if (Aura* stacks = target->GetAura(TIDAL_FORCE_STACKS, target->GetGUID()))
            stacks->SetStackAmount(stacks->GetSpellInfo()->StackAmount);
    }

    void Register() override
    {
        AfterEffectApply += AuraEffectApplyFn(spell_dummyfix_shaman_tidal_force::HandleApply, EFFECT_0, SPELL_AURA_DUMMY,
            AURA_EFFECT_HANDLE_REAL);
    }
};

constexpr uint32 DUCK_HUNTING = 81110;
constexpr uint32 HIGH_GROUND = 81090;
constexpr float HIGH_GROUND_YARDS = 5.0f;

int32 ElevationPct(Unit* attacker, Unit* target)
{
    if (!attacker || !target || attacker == target)
        return 0;
    int32 pct = 0;
    if (target->GetPositionZ() - attacker->GetPositionZ() >= HIGH_GROUND_YARDS)
        if (AuraEffect const* duck = attacker->GetAuraEffect(DUCK_HUNTING, EFFECT_0))
            pct += duck->GetAmount();
    if (attacker->GetPositionZ() - target->GetPositionZ() >= HIGH_GROUND_YARDS)
        if (AuraEffect const* ground = attacker->GetAuraEffect(HIGH_GROUND, EFFECT_0))
            pct += ground->GetAmount();
    return pct;
}

void DuckHuntingSlowFall(Unit* attacker, Unit* target)
{
    if (attacker && target && attacker != target && attacker->HasAura(DUCK_HUNTING) &&
        target->HasAuraType(SPELL_AURA_FEATHER_FALL))
        target->RemoveAurasByType(SPELL_AURA_FEATHER_FALL);
}

class dummyfix_shaman_unit_hooks : public UnitScript
{
public:
    dummyfix_shaman_unit_hooks() : UnitScript("dummyfix_shaman_unit_hooks", true,
        { UNITHOOK_MODIFY_MELEE_DAMAGE, UNITHOOK_MODIFY_SPELL_DAMAGE_TAKEN, UNITHOOK_MODIFY_PERIODIC_DAMAGE_AURAS_TICK }) { }

    void ModifyMeleeDamage(Unit* target, Unit* attacker, uint32& damage) override
    {
        if (!damage)
            return;
        if (int32 const pct = ElevationPct(attacker, target))
            AddPct(damage, pct);
        DuckHuntingSlowFall(attacker, target);
    }

    void ModifySpellDamageTaken(Unit* target, Unit* attacker, int32& damage, SpellInfo const* info) override
    {
        if (damage <= 0)
            return;
        if (int32 const pct = ElevationPct(attacker, target) + SacredRitesPct(attacker, target, info) +
            DownForTheCountPct(attacker, target, info))
            AddPct(damage, pct);
        if (FlameNovaExploding && info && info->SpellFamilyName == SPELLFAMILY_SHAMAN &&
            (info->SpellFamilyFlags[1] & SHAMAN_FIRE_NOVA_FLAG1))
            AddPct(damage, FLAME_NOVA_EXPLOSION_PCT);
        DuckHuntingSlowFall(attacker, target);
    }

    void ModifyPeriodicDamageAurasTick(Unit* target, Unit* attacker, uint32& damage, SpellInfo const* info) override
    {
        if (damage)
            if (int32 const pct = ElevationPct(attacker, target) + SacredRitesPct(attacker, target, info))
                AddPct(damage, pct);
    }
};
}

void ApplyAscensionDummyFixShamanContracts(SpellInfo* spellInfo)
{
    if (!spellInfo)
        return;

    switch (spellInfo->Id)
    {
        case 51883:
        case 51884:
        case 51885:
            if (spellInfo->Effects[EFFECT_0].ApplyAuraName == SPELL_AURA_DUMMY)
            {
                spellInfo->Effects[EFFECT_0].ApplyAuraName = SPELL_AURA_MOD_RATING_FROM_STAT;
                spellInfo->Effects[EFFECT_0].MiscValueB = STAT_INTELLECT;
            }
            if (spellInfo->Id == 51885 && spellInfo->Effects[EFFECT_1].ApplyAuraName == SPELL_AURA_DUMMY)
            {
                spellInfo->Effects[EFFECT_1].ApplyAuraName = SPELL_AURA_MOD_RATING_FROM_STAT;
                spellInfo->Effects[EFFECT_1].MiscValue = 1 << CR_CRIT_MELEE;
                spellInfo->Effects[EFFECT_1].MiscValueB = STAT_INTELLECT;
            }
            break;
        case 278033:
            if (spellInfo->Effects[EFFECT_0].ApplyAuraName == SPELL_AURA_DUMMY)
            {
                spellInfo->Effects[EFFECT_0].ApplyAuraName = SPELL_AURA_PROC_TRIGGER_SPELL;
                spellInfo->Effects[EFFECT_0].TriggerSpell = 278035;
            }
            break;
        case 281411:
        case 81140:
            if (spellInfo->Effects[EFFECT_0].ApplyAuraName == SPELL_AURA_PERIODIC_DUMMY)
            {
                spellInfo->Effects[EFFECT_0].ApplyAuraName = SPELL_AURA_DUMMY;
                spellInfo->Effects[EFFECT_0].Amplitude = 0;
            }
            break;
        case 283338:
        case 954057:
            if (spellInfo->Effects[EFFECT_2].ApplyAuraName == SPELL_AURA_DUMMY)
            {
                spellInfo->Effects[EFFECT_2].ApplyAuraName = SPELL_AURA_PERIODIC_DUMMY;
                spellInfo->Effects[EFFECT_2].Amplitude = 1000;
            }
            break;
        case 1590425:
            if (spellInfo->Effects[EFFECT_0].ApplyAuraName == SPELL_AURA_DUMMY)
            {
                spellInfo->Effects[EFFECT_0].ApplyAuraName = SPELL_AURA_PROC_TRIGGER_SPELL;
                spellInfo->Effects[EFFECT_0].TriggerSpell = 1590426;
            }
            break;
        default:
            break;
    }
}

constexpr uint32 ELEMENTAL_FOCUS_CLEARCASTING = 16246;

class spell_dummyfix_shaman_froststorm_focus : public AuraScript
{
    PrepareAuraScript(spell_dummyfix_shaman_froststorm_focus);

    bool CheckProc(ProcEventInfo& eventInfo)
    {
        SpellInfo const* info = eventInfo.GetSpellInfo();
        return info && (info->GetSchoolMask() & SPELL_SCHOOL_MASK_FROST) &&
            GetTarget()->HasAura(ELEMENTAL_FOCUS_CLEARCASTING);
    }

    void Register() override
    {
        DoCheckProc += AuraCheckProcFn(spell_dummyfix_shaman_froststorm_focus::CheckProc);
    }
};

void AddAscensionDummyFixShamanScripts()
{
    RegisterSpellScript(spell_dummyfix_shaman_froststorm_focus);
    RegisterSpellScript(spell_dummyfix_shaman_mental_quickness);
    RegisterSpellScript(spell_dummyfix_shaman_totemic_shatter);
    RegisterSpellScript(spell_dummyfix_shaman_raging_riptide);
    RegisterSpellScript(spell_dummyfix_shaman_raging_riptide_heal);
    RegisterSpellScript(spell_dummyfix_shaman_rising_winds);
    RegisterSpellScript(spell_dummyfix_shaman_by_fire_be_purged);
    RegisterSpellScript(spell_dummyfix_shaman_elemental_lord);
    RegisterSpellScript(spell_dummyfix_shaman_frugal_disposition);
    RegisterSpellScript(spell_dummyfix_shaman_pack_alpha);
    RegisterSpellScript(spell_dummyfix_shaman_lightning_mastery);
    RegisterSpellScript(spell_dummyfix_shaman_weapon_command);
    RegisterSpellScript(spell_dummyfix_shaman_tidecallers_boon);
    RegisterSpellScript(spell_dummyfix_shaman_converging_elements);
    RegisterSpellScript(spell_dummyfix_shaman_flame_nova);
    RegisterSpellScript(spell_dummyfix_shaman_imbue_strike);
    RegisterSpellScript(spell_dummyfix_shaman_learn_with);
    RegisterSpellScript(spell_dummyfix_shaman_echoing_power);
    RegisterSpellScript(spell_dummyfix_shaman_low_tide);
    RegisterSpellScript(spell_dummyfix_shaman_mechanical_arm);
    RegisterSpellScript(spell_dummyfix_shaman_electric_surge);
    RegisterSpellScript(spell_dummyfix_shaman_fire_watch);
    RegisterSpellScript(spell_dummyfix_shaman_tidal_force);
    new dummyfix_shaman_creature_hooks();
    new dummyfix_shaman_unit_hooks();
}
