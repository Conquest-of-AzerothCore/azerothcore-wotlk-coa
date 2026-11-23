/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "AscensionDummyFixes.h"
#include "Creature.h"
#include "MotionMaster.h"
#include "Pet.h"
#include "Player.h"
#include "ScriptMgr.h"
#include "Spell.h"
#include "SpellAuraEffects.h"
#include "SpellAuras.h"
#include "SpellInfo.h"
#include "SpellMgr.h"
#include "SpellScript.h"
#include "UnitScript.h"
#include <algorithm>
#include <list>
#include <mutex>
#include <unordered_map>

namespace
{
constexpr uint32 SPELL_ABOMINATIONS_LIMB_GRIP = 288831;
constexpr uint32 NPC_RISEN_GHOUL = 26125;

Unit* LimbSource(Unit* caster)
{
    if (Player* player = caster->ToPlayer())
        if (Pet* pet = player->GetPet())
            if (pet->IsAlive() && pet->GetCreatureType() == CREATURE_TYPE_UNDEAD)
                return pet;
    for (Unit* controlled : caster->m_Controlled)
        if (controlled && controlled->IsAlive() && controlled->GetEntry() == NPC_RISEN_GHOUL)
            return controlled;
    return nullptr;
}

class spell_dummyfix_deathknight_abominations_limb : public SpellScript
{
    PrepareSpellScript(spell_dummyfix_deathknight_abominations_limb);

    bool Validate(SpellInfo const* ) override
    {
        return ValidateSpellInfo({ SPELL_ABOMINATIONS_LIMB_GRIP });
    }

    SpellCastResult CheckCast()
    {
        return LimbSource(GetCaster()) ? SPELL_CAST_OK : SPELL_FAILED_NO_PET;
    }

    void HandleDummy(SpellEffIndex )
    {
        if (Unit* source = LimbSource(GetCaster()))
            source->CastSpell(source, SPELL_ABOMINATIONS_LIMB_GRIP, true);
    }

    void Register() override
    {
        OnCheckCast += SpellCheckCastFn(spell_dummyfix_deathknight_abominations_limb::CheckCast);
        OnEffectHit += SpellEffectFn(spell_dummyfix_deathknight_abominations_limb::HandleDummy, EFFECT_0, SPELL_EFFECT_DUMMY);
    }
};

class spell_dummyfix_deathknight_abominations_limb_grip : public SpellScript
{
    PrepareSpellScript(spell_dummyfix_deathknight_abominations_limb_grip);

    void HandleGrip(SpellEffIndex )
    {
        Unit* pet = GetCaster();
        Creature* target = GetHitUnit() ? GetHitUnit()->ToCreature() : nullptr;
        if (!pet || !target || target->GetCharmerOrOwnerPlayerOrPlayerItself() || target->isWorldBoss() ||
            target->IsDungeonBoss() || target->IsImmuneToKnockback() || target->IsImmuneToForcedMovement())
            return;
        target->GetMotionMaster()->MoveJump(pet->GetPositionX(), pet->GetPositionY(), pet->GetPositionZ() + 1.0f,
            24.0f, 8.0f);
    }

    void Register() override
    {
        OnEffectHitTarget += SpellEffectFn(spell_dummyfix_deathknight_abominations_limb_grip::HandleGrip, EFFECT_0, SPELL_EFFECT_DUMMY);
    }
};

constexpr uint32 SPELL_DEATH_TAP_CONVERSION = 288801;

bool HasRunes(Player const* player)
{
    return player->IsClass(CLASS_DEATH_KNIGHT, CLASS_CONTEXT_ABILITY) || player->getClass() == CLASS_HERO;
}

class spell_dummyfix_deathknight_death_tap : public SpellScript
{
    PrepareSpellScript(spell_dummyfix_deathknight_death_tap);

    bool Validate(SpellInfo const* ) override
    {
        return ValidateSpellInfo({ SPELL_DEATH_TAP_CONVERSION });
    }

