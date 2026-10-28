/*
 * Copyright (C) 2016+ AzerothCore <www.azerothcore.org>, released under GNU AGPL v3 license:
 * https://github.com/azerothcore/azerothcore-wotlk/blob/master/LICENSE-AGPL3
 */

#include "AscensionCoAConfig.h"
#include "AscensionCompatOpcodes.h"
#include "CharacterCache.h"
#include "Chat.h"
#include "CoAPlayerTicketService.h"
#include "CommandScript.h"
#include "DatabaseEnv.h"
#include "GameTime.h"
#include "Log.h"
#include "ObjectAccessor.h"
#include "ObjectMgr.h"
#include "Player.h"
#include "ScriptMgr.h"
#include "StringConvert.h"
#include "StringFormat.h"
#include "TicketMgr.h"
#include "Timer.h"
#include "WorldPacket.h"
#include "WorldSession.h"
#include <algorithm>
#include <array>
#include <cctype>
#include <atomic>
#include <deque>
#include <mutex>
#include <shared_mutex>
#include <unordered_map>

using namespace Acore::ChatCommands;

namespace
{
    constexpr uint16 SMSG_PLAYER_TICKET_INFO = 0x0701;
    constexpr uint16 SMSG_PLAYER_TICKET_UPDATE = 0x0702;
    constexpr uint16 CMSG_CREATE_PLAYER_TICKET = 0x0703;
    constexpr uint16 SMSG_CREATE_PLAYER_TICKET_RESULT = 0x0704;
    constexpr uint16 CMSG_CLOSE_PLAYER_TICKET = 0x0705;
    constexpr uint16 SMSG_CLOSE_PLAYER_TICKET_RESULT = 0x0706;
    constexpr uint16 CMSG_SEND_PLAYER_TICKET_MESSAGE = 0x0707;
    constexpr uint16 SMSG_SEND_PLAYER_TICKET_MESSAGE_RESULT = 0x0708;
    constexpr uint16 CMSG_REOPEN_PLAYER_TICKET = 0x0719;
    constexpr uint16 SMSG_REOPEN_PLAYER_TICKET_RESULT = 0x071A;
    constexpr uint16 CMSG_MARK_PLAYER_TICKET_MESSAGE_READ = 0x071D;
    constexpr uint16 SMSG_MARK_PLAYER_TICKET_MESSAGE_READ_RESULT = 0x071E;
    constexpr std::size_t MaxQueuedRequests = 16;
    constexpr std::string_view ConsoleSender = "Game Master";

    constexpr std::array<std::string_view, 5> StatusNames = { "none", "open", "closed", "waiting for player",
        "waiting for a GM" };
    constexpr std::array<std::string_view, CoAPlayerTicket::PriorityCount> PriorityNames = { "low", "medium", "high",
        "urgent" };
    constexpr std::array<std::string_view, CoAPlayerTicket::CategoryCount> CategoryNames = { "other", "talents",
        "dungeons", "items", "spells and abilities", "website or launcher", "mystic enchants", "raids", "quests",
        "UI or addons" };

    struct Request
    {
        uint16 Opcode = 0;
        std::vector<uint8> Payload;
    };

    std::mutex DeskLock;
    CoAPlayerTicket::Desk TicketDesk;
    std::mutex PendingLock;
    std::unordered_map<uint32, std::deque<Request>> PendingRequests;
    std::atomic<bool> AnyPending = false;

    bool QueueRequest(WorldSession* session, WorldPacket const& packet)
    {
        if (!session)
            return true;

        Request request{ packet.GetOpcode(), {} };
        if (!packet.empty())
            request.Payload.assign(packet.contents(), packet.contents() + packet.size());

        std::lock_guard<std::mutex> lock(PendingLock);
        std::deque<Request>& queue = PendingRequests[session->GetAccountId()];
        if (queue.size() < MaxQueuedRequests)
            queue.push_back(std::move(request));
        AnyPending = true;
        return true;
    }

