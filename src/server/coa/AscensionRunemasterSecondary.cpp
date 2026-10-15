/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */
#include "AscensionTalentReplacementData.h"
#include "Player.h"
#include "Random.h"
#include "ScriptMgr.h"
#include "Spell.h"
#include "SpellAuraEffects.h"
#include "SpellAuras.h"
#include "SpellMgr.h"
#include "SpellScript.h"
#include <algorithm>
#include <limits>

namespace
{
enum RunemasterSecondarySpells : uint32
{
    SPELL_RUNEBLADE = 707141,
    SPELL_FISTS_OF_POWER = 92153,
    SPELL_FISTS_AMOUNT = 500462,
    SPELL_FISTS_HIT = 712298,
    SPELL_RIFTBLADE = 92154,
    SPELL_RIFTBLADE_COUNTER = 500468,
    SPELL_RIFTBLADE_MANA = 500466,
    SPELL_WATER_AMOUNT = 802645,
    SPELL_LEYSTONE_SPRINGS = 300581,
    SPELL_LEYSTONE_MANA = 520866,
    SPELL_PRIMORDIAL_BLAST = 800732,
    SPELL_SMOLDER = 801087,
    SPELL_WARPDAGGER = 500287,
    SPELL_SPELLFIRE_RUNES = 801511,
    SPELL_SPELLFIRE_CHANCE = 802661,
    SPELL_SPELLFIRE_READY = 801512,
    SPELL_UNLEASHED_TATTOOS = 804561,
    SPELL_UNLEASHED_FIRE = 807377,
    SPELL_UNLEASHED_WATER = 807378,
    SPELL_FIRE_TATTOO = 801106,
    SPELL_WATER_TATTOO = 801107,
    SPELL_ARCANE_SIGIL = 805380,
    SPELL_ARCANE_SIGIL_DOT = 807819,
    SPELL_ARCANE_SIGIL_SILENCE = 808020,
    SPELL_FIRE_SIGIL_HIT = 807012,
    SPELL_FROST_SIGIL_HIT = 807825,
    SPELL_WATER_SIGIL_DRAIN = 807818,
    SPELL_ETERNAL_MAGIC = 806698,
    SPELL_ETERNAL_MAGIC_CHARGES = 3,
    SPELL_FIRE_ENGRAVING = 653211,
    SPELL_FIREBRAND = 653210
};

bool IsPrimordialBlast(uint32 spellId)
{
    if (sSpellMgr->GetFirstSpellInChain(spellId) == SPELL_PRIMORDIAL_BLAST)
        return true;
    return std::any_of(AscensionCompatData::TalentReplacements.begin(),
        AscensionCompatData::TalentReplacements.end(),
        [spellId](AscensionCompatData::TalentReplacement const& entry)
        {
            return entry.OriginalSpellId == SPELL_PRIMORDIAL_BLAST &&
                std::any_of(entry.Ranks.begin(), entry.Ranks.end(),
                    [spellId](AscensionCompatData::ReplacementRank const& rank)
                    {
                        return rank.SpellId == spellId;
                    });
        });
}

bool HasTattoo(Player* player, uint32 root)
{
    for (auto const& [key, application] : player->GetAppliedAuras())
    {
        Aura* aura = application->GetBase();
        if (aura->GetCasterGUID() == player->GetGUID() && sSpellMgr->GetFirstSpellInChain(aura->GetId()) == root)
            return true;
    }
    return false;
}

uint32 KnownRank(Player* player, uint32 root)
{
    for (auto const& [id, entry] : player->GetSpellMap())
        if (player->HasActiveSpell(id) && sSpellMgr->GetFirstSpellInChain(id) == root)
            return id;
    return 0;
}

void SyncUnleashed(Player* player)
{
    bool active = player->IsAlive() && player->HasAura(SPELL_UNLEASHED_TATTOOS, player->GetGUID());
    for (auto const& [tattoo, helper] : {std::pair{SPELL_FIRE_TATTOO, SPELL_UNLEASHED_FIRE},
        std::pair{SPELL_WATER_TATTOO, SPELL_UNLEASHED_WATER}})
        if (!active || !HasTattoo(player, tattoo))
            player->RemoveAurasDueToSpell(helper, player->GetGUID());
        else if (!player->HasAura(helper, player->GetGUID()))
            player->AddAura(helper, player);
}

class runemaster_secondary_auras : public UnitScript
{
public:
    runemaster_secondary_auras() : UnitScript("runemaster_secondary_auras", true,
        {UNITHOOK_ON_AURA_APPLY, UNITHOOK_ON_AURA_REMOVE, UNITHOOK_MODIFY_SPELL_EFFECT_BASE_VALUE}) { }