    void HandleDummy(SpellEffIndex )
    {
        Unit* caster = GetCaster();
        uint32 const cost = caster->CountPctFromMaxHealth(GetSpellInfo()->Effects[EFFECT_1].CalcValue());
        if (cost && caster->GetHealth() > 1)
            Unit::DealDamage(caster, caster, std::min<uint32>(cost, caster->GetHealth() - 1), nullptr, SELF_DAMAGE,
                SPELL_SCHOOL_MASK_NORMAL, GetSpellInfo(), false);
        caster->CastSpell(caster, SPELL_DEATH_TAP_CONVERSION, true);
    }

    void Register() override
    {
        OnEffectHit += SpellEffectFn(spell_dummyfix_deathknight_death_tap::HandleDummy, EFFECT_0, SPELL_EFFECT_DUMMY);
    }
};

class spell_dummyfix_deathknight_death_tap_conversion : public AuraScript
{
    PrepareAuraScript(spell_dummyfix_deathknight_death_tap_conversion);

    void HandleApply(AuraEffect const* aurEff, AuraEffectHandleModes )
    {
        PreventDefaultAction();
        Player* player = GetTarget()->ToPlayer();
        if (!player || !HasRunes(player))
            return;
        for (uint8 i = 0; i < MAX_RUNES; ++i)
        {
            if (player->GetCurrentRune(i) != RUNE_DEATH && !player->GetRuneCooldown(i))
            {
                player->AddRuneByAuraEffect(i, RUNE_DEATH, aurEff);
                return;
            }
        }
    }

    void HandleRemove(AuraEffect const* aurEff, AuraEffectHandleModes )
    {
        PreventDefaultAction();
        if (Player* player = GetTarget()->ToPlayer())
            if (HasRunes(player))
                player->RemoveRunesByAuraEffect(aurEff);
    }

    void Register() override
    {
        OnEffectApply += AuraEffectApplyFn(spell_dummyfix_deathknight_death_tap_conversion::HandleApply, EFFECT_0,
            SPELL_AURA_CONVERT_RUNE, AURA_EFFECT_HANDLE_REAL);
        OnEffectRemove += AuraEffectRemoveFn(spell_dummyfix_deathknight_death_tap_conversion::HandleRemove, EFFECT_0,
            SPELL_AURA_CONVERT_RUNE, AURA_EFFECT_HANDLE_REAL);
    }
};

constexpr uint32 SPELL_BLOOD_SHIELD_TALENT = 288804;
constexpr uint32 SPELL_BLOOD_SHIELD_ABSORB = 288805;
constexpr uint32 SPELL_FROST_PRESENCE = 48263;

std::mutex DeathStrikeLock;
std::unordered_map<ObjectGuid, bool> DeathStrikeHitPlayer;

class spell_dummyfix_deathknight_blood_shield_strike : public SpellScript
{
    PrepareSpellScript(spell_dummyfix_deathknight_blood_shield_strike);

    void NoteTarget(SpellMissInfo missInfo)
    {
        Unit* target = GetHitUnit();
        if (missInfo != SPELL_MISS_NONE || !target)
            return;
        std::lock_guard<std::mutex> lock(DeathStrikeLock);
        DeathStrikeHitPlayer[GetCaster()->GetGUID()] = target->GetCharmerOrOwnerPlayerOrPlayerItself() != nullptr;
    }

    void Register() override
    {
        BeforeHit += BeforeSpellHitFn(spell_dummyfix_deathknight_blood_shield_strike::NoteTarget);
    }
};

class spell_dummyfix_deathknight_blood_shield_heal : public SpellScript
{
    PrepareSpellScript(spell_dummyfix_deathknight_blood_shield_heal);

    bool Validate(SpellInfo const* ) override
    {
        return ValidateSpellInfo({ SPELL_BLOOD_SHIELD_TALENT, SPELL_BLOOD_SHIELD_ABSORB, SPELL_FROST_PRESENCE });
    }

