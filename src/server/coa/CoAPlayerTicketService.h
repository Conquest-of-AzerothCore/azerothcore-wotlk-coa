/*
 * Copyright (C) 2016+ AzerothCore <www.azerothcore.org>, released under GNU AGPL v3 license:
 * https://github.com/azerothcore/azerothcore-wotlk/blob/master/LICENSE-AGPL3
 */

#ifndef COA_PLAYER_TICKET_SERVICE_H
#define COA_PLAYER_TICKET_SERVICE_H

#include "ByteBuffer.h"
#include "utf8.h"
#include <cstdint>
#include <map>
#include <optional>
#include <string>
#include <string_view>
#include <vector>

namespace CoAPlayerTicket
{
    enum class Status : std::uint8_t
    {
        Open = 1,
        Closed = 2,
        WaitingForPlayer = 3,
        WaitingForGameMaster = 4,
    };

    constexpr std::uint8_t PriorityCount = 4;
    constexpr std::uint8_t CategoryCount = 10;
    constexpr std::size_t MaxTitleLetters = 128;
    constexpr std::size_t MaxTextLetters = 2048;
    constexpr std::size_t MaxAffectedLetters = 32;
    constexpr std::size_t MaxMessages = 200;

    constexpr std::string_view CreateOk = "CREATE_PLAYER_TICKET_OK";
    constexpr std::string_view CreateDisabled = "CREATE_PLAYER_TICKET_DISABLED";
    constexpr std::string_view CreateAlreadyOpen = "CREATE_PLAYER_TICKET_ALREADY_HAS_TICKET";
    constexpr std::string_view CreateInvalid = "CREATE_PLAYER_TICKET_INVALID";
    constexpr std::string_view CloseOk = "CLOSE_PLAYER_TICKET_OK";
    constexpr std::string_view CloseNoTicket = "CLOSE_PLAYER_TICKET_NO_TICKET";
    constexpr std::string_view SendOk = "SEND_PLAYER_TICKET_MESSAGE_OK";
    constexpr std::string_view SendNoTicket = "SEND_PLAYER_TICKET_MESSAGE_NO_TICKET";
    constexpr std::string_view SendClosed = "SEND_PLAYER_TICKET_MESSAGE_TICKET_CLOSED";
    constexpr std::string_view SendInvalid = "SEND_PLAYER_TICKET_MESSAGE_INVALID";
    constexpr std::string_view SendLimit = "SEND_PLAYER_TICKET_MESSAGE_LIMIT";
    constexpr std::string_view ReopenOk = "REOPEN_PLAYER_TICKET_OK";
    constexpr std::string_view ReopenNoTicket = "REOPEN_PLAYER_TICKET_NO_TICKET";
    constexpr std::string_view ReopenNotClosed = "REOPEN_PLAYER_TICKET_NOT_CLOSED";
    constexpr std::string_view MarkOk = "MARK_PLAYER_TICKET_MESSAGE_AS_READ_OK";
    constexpr std::string_view MarkNoTicket = "MARK_PLAYER_TICKET_MESSAGE_AS_READ_NO_TICKET";
    constexpr std::string_view MarkUnknownMessage = "MARK_PLAYER_TICKET_MESSAGE_AS_READ_UNKNOWN_MESSAGE";

    constexpr std::string_view AffectedNone = "AFFECTED_CHARACTERS_NONE";
    constexpr std::string_view AffectedAll = "AFFECTED_CHARACTERS_ALL";

    struct Message
    {
        std::uint32_t Id = 0;
        bool FromGameMaster = false;
        bool GameMasterOnly = false;
        std::string Sender;
        std::string Text;
        std::uint32_t Time = 0;
        std::string ReadBy;
        std::uint32_t ReadTime = 0;
    };

    struct Ticket
    {
        std::uint32_t Id = 0;
        std::uint32_t Account = 0;
        std::uint32_t CreatorGuid = 0;
        std::string Creator;
        std::string Title;
        std::uint8_t Category = 0;
        std::uint8_t Priority = 0;
        std::string AffectedCharacter;
        Status State = Status::Open;
        std::string AssignedTo;
        bool ClosedByCreator = false;
        std::uint32_t Created = 0;
        std::uint32_t Closed = 0;
        std::string Locale;
        std::vector<Message> Messages;

        bool IsClosed() const { return State == Status::Closed; }
    };

    struct Author
    {
        std::uint32_t Account = 0;
        std::uint32_t Guid = 0;
        std::string Name;
        std::string Locale;
    };

    struct Request
    {
        std::uint8_t Priority = 0;
        std::uint8_t Category = 0;
        std::string Title;
        std::string Description;
        std::string AffectedCharacter;
    };

    inline bool ValidText(std::string const& text, std::size_t maxLetters, bool multiline = false)
    {
        if (!utf8::is_valid(text.begin(), text.end()) ||
            std::size_t(utf8::distance(text.begin(), text.end())) > maxLetters)
            return false;
        bool visible = false;
        for (unsigned char const character : text)
        {
            if ((character < 0x20 && !(multiline && character == '\n')) || character == 0x7F)
                return false;
            visible = visible || (character != ' ' && character != '\n');
        }
        return visible;
    }

