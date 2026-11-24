/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "AscensionDummyFixes.h"
#include "AscensionDummySystemMelee.h"
#include "Item.h"
#include "Player.h"
#include "ScriptMgr.h"
#include "Spell.h"
#include "SpellAuraEffects.h"
#include "SpellAuras.h"
#include "SpellInfo.h"
#include "SpellMgr.h"
#include "SpellScript.h"
#include "TemporarySummon.h"
#include <array>
#include <list>
#include <unordered_map>

bool IsAscensionSwashbuckling(Unit const* unit)
{
    Player const* player = unit ? unit->ToPlayer() : nullptr;
    if (!player)
        return false;
    ShapeshiftForm const form = player->GetShapeshiftForm();
    if (form != FORM_NONE && form != FORM_STEALTH && form != FORM_SHADOW_DANCE && form != FORM_BATTLESTANCE &&
        form != FORM_DEFENSIVESTANCE && form != FORM_BERSERKERSTANCE)
        return false;
    Item const* main = player->GetItemByPos(INVENTORY_SLOT_BAG_0, EQUIPMENT_SLOT_MAINHAND);
    Item const* off = player->GetItemByPos(INVENTORY_SLOT_BAG_0, EQUIPMENT_SLOT_OFFHAND);
    if (!main || main->IsBroken())
        return false;
    uint32 const mainType = main->GetTemplate()->InventoryType;
    if (mainType != INVTYPE_WEAPON && mainType != INVTYPE_WEAPONMAINHAND)
        return false;
    if (!off)
        return true;
    ItemTemplate const* offTemplate = off->GetTemplate();
    return offTemplate->Class != ITEM_CLASS_WEAPON && offTemplate->InventoryType != INVTYPE_SHIELD;
}

namespace
{
bool DealsDamage(SpellInfo const* info)
{
    if (!info)
        return false;
    for (SpellEffectInfo const& effect : info->Effects)
        switch (effect.Effect)
        {
            case SPELL_EFFECT_SCHOOL_DAMAGE:
            case SPELL_EFFECT_WEAPON_DAMAGE:
            case SPELL_EFFECT_WEAPON_DAMAGE_NOSCHOOL:
            case SPELL_EFFECT_NORMALIZED_WEAPON_DMG:
            case SPELL_EFFECT_WEAPON_PERCENT_DAMAGE:
            case SPELL_EFFECT_HEALTH_LEECH:
                return true;
            case SPELL_EFFECT_APPLY_AURA:
                if (effect.ApplyAuraName == SPELL_AURA_PERIODIC_DAMAGE ||
                    effect.ApplyAuraName == SPELL_AURA_PERIODIC_LEECH)
                    return true;
                break;
            default:
                break;
        }
    return false;
}

bool KnowsSpell(Unit const* unit, uint32 spellId)
{
    Player const* player = unit->ToPlayer();
    return unit->HasAura(spellId) || (player && player->HasSpell(spellId));
}

struct OverridePair
{
    uint32 Enchant;
    uint32 Original;
    uint32 Replacement;
};

constexpr std::array<OverridePair, 2> MELEE_OVERRIDES = {{
    { 977864, 12294, 947486 },
    { 954326, 51713, 954327 },
}};

struct SwashbucklePassive
{
    uint32 Talent;
    uint32 Buff;
    bool DefensiveStance;
};

constexpr std::array<SwashbucklePassive, 4> SWASHBUCKLE_PASSIVES = {{
    { 277049, 277060, false },
    { 281944, 281945, false },
    { 81415, 81416, false },
    { 997127, 300110, true },
}};

constexpr uint32 BLOODSAIL_CAPTAIN = 997127;
constexpr uint32 EN_GARDE_MOCKING_BLOW = 92785;

SwashbucklePassive const* SwashbucklePassiveByTalent(uint32 talent)
{
    for (SwashbucklePassive const& rule : SWASHBUCKLE_PASSIVES)
        if (rule.Talent == talent)
            return &rule;
    return nullptr;
}

void SyncSwashbucklePassives(Unit* unit, uint32 leaving = 0)
{
    bool const swashbuckling = IsAscensionSwashbuckling(unit);
    bool const defensive = unit->ToPlayer() && unit->ToPlayer()->GetShapeshiftForm() == FORM_DEFENSIVESTANCE;
    std::unordered_map<uint32, bool> wanted;
    for (SwashbucklePassive const& rule : SWASHBUCKLE_PASSIVES)
    {
        bool& want = wanted[rule.Buff];
        if (!want && rule.Talent != leaving && swashbuckling && (!rule.DefensiveStance || defensive) &&
            unit->HasAura(rule.Talent, unit->GetGUID()))
            want = true;
    }
    for (auto const& [buff, want] : wanted)
    {
        bool const has = unit->HasAura(buff, unit->GetGUID());
        if (want && !has)
            unit->CastSpell(unit, buff, true);
        else if (!want && has)
            unit->RemoveAurasDueToSpell(buff, unit->GetGUID());
    }
}

class spell_dummysystem_melee_swashbuckling : public AuraScript
{
    PrepareAuraScript(spell_dummysystem_melee_swashbuckling);

