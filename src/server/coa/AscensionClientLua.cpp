/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */
#include "AscensionClientLua.h"
#include "Log.h"
#include "Player.h"
#include "WorldPacket.h"
#include "WorldSession.h"
#include <mutex>
#include <unordered_map>
#include <vector>

namespace
{
    constexpr uint32 RequirementTypeStringCount = 8;

    constexpr std::string_view BannerFilterLua = R"lua(
if C_TrackerHeader and not AscensionClientLuaTokens then
    AscensionClientLuaTokens = {}
    local show = C_TrackerHeader.Show
    C_TrackerHeader.Show = function(self, template, title, subText, ...)
        if type(subText) == "string" then
            for hidden in pairs(AscensionClientLuaTokens) do
                if subText:find(hidden, 1, true) then
                    return
                end
            end
        end
        return show(self, template, title, subText, ...)
    end
end
if AscensionClientLuaTokens then
    AscensionClientLuaTokens[")lua";

    constexpr uint32 HotPatchProtocolVersion = 1;

    struct Capability
    {
        bool Known = false;
        uint32 ProtocolVersion = 0;
        uint8 Mode = 0;
        std::vector<AscensionClientLuaChunk> Pending;
        std::size_t PendingBytes = 0;
    };

    std::mutex CapabilityMutex;
    std::unordered_map<uint32, Capability> Capabilities;

    void AppendSized(WorldPacket& data, std::string_view text)
    {
        data << uint32(text.size());
        if (!text.empty())
            data.append(reinterpret_cast<uint8 const*>(text.data()), text.size());
    }

    void SendRequirementType(WorldSession* session, uint32 id, std::string_view token, std::string_view formatter)
    {
        WorldPacket data(SMSG_COA_PATCH_CHALLENGE_REQUIREMENT_TYPE, 96 + token.size() * 2 + formatter.size());
        data << uint32(id);
        for (uint32 i = 0; i < RequirementTypeStringCount; ++i)
            data << uint32(0);
        AppendSized(data, token);
        AppendSized(data, token);
        AppendSized(data, "");
        AppendSized(data, "");
        AppendSized(data, "");
        AppendSized(data, formatter);
        AppendSized(data, "");
        AppendSized(data, "");
        session->SendPacket(&data);
    }

    AscensionClientLuaRoute RouteOf(Capability const& capability)
    {
        if (!capability.Known)
            return AscensionClientLuaRoute::Queue;
        return capability.ProtocolVersion >= HotPatchProtocolVersion ? AscensionClientLuaRoute::HotPatch
            : AscensionClientLuaRoute::Unsupported;
    }
}

void BeginAscensionClientLuaSession(uint32 accountId)
{
    std::lock_guard<std::mutex> lock(CapabilityMutex);
    Capabilities.try_emplace(accountId);
}

std::size_t SetAscensionClientLuaCapability(WorldSession* session, uint32 protocolVersion, uint8 mode)
{
    if (!session)
        return 0;

    std::lock_guard<std::mutex> lock(CapabilityMutex);
    Capability& capability = Capabilities[session->GetAccountId()];
    capability.Known = true;
    capability.ProtocolVersion = protocolVersion;
    capability.Mode = mode;
    std::vector<AscensionClientLuaChunk> pending = std::move(capability.Pending);
    capability.Pending.clear();
    capability.PendingBytes = 0;
    if (protocolVersion < HotPatchProtocolVersion)
        return 0;
    for (AscensionClientLuaChunk const& chunk : pending)
        SendAscensionClientLuaHotPatch(session, chunk);
    return pending.size();
}

void ForgetAscensionClientLuaCapability(uint32 accountId)
{
    std::lock_guard<std::mutex> lock(CapabilityMutex);
    Capabilities.erase(accountId);
}

AscensionClientLuaRoute GetAscensionClientLuaRoute(uint32 accountId)
{
    std::lock_guard<std::mutex> lock(CapabilityMutex);
    auto it = Capabilities.find(accountId);
    return it == Capabilities.end() ? AscensionClientLuaRoute::Unsupported : RouteOf(it->second);
}

void SendAscensionClientLuaHotPatch(WorldSession* session, AscensionClientLuaChunk const& chunk)
{
    WorldPacket data(AscensionClientLuaHotPatchOpcode, 12 + chunk.Token.size() + chunk.TargetAddon.size() + chunk.Lua.size());
    AppendSized(data, chunk.Token);
    AppendSized(data, chunk.TargetAddon);
    AppendSized(data, chunk.Lua);
    session->SendPacket(&data);
}

std::string BuildAscensionClientLuaFormatter(std::string_view token, std::string_view lua)
{
    std::string formatter = "end, (function()";
    formatter.append(BannerFilterLua);
    formatter.append(token);
    formatter.append("\"] = true\nend\n");
    formatter.append(lua);
    formatter.append("\nend)(), function(value)");
    return formatter;
}

void SendAscensionClientLuaFormatter(Player* player, uint32 requirementTypeId, std::string_view token, std::string_view lua)
{
    if (WorldSession* session = player ? player->GetSession() : nullptr)
        SendRequirementType(session, requirementTypeId, token, BuildAscensionClientLuaFormatter(token, lua));
}

void RunAscensionClientLua(Player* player, AscensionClientLuaChunk const& chunk)
{
    WorldSession* session = player ? player->GetSession() : nullptr;
    if (!session)
        return;

    std::lock_guard<std::mutex> lock(CapabilityMutex);
    auto it = Capabilities.find(session->GetAccountId());
    AscensionClientLuaRoute const route = it == Capabilities.end() ? AscensionClientLuaRoute::Unsupported
        : RouteOf(it->second);
    if (route == AscensionClientLuaRoute::HotPatch)
    {
        SendAscensionClientLuaHotPatch(session, chunk);
        return;
    }
    if (route == AscensionClientLuaRoute::Unsupported)
    {
        LOG_DEBUG("coa.hotpatch", "Account {} has no hot-patch channel; interface Lua {} not sent",
            session->GetAccountId(), chunk.Token);
        return;
    }

    Capability& capability = it->second;
    std::size_t const size = chunk.Token.size() + chunk.TargetAddon.size() + chunk.Lua.size();
    if (capability.PendingBytes + size > AscensionClientLuaQueueLimit)
    {
        LOG_DEBUG("coa.hotpatch", "Account {} hot-patch queue is full; interface Lua {} not queued",
            session->GetAccountId(), chunk.Token);
        return;
    }
    capability.Pending.push_back(chunk);
    capability.PendingBytes += size;
}