    inline std::vector<Message const*> PlayerMessages(Ticket const& ticket)
    {
        std::vector<Message const*> visible;
        for (Message const& message : ticket.Messages)
            if (!message.GameMasterOnly)
                visible.push_back(&message);
        return visible;
    }

    inline void WriteOptional(ByteBuffer& buffer, std::optional<std::uint32_t> value)
    {
        buffer << std::uint8_t(value.has_value());
        if (value)
            buffer << *value;
    }

    inline void WriteMessage(ByteBuffer& buffer, Ticket const& ticket, Message const& message, std::uint32_t visibleId,
        std::string const& viewer)
    {
        std::string const ticketId = std::to_string(ticket.Id);
        buffer << ticketId << visibleId << std::uint8_t(message.FromGameMaster) << message.Sender;
        buffer << std::uint8_t(1) << message.Text;
        buffer << std::uint8_t(message.GameMasterOnly) << message.Time;

        std::uint32_t const seen = message.FromGameMaster ? message.ReadTime : message.Time;
        buffer << std::uint32_t(seen != 0);
        if (seen)
            buffer << ticketId << visibleId << viewer << seen;
    }

    inline void WritePlayerMessage(ByteBuffer& buffer, Ticket const& ticket, Message const& message,
        std::string const& viewer)
    {
        std::vector<Message const*> const visible = PlayerMessages(ticket);
        for (std::size_t index = 0; index < visible.size(); ++index)
            if (visible[index] == &message)
                WriteMessage(buffer, ticket, message, std::uint32_t(index + 1), viewer);
    }

    inline void WritePlayerTicket(ByteBuffer& buffer, Ticket const& ticket, std::string const& viewer)
    {
        std::vector<Message const*> const visible = PlayerMessages(ticket);
        auto const unseen = [](Message const* message) { return message->FromGameMaster && !message->ReadTime; };

        buffer << std::to_string(ticket.Id) << ticket.Title << ticket.Created;
        WriteOptional(buffer, visible.empty() ? std::nullopt : std::optional<std::uint32_t>(visible.back()->Time));
        buffer << ticket.Creator << std::uint8_t(ticket.State);
        buffer << std::uint8_t(0) << std::uint32_t(0) << std::uint32_t(0) << std::uint32_t(0) << std::uint8_t(0);
        buffer << std::uint32_t(visible.size());
        for (std::size_t index = 0; index < visible.size(); ++index)
            WriteMessage(buffer, ticket, *visible[index], std::uint32_t(index + 1), viewer);
        buffer << std::uint32_t(!ticket.AssignedTo.empty());
        if (!ticket.AssignedTo.empty())
            buffer << ticket.AssignedTo;

        bool anyUnseen = false;
        for (Message const* message : visible)
            anyUnseen = anyUnseen || unseen(message);
        buffer << std::uint8_t(!visible.empty() && unseen(visible.back())) << std::uint8_t(anyUnseen);
        buffer << std::uint8_t(!visible.empty() && visible.back()->FromGameMaster);
        buffer << ticket.Priority << ticket.Category << std::uint8_t(ticket.ClosedByCreator);
        WriteOptional(buffer, ticket.Closed ? std::optional<std::uint32_t>(ticket.Closed) : std::nullopt);
        buffer << ticket.Locale << std::uint8_t(1) << viewer;
    }

    struct Outcome
    {
        std::string_view Result;
        Ticket* Changed = nullptr;
        Message const* Sent = nullptr;
    };

    class Desk
    {
    public:
        void Load(Ticket ticket)
        {
            std::uint32_t const id = ticket.Id;
            _tickets[id] = std::move(ticket);
            if (id >= _nextId)
                _nextId = id + 1;
        }

        void ReserveIds(std::uint32_t lastUsed)
        {
            if (lastUsed >= _nextId)
                _nextId = lastUsed + 1;
        }

        Ticket* Find(std::uint32_t id)
        {
            auto const itr = _tickets.find(id);
            return itr == _tickets.end() ? nullptr : &itr->second;
        }

        Ticket* Current(std::uint32_t account)
        {
            for (auto itr = _tickets.rbegin(); itr != _tickets.rend(); ++itr)
                if (itr->second.Account == account && !itr->second.ClosedByCreator)
                    return &itr->second;
            return nullptr;
        }

        std::vector<Ticket const*> Live() const
        {
            std::vector<Ticket const*> live;
            for (auto const& [id, ticket] : _tickets)
                live.push_back(&ticket);
            return live;
        }

        void Forget(std::uint32_t id) { _tickets.erase(id); }