    bool Validate(SpellInfo const* info) override
    {
        SwashbucklePassive const* rule = SwashbucklePassiveByTalent(info->Id);
        return rule && ValidateSpellInfo({ rule->Buff, EN_GARDE_MOCKING_BLOW });
    }

    void HandleApply(AuraEffect const* , AuraEffectHandleModes )
    {
        SyncSwashbucklePassives(GetTarget());
    }

    void HandleTick(AuraEffect const* )
    {
        PreventDefaultAction();
        SyncSwashbucklePassives(GetTarget());
    }

    void HandleRemove(AuraEffect const* , AuraEffectHandleModes )
    {
        SyncSwashbucklePassives(GetTarget(), GetId());
    }

    void HandleProc(AuraEffect const* aurEff, ProcEventInfo& )
    {
        PreventDefaultAction();
        if (GetId() == BLOODSAIL_CAPTAIN)
            GetTarget()->CastSpell(GetTarget(), EN_GARDE_MOCKING_BLOW, true, nullptr, aurEff);
    }

    void Register() override
    {
        AfterEffectApply += AuraEffectApplyFn(spell_dummysystem_melee_swashbuckling::HandleApply, EFFECT_0,
            SPELL_AURA_PERIODIC_DUMMY, AURA_EFFECT_HANDLE_REAL);
        OnEffectPeriodic += AuraEffectPeriodicFn(spell_dummysystem_melee_swashbuckling::HandleTick, EFFECT_0,
            SPELL_AURA_PERIODIC_DUMMY);
        AfterEffectRemove += AuraEffectRemoveFn(spell_dummysystem_melee_swashbuckling::HandleRemove, EFFECT_0,
            SPELL_AURA_PERIODIC_DUMMY, AURA_EFFECT_HANDLE_REAL);
        OnEffectProc += AuraEffectProcFn(spell_dummysystem_melee_swashbuckling::HandleProc, EFFECT_0,
            SPELL_AURA_PERIODIC_DUMMY);
    }
};

constexpr uint32 DEMOLISH_STRIKE = 954092;
constexpr uint32 DEMOLISH_TALENT = 273795;
constexpr uint32 READY_TO_DEMOLISH = 273801;
constexpr uint32 DEMOLISH_EXPOSE_ARMOR = 954093;
constexpr uint32 DEMOLISH_MONGOOSE_BITE = 954095;
constexpr uint32 DEMOLISHED_ARMS = 954091;
constexpr uint32 READY_TO_DEMOLISH_EXPOSE_ARMOR = 273796;
constexpr uint32 READY_TO_DEMOLISH_COUNTERATTACK = 273803;

class spell_dummysystem_melee_demolish : public AuraScript
{
    PrepareAuraScript(spell_dummysystem_melee_demolish);

    bool Validate(SpellInfo const* ) override
    {
        return ValidateSpellInfo({ DEMOLISH_EXPOSE_ARMOR, DEMOLISH_MONGOOSE_BITE, READY_TO_DEMOLISH_EXPOSE_ARMOR,
            READY_TO_DEMOLISH_COUNTERATTACK });
    }

    bool CheckProc(ProcEventInfo& eventInfo)
    {
        return GetId() != DEMOLISH_TALENT || (eventInfo.GetActor() && eventInfo.GetActor()->GetGUID() == GetCasterGUID());
    }