    void OnAuraApply(Unit* unit, Aura* aura) override
    {
        Player* player = unit ? unit->ToPlayer() : nullptr;
        if (!player || player->getClass() != CLASS_SPIRIT_MAGE || !aura)
            return;
        uint32 root = sSpellMgr->GetFirstSpellInChain(aura->GetId());
        if (root == SPELL_UNLEASHED_TATTOOS || root == SPELL_FIRE_TATTOO || root == SPELL_WATER_TATTOO)
            SyncUnleashed(player);
    }

    void OnAuraRemove(Unit* unit, AuraApplication* application, AuraRemoveMode) override
    {
        Player* player = unit ? unit->ToPlayer() : nullptr;
        if (!player || player->getClass() != CLASS_SPIRIT_MAGE || !application)
            return;
        Aura* aura = application->GetBase();
        uint32 root = sSpellMgr->GetFirstSpellInChain(aura->GetId());
        if (root == SPELL_UNLEASHED_TATTOOS || root == SPELL_FIRE_TATTOO || root == SPELL_WATER_TATTOO)
            SyncUnleashed(player);
        if (aura->GetCasterGUID() != player->GetGUID())
            return;
        if (root == SPELL_RIFTBLADE)
            player->RemoveAurasDueToSpell(SPELL_RIFTBLADE_COUNTER, player->GetGUID());
        if (root == SPELL_SPELLFIRE_RUNES)
            player->RemoveAurasDueToSpell(SPELL_SPELLFIRE_READY, player->GetGUID());
    }

    void ModifySpellEffectBaseValue(Unit const* caster, SpellInfo const* info, uint8 index, float& value) override
    {
        Player* player = caster ? const_cast<Unit*>(caster)->ToPlayer() : nullptr;
        if (!player || player->getClass() != CLASS_SPIRIT_MAGE || index != EFFECT_0)
            return;
        if (info->Id == SPELL_LEYSTONE_MANA)
        {
            AuraEffect const* springs = player->GetAuraEffect(SPELL_LEYSTONE_SPRINGS, EFFECT_1, player->GetGUID());
            if (springs && HasTattoo(player, SPELL_WATER_TATTOO))
                AddPct(value, springs->GetAmount());
            return;
        }
        if (info->Id != SPELL_RIFTBLADE_MANA)
            return;
        value += std::max(0.0f, player->GetTotalAttackPowerValue(BASE_ATTACK)) * 0.3f;
        if (HasTattoo(player, SPELL_WATER_TATTOO))
            if (SpellInfo const* reference = sSpellMgr->GetSpellInfo(SPELL_WATER_AMOUNT))
                AddPct(value, reference->Effects[EFFECT_2].CalcValue(player));
    }
};

class runemaster_secondary_casts : public AllSpellScript
{
public:
    runemaster_secondary_casts() : AllSpellScript("runemaster_secondary_casts",
        {ALLSPELLHOOK_ON_CAST, ALLSPELLHOOK_ON_HIT_RESULT}) { }

