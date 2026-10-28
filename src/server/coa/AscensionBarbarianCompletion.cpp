/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "AscensionBarbarianCompletion.h"
#include "Creature.h"
#include "DBCStores.h"
#include "Item.h"
#include "Pet.h"
#include "Player.h"
#include "Random.h"
#include "ScriptMgr.h"
#include "Spell.h"
#include "SpellAuraEffects.h"
#include "SpellAuras.h"
#include "SpellMgr.h"
#include "SpellScript.h"
#include <algorithm>
#include <cmath>

namespace AscensionBarbarian
{
Player* Owner(Unit* unit)
{
    Player* player = unit ? unit->ToPlayer() : nullptr;
    return player && player->getClass() == CLASS_BARBARIAN ? player : nullptr;
}

Unit* Ancestor(Player* player)
{
    Unit* pet = player ? player->GetGuardianPet() : nullptr;
    return pet && pet->GetEntry() == 51265 && pet->GetOwnerGUID() == player->GetGUID() && pet->IsAlive() ?
        pet : nullptr;
}

class barbarian_ancestor_appearance : public PetScript
{
public:
    barbarian_ancestor_appearance() : PetScript("barbarian_ancestor_appearance", {PETHOOK_ON_PET_ADD_TO_WORLD}) { }

    void OnPetAddToWorld(Pet* pet) override
    {
        Player* player = pet ? pet->GetOwner() : nullptr;
        if (!player || player->getClass() != CLASS_BARBARIAN || pet->GetEntry() != 51265)
            return;

        uint32 const displayId = player->getRace() == RACE_DWARF ? 260901 : 173031;
        CreatureDisplayInfoEntry const* display = sCreatureDisplayInfoStore.LookupEntry(displayId);
        if (!display || !sCreatureModelDataStore.LookupEntry(display->ModelId))
            return;

        pet->SetNativeDisplayId(display->Displayid);
        if (!pet->HasAuraType(SPELL_AURA_TRANSFORM) && !pet->HasAuraType(SPELL_AURA_CLONE_CASTER) &&
            !pet->HasAuraType(SPELL_AURA_MOD_SHAPESHIFT))
            pet->SetDisplayId(display->Displayid, pet->GetObjectScale());
    }
};

bool Enraged(Unit const* unit)
{
    return unit && (unit->HasAuraState(AURA_STATE_ENRAGE) || unit->HasAura(801761) || unit->HasAura(805804));
}

void ReadyToKill(Player* player)
{
    for (uint32 rank : {850021u, 850038u, 850039u, 850040u, 850041u, 850042u, 850043u})
        if (player->HasSpell(rank))
        {
            player->CastSpell(player, 850025, true);
            return;
        }
}

void Extend(Unit* owner, uint32 id, int32 amount, int32 cap)
{
    if (Aura* aura = owner->GetAura(id, owner->GetGUID()))
    {
        int32 duration = aura->GetDuration();
        if (duration <= 0)
            return;
        duration = int32(std::min<int64>(int64(duration) + amount, cap > 0 ? cap : 3600000));
        aura->SetMaxDuration(std::max(aura->GetMaxDuration(), duration));
        aura->SetDuration(duration);
    }
}

void ApplyContracts(SpellInfo* info)
{
    if (!info || info->SpellFamilyName != 18)
        return;
    uint32 id = info->Id;
    if (id == 705171)
        info->Effects[EFFECT_2].Effect = 0;
    if (id == 705186)
        info->Effects[EFFECT_0].SpellClassMask = flag96(0, 64 | 2 | 2048, 0);
    if (id == 705234 || id == 707779)
    {
        info->Effects[EFFECT_0].MiscValue = ASCENSION_STATE_MASKED_CRIT;
        info->Effects[EFFECT_0].SpellClassMask = flag96(5120, 4 | 256 | 8 | 524288, 0);
    }
    if (id == 705152 || id == 707766)
    {
        info->Effects[EFFECT_0].ApplyAuraName = SPELL_AURA_ADD_PCT_MODIFIER;
        info->Effects[EFFECT_0].SpellClassMask[0] |= 33554432;
    }
    if (id == 804750)
    {
        info->Effects[EFFECT_0].TargetA = SpellImplicitTargetInfo(TARGET_UNIT_CASTER);
        info->Effects[EFFECT_1].ApplyAuraName = SPELL_AURA_DUMMY;
    }
    if (id == 807047)
        info->Effects[EFFECT_1].ApplyAuraName = SPELL_AURA_DUMMY;
    if (id == 570242 || id == 560446)
    {
        info->Effects[EFFECT_0].ApplyAuraName = SPELL_AURA_DUMMY;
        info->Effects[EFFECT_0].TargetA = SpellImplicitTargetInfo(TARGET_UNIT_CASTER);
    }
    if (id == 705235)
    {
        info->Effects[EFFECT_1].ApplyAuraName = SPELL_AURA_DUMMY;
        info->Effects[EFFECT_2].ApplyAuraName = SPELL_AURA_DUMMY;
    }
    if (id == 570337 || id == 561330 || id == 706421)
        for (SpellEffectInfo& effect : info->Effects)
            if (effect.IsAura())
                effect.ApplyAuraName = SPELL_AURA_DUMMY;
    if (id == 806228)
        info->Effects[EFFECT_1].ApplyAuraName = SPELL_AURA_DUMMY;
    if (id == 570106)
        info->Effects[EFFECT_1].Effect = 0;
    if (id == 804862)
        info->Effects[EFFECT_1].Effect = 0;
    if (id == 804341)
    {
        info->Effects[EFFECT_0].Effect = 0;
        info->ProcCharges = 3;
    }
    if (id == 524684)
        info->ProcCharges = 1;
    if (id == 706487)
        info->StackAmount = 1;
    if (id == 707584)
    {
        info->Effects[EFFECT_0].Effect = 0;
        info->Effects[EFFECT_2].Effect = 0;
    }
    if (id == 805232)
    {
        info->Effects[EFFECT_1].BasePoints = -1;
        info->Effects[EFFECT_2].Effect = 0;
        for (uint8 i : { uint8(EFFECT_0), uint8(EFFECT_1) })
        {
            info->Effects[i].TargetA = SpellImplicitTargetInfo(TARGET_UNIT_TARGET_ENEMY);
            info->Effects[i].TargetB = SpellImplicitTargetInfo();
        }
    }
    if (id == 801783)
    {
        info->Effects[EFFECT_0].BasePoints = 99;
        info->Effects[EFFECT_1].Effect = 0;
    }
    if (id == 573077 || id == 804771 || id == 500534)
        for (SpellEffectInfo& effect : info->Effects)
            if (effect.IsEffect())
                effect.TargetA = SpellImplicitTargetInfo(TARGET_UNIT_TARGET_ALLY);
    if (id == 560125 || id == 560626 || id == 561333)
        info->Effects[EFFECT_0].SpellClassMask = flag96(0xFFFFFFFF, 0xFFFFFFFF, 0xFFFFFFFF);
    if (id == 783054 || id == 782801 || id == 300870 || id == 707660 || id == 524675 || id == 500534)
    {
        info->AttributesEx2 |= SPELL_ATTR2_CANT_CRIT;
        info->AttributesEx3 |= SPELL_ATTR3_IGNORE_CASTER_MODIFIERS;
        info->AttributesEx4 |= SPELL_ATTR4_IGNORE_DAMAGE_TAKEN_MODIFIERS;
        info->AttributesCu |= SPELL_ATTR0_CU_IGNORE_ARMOR;
    }
    if (id == 707410)
        info->Effects[EFFECT_0].ApplyAuraName = SPELL_AURA_DUMMY;
    if (id == 800401)
        info->AttributesCu &= ~SPELL_ATTR0_CU_NEGATIVE;
    if (id == 801761)
    {
        SpellEffectInfo& cost = info->Effects[EFFECT_1];
        cost.ApplyAuraName = SPELL_AURA_ADD_PCT_MODIFIER;
        cost.MiscValue = SPELLMOD_COST;
        cost.SpellClassMask = flag96(65536, 0, 0);
        cost.TargetA = SpellImplicitTargetInfo(TARGET_UNIT_CASTER);
    }
}
}

