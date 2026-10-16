/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */
#include "ObjectAccessor.h"
#include "AscensionWildcard.h"
#include "Player.h"
#include "ScriptMgr.h"
#include "Spell.h"
#include "SpellAuraEffects.h"
#include "SpellAuras.h"
#include "SpellMgr.h"
#include "SpellScript.h"

namespace
{
enum HurricaneSpells : uint32
{
    SPELL_HURRICANE = 645435,
    SPELL_HURRICANE_HIT = 645437,
    SPELL_HURRICANE_DODGE = 645440,
    SPELL_RUNIC_HURRICANE = 280930,
    SPELL_RUNIC_HURRICANE_HIT = 280932,
    SPELL_RUNIC_HURRICANE_DODGE = 280933,
    SPELL_WAVEFORGED = 705565,
    SPELL_WAVEFORGED_READY = 500469,
    SPELL_SWIFT_ETCHING = 705600,
    SPELL_SWIFT_ETCHING_READY = 500506,
    SPELL_WATER_RUNES = 707150,
    SPELL_WATER_ENGRAVING = 653214,
    SPELL_ICE_ENGRAVING = 653266
};

struct WaterRune
{
    SpellEffIndex Effect;
    uint32 Engraving;
};

constexpr WaterRune WaterRunes[] = {{EFFECT_1, SPELL_WATER_ENGRAVING}, {EFFECT_2, SPELL_ICE_ENGRAVING}};

constexpr float HURRICANE_STRIKE_DISTANCE = 1.5f;
constexpr uint32 HURRICANE_STRIKE_DIRECTIONS = 5;

bool CanUseHurricane(Unit* caster, uint32 spell)
{
    Player* player = caster ? caster->ToPlayer() : nullptr;
    return player && ((spell == SPELL_HURRICANE && player->getClass() == CLASS_SPIRIT_MAGE) ||
        (spell == SPELL_RUNIC_HURRICANE && AscensionWildcard::IsWildcardHero(player)));
}

uint32 HurricaneDodge(uint32 spell)
{
    return spell == SPELL_RUNIC_HURRICANE ? SPELL_RUNIC_HURRICANE_DODGE : SPELL_HURRICANE_DODGE;
}

void ApplyWaterRunes(Unit* player, Unit* target)
{
    Aura* runes = player->GetAura(SPELL_WATER_RUNES, player->GetGUID());
    if (!runes)
        return;
    for (WaterRune const& rune : WaterRunes)
        if (AuraEffect const* effect = runes->GetEffect(rune.Effect);
            effect && target->IsAlive() && player->HasAura(rune.Engraving, player->GetGUID()))
            player->CastSpell(target, runes->GetSpellInfo()->Effects[rune.Effect].TriggerSpell, TRIGGERED_FULL_MASK,
                nullptr, effect);
}

bool StrikeHurricane(Unit* player, Aura* aura)
{
    Unit* target = ObjectAccessor::GetUnit(*player, ObjectGuid(aura->GetScriptValue(aura->GetId())));
    if (!player->IsAlive() || !player->IsInWorld() || !target || !target->IsInWorld() ||
        player->GetMap() != target->GetMap() || !player->InSamePhase(target) ||
        !player->IsValidAttackTarget(target))
        return false;
    uint64 const strikes = aura->GetScriptValue(SPELL_HURRICANE_HIT);
    if (aura->GetId() == SPELL_RUNIC_HURRICANE && strikes >= HURRICANE_STRIKE_DIRECTIONS)
        return false;
    aura->SetScriptValue(SPELL_HURRICANE_HIT, strikes + 1);
    float const angle = player->GetOrientation() +
        float(strikes % HURRICANE_STRIKE_DIRECTIONS) * 2.0f * float(M_PI) / float(HURRICANE_STRIKE_DIRECTIONS);
    float const x = target->GetPositionX() + std::cos(angle) * HURRICANE_STRIKE_DISTANCE;
    float const y = target->GetPositionY() + std::sin(angle) * HURRICANE_STRIKE_DISTANCE;
    float z = target->GetPositionZ();
    if (!player->IsUnderWater())
    {
        float const ground = player->GetMap()->GetHeight(x, y, MAX_HEIGHT);
        if (ground > INVALID_HEIGHT)
            z = ground;
    }
    player->NearTeleportTo(x, y, z, player->GetOrientation());
    player->SetFacingToObject(target);
    player->CastSpell(target,
        aura->GetId() == SPELL_RUNIC_HURRICANE ? SPELL_RUNIC_HURRICANE_HIT : SPELL_HURRICANE_HIT, true);
    return true;
}

class runemaster_hurricane_cast : public AllSpellScript
{
public:
    runemaster_hurricane_cast() : AllSpellScript("runemaster_hurricane_cast", {ALLSPELLHOOK_ON_CAST}) { }

    void OnSpellCast(Spell* spell, Unit* caster, SpellInfo const* info, bool) override
    {
        if (!CanUseHurricane(caster, info->Id) || spell->IsTriggered())
            return;
        Aura* aura = caster->GetAura(info->Id, caster->GetGUID());
        Unit* target = spell->m_targets.GetUnitTarget();
        if (!aura || !target)
            return;
        aura->SetScriptValue(info->Id, target->GetGUID().GetRawValue());
        if (Aura* dodge = caster->AddAura(HurricaneDodge(info->Id), caster))
        {
            dodge->SetMaxDuration(-1);
            dodge->SetDuration(-1);
        }
        StrikeHurricane(caster, aura);
    }
};

class aura_ascension_runemaster_hurricane : public AuraScript
{
    PrepareAuraScript(aura_ascension_runemaster_hurricane);