    void HandleAfterHit()
    {
        Unit* caster = GetCaster();
        int32 const heal = GetHitHeal();
        if (!caster || heal <= 0 || GetHitUnit() != caster)
            return;
        bool pvp = false;
        {
            std::lock_guard<std::mutex> lock(DeathStrikeLock);
            auto const itr = DeathStrikeHitPlayer.find(caster->GetGUID());
            if (itr != DeathStrikeHitPlayer.end())
            {
                pvp = itr->second;
                DeathStrikeHitPlayer.erase(itr);
            }
        }
        AuraEffect const* talent = caster->GetAuraEffect(SPELL_BLOOD_SHIELD_TALENT, EFFECT_0);
        if (!talent || !caster->HasAuraOrTwin(SPELL_FROST_PRESENCE))
            return;
        SpellInfo const* info = talent->GetSpellInfo();
        int32 absorb = CalculatePct(heal, talent->GetAmount());
        if (AuraEffect const* shield = caster->GetAuraEffect(SPELL_BLOOD_SHIELD_ABSORB, EFFECT_0, caster->GetGUID()))
            absorb += shield->GetAmount();
        int32 const cap = int32(caster->CountPctFromMaxHealth(info->Effects[pvp ? EFFECT_2 : EFFECT_1].CalcValue()));
        absorb = std::min(absorb, cap);
        if (absorb > 0)
            caster->CastCustomSpell(SPELL_BLOOD_SHIELD_ABSORB, SPELLVALUE_BASE_POINT0, absorb, caster, true);
    }

    void Register() override
    {
        AfterHit += SpellHitFn(spell_dummyfix_deathknight_blood_shield_heal::HandleAfterHit);
    }
};

constexpr uint32 SPELL_SOUL_REAPER = 288811;
constexpr uint32 SPELL_SOUL_REAPER_HASTE = 288815;

class spell_dummyfix_deathknight_soul_reaper : public AuraScript
{
    PrepareAuraScript(spell_dummyfix_deathknight_soul_reaper);

    bool Validate(SpellInfo const* ) override
    {
        return ValidateSpellInfo({ SPELL_SOUL_REAPER_HASTE });
    }

    void HandleRemove(AuraEffect const* , AuraEffectHandleModes )
    {
        if (GetTargetApplication()->GetRemoveMode() != AURA_REMOVE_BY_EXPIRE)
            return;
        Unit* target = GetTarget();
        Unit* caster = GetCaster();
        if (caster && target->IsAlive() && target->HealthBelowPct(GetSpellInfo()->Effects[EFFECT_2].CalcValue()))
            caster->CastSpell(caster, SPELL_SOUL_REAPER_HASTE, true);
    }

    void Register() override
    {
        AfterEffectRemove += AuraEffectRemoveFn(spell_dummyfix_deathknight_soul_reaper::HandleRemove, EFFECT_0,
            SPELL_AURA_PERIODIC_DAMAGE, AURA_EFFECT_HANDLE_REAL);
    }
};

constexpr uint32 SPELL_GARGOYLES_WRATH = 288946;
constexpr uint32 NPC_EBON_GARGOYLE = 27829;

Creature* OwnedGargoyle(Unit* owner)
{
    std::list<Creature*> creatures;
    owner->GetCreatureListWithEntryInGrid(creatures, NPC_EBON_GARGOYLE, 100.0f);
    for (Creature* creature : creatures)
        if (creature->IsAlive() && creature->GetOwnerGUID() == owner->GetGUID())
            return creature;
    return nullptr;
}

class spell_dummyfix_deathknight_unholy_commander : public AuraScript
{
    PrepareAuraScript(spell_dummyfix_deathknight_unholy_commander);

    bool Validate(SpellInfo const* ) override
    {
        return ValidateSpellInfo({ SPELL_GARGOYLES_WRATH });
    }

