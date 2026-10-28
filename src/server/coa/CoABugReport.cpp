/*
 * Copyright (C) 2016+ AzerothCore <www.azerothcore.org>, released under GNU AGPL v3 license:
 * https://github.com/azerothcore/azerothcore-wotlk/blob/master/LICENSE-AGPL3
 */

#include "AscensionCompatOpcodes.h"
#include "CoABugReportService.h"
#include "Config.h"
#include "GameTime.h"
#include "GitRevision.h"
#include "Log.h"
#include "Player.h"
#include "ScriptMgr.h"
#include "WorldPacket.h"
#include "WorldSession.h"
#include <atomic>
#include <deque>
#include <memory>
#include <mutex>
#include <sstream>
#include <unordered_map>

namespace
{
    constexpr uint16 CMSG_CREATE_BUG_REPORT = 0x0562;
    constexpr uint16 SMSG_CREATE_BUG_REPORT_ERROR = 0x0565;
    constexpr uint16 SMSG_CREATE_BUG_REPORT_SUCCESS = 0x0566;
    constexpr std::size_t MaxQueuedReports = 4;

    std::unique_ptr<CoABugReport::Service> ReportService;
    std::mutex PendingLock;
    std::unordered_map<uint32, std::deque<CoABugReport::Report>> PendingReports;
    std::atomic<bool> AnyPending = false;

    bool ReadBytes(WorldPacket& packet, std::size_t limit, std::string& bytes)
    {
        uint32 const size = packet.read<uint32>();
        if (size > limit)
            return false;
        bytes.assign(size, '\0');
        if (size)
            packet.read(reinterpret_cast<uint8*>(bytes.data()), size);
        return true;
    }

    bool QueueReport(WorldSession* session, WorldPacket const& received)
    {
        if (!session)
            return true;

        CoABugReport::Report report;
        WorldPacket packet(received);
        packet.rpos(0);
        try
        {
            packet.read_skip<uint32>();
            report.Category = packet.read<uint32>();
            report.Priority = packet.read<uint32>();
            report.Public = packet.read<uint8>() != 0;
            if (!ReadBytes(packet, CoABugReport::MaxTitle, report.Title) ||
                !ReadBytes(packet, CoABugReport::MaxDescription, report.Description) || packet.rpos() != packet.size())
                report = {};
        }
        catch (ByteBufferException const&)
        {
            report = {};
        }

        std::lock_guard<std::mutex> lock(PendingLock);
        std::deque<CoABugReport::Report>& queue = PendingReports[session->GetAccountId()];
        if (queue.size() < MaxQueuedReports)
            queue.push_back(std::move(report));
        AnyPending = true;
        return true;
    }

    void SendError(Player* player, std::string_view error)
    {
        WorldPacket packet(SMSG_CREATE_BUG_REPORT_ERROR, sizeof(uint32) + error.size());
        packet << uint32(error.size());
        packet.append(reinterpret_cast<uint8 const*>(error.data()), error.size());
        player->SendDirectMessage(&packet);
    }

    void SendSuccess(Player* player, uint32 id)
    {
        WorldPacket packet(SMSG_CREATE_BUG_REPORT_SUCCESS, sizeof(uint32));
        packet << id;
        player->SendDirectMessage(&packet);
    }

    std::string ServerContext(Player* player, CoABugReport::Report const& report)
    {
        std::ostringstream context;
        context << "\n\n### Server context\nCategory ID: " << report.Category << "\nPriority: " << report.Priority
            << "\nClass ID: " << uint32(player->getClass()) << "\nLevel: " << uint32(player->GetLevel())
            << "\nMap ID: " << player->GetMapId() << "\nPosition: " << player->GetPositionX() << ", "
            << player->GetPositionY() << ", " << player->GetPositionZ() << "\nCore revision: "
            << GitRevision::GetHash() << '\n';
        return context.str();
    }

    void Submit(Player* player, CoABugReport::Report const& report)
    {
        if (!ReportService)
        {
            SendError(player, CoABugReport::Disabled);
            return;
        }

        CoABugReport::Outcome const outcome = ReportService->Submit(player->GetSession()->GetAccountId(), report,
            ServerContext(player, report), GameTime::GetGameTime().count());
        if (!outcome.Error.empty())
        {
            SendError(player, outcome.Error);
            return;
        }
        SendSuccess(player, outcome.Id);
        LOG_INFO("coa", "Queued bug report {} from account {}", outcome.Id, player->GetSession()->GetAccountId());
    }

    class CoABugReportWorld final : public WorldScript
    {
    public:
        CoABugReportWorld() : WorldScript("CoABugReportWorld", { WORLDHOOK_ON_AFTER_CONFIG_LOAD }) { }

        void OnAfterConfigLoad(bool reload) override
        {
            if (reload || !sConfigMgr->GetOption<bool>("CoABugReport.Enable", false))
                return;
            std::filesystem::path const path(sConfigMgr->GetOption<std::string>("CoABugReport.SpoolDirectory", ""));
            std::error_code error;
            if (!path.is_absolute() || !std::filesystem::is_directory(path, error) || error)
            {
                LOG_ERROR("server.loading",
                    "CoA bug reports disabled: configure an existing absolute spool directory.");
                return;
            }
            ReportService = std::make_unique<CoABugReport::Service>(path,
                sConfigMgr->GetOption<uint32>("CoABugReport.CooldownSeconds", 120));
            LOG_INFO("server.loading", "CoA bug-report queue enabled. GitHub delivery requires the separate relay.");
        }
    };

    class CoABugReportPlayer final : public PlayerScript
    {
    public:
        CoABugReportPlayer() : PlayerScript("CoABugReportPlayer", { PLAYERHOOK_ON_UPDATE, PLAYERHOOK_ON_LOGOUT }) { }

        void OnPlayerLogout(Player* player) override
        {
            if (player->GetSession()->IsBot())
                return;

            std::lock_guard<std::mutex> lock(PendingLock);
            PendingReports.erase(player->GetSession()->GetAccountId());
            AnyPending = !PendingReports.empty();
        }

        void OnPlayerUpdate(Player* player, uint32) override
        {
            if (!AnyPending || player->GetSession()->IsBot())
                return;

            std::deque<CoABugReport::Report> reports;
            {
                std::lock_guard<std::mutex> lock(PendingLock);
                auto itr = PendingReports.find(player->GetSession()->GetAccountId());
                if (itr == PendingReports.end())
                    return;
                reports = std::move(itr->second);
                PendingReports.erase(itr);
                AnyPending = !PendingReports.empty();
            }

            for (CoABugReport::Report const& report : reports)
            {
                if (report.Title.empty())
                    SendError(player, CoABugReport::Invalid);
                else
                    Submit(player, report);
            }
        }
    };
}

void AddCoABugReportScripts()
{
    AscensionCompatOpcodes::Claim(CMSG_CREATE_BUG_REPORT, &QueueReport);
    new CoABugReportWorld();
    new CoABugReportPlayer();
}