namespace
{
using namespace AscensionBarbarian;

constexpr uint32 SPELL_BARBARIC_RAGE = 804337;

bool EnrageSource(SpellInfo const* info)
{
    return info->GetAuraState() == AURA_STATE_ENRAGE || info->Id == 801761 || info->Id == 805804;
}

class barbarian_barbaric_rage : public UnitScript
{
public:
    barbarian_barbaric_rage() : UnitScript("barbarian_barbaric_rage", true, { UNITHOOK_ON_AURA_APPLY,
        UNITHOOK_ON_AURA_REMOVE, UNITHOOK_ON_AFTER_AURA_EFFECT_CALCULATE_AMOUNT }) { }

    void OnAfterAuraEffectCalculateAmount(AuraEffect const* effect, Unit*, int32& amount) override
    {
        if (effect->GetId() == SPELL_BARBARIC_RAGE && effect->GetEffIndex() == EFFECT_0 &&
            effect->GetBase()->GetType() == UNIT_AURA_TYPE && !Enraged(effect->GetBase()->GetUnitOwner()))
            amount = 0;
    }

    void OnAuraApply(Unit* unit, Aura* aura) override
    {
        if (aura)
            Synchronize(Owner(unit), aura->GetSpellInfo());
    }

    void OnAuraRemove(Unit* unit, AuraApplication* application, AuraRemoveMode) override
    {
        if (application)
            Synchronize(Owner(unit), application->GetBase()->GetSpellInfo());
    }

private:
    static void Synchronize(Player* player, SpellInfo const* changed)
    {
        if (player && EnrageSource(changed))
            if (AuraEffect* effect = player->GetAuraEffect(SPELL_BARBARIC_RAGE, EFFECT_0, player->GetGUID()))
                effect->RecalculateAmount(player);
    }
};

class barbarian_scaling : public UnitScript
{
public:
    barbarian_scaling() : UnitScript("barbarian_scaling", true, { UNITHOOK_MODIFY_SPELL_EFFECT_BASE_VALUE }) { }

