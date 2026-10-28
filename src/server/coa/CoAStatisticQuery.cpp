/*
 * Copyright (C) 2016+ AzerothCore <www.azerothcore-wotlk.org>, released under GNU AGPL v3 license: https://github.com/azerothcore/azerothcore-wotlk/blob/master/LICENSE-AGPL3
 */

#include "AscensionCompatOpcodes.h"
#include "Player.h"
#include "ScriptMgr.h"
#include "WorldPacket.h"
#include "WorldSession.h"
#include <array>
#include <cmath>

namespace
{
constexpr uint16 SMSG_PROCESSED_STATISTIC_QUERY = 0x076D;
constexpr uint16 CMSG_STATISTIC_QUERY = 0x0777;

struct HitGroup
{
    uint32 Group;
    CombatRating Rating;
    float Unit::* Total;
};

constexpr std::array<HitGroup, 3> HIT_GROUPS = {{
    { 0x1, CR_HIT_MELEE, &Unit::m_modMeleeHitChance },
    { 0x2, CR_HIT_RANGED, &Unit::m_modRangedHitChance },
    { 0x4, CR_HIT_SPELL, &Unit::m_modSpellHitChance },
}};

bool HandleStatisticQuery(WorldSession* session, WorldPacket const& packet)
{
    Player* player = session ? session->GetPlayer() : nullptr;
    if (!player || packet.size() < sizeof(uint32))
        return true;

    uint32 const groups = packet.read<uint32>(0);
    for (HitGroup const& hit : HIT_GROUPS)
    {
        if (!(groups & hit.Group))
            continue;

        float const fromAuras = player->*hit.Total - player->GetRatingBonusValue(hit.Rating);
        WorldPacket reply(SMSG_PROCESSED_STATISTIC_QUERY, 2 * sizeof(uint32));
        reply << hit.Group << int32(std::lround(fromAuras));
        session->SendPacket(&reply);
    }
    return true;
}
}

void AddSC_CoAStatisticQuery()
{
    AscensionCompatOpcodes::Claim(CMSG_STATISTIC_QUERY, &HandleStatisticQuery);
}