    std::string Escaped(std::string text)
    {
        CharacterDatabase.EscapeString(text);
        return text;
    }

    void Save(CoAPlayerTicket::Ticket const& ticket)
    {
        CharacterDatabaseTransaction transaction = CharacterDatabase.BeginTransaction();
        transaction->Append("REPLACE INTO `ascension_player_ticket` (`id`, `account`, `creator_guid`, `creator`, "
            "`title`, `category`, `priority`, `affected_character`, `status`, `assigned_to`, `closed_by_creator`, "
            "`created`, `closed`, `locale`) VALUES ({}, {}, {}, '{}', '{}', {}, {}, '{}', {}, '{}', {}, {}, {}, '{}')",
            ticket.Id, ticket.Account, ticket.CreatorGuid, Escaped(ticket.Creator), Escaped(ticket.Title),
            uint32(ticket.Category), uint32(ticket.Priority), Escaped(ticket.AffectedCharacter),
            uint32(ticket.State), Escaped(ticket.AssignedTo), uint32(ticket.ClosedByCreator), ticket.Created,
            ticket.Closed, Escaped(ticket.Locale));
        for (CoAPlayerTicket::Message const& message : ticket.Messages)
            transaction->Append("REPLACE INTO `ascension_player_ticket_message` (`ticket`, `id`, `from_gm`, "
                "`gm_only`, `sender`, `message`, `created`, `read_by`, `read_at`) "
                "VALUES ({}, {}, {}, {}, '{}', '{}', {}, '{}', {})",
                ticket.Id, message.Id, uint32(message.FromGameMaster), uint32(message.GameMasterOnly),
                Escaped(message.Sender), Escaped(message.Text), message.Time, Escaped(message.ReadBy),
                message.ReadTime);
        CharacterDatabase.CommitTransaction(transaction);
    }

    void Load()
    {
        std::lock_guard<std::mutex> lock(DeskLock);
        TicketDesk = {};
        if (QueryResult result = CharacterDatabase.Query("SELECT MAX(`id`) FROM `ascension_player_ticket`"))
            TicketDesk.ReserveIds(result->Fetch()[0].Get<uint32>());

        std::map<uint32, CoAPlayerTicket::Ticket> tickets;
        if (QueryResult result = CharacterDatabase.Query("SELECT `id`, `account`, `creator_guid`, `creator`, "
            "`title`, `category`, `priority`, `affected_character`, `status`, `assigned_to`, `created`, `closed`, "
            "`locale` FROM `ascension_player_ticket` WHERE `closed_by_creator` = 0"))
        {
            do
            {
                Field* fields = result->Fetch();
                CoAPlayerTicket::Ticket& ticket = tickets[fields[0].Get<uint32>()];
                ticket.Id = fields[0].Get<uint32>();
                ticket.Account = fields[1].Get<uint32>();
                ticket.CreatorGuid = fields[2].Get<uint32>();
                ticket.Creator = fields[3].Get<std::string>();
                ticket.Title = fields[4].Get<std::string>();
                ticket.Category = fields[5].Get<uint8>();
                ticket.Priority = fields[6].Get<uint8>();
                ticket.AffectedCharacter = fields[7].Get<std::string>();
                ticket.State = CoAPlayerTicket::Status(fields[8].Get<uint8>());
                ticket.AssignedTo = fields[9].Get<std::string>();
                ticket.Created = fields[10].Get<uint32>();
                ticket.Closed = fields[11].Get<uint32>();
                ticket.Locale = fields[12].Get<std::string>();
            } while (result->NextRow());
        }

        if (QueryResult result = CharacterDatabase.Query("SELECT `m`.`ticket`, `m`.`id`, `m`.`from_gm`, "
            "`m`.`gm_only`, `m`.`sender`, `m`.`message`, `m`.`created`, `m`.`read_by`, `m`.`read_at` "
            "FROM `ascension_player_ticket_message` AS `m` "
            "JOIN `ascension_player_ticket` AS `t` ON `t`.`id` = `m`.`ticket` "
            "WHERE `t`.`closed_by_creator` = 0 ORDER BY `m`.`ticket`, `m`.`id`"))
        {
            do
            {
                Field* fields = result->Fetch();
                auto const itr = tickets.find(fields[0].Get<uint32>());
                if (itr == tickets.end())
                    continue;
                itr->second.Messages.push_back({ fields[1].Get<uint32>(), fields[2].Get<uint8>() != 0,
                    fields[3].Get<uint8>() != 0, fields[4].Get<std::string>(), fields[5].Get<std::string>(),
                    fields[6].Get<uint32>(), fields[7].Get<std::string>(), fields[8].Get<uint32>() });
            } while (result->NextRow());
        }

        for (auto& [id, ticket] : tickets)
            TicketDesk.Load(std::move(ticket));
        LOG_INFO("server.loading", ">> Loaded {} open player tickets", tickets.size());
    }