    void ModifySpellEffectBaseValue(Unit const* caster, SpellInfo const* info, uint8 index, float& value) override
    {
        Player const* player = caster ? caster->ToPlayer() : nullptr;
        if (!player || player->getClass() != CLASS_BARBARIAN || info->SpellFamilyName != 18)
            return;
        if (!index && Family(info, 1, 262144) && player->HasAura(570242))
            value += player->GetStat(STAT_AGILITY) * 0.2f;
        if (player->HasAura(560446) && ((!index && Family(info, 1, 1048576)) ||
            (index == 2 && Family(info, 1, 64))))
            value += player->GetStat(STAT_STRENGTH) * 0.3f;
        if (!index && info->Id == 560521 && player->HasAura(705235))
            value += player->GetStat(STAT_AGILITY) * 0.1f;
        if (info->Id == 255846 && index == 1)
            value += player->GetTotalAttackPowerValue(RANGED_ATTACK) * 0.15f;
        if (info->Id == 804143 && !index)
            value += player->GetTotalAttackPowerValue(RANGED_ATTACK) * 0.055f;
        if ((info->Id == 801753 || info->Id == 803908) && index == 1)
            value += player->GetTotalAttackPowerValue(BASE_ATTACK);
        if (info->Id == 801761 && index == 1)
            value = player->HasAura(707410) ? -100.0f : 0.0f;
    }
};

class aura_ascension_barbarian_tankard : public AuraScript
{
    PrepareAuraScript(aura_ascension_barbarian_tankard);

    bool Validate(SpellInfo const*) override
    {
        return ValidateSpellInfo({SPELL_FULL_TANKARD, SPELL_EMPTY_TANKARD});
    }

