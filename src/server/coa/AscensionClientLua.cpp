/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */
#include "AscensionClientLua.h"
#include "Player.h"
#include "WorldPacket.h"
#include "WorldSession.h"

namespace
{
    constexpr uint32 TriggerChallengeId = 5;
    constexpr uint32 TriggerChallengeLevel = 1;
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

    AscensionChallengeStateSync& StateSync()
    {
        static AscensionChallengeStateSync sync = nullptr;
        return sync;
    }

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

    void SendRequirement(WorldSession* session, uint32 id, std::string_view token)
    {
        WorldPacket data(SMSG_COA_CHALLENGE_REQUIREMENT, 40 + token.size());
        data << uint32(id);
        data << uint32(0) << uint32(0) << uint32(0);
        data << uint32(0);
        data << float(0) << float(0) << float(0) << float(0);
        AppendSized(data, token);
        session->SendPacket(&data);
    }

    void SendTriggerChallenge(WorldSession* session)
    {
        WorldPacket data(SMSG_COA_CHALLENGE_ACTIVE_LIST, 30);
        data << uint32(1);
        data << uint32(0) << uint32(TriggerChallengeId) << uint32(TriggerChallengeLevel);
        data << uint32(1) << uint32(0) << uint32(0) << uint16(0);
        session->SendPacket(&data);
    }

    void SendEmptyChallengeList(WorldSession* session)
    {
        WorldPacket data(SMSG_COA_CHALLENGE_ACTIVE_LIST, 4);
        data << uint32(0);
        session->SendPacket(&data);
    }

    void SendCriteria(WorldSession* session, uint32 requirementId, uint32 progress)
    {
        WorldPacket data(SMSG_COA_CHALLENGE_CRITERIA_UPDATED, 33);
        data << uint32(0) << uint32(TriggerChallengeId) << uint32(TriggerChallengeLevel) << uint32(requirementId);
        data << uint32(0) << uint32(0);
        data << uint32(progress) << uint32(0);
        data << uint8(progress ? 1 : 0);
        session->SendPacket(&data);
    }
}

void RegisterAscensionChallengeStateSync(AscensionChallengeStateSync sync)
{
    StateSync() = sync;
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

    SendRequirementType(session, chunk.RequirementTypeId, chunk.Token,
        BuildAscensionClientLuaFormatter(chunk.Token, chunk.Lua));
    SendRequirement(session, chunk.RequirementId, chunk.Token);
    SendTriggerChallenge(session);
    SendCriteria(session, chunk.RequirementId, 0);
    SendCriteria(session, chunk.RequirementId, 1);

    if (AscensionChallengeStateSync sync = StateSync())
        sync(player);
    else
        SendEmptyChallengeList(session);
}