    void SendResult(Player* player, uint16 opcode, std::string_view result)
    {
        WorldPacket packet(opcode, result.size() + 1);
        packet << result;
        player->SendDirectMessage(&packet);
    }

    void SendTicket(Player* player, uint16 opcode, CoAPlayerTicket::Ticket const& ticket)
    {
        WorldPacket packet(opcode, 256);
        CoAPlayerTicket::WritePlayerTicket(packet, ticket, player->GetName());
        player->SendDirectMessage(&packet);
    }

    Player* OnlineCreator(CoAPlayerTicket::Ticket const& ticket)
    {
        std::shared_lock<std::shared_mutex> lock(*HashMapHolder<Player>::GetLock());
        for (auto const& [guid, player] : ObjectAccessor::GetPlayers())
            if (player->IsInWorld() && !player->GetSession()->IsBot() &&
                player->GetSession()->GetAccountId() == ticket.Account)
                return player;
        return nullptr;
    }

    void NotifyGameMasters(std::string const& text)
    {
        ChatHandler(nullptr).SendGMText("{}", text);
    }

    std::optional<std::string> ReadTicketId(WorldPacket& packet, std::size_t trailingBytes)
    {
        if (packet.size() - packet.rpos() <= trailingBytes)
            return std::nullopt;
        return packet.ReadCString();
    }

    bool AffectsAccount(uint32 account, std::string const& name)
    {
        if (name == CoAPlayerTicket::AffectedNone || name == CoAPlayerTicket::AffectedAll)
            return true;
        ObjectGuid const guid = sCharacterCache->GetCharacterGuidByName(name);
        return guid && sCharacterCache->GetCharacterAccountIdByGuid(guid) == account;
    }

    CoAPlayerTicket::Author AuthorOf(Player* player)
    {
        WorldSession* session = player->GetSession();
        return { session->GetAccountId(), player->GetGUID().GetCounter(), player->GetName(),
            localeNames[session->GetSessionDbcLocale()] };
    }

    void CreateTicket(Player* player, WorldPacket& packet, uint32 now)
    {
        CoAPlayerTicket::Author const author = AuthorOf(player);
        CoAPlayerTicket::Request request;
        request.Priority = packet.read<uint8>();
        request.Category = packet.read<uint8>();
        packet >> request.Title >> request.Description >> request.AffectedCharacter;
        if (!sTicketMgr->GetStatus())
        {
            SendResult(player, SMSG_CREATE_PLAYER_TICKET_RESULT, CoAPlayerTicket::CreateDisabled);
            return;
        }
        if (!AffectsAccount(author.Account, request.AffectedCharacter))
        {
            SendResult(player, SMSG_CREATE_PLAYER_TICKET_RESULT, CoAPlayerTicket::CreateInvalid);
            return;
        }

        std::lock_guard<std::mutex> lock(DeskLock);
        CoAPlayerTicket::Outcome const outcome = TicketDesk.Create(author, request, now);
        if (outcome.Changed)
        {
            Save(*outcome.Changed);
            SendTicket(player, SMSG_PLAYER_TICKET_INFO, *outcome.Changed);
            NotifyGameMasters(Acore::StringFormat("Player ticket #{} from {}: {} (.support view {})",
                outcome.Changed->Id, author.Name, request.Title, outcome.Changed->Id));
        }
        SendResult(player, SMSG_CREATE_PLAYER_TICKET_RESULT, outcome.Result);
    }