    void OnSpellCast(Spell* spell, Unit* caster, SpellInfo const* info, bool) override
    {
        Player* player = caster ? caster->ToPlayer() : nullptr;
        if (!player || player->getClass() != CLASS_SPIRIT_MAGE || !player->IsAlive() || spell->IsTriggered())
            return;
        uint32 root = sSpellMgr->GetFirstSpellInChain(info->Id);
        if (root == SPELL_SMOLDER)
            player->RemoveAurasDueToSpell(SPELL_SPELLFIRE_READY, player->GetGUID());
        bool const riftblade = player->HasAura(SPELL_RIFTBLADE, player->GetGUID());
        bool const eternalMagic = player->HasAura(SPELL_ETERNAL_MAGIC, player->GetGUID());
        bool const primordialBlast = IsPrimordialBlast(info->Id);
        if ((primordialBlast && (riftblade || eternalMagic)) ||
            (root == SPELL_SMOLDER && riftblade))
        {
            if (uint32 rank = KnownRank(player, SPELL_RUNEBLADE))
                player->RestoreSpellCharge(rank,
                    primordialBlast && eternalMagic ? SPELL_ETERNAL_MAGIC_CHARGES : 1);
        }
        if (root == SPELL_RUNEBLADE && riftblade)
        {
            player->CastSpell(player, SPELL_RIFTBLADE_COUNTER, true);
            if (Aura* counter = player->GetAura(SPELL_RIFTBLADE_COUNTER, player->GetGUID());
                counter && counter->GetStackAmount() >= 3)
            {
                player->RemoveAurasDueToSpell(SPELL_RIFTBLADE_COUNTER, player->GetGUID());
                player->CastSpell(player, SPELL_RIFTBLADE_MANA, true);
            }
        }
        if ((root == SPELL_RUNEBLADE || root == SPELL_WARPDAGGER) &&
            player->HasAura(SPELL_SPELLFIRE_RUNES, player->GetGUID()))
        {
            SpellInfo const* reference = sSpellMgr->GetSpellInfo(root == SPELL_RUNEBLADE
                ? SPELL_SPELLFIRE_CHANCE : SPELL_SPELLFIRE_RUNES);
            if (reference && roll_chance_i(reference->ProcChance))
            {
                if (uint32 rank = KnownRank(player, SPELL_SMOLDER))
                    player->RemoveSpellCooldown(rank, true);
                player->AddAura(SPELL_SPELLFIRE_READY, player);
            }
        }
    }

    void OnSpellHitResult(Spell* spell, Unit* target, uint8 miss, uint32 damage, uint32, bool) override
    {
        Player* player = spell->GetCaster()->ToPlayer();
        if (!player || player->getClass() != CLASS_SPIRIT_MAGE || !player->IsAlive() || !player->IsInWorld() ||
            spell->IsTriggered() || !damage ||
            miss != SPELL_MISS_NONE || !target || !target->IsAlive() || target == player ||
            player->IsFriendlyTo(target) || !player->GetWeaponForAttack(OFF_ATTACK, true) ||
            sSpellMgr->GetFirstSpellInChain(spell->GetSpellInfo()->Id) != SPELL_RUNEBLADE ||
            !player->HasAura(SPELL_FISTS_OF_POWER, player->GetGUID()) || spell->GetScriptValue(SPELL_FISTS_HIT))
            return;
        SpellInfo const* reference = sSpellMgr->GetSpellInfo(SPELL_FISTS_AMOUNT);
        SpellInfo const* helper = sSpellMgr->GetSpellInfo(SPELL_FISTS_HIT);
        if (!reference || !helper)
            return;
        spell->SetScriptValue(SPELL_FISTS_HIT, 1);
        uint64 amount = uint64(damage) * std::clamp(reference->Effects[EFFECT_0].CalcValue(player), 0, 100) / 100;
        SpellCastTargets targets;
        targets.SetUnitTarget(target);
        CustomSpellValues values;
        values.AddSpellMod(SPELLVALUE_BASE_POINT0, int32(std::min<uint64>(amount, std::numeric_limits<int32>::max())));
        values.AddSpellMod(SPELLVALUE_MELEE_ATTACK_TYPE, OFF_ATTACK);
        player->CastSpell(targets, helper, &values, TRIGGERED_FULL_MASK);
    }
};

class aura_ascension_arcane_palm_sigil : public AuraScript
{
    PrepareAuraScript(aura_ascension_arcane_palm_sigil);

