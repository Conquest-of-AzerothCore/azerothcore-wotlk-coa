/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */
#include "AscensionClientLua.h"
#include "AscensionCompatOpcodes.h"
#include "Log.h"
#include "ObjectAccessor.h"
#include "Player.h"
#include "PlayerScript.h"
#include "ScriptMgr.h"
#include "WorldPacket.h"
#include "WorldSession.h"

namespace
{
    constexpr Milliseconds CapabilityRetry = Milliseconds(2000);
    constexpr std::size_t MaxResultText = 255;

    char const* const OutcomeNames[] = {
        "ran", "applied", "deferred", "skipped", "duplicate", "refused-by-player", "refused-guard", "error"
    };

    bool ReadSized(WorldPacket& packet, std::string& text, std::size_t limit)
    {
        if (packet.rpos() + 4 > packet.size())
            return false;
        uint32 const length = packet.read<uint32>();
        if (length > limit || packet.rpos() + length > packet.size())
            return false;
        text.assign(reinterpret_cast<char const*>(packet.contents() + packet.rpos()), length);
        packet.read_skip(length);
        return true;
    }

    bool HandleCapability(WorldSession* session, WorldPacket const& received)
    {
        WorldPacket packet(received);
        packet.rpos(0);
        if (!session || packet.size() < 5)
            return true;

        uint32 const protocolVersion = packet.read<uint32>();
        uint8 const mode = packet.read<uint8>();
        SetAscensionClientLuaCapability(session->GetAccountId(), protocolVersion, mode);
        LOG_DEBUG("coa.hotpatch", "Account {} accepts hot patches (protocol {}, mode {})",
            session->GetAccountId(), protocolVersion, mode);
        return true;
    }

    bool HandleResult(WorldSession* session, WorldPacket const& received)
    {
        WorldPacket packet(received);
        packet.rpos(0);
        std::string patchId;
        std::string detail;
        if (!session || !ReadSized(packet, patchId, MaxResultText) || packet.rpos() + 1 > packet.size())
            return true;

        uint8 const outcome = packet.read<uint8>();
        ReadSized(packet, detail, MaxResultText);
        LOG_INFO("coa.hotpatch", "Account {} hot patch {}: {}{}{}", session->GetAccountId(), patchId,
            outcome < std::size(OutcomeNames) ? OutcomeNames[outcome] : "unknown", detail.empty() ? "" : " - ", detail);
        return true;
    }

    void RetryWhenCapabilityKnown(Player* player, AscensionClientLuaChunk const& chunk)
    {
        player->m_Events.AddEventAtOffset([guid = player->GetGUID(), chunk]()
        {
            if (Player* current = ObjectAccessor::FindPlayer(guid))
                RunAscensionClientLua(current, chunk);
        }, CapabilityRetry);
    }

    class AscensionClientHotPatchPlayer final : public PlayerScript
    {
    public:
        AscensionClientHotPatchPlayer() : PlayerScript("ascension_client_hot_patch", {PLAYERHOOK_ON_LOGIN, PLAYERHOOK_ON_LOGOUT}) { }

        void OnPlayerLogin(Player* player) override
        {
            if (WorldSession* session = player->GetSession(); session && !session->IsBot())
                ResetAscensionClientLuaCapability(session->GetAccountId(), AscensionClientLuaClock::now());
        }

        void OnPlayerLogout(Player* player) override
        {
            if (WorldSession* session = player->GetSession())
                ForgetAscensionClientLuaCapability(session->GetAccountId());
        }
    };
}

void AddSC_AscensionClientHotPatch()
{
    AscensionCompatOpcodes::Claim(AscensionClientLuaCapabilityOpcode, &HandleCapability);
    AscensionCompatOpcodes::Claim(AscensionClientLuaResultOpcode, &HandleResult);
    RegisterAscensionClientLuaDeferral(&RetryWhenCapabilityKnown);
    new AscensionClientHotPatchPlayer();
}