    void CloseTicket(Player* player, WorldPacket& packet, uint32 now)
    {
        std::optional<std::string> const ticketId = ReadTicketId(packet, 0);
        std::lock_guard<std::mutex> lock(DeskLock);
        CoAPlayerTicket::Outcome const outcome = TicketDesk.PlayerClose(AuthorOf(player), ticketId, now);
        if (outcome.Changed)
        {
            uint32 const id = outcome.Changed->Id;
            Save(*outcome.Changed);
            SendTicket(player, SMSG_PLAYER_TICKET_UPDATE, *outcome.Changed);
            TicketDesk.Forget(id);
            NotifyGameMasters(Acore::StringFormat("Player ticket #{} was closed by {}.", id, player->GetName()));
        }
        SendResult(player, SMSG_CLOSE_PLAYER_TICKET_RESULT, outcome.Result);
    }

    void SendMessage(Player* player, WorldPacket& packet, uint32 now)
    {
        std::string first = packet.ReadCString();
        std::optional<std::string> ticketId;
        std::string text;
        if (packet.size() - packet.rpos() > sizeof(uint8))
        {
            ticketId = std::move(first);
            text = packet.ReadCString();
        }
        else
            text = std::move(first);
        bool const gameMasterOnly = packet.read<uint8>() != 0;

        std::lock_guard<std::mutex> lock(DeskLock);
        CoAPlayerTicket::Outcome const outcome =
            TicketDesk.PlayerSend(AuthorOf(player), ticketId, text, gameMasterOnly, now);
        WorldPacket result(SMSG_SEND_PLAYER_TICKET_MESSAGE_RESULT, 64);
        result << outcome.Result << uint8(outcome.Sent != nullptr);
        if (outcome.Sent)
            CoAPlayerTicket::WritePlayerMessage(result, *outcome.Changed, *outcome.Sent, player->GetName());
        player->SendDirectMessage(&result);
        if (!outcome.Changed)
            return;

        Save(*outcome.Changed);
        SendTicket(player, SMSG_PLAYER_TICKET_UPDATE, *outcome.Changed);
        NotifyGameMasters(Acore::StringFormat("Player ticket #{}: new message from {} (.support view {})",
            outcome.Changed->Id, player->GetName(), outcome.Changed->Id));
    }

    void ReopenTicket(Player* player, WorldPacket& packet)
    {
        std::optional<std::string> const ticketId = ReadTicketId(packet, 0);
        std::lock_guard<std::mutex> lock(DeskLock);
        CoAPlayerTicket::Outcome const outcome = TicketDesk.PlayerReopen(AuthorOf(player), ticketId);
        if (outcome.Changed)
        {
            Save(*outcome.Changed);
            SendTicket(player, SMSG_PLAYER_TICKET_UPDATE, *outcome.Changed);
            NotifyGameMasters(Acore::StringFormat("Player ticket #{} was reopened by {}.", outcome.Changed->Id,
                player->GetName()));
        }
        SendResult(player, SMSG_REOPEN_PLAYER_TICKET_RESULT, outcome.Result);
    }

    void MarkMessageSeen(Player* player, WorldPacket& packet, uint32 now)
    {
        std::optional<std::string> const ticketId = ReadTicketId(packet, sizeof(uint32));
        uint32 const messageId = packet.read<uint32>();
        std::lock_guard<std::mutex> lock(DeskLock);
        CoAPlayerTicket::Outcome const outcome = TicketDesk.PlayerMarkSeen(AuthorOf(player), ticketId, messageId, now);
        if (outcome.Changed)
        {
            Save(*outcome.Changed);
            SendTicket(player, SMSG_PLAYER_TICKET_UPDATE, *outcome.Changed);
        }
        SendResult(player, SMSG_MARK_PLAYER_TICKET_MESSAGE_READ_RESULT, outcome.Result);
    }