    bool Load() override
    {
        return GetCaster() && GetCaster() == GetUnitOwner() && CanUseHurricane(GetCaster(), GetId());
    }

    void SetFearImmunity(bool apply)
    {
        Unit* player = GetTarget();
        player->ApplySpellImmune(GetId(), IMMUNITY_MECHANIC, MECHANIC_FEAR, apply);
        player->ApplySpellImmune(GetId(), IMMUNITY_STATE, SPELL_AURA_MOD_FEAR, apply);
    }

    void Apply(AuraEffect const*, AuraEffectHandleModes)
    {
        SetFearImmunity(true);
    }

    void Tick(AuraEffect const*)
    {
        if (!StrikeHurricane(GetTarget(), GetAura()))
            GetAura()->Remove();
    }

    void End(AuraEffect const*, AuraEffectHandleModes)
    {
        Unit* player = GetTarget();
        SetFearImmunity(false);
        player->RemoveAurasDueToSpell(HurricaneDodge(GetId()), player->GetGUID());
        if (GetId() == SPELL_RUNIC_HURRICANE || !player->IsAlive() || !player->IsInWorld() ||
            GetTargetApplication()->GetRemoveMode() == AURA_REMOVE_BY_DEATH)
            return;
        if (player->HasAura(SPELL_WAVEFORGED, player->GetGUID()))
            player->CastSpell(player, SPELL_WAVEFORGED_READY, true);
        if (player->HasAura(SPELL_SWIFT_ETCHING, player->GetGUID()))
            player->CastSpell(player, SPELL_SWIFT_ETCHING_READY, true);
    }

    void Register() override
    {
        AfterEffectApply += AuraEffectApplyFn(aura_ascension_runemaster_hurricane::Apply,
            EFFECT_0, SPELL_AURA_PERIODIC_DUMMY, AURA_EFFECT_HANDLE_REAL);
        OnEffectPeriodic += AuraEffectPeriodicFn(aura_ascension_runemaster_hurricane::Tick,
            EFFECT_0, SPELL_AURA_PERIODIC_DUMMY);
        AfterEffectRemove += AuraEffectRemoveFn(aura_ascension_runemaster_hurricane::End,
            EFFECT_0, SPELL_AURA_PERIODIC_DUMMY, AURA_EFFECT_HANDLE_REAL);
    }
};

class spell_ascension_hurricane_damage : public SpellScript
{
    PrepareSpellScript(spell_ascension_hurricane_damage);

    bool Load() override { return GetCaster()->IsPlayer() && GetCaster()->getClass() == CLASS_SPIRIT_MAGE; }

    void Scale()
    {
        double level = GetCaster()->GetLevel();
        double scale = 0.0267291844060354 + 0.0048541098014737 * level +
            0.0001859597762293 * level * level;
        GetSpell()->SetSpellValue(SPELLVALUE_BASE_POINT2,
            int32((GetSpellInfo()->Effects[EFFECT_2].BasePoints + 1) * scale));
    }

    void Hit()
    {
        if (GetHitUnit()->IsPlayer())
            SetHitDamage(CalculatePct(GetHitDamage(), 80));
    }

    void EngraveStruckTarget()
    {
        if (Unit* target = GetHitUnit())
            ApplyWaterRunes(GetCaster(), target);
    }

    void Register() override
    {
        BeforeCast += SpellCastFn(spell_ascension_hurricane_damage::Scale);
        OnHit += SpellHitFn(spell_ascension_hurricane_damage::Hit);
        AfterHit += SpellHitFn(spell_ascension_hurricane_damage::EngraveStruckTarget);
    }
};

class runemaster_hurricane_metadata : public GlobalScript
{
public:
    runemaster_hurricane_metadata() : GlobalScript("runemaster_hurricane_metadata",
        {GLOBALHOOK_ON_LOAD_SPELL_CUSTOM_ATTR}) { }

    void OnLoadSpellCustomAttr(SpellInfo* info) override
    {
        if (info->SpellFamilyName == SPELLFAMILY_GENERIC &&
            (info->Id == SPELL_RUNIC_HURRICANE || info->Id == SPELL_RUNIC_HURRICANE_DODGE))
        {
            if (info->Id == SPELL_RUNIC_HURRICANE)
                info->AttributesEx5 &= ~SPELL_ATTR5_EXTRA_INITIAL_PERIOD;
            info->AttributesCu &= ~SPELL_ATTR0_CU_FORCE_AURA_SAVING;
            info->AttributesCu |= SPELL_ATTR0_CU_AURA_CANNOT_BE_SAVED;
        }
        if (info->SpellFamilyName != 38)
            return;
        if (info->Id == SPELL_HURRICANE)
            info->AttributesEx5 &= ~SPELL_ATTR5_EXTRA_INITIAL_PERIOD;
        if (info->Id == SPELL_HURRICANE || info->Id == SPELL_HURRICANE_DODGE || info->Id == SPELL_WAVEFORGED_READY)
        {
            info->AttributesCu &= ~SPELL_ATTR0_CU_FORCE_AURA_SAVING;
            info->AttributesCu |= SPELL_ATTR0_CU_AURA_CANNOT_BE_SAVED;
        }
        if (info->Id == SPELL_WATER_RUNES && info->ProcFlags == PROC_FLAG_DONE_MELEE_AUTO_ATTACK)
            info->ProcFlags = PROC_FLAG_NONE;
    }
};
}

void AddSC_AscensionRunemasterHurricane()
{
    new runemaster_hurricane_cast();
    new runemaster_hurricane_metadata();
    RegisterSpellScript(aura_ascension_runemaster_hurricane);
    RegisterSpellScript(spell_ascension_hurricane_damage);
}