    void Apply(AuraEffect const*, AuraEffectHandleModes)
    {
        Player* player = Owner(GetTarget());
        if (!player)
            return;

        if (GetStackAmount() >= GetSpellInfo()->CalcMaxAuraStacks(player))
        {
            if (!player->HasAura(SPELL_FULL_TANKARD))
                player->AddAura(SPELL_FULL_TANKARD, player);
        }
        else
            player->RemoveAurasDueToSpell(SPELL_FULL_TANKARD);
    }

    void Remove(AuraEffect const*, AuraEffectHandleModes)
    {
        if (Player* player = Owner(GetTarget()))
            player->RemoveAurasDueToSpell(SPELL_FULL_TANKARD);
    }

    void Register() override
    {
        AfterEffectApply += AuraEffectApplyFn(aura_ascension_barbarian_tankard::Apply, EFFECT_0,
            SPELL_AURA_ADD_PCT_MODIFIER, AURA_EFFECT_HANDLE_REAL_OR_REAPPLY_MASK);
        AfterEffectRemove += AuraEffectRemoveFn(aura_ascension_barbarian_tankard::Remove, EFFECT_0,
            SPELL_AURA_ADD_PCT_MODIFIER, AURA_EFFECT_HANDLE_REAL);
    }
};

class aura_ascension_barbarian_lifecycle : public AuraScript
{
    PrepareAuraScript(aura_ascension_barbarian_lifecycle);

    void Apply(AuraEffect const* effect, AuraEffectHandleModes)
    {
        if (Spirit(GetId()))
            if (Player* self = Owner(GetTarget()))
                for (uint32 spirit : { 707763, 707764, 707775, 712467, 712468 })
                    if (spirit != GetId())
                        self->RemoveAurasDueToSpell(spirit);
        if (effect->GetEffIndex() != EFFECT_0)
            return;
        if (GetId() == 805804)
            if (Unit* caster = GetCaster())
                caster->AddAura(805843, GetTarget());
        if (Family(GetSpellInfo(), 0, 262144))
            if (Player* caster = Owner(GetCaster()))
            {
                uint32 helper = caster->HasAura(561332) ? 561333 : caster->HasAura(560586) ? 560626 : 0;
                if (helper)
                    caster->CastSpell(GetTarget(), helper, true);
            }
        Player* player = Owner(GetTarget());
        if (!player)
            return;
        uint32 id = GetId();
        if (id == 801761 && player->HasAura(707410))
            player->CastSpell(player, 521240, true);
        if (id == 707410)
            if (AuraEffect* cost = player->GetAuraEffect(801761, EFFECT_1))
                cost->RecalculateAmount();
        if (id == 560521)
            ReadyToKill(player);
        if (id == 560933 && player->HasAura(560910))
            player->CastSpell(player, 560909, true);
        if (id == 705198 && !player->HasSpell(807482))
            player->learnSpell(807482, true);
        if (id == 706487)
        {
            if (!player->HasSpell(807482))
                player->learnSpell(807482, true);
            for (auto const& [sid, entry] : player->GetSpellMap())
                if (player->HasActiveSpell(sid) &&
                    Family(sSpellMgr->GetSpellInfo(sid), 1, 262144) && sid != 807236)
                    player->SetTemporarySpellReplacement(sid, 807482);
        }
    }

