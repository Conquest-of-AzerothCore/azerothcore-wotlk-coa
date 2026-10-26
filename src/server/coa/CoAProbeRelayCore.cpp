/*
 * Copyright (C) 2016+ AzerothCore <www.azerothcore.org>, released under GNU AGPL v3 license: https://github.com/azerothcore/azerothcore-wotlk/blob/master/LICENSE-AGPL3
 */

#include "CoAProbeRelay.h"
#include "Timer.h"
#include <algorithm>
#include <array>
#include <cctype>

namespace CoAProbeRelay
{
namespace
{
constexpr std::array<std::string_view, 11> ReadOnlyCommands =
    {"ping", "spell", "item", "auras", "spellbook", "known", "log", "state", "ca", "frame", "errors"};
constexpr std::string_view RequestTag = "Q:";
constexpr std::string_view ReplyTag = "R:";
constexpr std::size_t MaxRequestIdLength = 16;
constexpr std::size_t MaxNumberLength = 3;

std::string_view FirstWord(std::string_view line)
{
    return line.substr(0, line.find(' '));
}

std::optional<uint32> ParseNumber(std::string_view text)
{
    if (text.empty() || text.size() > MaxNumberLength)
        return std::nullopt;
    uint32 value = 0;
    for (char c : text)
    {
        if (c < '0' || c > '9')
            return std::nullopt;
        value = value * 10 + uint32(c - '0');
    }
    return value;
}

std::optional<std::string_view> TakeField(std::string_view& rest)
{
    std::size_t const colon = rest.find(':');
    if (colon == std::string_view::npos)
        return std::nullopt;
    std::string_view const field = rest.substr(0, colon);
    rest.remove_prefix(colon + 1);
    return field;
}
}

bool IsRequestId(std::string_view req)
{
    return !req.empty() && req.size() <= MaxRequestIdLength
        && std::all_of(req.begin(), req.end(), [](unsigned char c) { return std::isalnum(c) != 0; });
}

bool IsReadOnlyCommand(std::string_view command)
{
    return std::find(ReadOnlyCommands.begin(), ReadOnlyCommands.end(), command) != ReadOnlyCommands.end();
}

bool IsLabAccount(std::string_view accountName, std::string_view prefix)
{
    if (prefix.empty() || accountName.size() < prefix.size())
        return false;
    return std::equal(prefix.begin(), prefix.end(), accountName.begin(), [](unsigned char a, unsigned char b)
        { return std::toupper(a) == std::toupper(b); });
}

std::optional<std::string> RequestMessage(std::string_view req, std::string_view line)
{
    if (!IsRequestId(req) || !IsReadOnlyCommand(FirstWord(line)))
        return std::nullopt;
    if (line.find_first_of(std::string_view("\t\n\0", 3)) != std::string_view::npos)
        return std::nullopt;
    std::string message;
    message.reserve(Prefix.size() + 1 + RequestTag.size() + req.size() + 1 + line.size());
    message.append(Prefix).append("\t").append(RequestTag).append(req).append(":").append(line);
    if (message.size() > MaxAddonMessage)
        return std::nullopt;
    return message;
}

std::optional<ReplyChunk> ParseReplyChunk(std::string_view message)
{
    if (!message.starts_with(Prefix))
        return std::nullopt;
    message.remove_prefix(Prefix.size());
    if (!message.starts_with('\t'))
        return std::nullopt;
    message.remove_prefix(1);
    if (!message.starts_with(ReplyTag))
        return std::nullopt;
    message.remove_prefix(ReplyTag.size());

    std::optional<std::string_view> const req = TakeField(message);
    std::optional<std::string_view> const index = TakeField(message);
    std::optional<std::string_view> const total = TakeField(message);
    if (!req || !index || !total || !IsRequestId(*req))
        return std::nullopt;
    std::optional<uint32> const indexValue = ParseNumber(*index);
    std::optional<uint32> const totalValue = ParseNumber(*total);
    if (!indexValue || !totalValue || *indexValue < 1 || *indexValue > *totalValue || *totalValue > MaxChunks)
        return std::nullopt;
    return ReplyChunk{std::string(*req), *indexValue, *totalValue, std::string(message)};
}

void ReplyBook::Expire(uint32 nowMs)
{
    std::erase_if(_entries,
        [nowMs](Entry const& entry) { return getMSTimeDiff(entry.armedMs, nowMs) > ReplyLifetimeMs; });
}

ReplyBook::Entry* ReplyBook::Find(uint64 player, std::string_view req)
{
    auto it = std::find_if(_entries.begin(), _entries.end(),
        [player, req](Entry const& entry) { return entry.player == player && entry.req == req; });
    return it == _entries.end() ? nullptr : &*it;
}

void ReplyBook::Arm(uint64 player, std::string const& req, uint32 nowMs)
{
    Expire(nowMs);
    std::erase_if(_entries, [player, &req](Entry const& entry) { return entry.player == player && entry.req == req; });
    uint32 const pending = uint32(std::count_if(_entries.begin(), _entries.end(),
        [player](Entry const& entry) { return entry.player == player; }));
    if (pending >= MaxPendingPerPlayer)
    {
        auto oldest = std::find_if(_entries.begin(), _entries.end(),
            [player](Entry const& entry) { return entry.player == player; });
        _entries.erase(oldest);
    }
    Entry entry;
    entry.player = player;
    entry.req = req;
    entry.armedMs = nowMs;
    _entries.push_back(std::move(entry));
}

bool ReplyBook::Accept(uint64 player, ReplyChunk const& chunk, uint32 nowMs)
{
    Expire(nowMs);
    Entry* entry = Find(player, chunk.req);
    if (!entry)
        return false;
    if (entry->total == 0)
        entry->total = chunk.total;
    else if (entry->total != chunk.total)
        return false;
    return entry->chunks.emplace(chunk.index, chunk.data).second;
}

ReplyStatus ReplyBook::Status(uint64 player, std::string const& req, uint32 nowMs)
{
    Expire(nowMs);
    Entry const* entry = Find(player, req);
    if (!entry)
        return {};
    ReplyStatus status;
    status.received = uint32(entry->chunks.size());
    status.total = entry->total;
    if (entry->total == 0 || status.received < entry->total)
    {
        status.state = ReplyState::Pending;
        return status;
    }
    status.state = ReplyState::Complete;
    for (auto const& [index, data] : entry->chunks)
        status.body += data;
    return status;
}

void ReplyBook::Forget(uint64 player)
{
    std::erase_if(_entries, [player](Entry const& entry) { return entry.player == player; });
}
}