    bool Check(ProcEventInfo& event)
    {
        Unit* player = GetTarget();
        DamageInfo const* damage = event.GetDamageInfo();
        Unit* target = event.GetActionTarget();
        return player->IsPlayer() && player->getClass() == CLASS_SPIRIT_MAGE && player->IsAlive() &&
            GetCaster() == player && event.GetActor() == player && target && target->IsAlive() &&
            target != player && !player->IsFriendlyTo(target) && damage && damage->GetDamage() &&
            damage->GetDamageType() == SPELL_DIRECT_DAMAGE && (damage->GetSchoolMask() & SPELL_SCHOOL_MASK_MAGIC);
    }

    void Proc(AuraEffect const* effect, ProcEventInfo& event)
    {
        PreventDefaultAction();
        Unit* player = GetTarget();
        uint64 amount = uint64(event.GetDamageInfo()->GetDamage()) * std::clamp(effect->GetAmount(), 0, 100) / 100;
        player->CastCustomSpell(SPELL_ARCANE_SIGIL_DOT, SPELLVALUE_BASE_POINT0,
            int32(std::min<uint64>(amount, std::numeric_limits<int32>::max())),
            event.GetActionTarget(), TRIGGERED_FULL_MASK);
        player->CastSpell(event.GetActionTarget(), SPELL_ARCANE_SIGIL_SILENCE, true);
    }

    void Register() override
    {
        DoCheckProc += AuraCheckProcFn(aura_ascension_arcane_palm_sigil::Check);
        OnEffectProc += AuraEffectProcFn(aura_ascension_arcane_palm_sigil::Proc, EFFECT_0, AuraType(354));
    }
};

class aura_ascension_damage_palm_sigil : public AuraScript
{
    PrepareAuraScript(aura_ascension_damage_palm_sigil);

    bool Validate(SpellInfo const* info) override
    {
        uint32 const helper = info->Effects[EFFECT_0].TriggerSpell;
        return info->Effects[EFFECT_0].IsAura(AuraType(354)) &&
            (helper == SPELL_FIRE_SIGIL_HIT || helper == SPELL_FROST_SIGIL_HIT ||
                helper == SPELL_WATER_SIGIL_DRAIN) && ValidateSpellInfo({helper});
    }

    bool Check(ProcEventInfo& event)
    {
        Unit* player = GetTarget();
        Unit* target = event.GetActionTarget();
        DamageInfo const* damage = event.GetDamageInfo();
        bool const physicalSpellAllowed = GetSpellInfo()->Effects[EFFECT_0].TriggerSpell == SPELL_FIRE_SIGIL_HIT;
        return player->IsPlayer() && player->getClass() == CLASS_SPIRIT_MAGE && player->IsAlive() &&
            GetCaster() == player && event.GetActor() == player && target && target->IsAlive() &&
            target != player && !player->IsFriendlyTo(target) && damage && damage->GetDamage() &&
            damage->GetDamageType() == SPELL_DIRECT_DAMAGE &&
            (physicalSpellAllowed || (damage->GetSchoolMask() & SPELL_SCHOOL_MASK_MAGIC));
    }

    void Proc(AuraEffect const* effect, ProcEventInfo& event)
    {
        PreventDefaultAction();
        uint64 const amount = uint64(event.GetDamageInfo()->GetDamage()) * std::max(0, effect->GetAmount()) / 100;
        GetTarget()->CastCustomSpell(effect->GetSpellInfo()->Effects[effect->GetEffIndex()].TriggerSpell,
            SPELLVALUE_BASE_POINT0,
            int32(std::min<uint64>(amount, std::numeric_limits<int32>::max())), event.GetActionTarget(),
            TRIGGERED_FULL_MASK, nullptr, effect);
    }