    std::pair<uint16, std::string_view> MalformedResult(uint16 opcode)
    {
        switch (opcode)
        {
            case CMSG_CREATE_PLAYER_TICKET:
                return { SMSG_CREATE_PLAYER_TICKET_RESULT, CoAPlayerTicket::CreateInvalid };
            case CMSG_CLOSE_PLAYER_TICKET:
                return { SMSG_CLOSE_PLAYER_TICKET_RESULT, CoAPlayerTicket::CloseNoTicket };
            case CMSG_SEND_PLAYER_TICKET_MESSAGE:
                return { SMSG_SEND_PLAYER_TICKET_MESSAGE_RESULT, CoAPlayerTicket::SendInvalid };
            case CMSG_REOPEN_PLAYER_TICKET:
                return { SMSG_REOPEN_PLAYER_TICKET_RESULT, CoAPlayerTicket::ReopenNoTicket };
            default:
                return { SMSG_MARK_PLAYER_TICKET_MESSAGE_READ_RESULT, CoAPlayerTicket::MarkUnknownMessage };
        }
    }

    void Process(Player* player, Request const& request)
    {
        WorldPacket packet(request.Opcode, request.Payload.size());
        if (!request.Payload.empty())
            packet.append(request.Payload.data(), request.Payload.size());
        uint32 const now = uint32(GameTime::GetGameTime().count());
        try
        {
            switch (request.Opcode)
            {
                case CMSG_CREATE_PLAYER_TICKET:
                    CreateTicket(player, packet, now);
                    break;
                case CMSG_CLOSE_PLAYER_TICKET:
                    CloseTicket(player, packet, now);
                    break;
                case CMSG_SEND_PLAYER_TICKET_MESSAGE:
                    SendMessage(player, packet, now);
                    break;
                case CMSG_REOPEN_PLAYER_TICKET:
                    ReopenTicket(player, packet);
                    break;
                case CMSG_MARK_PLAYER_TICKET_MESSAGE_READ:
                    MarkMessageSeen(player, packet, now);
                    break;
                default:
                    break;
            }
        }
        catch (ByteBufferException const&)
        {
            auto const [opcode, result] = MalformedResult(request.Opcode);
            SendResult(player, opcode, result);
        }
    }

    std::string GameMasterName(ChatHandler* handler)
    {
        Player* player = handler->GetSession() ? handler->GetSession()->GetPlayer() : nullptr;
        return player ? player->GetName() : std::string(ConsoleSender);
    }

    template <std::size_t Count>
    std::string_view NameOf(std::array<std::string_view, Count> const& names, std::size_t index)
    {
        return index < Count ? names[index] : "unknown";
    }

    std::string_view StatusOf(CoAPlayerTicket::Ticket const& ticket)
    {
        return NameOf(StatusNames, std::size_t(ticket.State));
    }

    std::string AssignmentOf(CoAPlayerTicket::Ticket const& ticket)
    {
        return ticket.AssignedTo.empty() ? std::string() : ", assigned to " + ticket.AssignedTo;
    }

    void Publish(CoAPlayerTicket::Ticket const& ticket)
    {
        Save(ticket);
        if (Player* player = OnlineCreator(ticket))
            SendTicket(player, SMSG_PLAYER_TICKET_UPDATE, ticket);
    }

    class CoAPlayerTicketWorld final : public WorldScript
    {
    public:
        CoAPlayerTicketWorld() : WorldScript("CoAPlayerTicketWorld", { WORLDHOOK_ON_STARTUP }) { }

        void OnStartup() override
        {
            Load();
        }
    };

    class CoAPlayerTicketPlayer final : public PlayerScript
    {
    public:
        CoAPlayerTicketPlayer() : PlayerScript("CoAPlayerTicketPlayer", { PLAYERHOOK_ON_UPDATE,
            PLAYERHOOK_ON_LOGOUT, PLAYERHOOK_ON_SEND_INITIAL_PACKETS_BEFORE_ADD_TO_MAP }) { }