    bool CheckProc(ProcEventInfo& eventInfo)
    {
        Unit* target = eventInfo.GetActionTarget();
        return target && target != GetTarget() && OwnedGargoyle(GetTarget()) != nullptr;
    }

    void HandleProc(AuraEffect const* aurEff, ProcEventInfo& eventInfo)
    {
        PreventDefaultAction();
        Unit* target = eventInfo.GetActionTarget();
        if (Creature* gargoyle = OwnedGargoyle(GetTarget()))
            if (target && target->IsAlive())
                gargoyle->CastSpell(target, SPELL_GARGOYLES_WRATH, true, nullptr, aurEff, GetTarget()->GetGUID());
    }

    void Register() override
    {
        DoCheckProc += AuraCheckProcFn(spell_dummyfix_deathknight_unholy_commander::CheckProc);
        OnEffectProc += AuraEffectProcFn(spell_dummyfix_deathknight_unholy_commander::HandleProc, EFFECT_0, SPELL_AURA_DUMMY);
    }
};

constexpr uint32 SPELL_GLYPH_OF_PLAGUE_STRIKE = 118601;
constexpr uint32 SPELL_GLYPH_OF_BLOOD_STRIKE = 118636;
constexpr uint32 SPELL_GLYPH_OF_DEATH_STRIKE = 118639;
constexpr uint32 SPELL_PLAGUEBLADE = 288971;
constexpr uint32 SPELL_DEFILE_THE_GROVE = 288828;
constexpr uint32 SPELL_DEATH_AND_DECAY_R1 = 43265;
constexpr uint32 SPELL_BLIGHTED_EDGE = 288987;
constexpr uint32 SPELL_UNHOLY_BLIGHT_R1 = 49194;
constexpr uint32 SPELL_UNHOLY_BLIGHT_R2 = 49196;

bool IsPoisonOrDisease(SpellInfo const* info)
{
    return info->Dispel == DISPEL_POISON || info->Dispel == DISPEL_DISEASE;
}

bool IsPeriodicDamage(SpellInfo const* info)
{
    return info->HasAura(SPELL_AURA_PERIODIC_DAMAGE) || info->HasAura(SPELL_AURA_PERIODIC_LEECH);
}

void ApplyPlagueblade(Unit* target, Unit* attacker, uint32& damage, SpellInfo const* info)
{
    if (!IsPoisonOrDisease(info))
        return;
    if (AuraEffect const* effect = target->GetAuraEffect(SPELL_PLAGUEBLADE, EFFECT_0, attacker->GetGUID()))
        if (effect->GetAmount() > 0)
            AddPct(damage, effect->GetAmount());
}

class dummyfix_deathknight_unit_hooks : public UnitScript
{
public:
    dummyfix_deathknight_unit_hooks() : UnitScript("dummyfix_deathknight_unit_hooks", true,
        { UNITHOOK_MODIFY_PERIODIC_DAMAGE_AURAS_TICK, UNITHOOK_MODIFY_SPELL_DAMAGE_TAKEN }) { }

    void ModifyPeriodicDamageAurasTick(Unit* target, Unit* attacker, uint32& damage, SpellInfo const* info) override
    {
        if (!target || !attacker || !info || !damage || !IsPeriodicDamage(info))
            return;
        ApplyPlagueblade(target, attacker, damage, info);
        if (info->Id == SPELL_SOUL_REAPER && target->HealthBelowPct(info->Effects[EFFECT_2].CalcValue()))
            damage = uint32(CalculatePct(uint64(damage), info->Effects[EFFECT_1].CalcValue()));
        if (info->SpellFamilyName == SPELLFAMILY_DRUID)
            if (AuraEffect const* grove = attacker->GetAuraEffect(SPELL_DEFILE_THE_GROVE, EFFECT_0))
                if (grove->GetAmount() > 0 && target->GetAuraOfRankedSpellOrTwin(SPELL_DEATH_AND_DECAY_R1, attacker->GetGUID()))
                    AddPct(damage, grove->GetAmount());
    }

