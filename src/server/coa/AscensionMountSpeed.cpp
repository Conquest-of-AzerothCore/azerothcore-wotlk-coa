/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "AscensionMountSpeed.h"
#include "AllSpellScript.h"
#include "AreaDefines.h"
#include "Battlefield.h"
#include "BattlefieldMgr.h"
#include "DBCStores.h"
#include "Player.h"
#include "ScriptMgr.h"
#include "Spell.h"
#include "SpellAuraEffects.h"
#include "SpellInfo.h"
#include "SpellMgr.h"

namespace
{
constexpr uint32 ColdWeatherFlying = 54197;

bool IsLearnedMount(Player const* player, SpellInfo const* spell)
{
    return spell->HasAura(SPELL_AURA_MOUNTED) && player->HasSpell(spell->Id);
}

uint8 FlightEffectMask(SpellInfo const* spell)
{
    uint8 mask = 0;
    for (SpellEffectInfo const& effect : spell->GetEffects())
        if (effect.ApplyAuraName == SPELL_AURA_FLY ||
            (effect.ApplyAuraName >= SPELL_AURA_MOD_INCREASE_FLIGHT_SPEED &&
             effect.ApplyAuraName <= SPELL_AURA_MOD_FLIGHT_SPEED_MOUNTED_NOT_STACKING))
            mask |= 1 << effect.EffectIndex;
    return mask;
}

class LearnedMountFlight : public AllSpellScript
{
public:
    LearnedMountFlight() : AllSpellScript("AscensionLearnedMountFlight", { ALLSPELLHOOK_ON_CALCULATED_TARGET }) { }

    void OnSpellCalculatedTarget(Spell* spell, Unit* target, TargetInfo& hit) override
    {
        Player* player = spell->GetCaster()->ToPlayer();
        SpellInfo const* mount = spell->GetSpellInfo();
        if (player && target == player && IsLearnedMount(player, mount) &&
            !AscensionMountSpeed::CanFly(player, mount))
            hit.effectMask &= ~FlightEffectMask(mount);
    }
};

class LearnedMountSpeed : public UnitScript
{
public:
    LearnedMountSpeed() : UnitScript("AscensionLearnedMountSpeed", true,
        { UNITHOOK_ON_AFTER_AURA_EFFECT_CALCULATE_AMOUNT }) { }

    void OnAfterAuraEffectCalculateAmount(AuraEffect const* effect, Unit* caster, int32& amount) override
    {
        AuraType const type = effect->GetAuraType();
        if (amount <= 0 ||
            (type != SPELL_AURA_MOD_INCREASE_MOUNTED_SPEED && type != SPELL_AURA_MOD_INCREASE_MOUNTED_FLIGHT_SPEED))
            return;

        Player* player = caster ? caster->ToPlayer() : nullptr;
        if (!player || effect->GetBase()->GetOwner() != player || !IsLearnedMount(player, effect->GetSpellInfo()))
            return;

        uint16 const riding = player->GetBaseSkillValue(SKILL_RIDING);
        amount = type == SPELL_AURA_MOD_INCREASE_MOUNTED_SPEED ? GetRidingGroundMountSpeed(riding) :
            GetRidingFlightMountSpeed(riding);
    }
};
}

namespace AscensionMountSpeed
{
bool CanFly(Player*, SpellInfo const*)
{
    return false;
}
}

void AddSC_AscensionMountSpeed()
{
    new LearnedMountFlight();
    new LearnedMountSpeed();
}
