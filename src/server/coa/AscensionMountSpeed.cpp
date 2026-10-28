/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "AscensionMountSpeed.h"
#include "AllSpellScript.h"
#include "AreaDefines.h"
#include "Battlefield.h"
#include "BattlefieldMgr.h"
#include "Config.h"
#include "DBCStores.h"
#include "Player.h"
#include "ScriptMgr.h"
#include "Spell.h"
#include "SpellAuraEffects.h"
#include "SpellAuras.h"
#include "SpellInfo.h"
#include "SpellMgr.h"
#include <atomic>
#include <vector>

namespace
{
constexpr uint32 ColdWeatherFlying = 54197;
constexpr uint32 AshadarItemMount = 287665;
constexpr uint32 AshadarMount = 917000;

std::atomic<bool> legacyFlight{ false };

bool IsLearnedMount(Player const* player, SpellInfo const* spell)
{
    return spell->HasAura(SPELL_AURA_MOUNTED) && player->HasSpell(spell->Id);
}

uint8 LegacyAshadarFlightMask(SpellInfo const* spell)
{
    uint8 mask = 0;
    if (spell->Id == AshadarItemMount || spell->Id == AshadarMount)
        for (SpellEffectInfo const& effect : spell->GetEffects())
            if (effect.IsAura(SPELL_AURA_MOD_INCREASE_MOUNTED_FLIGHT_SPEED))
                mask |= 1 << effect.EffectIndex;
    return mask;
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

bool FliesOnMount(Aura const* mount)
{
    uint8 const flight = FlightEffectMask(mount->GetSpellInfo());
    for (uint8 index = 0; index < MAX_SPELL_EFFECTS; ++index)
        if ((flight & (1 << index)) && mount->HasEffect(index))
            return true;
    return false;
}

class MountFlight : public AllSpellScript
{
public:
    MountFlight() : AllSpellScript("AscensionMountFlight", { ALLSPELLHOOK_ON_CALCULATED_TARGET }) { }

    void OnSpellCalculatedTarget(Spell* spell, Unit* target, TargetInfo& hit) override
    {
        SpellInfo const* info = spell->GetSpellInfo();
        bool const legacy = legacyFlight.load();
        if (legacy)
            hit.effectMask &= ~LegacyAshadarFlightMask(info);

        Player* player = spell->GetCaster()->ToPlayer();
        if (!player || target != player || !info->HasAura(SPELL_AURA_MOUNTED) ||
            (legacy && !player->HasSpell(info->Id)))
            return;

        if (!AscensionMountSpeed::CanFly(player, info))
            hit.effectMask &= ~FlightEffectMask(info);
    }
};

class FlightConfiguration : public WorldScript
{
public:
    FlightConfiguration() : WorldScript("AscensionMountFlightConfiguration",
        { WORLDHOOK_ON_AFTER_CONFIG_LOAD, WORLDHOOK_ON_STARTUP }) { }

    void OnAfterConfigLoad(bool) override { Load(); }

    void OnStartup() override { Load(); }

private:
    static void Load()
    {
        legacyFlight.store(sConfigMgr->GetOption<bool>("CoA.LegacyMountFlight", false));
    }
};

class MountFlightArea : public PlayerScript
{
public:
    MountFlightArea() : PlayerScript("AscensionMountFlightArea", { PLAYERHOOK_ON_UPDATE_AREA }) { }

    void OnPlayerUpdateArea(Player* player, uint32, uint32) override
    {
        if (legacyFlight.load())
            return;

        std::vector<Aura*> grounded;
        for (AuraEffect const* effect : player->GetAuraEffectsByType(SPELL_AURA_MOUNTED))
        {
            Aura* mount = effect->GetBase();
            if (mount->GetCasterGUID() == player->GetGUID() && FliesOnMount(mount) &&
                !AscensionMountSpeed::CanFly(player, mount->GetSpellInfo()))
                grounded.push_back(mount);
        }

        for (Aura* mount : grounded)
            mount->Remove();
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
    new FlightConfiguration();
    new MountFlight();
    new MountFlightArea();
    new LearnedMountSpeed();
}