        void OnPlayerSendInitialPacketsBeforeAddToMap(Player* player, WorldPacket&) override
        {
            std::lock_guard<std::mutex> lock(DeskLock);
            if (CoAPlayerTicket::Ticket const* ticket = TicketDesk.Current(player->GetSession()->GetAccountId()))
                SendTicket(player, SMSG_PLAYER_TICKET_INFO, *ticket);
        }

        void OnPlayerLogout(Player* player) override
        {
            if (player->GetSession()->IsBot())
                return;

            std::lock_guard<std::mutex> lock(PendingLock);
            PendingRequests.erase(player->GetSession()->GetAccountId());
            AnyPending = !PendingRequests.empty();
        }

        void OnPlayerUpdate(Player* player, uint32) override
        {
            if (!AnyPending || player->GetSession()->IsBot())
                return;

            std::deque<Request> requests;
            {
                std::lock_guard<std::mutex> lock(PendingLock);
                auto itr = PendingRequests.find(player->GetSession()->GetAccountId());
                if (itr == PendingRequests.end())
                    return;
                requests = std::move(itr->second);
                PendingRequests.erase(itr);
                AnyPending = !PendingRequests.empty();
            }

            for (Request const& request : requests)
                Process(player, request);
        }
    };

    class CoAPlayerTicketCommands final : public CommandScript
    {
    public:
        CoAPlayerTicketCommands() : CommandScript("CoAPlayerTicketCommands") { }

        ChatCommandTable GetCommands() const override
        {
            static ChatCommandTable const supportCommands = {
                { "list", HandleList, SEC_GAMEMASTER, Console::Yes },
                { "view", HandleView, SEC_GAMEMASTER, Console::Yes },
                { "reply", HandleReply, SEC_GAMEMASTER, Console::Yes },
                { "note", HandleNote, SEC_GAMEMASTER, Console::Yes },
                { "close", HandleClose, SEC_GAMEMASTER, Console::Yes },
                { "assign", HandleAssign, SEC_GAMEMASTER, Console::Yes },
            };
            static ChatCommandTable const commands = {
                { "support", supportCommands },
            };
            return commands;
        }

        static bool HandleList(ChatHandler* handler)
        {
            std::lock_guard<std::mutex> lock(DeskLock);
            std::vector<CoAPlayerTicket::Ticket const*> const tickets = TicketDesk.Live();
            if (tickets.empty())
            {
                handler->SendSysMessage("No player tickets.");
                return true;
            }
            for (CoAPlayerTicket::Ticket const* ticket : tickets)
                handler->PSendSysMessage("#{} [{}] {} - {}{}, {} messages{}", ticket->Id, StatusOf(*ticket),
                    ticket->Title, ticket->Creator, OnlineCreator(*ticket) ? " (online)" : "",
                    ticket->Messages.size(), AssignmentOf(*ticket));
            return true;
        }

        static bool HandleView(ChatHandler* handler, std::string target)
        {
            std::lock_guard<std::mutex> lock(DeskLock);
            CoAPlayerTicket::Ticket const* ticket = Target(target);
            if (!ticket)
                return Missing(handler, target);
            handler->PSendSysMessage("#{} {} [{}]", ticket->Id, ticket->Title, StatusOf(*ticket));
            handler->PSendSysMessage("From {} (account {}), affects {}, {} priority, category {}{}", ticket->Creator,
                ticket->Account, ticket->AffectedCharacter, NameOf(PriorityNames, ticket->Priority),
                NameOf(CategoryNames, ticket->Category), AssignmentOf(*ticket));
            for (CoAPlayerTicket::Message const& message : ticket->Messages)
                handler->PSendSysMessage("{} {}{}: {}", Acore::Time::TimeToTimestampStr(Seconds(message.Time)),
                    message.Sender, message.GameMasterOnly ? " (GM note)" : "", message.Text);
            return true;
        }