    void HandleProc(AuraEffect const* , ProcEventInfo& )
    {
        PreventDefaultAction();
        if (GetStackAmount() < GetSpellInfo()->StackAmount)
        {
            ModStackAmount(1);
            return;
        }
        Unit* caster = GetCaster();
        uint32 const id = GetId();
        Remove();
        if (!caster || !caster->IsAlive())
            return;
        if (id == DEMOLISH_STRIKE)
        {
            caster->CastSpell(caster, DEMOLISH_EXPOSE_ARMOR, true);
            caster->CastSpell(caster, DEMOLISH_MONGOOSE_BITE, true);
        }
        else if (caster->HasAura(READY_TO_DEMOLISH))
        {
            caster->CastSpell(caster, READY_TO_DEMOLISH_EXPOSE_ARMOR, true);
            caster->CastSpell(caster, READY_TO_DEMOLISH_COUNTERATTACK, true);
            caster->CastSpell(caster, DEMOLISH_MONGOOSE_BITE, true);
        }
    }

    void Register() override
    {
        DoCheckProc += AuraCheckProcFn(spell_dummysystem_melee_demolish::CheckProc);
        OnEffectProc += AuraEffectProcFn(spell_dummysystem_melee_demolish::HandleProc, EFFECT_1, SPELL_AURA_DUMMY);
    }
};

class spell_dummysystem_melee_demolished_riposte : public SpellScript
{
    PrepareSpellScript(spell_dummysystem_melee_demolished_riposte);

    bool Validate(SpellInfo const* ) override
    {
        return ValidateSpellInfo({ DEMOLISH_EXPOSE_ARMOR, DEMOLISHED_ARMS });
    }

    void HandleHit()
    {
        Unit* caster = GetCaster();
        Unit* target = GetHitUnit();
        if (target && caster->HasAura(DEMOLISH_EXPOSE_ARMOR))
            caster->CastSpell(target, DEMOLISHED_ARMS, true);
    }

    void Register() override
    {
        AfterHit += SpellHitFn(spell_dummysystem_melee_demolished_riposte::HandleHit);
    }
};

constexpr uint32 FORBIDDEN_TECHNIQUE = 271981;
constexpr uint32 FORBIDDEN_DANCE_TALENT = 271997;
constexpr uint32 FORBIDDEN_DANCE = 271985;
constexpr uint32 FORBIDDEN_DANCE_ENCHANTED = 986233;
constexpr uint32 SHADOW_TRICKSTER = 840031;

class spell_dummysystem_melee_forbidden_technique : public SpellScript
{
    PrepareSpellScript(spell_dummysystem_melee_forbidden_technique);

    bool Validate(SpellInfo const* ) override
    {
        return ValidateSpellInfo({ FORBIDDEN_DANCE, FORBIDDEN_DANCE_ENCHANTED });
    }

    void HandleMarker(SpellEffIndex effIndex)
    {
        PreventHitDefaultEffect(effIndex);
        Unit* caster = GetCaster();
        if (GetSpellInfo()->Id == FORBIDDEN_TECHNIQUE)
        {
            if (caster->HasAura(FORBIDDEN_DANCE_TALENT))
                caster->CastSpell(caster, FORBIDDEN_DANCE, true);
            return;
        }
        Unit const* target = GetExplTargetUnit();
        if (target && target->IsCreature() && !target->IsControlledByPlayer())
            caster->CastSpell(caster, FORBIDDEN_DANCE_ENCHANTED, true);
    }

    void Register() override
    {
        OnEffectHitTarget += SpellEffectFn(spell_dummysystem_melee_forbidden_technique::HandleMarker, EFFECT_2,
            SPELL_EFFECT_TRIGGER_SPELL);
    }
};

class spell_dummysystem_melee_shadow_return : public AuraScript
{
    PrepareAuraScript(spell_dummysystem_melee_shadow_return);

    void HandleRemove(AuraEffect const* , AuraEffectHandleModes )
    {
        Unit* target = GetTarget();
        if (GetTargetApplication()->GetRemoveMode() == AURA_REMOVE_BY_DEATH || !target->IsAlive())
            return;
        std::list<Creature*> shadows;
        target->GetCreatureListWithEntryInGrid(shadows, SHADOW_TRICKSTER, 100.0f);
        for (Creature* shadow : shadows)
        {
            TempSummon const* summon = shadow->ToTempSummon();
            if (!summon || summon->GetSummonerGUID() != target->GetGUID() || !shadow->IsAlive())
                continue;
            target->NearTeleportTo(shadow->GetPositionX(), shadow->GetPositionY(), shadow->GetPositionZ(),
                target->GetOrientation());
            shadow->DespawnOrUnsummon();
            return;
        }
    }