    void Remove(AuraEffect const* effect, AuraEffectHandleModes)
    {
        if (effect->GetEffIndex() != EFFECT_0)
            return;
        if (GetId() == 805804)
            GetTarget()->RemoveAurasDueToSpell(805843, GetCasterGUID());
        if (Family(GetSpellInfo(), 0, 262144))
        {
            GetTarget()->RemoveAurasDueToSpell(560626, GetCasterGUID());
            GetTarget()->RemoveAurasDueToSpell(561333, GetCasterGUID());
        }
        Player* player = Owner(GetTarget());
        if (!player)
            return;
        uint32 id = GetId();
        if (id == 706487 || id == 705198)
            for (auto const& [sid, entry] : player->GetSpellMap())
            {
                (void)entry;
                if (player->GetTemporarySpellReplacement(sid) == 807482)
                    player->SetTemporarySpellReplacement(sid, 0);
            }
        if (id == 705198)
            player->RemoveAurasDueToSpell(706487);
        if (id == 705198)
            player->removeSpell(807482, SPEC_MASK_ALL, true);
        if (id == 804141)
            player->RemoveAurasDueToSpell(572531);
        if (id == 707410)
            if (AuraEffect* cost = player->GetAuraEffect(801761, EFFECT_1))
                cost->RecalculateAmount();
        if (id == 800637 || id == 355562)
            player->RemoveAurasDueToSpell(800645);
    }

    void Periodic(AuraEffect const* effect, bool&, int32& amplitude)
    {
        if (GetId() == 560521 && effect->GetEffIndex() <= EFFECT_1)
            if (Unit* caster = GetCaster())
                if (caster->HasAura(705235))
                    amplitude = int32(amplitude / 1.25f);
    }

    void Register() override
    {
        AfterEffectApply += AuraEffectApplyFn(aura_ascension_barbarian_lifecycle::Apply,
            EFFECT_ALL, SPELL_AURA_ANY, AURA_EFFECT_HANDLE_REAL_OR_REAPPLY_MASK);
        AfterEffectRemove += AuraEffectRemoveFn(aura_ascension_barbarian_lifecycle::Remove,
            EFFECT_ALL, SPELL_AURA_ANY, AURA_EFFECT_HANDLE_REAL);
        DoEffectCalcPeriodic += AuraEffectCalcPeriodicFn(aura_ascension_barbarian_lifecycle::Periodic,
            EFFECT_ALL, SPELL_AURA_ANY);
    }
};

class barbarian_casts : public AllSpellScript
{
public:
    barbarian_casts() : AllSpellScript("barbarian_casts", { ALLSPELLHOOK_ON_CAST, ALLSPELLHOOK_ON_CALCULATED_TARGET,
        ALLSPELLHOOK_ON_SUCCESSFUL_INTERRUPT, ALLSPELLHOOK_ON_SPELL_CHECK_CAST, ALLSPELLHOOK_ON_BEFORE_EFFECTS,
        ALLSPELLHOOK_ON_CALC_MAX_DURATION }) { }

    void OnCalcMaxDuration(Aura const* aura, int32& duration) override
    {
        if (aura && aura->GetId() == 705170)
            duration = -1;
    }

    void OnSpellBeforeEffects(Spell* spell, Unit* caster, SpellInfo const* info) override
    {
        Player* player = Owner(caster);
        if (!player || spell->IsTriggered() || !Family(info, 1, 2048) || !spell->TryMarkScriptEventHandled(26))
            return;
        bool landed = std::any_of(spell->GetUniqueTargetInfo()->begin(), spell->GetUniqueTargetInfo()->end(),
            [](TargetInfo const& hit) { return hit.missCondition == SPELL_MISS_NONE; });
        if (!landed)
            return;
        uint32 extra = std::min<uint32>(player->GetPower(POWER_ENERGY) / 2,
            std::max(0, info->Effects[EFFECT_2].CalcValue(player)));
        player->ModifyPower(POWER_ENERGY, -int32(extra));
        spell->SetScriptExtraPowerSpent(extra);
    }

    void OnSpellCheckCast(Spell* spell, bool, SpellCastResult& result) override
    {
        Player* player = Owner(spell->GetCaster());
        if (player && !spell->IsTriggered() &&
            (spell->GetSpellInfo()->Id == 801759 || spell->GetSpellInfo()->Id == 803499) && !Enraged(player))
            result = SPELL_FAILED_CASTER_AURASTATE;
    }

