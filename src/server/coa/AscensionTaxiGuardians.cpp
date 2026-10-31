/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */
#include "Creature.h"
#include "DataMap.h"
#include "Map.h"
#include "MotionMaster.h"
#include "ObjectAccessor.h"
#include "Player.h"
#include "ScriptMgr.h"
#include <vector>

namespace
{
constexpr char StowedGuardiansKey[] = "AscensionTaxiGuardians";
constexpr uint32 CarryInterval = 1000;

struct StowedGuardians final : DataMap::Base
{
    std::vector<ObjectGuid> guids;
    uint32 sinceCarry = 0;
};

bool FollowsOnFoot(Player* player, Creature* guardian)
{
    return guardian->IsAlive() && guardian->IsInWorld() && guardian->HasUnitTypeMask(UNIT_MASK_GUARDIAN) &&
        !guardian->IsPet() && !guardian->IsTotem() && !guardian->IsVehicle() &&
        guardian->GetOwnerGUID() == player->GetGUID() && guardian->GetGUID() != player->GetCritterGUID() &&
        guardian->IsVisible() &&
        guardian->GetMotionMaster()->GetCurrentMovementGeneratorType() == FOLLOW_MOTION_TYPE;
}

void Stow(Player* player)
{
    std::vector<Creature*> guardians;
    for (Unit* controlled : player->m_Controlled)
        if (Creature* guardian = controlled->ToCreature(); guardian && FollowsOnFoot(player, guardian))
            guardians.push_back(guardian);
    if (guardians.empty())
        return;
    StowedGuardians* stowed = player->CustomData.GetDefault<StowedGuardians>(StowedGuardiansKey);
    for (Creature* guardian : guardians)
    {
        guardian->AttackStop();
        guardian->InterruptNonMeleeSpells(false);
        guardian->SetControlled(true, UNIT_STATE_ROOT);
        guardian->SetVisible(false);
        stowed->guids.push_back(guardian->GetGUID());
    }
}

void Carry(Player* player, StowedGuardians& stowed)
{
    for (ObjectGuid const& guid : stowed.guids)
        if (Creature* guardian = ObjectAccessor::GetCreature(*player, guid); guardian && guardian->IsInWorld())
            player->GetMap()->CreatureRelocation(guardian, player->GetPositionX(), player->GetPositionY(),
                                                 player->GetPositionZ(), player->GetOrientation());
}

void Return(Player* player, StowedGuardians& stowed)
{
    for (ObjectGuid const& guid : stowed.guids)
    {
        Creature* guardian = ObjectAccessor::GetCreature(*player, guid);
        if (!guardian || !guardian->IsInWorld())
            continue;
        guardian->NearTeleportTo(player->GetPositionX(), player->GetPositionY(), player->GetPositionZ(),
                                 player->GetOrientation());
        guardian->SetControlled(false, UNIT_STATE_ROOT);
        guardian->SetVisible(true);
    }
    player->CustomData.Erase(StowedGuardiansKey);
}

class ascension_taxi_guardians : public PlayerScript
{
public:
    ascension_taxi_guardians() : PlayerScript("ascension_taxi_guardians", {PLAYERHOOK_ON_UPDATE}) { }

    void OnPlayerUpdate(Player* player, uint32 diff) override
    {
        StowedGuardians* stowed = player->CustomData.Get<StowedGuardians>(StowedGuardiansKey);
        if (!player->IsInFlight())
        {
            if (stowed)
                Return(player, *stowed);
            return;
        }
        if (!stowed)
        {
            Stow(player);
            return;
        }
        stowed->sinceCarry += diff;
        if (stowed->sinceCarry < CarryInterval)
            return;
        stowed->sinceCarry = 0;
        Carry(player, *stowed);
    }
};
}

void AddSC_AscensionTaxiGuardians()
{
    new ascension_taxi_guardians();
}