    void Register() override
    {
        AfterEffectRemove += AuraEffectRemoveFn(spell_dummysystem_melee_shadow_return::HandleRemove, EFFECT_0,
            SPELL_AURA_ANY, AURA_EFFECT_HANDLE_REAL);
    }
};

constexpr uint32 SHADOW_DAGGER = 271987;
constexpr uint32 DUSK_DAGGER = 954330;

class spell_dummysystem_melee_forbidden_dance : public AuraScript
{
    PrepareAuraScript(spell_dummysystem_melee_forbidden_dance);

    bool Validate(SpellInfo const* ) override
    {
        return ValidateSpellInfo({ SHADOW_DAGGER, DUSK_DAGGER });
    }

    void HandleProc(ProcEventInfo& eventInfo)
    {
        Unit* target = eventInfo.GetActionTarget();
        if (!target || target == GetTarget() || !target->IsAlive())
            return;
        GetTarget()->CastSpell(target, GetId() == FORBIDDEN_DANCE_ENCHANTED ? DUSK_DAGGER : SHADOW_DAGGER, true);
    }

    void Register() override
    {
        AfterProc += AuraProcFn(spell_dummysystem_melee_forbidden_dance::HandleProc);
    }
};

constexpr uint32 FORBIDDEN_TECHNIQUE_ENCHANT = 954326;
constexpr uint32 FORBIDDEN_CHANTS = 901122;

class spell_dummysystem_melee_meditate : public SpellScript
{
    PrepareSpellScript(spell_dummysystem_melee_meditate);

    void HandleCast()
    {
        GetCaster()->RemoveAurasDueToSpell(FORBIDDEN_CHANTS, GetCaster()->GetGUID());
    }

    void Register() override
    {
        BeforeCast += SpellCastFn(spell_dummysystem_melee_meditate::HandleCast);
    }
};

class spell_dummysystem_melee_meditate_chants : public AuraScript
{
    PrepareAuraScript(spell_dummysystem_melee_meditate_chants);

    bool Validate(SpellInfo const* ) override
    {
        return ValidateSpellInfo({ FORBIDDEN_CHANTS });
    }

    void HandleTick(AuraEffect const* aurEff)
    {
        Unit* target = GetTarget();
        if (target->HasAura(FORBIDDEN_TECHNIQUE_ENCHANT))
            target->CastSpell(target, FORBIDDEN_CHANTS, true, nullptr, aurEff);
    }

    void Register() override
    {
        OnEffectPeriodic += AuraEffectPeriodicFn(spell_dummysystem_melee_meditate_chants::HandleTick, EFFECT_0,
            SPELL_AURA_PERIODIC_ENERGIZE);
    }
};

constexpr uint32 POWER_LOOP = 986075;
constexpr uint32 MAELSTROM_WEAPON_TALENT = 51530;
constexpr uint32 MAELSTROM_WEAPON = 53817;
constexpr uint32 POWER_LOOP_STACKS_COOLDOWN = 979231;
constexpr uint32 POWER_LOOP_COMBO_POINTS = 986076;
constexpr int32 POWER_LOOP_PCT = 20;
constexpr uint8 POWER_LOOP_STACKS = 2;

class spell_dummysystem_melee_power_loop : public AuraScript
{
    PrepareAuraScript(spell_dummysystem_melee_power_loop);

    bool Validate(SpellInfo const* ) override
    {
        return ValidateSpellInfo({ MAELSTROM_WEAPON, POWER_LOOP_STACKS_COOLDOWN });
    }

    bool CheckProc(ProcEventInfo& eventInfo)
    {
        Player* player = GetTarget()->ToPlayer();
        SpellInfo const* info = eventInfo.GetSpellInfo();
        if (!player || !info || !info->NeedsComboPoints() || player->HasAura(POWER_LOOP_STACKS_COOLDOWN) ||
            !KnowsSpell(player, MAELSTROM_WEAPON_TALENT))
            return false;
        uint8 const points = player->GetComboPoints();
        return points && roll_chance_i(POWER_LOOP_PCT * points);
    }

    void HandleProc(AuraEffect const* aurEff, ProcEventInfo& )
    {
        PreventDefaultAction();
        Unit* target = GetTarget();
        for (uint8 i = 0; i < POWER_LOOP_STACKS; ++i)
            target->CastSpell(target, MAELSTROM_WEAPON, true, nullptr, aurEff);
        target->CastSpell(target, POWER_LOOP_STACKS_COOLDOWN, true, nullptr, aurEff);
    }

