/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */
#ifndef ASCENSION_CLIENT_LUA_H
#define ASCENSION_CLIENT_LUA_H

#include "Define.h"
#include <string>
#include <string_view>
#include <vector>

class Player;
class WorldSession;

struct AscensionClientLuaChunk
{
    uint32 RequirementTypeId = 0;
    uint32 RequirementId = 0;
    std::string Token;
    std::string Lua;
    std::string TargetAddon;
};

enum class AscensionClientLuaRoute : uint8
{
    Unsupported,
    HotPatch,
    Queue,
};

constexpr uint16 AscensionClientLuaHotPatchOpcode = 0x8F0;
constexpr uint16 AscensionClientLuaCapabilityOpcode = 0x8F1;
constexpr uint16 AscensionClientLuaResultOpcode = 0x8F2;

void BeginAscensionClientLuaSession(uint32 accountId);
std::vector<AscensionClientLuaChunk> SetAscensionClientLuaCapability(uint32 accountId, uint32 protocolVersion, uint8 mode);
void ForgetAscensionClientLuaCapability(uint32 accountId);
AscensionClientLuaRoute GetAscensionClientLuaRoute(uint32 accountId);
void SendAscensionClientLuaHotPatch(WorldSession* session, AscensionClientLuaChunk const& chunk);
std::string BuildAscensionClientLuaFormatter(std::string_view token, std::string_view lua);
void SendAscensionClientLuaFormatter(Player* player, uint32 requirementTypeId, std::string_view token, std::string_view lua);
void RunAscensionClientLua(Player* player, AscensionClientLuaChunk const& chunk);

#endif
