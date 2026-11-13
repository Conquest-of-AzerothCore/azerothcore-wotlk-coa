/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */
#include "AscensionClientLua.h"
#include "Player.h"
#include "PlayerScript.h"
#include "ScriptMgr.h"

namespace
{
    constexpr char Token[] = "COA_TOTEM_TOOLTIP_STRINGS";
    constexpr char Lua[] = R"lua(
STANDARD = STANDARD or "Standard"
if COA_TOTEM_NAME_REMAP then
    for _, id in ipairs({ 500260, 500263, 500299, 500547, 706805, 800319, 803931, 803932, 803933, 803934,
                          803935, 803936, 803937, 803938 }) do
        if COA_TOTEM_NAME_REMAP[id] == nil then
            COA_TOTEM_NAME_REMAP[id] = STANDARD
        end
    end
end
)lua";

    class TotemTooltipStrings final : public PlayerScript
    {
    public:
        TotemTooltipStrings() : PlayerScript("coa_totem_tooltip_strings", {PLAYERHOOK_ON_LOGIN}) { }

        void OnPlayerLogin(Player* player) override
        {
            AscensionClientLuaChunk chunk;
            chunk.Token = Token;
            chunk.Lua = Lua;
            RunAscensionClientLua(player, chunk);
        }
    };
}

void AddSC_AscensionTotemTooltipStrings()
{
    new TotemTooltipStrings();
}
