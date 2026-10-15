/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "Pet.h"
#include "Player.h"
#include "ScriptMgr.h"
#include "SpellAuraEffects.h"
#include "SpellAuras.h"
#include "SpellInfo.h"
#include "SpellScript.h"

#include <algorithm>
#include <array>
#include <limits>

namespace
{
enum EmpoweredBoonSpells : uint32
{
    EmpoweredBear = 523524,
    EmpoweredTurtle = 523523,
    EmpoweredHawk = 523526,
    EmpoweredWolf = 523527,
    EmpoweredLion = 505220
};

constexpr std::array<std::pair<uint32, uint32>, 5> Boons = {{
    {500939, EmpoweredBear}, {500935, EmpoweredTurtle}, {500943, EmpoweredHawk},
    {800137, EmpoweredWolf}, {504856, EmpoweredLion}
}};

class aura_ascension_empowered_boons : public AuraScript
{
    PrepareAuraScript(aura_ascension_empowered_boons);

    bool Validate(SpellInfo const*) override
    {
        return ValidateSpellInfo({EmpoweredBear, EmpoweredTurtle, EmpoweredHawk, EmpoweredWolf, EmpoweredLion});
    }

    bool Load() override
    {
        return GetUnitOwner()->IsPlayer() && GetUnitOwner()->getClass() == CLASS_WILDWALKER &&
            GetCasterGUID() == GetUnitOwner()->GetGUID();
    }

    void Empower(AuraEffect const*, ProcEventInfo&)
    {
        PreventDefaultAction();
        Player* owner = GetTarget()->ToPlayer();
        for (auto const& [boon, empowered] : Boons)
            if (owner->HasAura(boon, owner->GetGUID()))
            {
                if (empowered == EmpoweredLion)
                {
                    if (Pet* pet = owner->GetPet(); pet && pet->IsAlive())
                        owner->CastSpell(pet, empowered, TRIGGERED_FULL_MASK);
                }
                else
                    owner->CastSpell(owner, empowered, TRIGGERED_FULL_MASK);
                return;
            }
    }

    void Register() override
    {
        OnEffectProc += AuraEffectProcFn(aura_ascension_empowered_boons::Empower,
            EFFECT_0, SPELL_AURA_PROC_TRIGGER_SPELL);
    }
};

class primalist_empowered_boons_metadata : public GlobalScript
{
public:
    primalist_empowered_boons_metadata() : GlobalScript("primalist_empowered_boons_metadata",
        {GLOBALHOOK_ON_LOAD_SPELL_CUSTOM_ATTR}) { }

    void OnLoadSpellCustomAttr(SpellInfo* info) override
    {
        if (info->Id != EmpoweredHawk || info->SpellFamilyName != 37)
            return;
        if (info->Effects[EFFECT_0].Effect == SPELL_EFFECT_ENERGIZE_PCT &&
            info->Effects[EFFECT_0].MiscValueB == 1)
            info->Effects[EFFECT_0].Effect = SPELL_EFFECT_ENERGIZE;
        if (info->Effects[EFFECT_1].Effect == SPELL_EFFECT_HEAL_PCT &&
            info->Effects[EFFECT_1].MiscValueB == 1)
            info->Effects[EFFECT_1].Effect = SPELL_EFFECT_HEAL;
    }
};

class spell_ascension_empowered_hawk : public SpellScript
{
    PrepareSpellScript(spell_ascension_empowered_hawk);

    void Amount(SpellEffIndex index)
    {
        Unit* target = GetHitUnit();
        if (!target)
            return;
        uint64 maximum = index == EFFECT_0 ? target->GetMaxPower(POWER_MANA) : target->GetMaxHealth();
        uint64 current = index == EFFECT_0 ? target->GetPower(POWER_MANA) : target->GetHealth();
        uint64 amount = (maximum - std::min(current, maximum)) * std::clamp(GetEffectValue(), 0, 100) / 100;
        SetEffectValue(int32(std::min<uint64>(amount, std::numeric_limits<int32>::max())));
    }

    void Register() override
    {
        OnEffectHitTarget += SpellEffectFn(spell_ascension_empowered_hawk::Amount, EFFECT_0, SPELL_EFFECT_ENERGIZE);
        OnEffectLaunchTarget += SpellEffectFn(spell_ascension_empowered_hawk::Amount, EFFECT_1, SPELL_EFFECT_HEAL);
    }
};

class spell_ascension_empowered_wolf : public SpellScript
{
    PrepareSpellScript(spell_ascension_empowered_wolf);

    void Cleanse(SpellEffIndex index)
    {
        PreventHitDefaultEffect(index);
        if (index != EFFECT_0)
            return;
        Unit* target = GetHitUnit();
        if (!target)
            return;
        for (auto const& [id, aura] : target->GetOwnedAuras())
            if (AuraApplication const* application = aura->GetApplicationOfTarget(target->GetGUID());
                application && !application->IsPositive() &&
                (aura->GetSpellInfo()->GetAllEffectsMechanicMask() &
                    ((1ULL << MECHANIC_ROOT) | (1ULL << MECHANIC_SNARE))))
            {
                target->RemoveAura(aura, AURA_REMOVE_BY_ENEMY_SPELL);
                return;
            }
    }

    void Register() override
    {
        OnEffectHitTarget += SpellEffectFn(spell_ascension_empowered_wolf::Cleanse,
            EFFECT_ALL, SPELL_EFFECT_DISPEL_MECHANIC);
    }
};
}

void AddSC_AscensionPrimalistEmpoweredBoons()
{
    RegisterSpellScript(aura_ascension_empowered_boons);
    new primalist_empowered_boons_metadata();
    RegisterSpellScript(spell_ascension_empowered_hawk);
    RegisterSpellScript(spell_ascension_empowered_wolf);
}