        static bool HandleReply(ChatHandler* handler, std::string target, Tail text)
        {
            return Answer(handler, target, std::string(text), false);
        }

        static bool HandleNote(ChatHandler* handler, std::string target, Tail text)
        {
            return Answer(handler, target, std::string(text), true);
        }

        static bool HandleClose(ChatHandler* handler, std::string target)
        {
            std::lock_guard<std::mutex> lock(DeskLock);
            CoAPlayerTicket::Ticket* ticket = Target(target);
            if (!ticket)
                return Missing(handler, target);
            if (!TicketDesk.Close(ticket->Id, uint32(GameTime::GetGameTime().count())))
            {
                handler->SendErrorMessage("Player ticket #{} is already closed.", ticket->Id);
                return false;
            }
            Publish(*ticket);
            NotifyGameMasters(Acore::StringFormat("Player ticket #{} was closed by {}.", ticket->Id,
                GameMasterName(handler)));
            return true;
        }

        static bool HandleAssign(ChatHandler* handler, std::string target, Optional<std::string> name)
        {
            std::lock_guard<std::mutex> lock(DeskLock);
            CoAPlayerTicket::Ticket* ticket = Target(target);
            if (!ticket)
                return Missing(handler, target);
            TicketDesk.Assign(ticket->Id, name.value_or(""));
            Publish(*ticket);
            handler->PSendSysMessage("Player ticket #{} is {}.", ticket->Id,
                name ? "assigned to " + *name : "unassigned");
            return true;
        }

    private:
        static CoAPlayerTicket::Ticket* Target(std::string target)
        {
            if (!target.empty() && std::all_of(target.begin(), target.end(), [](unsigned char character)
                { return std::isdigit(character); }))
                return TicketDesk.Find(Acore::StringTo<uint32>(target).value_or(0));
            if (!normalizePlayerName(target))
                return nullptr;
            ObjectGuid const guid = sCharacterCache->GetCharacterGuidByName(target);
            return guid ? TicketDesk.Current(sCharacterCache->GetCharacterAccountIdByGuid(guid)) : nullptr;
        }

        static bool Missing(ChatHandler* handler, std::string const& target)
        {
            handler->SendErrorMessage("No open player ticket matches {}.", target);
            return false;
        }

        static bool Answer(ChatHandler* handler, std::string const& target, std::string const& text,
            bool gameMasterOnly)
        {
            std::lock_guard<std::mutex> lock(DeskLock);
            CoAPlayerTicket::Ticket* ticket = Target(target);
            if (!ticket)
                return Missing(handler, target);
            if (!TicketDesk.Reply(ticket->Id, GameMasterName(handler), text, gameMasterOnly,
                uint32(GameTime::GetGameTime().count())))
            {
                handler->SendErrorMessage("Player ticket #{} is closed, full, or the text is empty or too long.",
                    ticket->Id);
                return false;
            }
            Publish(*ticket);
            handler->PSendSysMessage(gameMasterOnly ? "Note added to player ticket #{}." :
                "Reply sent on player ticket #{}.", ticket->Id);
            return true;
        }
    };
}

void AddCoAPlayerTicketScripts()
{
    for (uint16 opcode : { CMSG_CREATE_PLAYER_TICKET, CMSG_CLOSE_PLAYER_TICKET, CMSG_SEND_PLAYER_TICKET_MESSAGE,
        CMSG_REOPEN_PLAYER_TICKET, CMSG_MARK_PLAYER_TICKET_MESSAGE_READ })
        AscensionCompatOpcodes::Claim(opcode, &QueueRequest);
    RegisterAscensionClientConfig([](AscensionClientConfig& config)
    {
        config.Booleans.emplace_back("CONFIG_ALLOW_TICKETS", sTicketMgr->GetStatus());
    });
    new CoAPlayerTicketWorld();
    new CoAPlayerTicketPlayer();
    new CoAPlayerTicketCommands();
}
