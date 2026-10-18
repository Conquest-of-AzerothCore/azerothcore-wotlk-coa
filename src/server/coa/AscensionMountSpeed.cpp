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
        if (effect.ApplyAuraName == SPELL_AURA_MOD_INCREASE_MOUNTED_FLIGHT_SPEED ||
            effect.ApplyAuraName == SPELL_AURA_FLY)
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
bool CanFly(Player* player, SpellInfo const* mount)
{
    if (!mount || player->GetBaseSkillValue(SKILL_RIDING) < RIDING_SKILL_EXPERT || player->InBattleground())
        return false;

    uint32 const map = GetVirtualMapForMapAndZone(player->GetMapId(), player->GetZoneId());
    if (map != MAP_OUTLAND && (map != MAP_NORTHREND || !player->HasSpell(ColdWeatherFlying)))
        return false;

    AreaTableEntry const* area = sAreaTableStore.LookupEntry(player->GetAreaId());
    Battlefield* battlefield = sBattlefieldMgr->GetBattlefieldToZoneId(player->GetZoneId());
    if ((area && (area->flags & AREA_FLAG_NO_FLY_ZONE)) || (battlefield && !battlefield->CanFlyIn()))
        return false;

    return mount->CheckLocation(player->GetMapId(), player->GetZoneId(), player->GetAreaId(), player) ==
        SPELL_CAST_OK && player->canFlyInZone(player->GetMapId(), player->GetZoneId(), mount);
}
}

void AddSC_AscensionMountSpeed()
{
    new LearnedMountFlight();
    new LearnedMountSpeed();
}