    void Register() override
    {
        DoCheckProc += AuraCheckProcFn(spell_dummysystem_melee_power_loop::CheckProc);
        OnEffectProc += AuraEffectProcFn(spell_dummysystem_melee_power_loop::HandleProc, EFFECT_0, SPELL_AURA_DUMMY);
    }
};

class spell_dummysystem_melee_power_loop_maelstrom : public AuraScript
{
    PrepareAuraScript(spell_dummysystem_melee_power_loop_maelstrom);

    bool Validate(SpellInfo const* ) override
    {
        return ValidateSpellInfo({ POWER_LOOP_COMBO_POINTS });
    }

    void HandleProc(ProcEventInfo& eventInfo)
    {
        Unit* owner = GetTarget();
        if (!owner->HasAura(POWER_LOOP) || owner->HasAura(POWER_LOOP_COMBO_POINTS) ||
            !KnowsSpell(owner, MAELSTROM_WEAPON_TALENT) || !DealsDamage(eventInfo.GetSpellInfo()))
            return;
        Unit* target = eventInfo.GetActionTarget();
        if (!target || target == owner)
            if (Spell const* spell = eventInfo.GetProcSpell())
                target = spell->m_targets.GetUnitTarget();
        if (!target || target == owner || !target->IsAlive() || !roll_chance_i(POWER_LOOP_PCT * GetStackAmount()))
            return;
        owner->CastSpell(target, POWER_LOOP_COMBO_POINTS, true);
    }

    void Register() override
    {
        AfterProc += AuraProcFn(spell_dummysystem_melee_power_loop_maelstrom::HandleProc);
    }
};
}

void ApplyAscensionDummySystemMeleeContracts(SpellInfo* spellInfo)
{
    if (!spellInfo)
        return;

    for (OverridePair const& pair : MELEE_OVERRIDES)
    {
        if (pair.Enchant != spellInfo->Id)
            continue;
        SpellEffectInfo& effect = spellInfo->Effects[EFFECT_0];
        if (effect.ApplyAuraName != SPELL_AURA_DUMMY || effect.MiscValue != int32(pair.Original))
            continue;
        effect.ApplyAuraName = SPELL_AURA_ASCENSION_OVERRIDE_SPELL;
        effect.BasePoints = int32(pair.Replacement);
        effect.MiscValueB = 0;
        effect.DieSides = 0;
        effect.RealPointsPerLevel = 0.0f;
        effect.PointsPerComboPoint = 0.0f;
    }

    switch (spellInfo->Id)
    {
        case 277049:
        case 281944:
        case 81415:
        case BLOODSAIL_CAPTAIN:
            if (spellInfo->Effects[EFFECT_0].ApplyAuraName == SPELL_AURA_DUMMY)
            {
                spellInfo->Effects[EFFECT_0].ApplyAuraName = SPELL_AURA_PERIODIC_DUMMY;
                spellInfo->Effects[EFFECT_0].Amplitude = 1000;
            }
            break;
        case FORBIDDEN_CHANTS:
            if (spellInfo->Effects[EFFECT_1].ApplyAuraName == SPELL_AURA_MOD_RANGED_ATTACK_POWER_PCT &&
                !spellInfo->Effects[EFFECT_1].TargetA.GetTarget())
                spellInfo->Effects[EFFECT_1].TargetA = SpellImplicitTargetInfo(TARGET_UNIT_CASTER);
            break;
        default:
            break;
    }
}

void AddAscensionDummySystemMeleeScripts()
{
    RegisterSpellScript(spell_dummysystem_melee_swashbuckling);
    RegisterSpellScript(spell_dummysystem_melee_demolish);
    RegisterSpellScript(spell_dummysystem_melee_demolished_riposte);
    RegisterSpellScript(spell_dummysystem_melee_forbidden_technique);
    RegisterSpellScript(spell_dummysystem_melee_shadow_return);
    RegisterSpellScript(spell_dummysystem_melee_forbidden_dance);
    RegisterSpellScript(spell_dummysystem_melee_meditate);
    RegisterSpellScript(spell_dummysystem_melee_meditate_chants);
    RegisterSpellScript(spell_dummysystem_melee_power_loop);
    RegisterSpellScript(spell_dummysystem_melee_power_loop_maelstrom);
}