    void OnSpellCast(Spell* spell, Unit* caster, SpellInfo const* info, bool) override
    {
        Player* player = Owner(caster);
        if (!player || spell->IsTriggered())
            return;
        auto talent = [&](uint32 passive, uint32 child)
        {
            if (player->HasAura(passive))
                player->CastSpell(player, child, true);
        };
        uint32 id = info->Id;
        if (Family(info, 1, 16777216))
        {
            talent(805812, 570106);
            Item* weapon = player->GetWeaponForAttack(BASE_ATTACK, true);
            if (player->HasAura(805812) && weapon && weapon->GetTemplate()->InventoryType == INVTYPE_2HWEAPON)
                player->CastSpell(player, 570222, true);
        }
        if (id == 801761)
        {
            talent(561359, 560933);
            talent(705202, 560521);
            if (player->HasAura(572799))
                if (Unit* pet = Ancestor(player))
                    player->CastSpell(pet, 804771, true);
        }
        if (Family(info, 1, 8388608))
            talent(560205, 560521);
        if (Spear(info) && Enraged(player) && player->HasAura(560564))
        {
            player->CastSpell(player, 804341, true);
            player->RestoreSpellChargeCategory(60, 3);
        }
        if (Family(info, 1, 262144) && player->HasAura(705198) && roll_chance_i(25))
            player->CastSpell(player, 706487, true);
        if (id == 807482)
        {
            player->RemoveAurasDueToSpell(706487);
            player->CastSpell(player, 560521, true);
        }
        if (id == 560883 && player->HasAura(712429) && !player->HasSpellCooldown(712429))
        {
            player->RemoveSpellCooldown(id, true);
            player->AddSpellCooldown(712429, 0, 90000);
        }
        if (Family(info, 1, 536870912))
            talent(705162, 560946);
        if (Family(info, 0, 268435456))
        {
            uint32 chance = player->HasAura(681466) ? 60 : player->HasAura(681063) ? 30 : 0;
            if (chance && roll_chance_i(chance))
                player->RemoveSpellCooldown(id, true);
        }
    }

    void OnSpellCalculatedTarget(Spell* spell, Unit* target, TargetInfo& hit) override
    {
        Player* player = Owner(spell->GetCaster());
        if (!player || !target || target == player)
            return;
        SpellInfo const* info = spell->GetSpellInfo();
        float multiplier = 1.0f;
        if (Family(info, 1, 2048) && !target->IsControlledByPlayer())
            multiplier *= 1.0f + spell->GetScriptExtraPowerSpent() / 100.0f;
        if (Family(info, 1, 1048576))
            if (Item* weapon = player->GetWeaponForAttack(BASE_ATTACK, true))
                multiplier *= weapon->GetTemplate()->Delay / 2700.0f;
        if ((Whirl(info->Id) || info->Id == 805232) && player->HasAura(804750) && target->HealthBelowPct(35))
            multiplier *= 2.0f;
        if (Family(info, 1, 64))
        {
            if (player->HasAura(807047) && !target->IsControlledByPlayer())
                multiplier *= 1.15f;
            if (player->HasAura(804745) &&
                (target->HasAura(520523) || target->HasAura(520710) || target->HasAura(520711)))
                hit.crit = true;
        }
        hit.damage = int32(hit.damage * multiplier);
        hit.damageBeforeTakenMods = int32(hit.damageBeforeTakenMods * multiplier);
    }

    void OnSpellSuccessfulInterrupt(Spell* spell, Unit*) override
    {
        Player* player = Owner(spell->GetCaster());
        if (player && spell->GetSpellInfo()->Id == 802792 && !spell->IsTriggered() && player->HasAura(705196) &&
            spell->TryMarkScriptEventHandled(25))
        {
            player->CastSpell(player, 804862, true);
            player->ModifyPower(POWER_ENERGY, std::max(0, spell->GetPowerCost()) / 2);
        }
    }
};
}

void AddAscensionBarbarianCompletionScripts()
{
    new barbarian_ancestor_appearance();
    new barbarian_barbaric_rage();
    new barbarian_scaling();
    new barbarian_casts();
    RegisterSpellScript(aura_ascension_barbarian_tankard);
    RegisterSpellScript(aura_ascension_barbarian_lifecycle);
}