    void Register() override
    {
        DoCheckProc += AuraCheckProcFn(aura_ascension_damage_palm_sigil::Check);
        OnEffectProc += AuraEffectProcFn(aura_ascension_damage_palm_sigil::Proc, EFFECT_0, AuraType(354));
    }
};

class aura_ascension_runemaster_fire_engraving : public AuraScript
{
    PrepareAuraScript(aura_ascension_runemaster_fire_engraving);

    bool Check(ProcEventInfo& event)
    {
        Unit* player = GetTarget();
        DamageInfo const* damage = event.GetDamageInfo();
        Unit* target = event.GetActionTarget();
        return player->IsPlayer() && player->getClass() == CLASS_SPIRIT_MAGE && event.GetActor() == player &&
            target && target != player && target->IsAlive() && damage && damage->GetDamage() &&
            damage->GetDamageType() != DOT;
    }

    void Proc(AuraEffect const*, ProcEventInfo& event)
    {
        PreventDefaultAction();
        Unit* player = GetTarget();
        Unit* target = event.GetActionTarget();
        if (Aura* brand = target->GetAura(SPELL_FIREBRAND, player->GetGUID()))
        {
            int32 const duration = brand->GetDuration();
            brand->ModStackAmount(1);
            brand->SetDuration(duration);
            return;
        }
        player->CastSpell(target, SPELL_FIREBRAND, true);
    }

    void Register() override
    {
        DoCheckProc += AuraCheckProcFn(aura_ascension_runemaster_fire_engraving::Check);
        OnEffectProc += AuraEffectProcFn(aura_ascension_runemaster_fire_engraving::Proc, EFFECT_0,
                                         SPELL_AURA_PROC_TRIGGER_SPELL);
    }
};

class runemaster_secondary_metadata : public GlobalScript
{
public:
    runemaster_secondary_metadata() : GlobalScript("runemaster_secondary_metadata",
        {GLOBALHOOK_ON_LOAD_SPELL_CUSTOM_ATTR}) { }

    void OnLoadSpellCustomAttr(SpellInfo* info) override
    {
        if (info->SpellFamilyName != 38)
            return;
        if (info->Id == SPELL_FISTS_HIT || info->Id == SPELL_ARCANE_SIGIL_DOT ||
            info->Id == SPELL_FIRE_SIGIL_HIT || info->Id == SPELL_FROST_SIGIL_HIT ||
            info->Id == SPELL_WATER_SIGIL_DRAIN)
        {
            info->AttributesEx2 |= SPELL_ATTR2_CANT_CRIT;
            info->AttributesEx3 |= SPELL_ATTR3_IGNORE_CASTER_MODIFIERS;
            info->AttributesEx4 |= SPELL_ATTR4_IGNORE_DAMAGE_TAKEN_MODIFIERS;
            info->AscensionInheritsResolvedAmount = true;
            info->Effects[EFFECT_0].BonusMultiplier = 0.0f;
        }
        if (info->Id == SPELL_UNLEASHED_FIRE || info->Id == SPELL_UNLEASHED_WATER ||
            info->Id == SPELL_SPELLFIRE_READY || info->Id == SPELL_RIFTBLADE_COUNTER)
        {
            info->AttributesCu &= ~SPELL_ATTR0_CU_FORCE_AURA_SAVING;
            info->AttributesCu |= SPELL_ATTR0_CU_AURA_CANNOT_BE_SAVED;
        }
    }
};
}

void AddSC_AscensionRunemasterSecondary()
{
    new runemaster_secondary_auras();
    new runemaster_secondary_casts();
    new runemaster_secondary_metadata();
    RegisterSpellScript(aura_ascension_arcane_palm_sigil);
    RegisterSpellScript(aura_ascension_damage_palm_sigil);
    RegisterSpellScript(aura_ascension_runemaster_fire_engraving);
}
