/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */
#include "GameObject.h"
#include "GameObjectScript.h"
#include "Player.h"
#include "ScriptMgr.h"
#include <algorithm>
#include <array>

namespace
{
struct RopeLanding
{
    ObjectGuid::LowType spawn;
    float x;
    float y;
    float z;
    float orientation;
};

constexpr std::array<RopeLanding, 3> RopeLandings = {{
    {7910011, -8613.5f, -566.9f, 149.652f, 2.094f},
    {7910012, -8603.1f, -580.0f, 150.34f, 3.142f},
    {7910013, -8597.5f, -564.5f, 150.81f, 0.0f},
}};

class go_coa_theologian_rope : public GameObjectScript
{
public:
    go_coa_theologian_rope() : GameObjectScript("go_coa_theologian_rope") { }

    bool OnGossipHello(Player* player, GameObject* go) override
    {
        auto rope = std::find_if(RopeLandings.begin(), RopeLandings.end(),
            [go](RopeLanding const& r) { return r.spawn == go->GetSpawnId(); });
        if (rope != RopeLandings.end())
            player->NearTeleportTo(rope->x, rope->y, rope->z, rope->orientation);
        return true;
    }
};
}

void AddSC_AscensionNorthshireRuins()
{
    new go_coa_theologian_rope();
}
