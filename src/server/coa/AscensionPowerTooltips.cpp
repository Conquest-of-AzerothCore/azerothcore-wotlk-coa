/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "Player.h"
#include "PlayerScript.h"
#include "ScriptMgr.h"
#include "WorldPacket.h"
#include <array>
#include <cstring>

namespace PowerTooltips
{
constexpr uint16 PatchGlobalStringsOpcode = 0x0676;
constexpr uint32 AppliesInGame = 0x1;
constexpr uint32 AppliesAtLogin = 0x2;

struct ClientString
{
    uint32 id;
    char const* key;
    char const* text;
};

constexpr std::array<ClientString, 8> PowerStrings = { {
    { 9700101, "PVE_POWER_TOOLTIP1", "Damage against creatures increased by: %g%%." },
    { 9700102, "PVE_POWER_TOOLTIP2", "Damage taken from creatures reduced by: %g%%." },
    { 9700103, "PVE_POWER_TOOLTIP3", "Healing and Absorption done in instances increased by: %g%%." },
    { 9700104, "PVP_POWER_TOOLTIP1", "Damage against players increased by: %g%%." },
    { 9700105, "PVP_POWER_TOOLTIP2", "Spirit Primary Stat Increases your Healing and Absorption done in Open World "
        "when in War Mode or High Risk, Arenas and Battlegrounds by: %g%%." },
    { 9700106, "PVP_POWER_TOOLTIP2_ALT", "Increases your Healing and Absorption done in Open World when in War Mode "
        "or High Risk, Arenas and Battlegrounds by: %g%%." },
    { 9700107, "PVP_POWER_TOOLTIP4", "Damage against creatures increased by: %g%%." },
    { 9700108, "PVP_POWER_TOOLTIP5", "Damage taken from creatures reduced by: %g%%." },
} };

class DecimalPercentages : public PlayerScript
{
public:
    DecimalPercentages() : PlayerScript("PowerTooltipDecimals", { PLAYERHOOK_ON_LOGIN }) { }

    void OnPlayerLogin(Player* player) override
    {
        for (ClientString const& string : PowerStrings)
        {
            WorldPacket data(PatchGlobalStringsOpcode, 32 + std::strlen(string.key) + std::strlen(string.text));
            data << string.id << uint32(AppliesInGame | AppliesAtLogin) << uint32(0) << uint32(0);
            data << string.key << string.text;
            player->SendDirectMessage(&data);
        }
    }
};
}

void AddSC_AscensionPowerTooltips()
{
    new PowerTooltips::DecimalPercentages();
}