        Outcome Create(Author const& author, Request const& request, std::uint32_t now)
        {
            if (Current(author.Account))
                return { CreateAlreadyOpen };
            if (request.Priority >= PriorityCount || request.Category >= CategoryCount ||
                !ValidText(request.Title, MaxTitleLetters) || !ValidText(request.Description, MaxTextLetters, true) ||
                !ValidText(request.AffectedCharacter, MaxAffectedLetters))
                return { CreateInvalid };

            Ticket ticket;
            ticket.Id = _nextId++;
            ticket.Account = author.Account;
            ticket.CreatorGuid = author.Guid;
            ticket.Creator = author.Name;
            ticket.Title = request.Title;
            ticket.Category = request.Category;
            ticket.Priority = request.Priority;
            ticket.AffectedCharacter = request.AffectedCharacter;
            ticket.Created = now;
            ticket.Locale = author.Locale;
            Ticket& created = _tickets[ticket.Id] = std::move(ticket);
            return { CreateOk, &created, &Append(created, false, false, author.Name, request.Description, now) };
        }

        Outcome PlayerSend(Author const& author, std::optional<std::string> const& ticketId, std::string const& text,
            bool gameMasterOnly, std::uint32_t now)
        {
            Ticket* ticket = Addressed(author.Account, ticketId);
            if (!ticket)
                return { SendNoTicket };
            if (ticket->IsClosed())
                return { SendClosed };
            if (gameMasterOnly || !ValidText(text, MaxTextLetters, true))
                return { SendInvalid };
            if (ticket->Messages.size() >= MaxMessages)
                return { SendLimit };

            Message const& sent = Append(*ticket, false, false, author.Name, text, now);
            ticket->State = Status::WaitingForGameMaster;
            return { SendOk, ticket, &sent };
        }

        Outcome PlayerClose(Author const& author, std::optional<std::string> const& ticketId, std::uint32_t now)
        {
            Ticket* ticket = Addressed(author.Account, ticketId);
            if (!ticket)
                return { CloseNoTicket };
            if (!ticket->IsClosed())
                ticket->Closed = now;
            ticket->State = Status::Closed;
            ticket->ClosedByCreator = true;
            return { CloseOk, ticket };
        }

        Outcome PlayerReopen(Author const& author, std::optional<std::string> const& ticketId)
        {
            Ticket* ticket = Addressed(author.Account, ticketId);
            if (!ticket)
                return { ReopenNoTicket };
            if (!ticket->IsClosed())
                return { ReopenNotClosed };
            ticket->State = Status::Open;
            ticket->Closed = 0;
            return { ReopenOk, ticket };
        }

        Outcome PlayerMarkSeen(Author const& author, std::optional<std::string> const& ticketId,
            std::uint32_t visibleId, std::uint32_t now)
        {
            Ticket* ticket = Addressed(author.Account, ticketId);
            if (!ticket)
                return { MarkNoTicket };
            Message* message = VisibleMessage(*ticket, visibleId);
            if (!message)
                return { MarkUnknownMessage };
            if (!message->FromGameMaster || message->ReadTime)
                return { MarkOk };
            message->ReadBy = author.Name;
            message->ReadTime = now;
            return { MarkOk, ticket };
        }

        Message const* Reply(std::uint32_t id, std::string const& sender, std::string const& text,
            bool gameMasterOnly, std::uint32_t now)
        {
            Ticket* ticket = Find(id);
            if (!ticket || (ticket->IsClosed() && !gameMasterOnly) || !ValidText(text, MaxTextLetters, true) ||
                ticket->Messages.size() >= MaxMessages)
                return nullptr;
            Message const& message = Append(*ticket, true, gameMasterOnly, sender, text, now);
            if (!gameMasterOnly)
                ticket->State = Status::WaitingForPlayer;
            return &message;
        }

        bool Close(std::uint32_t id, std::uint32_t now)
        {
            Ticket* ticket = Find(id);
            if (!ticket || ticket->IsClosed())
                return false;
            ticket->State = Status::Closed;
            ticket->Closed = now;
            return true;
        }

        bool Assign(std::uint32_t id, std::string const& name)
        {
            Ticket* ticket = Find(id);
            if (!ticket)
                return false;
            ticket->AssignedTo = name;
            return true;
        }

    private:
        Ticket* Addressed(std::uint32_t account, std::optional<std::string> const& ticketId)
        {
            Ticket* ticket = Current(account);
            if (ticket && ticketId && *ticketId != std::to_string(ticket->Id))
                return nullptr;
            return ticket;
        }

        static Message* VisibleMessage(Ticket& ticket, std::uint32_t visibleId)
        {
            std::uint32_t position = 0;
            for (Message& message : ticket.Messages)
                if (!message.GameMasterOnly && ++position == visibleId)
                    return &message;
            return nullptr;
        }

        static Message& Append(Ticket& ticket, bool fromGameMaster, bool gameMasterOnly, std::string const& sender,
            std::string const& text, std::uint32_t now)
        {
            std::uint32_t const id = ticket.Messages.empty() ? 1 : ticket.Messages.back().Id + 1;
            return ticket.Messages.emplace_back(
                Message{ id, fromGameMaster, gameMasterOnly, sender, text, now, {}, 0 });
        }

        std::map<std::uint32_t, Ticket> _tickets;
        std::uint32_t _nextId = 1;
    };
}

#endif