    void ModifySpellDamageTaken(Unit* target, Unit* attacker, int32& damage, SpellInfo const* info) override
    {
        if (!target || !attacker || !info || damage <= 0)
            return;
        uint32 amount = uint32(damage);
        ApplyPlagueblade(target, attacker, amount, info);
        if (info->SpellFamilyName == SPELLFAMILY_DEATHKNIGHT)
        {
            flag96 const& flags = info->SpellFamilyFlags;
            if (flags[0] & 0x1)
            {
                if (AuraEffect const* glyph = attacker->GetAuraEffect(SPELL_GLYPH_OF_PLAGUE_STRIKE, EFFECT_0))
                    AddPct(amount, glyph->GetAmount());
            }
            else if (flags[0] & 0x400000)
            {
                if (AuraEffect const* glyph = attacker->GetAuraEffect(SPELL_GLYPH_OF_BLOOD_STRIKE, EFFECT_0))
                    if (target->HasDecreaseSpeedAura())
                        AddPct(amount, glyph->GetAmount());
            }
            else if (flags[0] & 0x10)
            {
                if (AuraEffect const* glyph = attacker->GetAuraEffect(SPELL_GLYPH_OF_DEATH_STRIKE, EFFECT_0))
                {
                    int32 const step = std::max<int32>(1, glyph->GetAmount());
                    int32 const rage = int32(attacker->GetPower(POWER_RAGE) / 10);
                    int32 const bonus = std::min<int32>(rage / step * glyph->GetAmount(),
                        glyph->GetSpellInfo()->Effects[EFFECT_1].CalcValue());
                    if (bonus > 0)
                        AddPct(amount, bonus);
                }
            }
            if (flags[2] & 0x80)
                if (AuraEffect const* edge = attacker->GetAuraEffect(SPELL_BLIGHTED_EDGE, EFFECT_1))
                {
                    flag96 const& blight = edge->GetSpellInfo()->Effects[EFFECT_1].SpellClassMask;
                    if (edge->GetAmount() > 0 && target->GetAuraEffect(SPELL_AURA_PERIODIC_DAMAGE, SPELLFAMILY_DEATHKNIGHT,
                        blight[0], blight[1], blight[2], attacker->GetGUID()))
                        AddPct(amount, edge->GetAmount());
                }
        }
        damage = int32(amount);
    }
};
}

void ApplyAscensionDummyFixDeathKnightContracts(SpellInfo* spellInfo)
{
    if (!spellInfo)
        return;
    switch (spellInfo->Id)
    {
        case SPELL_UNHOLY_BLIGHT_R2:
            if (SpellInfo const* rank1 = sSpellMgr->GetSpellInfo(SPELL_UNHOLY_BLIGHT_R1))
                spellInfo->Effects[EFFECT_0].BasePoints = rank1->Effects[EFFECT_0].BasePoints;
            else
                spellInfo->Effects[EFFECT_0].BasePoints = 49;
            break;
        default:
            break;
    }
}

void AddAscensionDummyFixDeathKnightScripts()
{
    RegisterSpellScript(spell_dummyfix_deathknight_abominations_limb);
    RegisterSpellScript(spell_dummyfix_deathknight_abominations_limb_grip);
    RegisterSpellScript(spell_dummyfix_deathknight_death_tap);
    RegisterSpellScript(spell_dummyfix_deathknight_death_tap_conversion);
    RegisterSpellScript(spell_dummyfix_deathknight_blood_shield_strike);
    RegisterSpellScript(spell_dummyfix_deathknight_blood_shield_heal);
    RegisterSpellScript(spell_dummyfix_deathknight_soul_reaper);
    RegisterSpellScript(spell_dummyfix_deathknight_unholy_commander);
    new dummyfix_deathknight_unit_hooks();
}
