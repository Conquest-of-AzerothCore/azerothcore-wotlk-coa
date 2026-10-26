/*
 * Copyright (C) 2016+ AzerothCore <www.azerothcore.org>, released under GNU AGPL v3 license: https://github.com/azerothcore/azerothcore-wotlk/blob/master/LICENSE-AGPL3
 */

#ifndef COA_PROBE_RELAY_H
#define COA_PROBE_RELAY_H

#include "Define.h"
#include <cstddef>
#include <map>
#include <optional>
#include <string>
#include <string_view>
#include <vector>

namespace CoAProbeRelay
{
constexpr std::string_view Prefix = "CoaProbe";
constexpr std::size_t MaxAddonMessage = 255;
constexpr uint32 MaxChunks = 64;
constexpr uint32 MaxPendingPerPlayer = 16;
constexpr uint32 ReplyLifetimeMs = 120000;

bool IsRequestId(std::string_view req);
bool IsReadOnlyCommand(std::string_view command);
bool IsLabAccount(std::string_view accountName, std::string_view prefix);
std::optional<std::string> RequestMessage(std::string_view req, std::string_view line);

struct ReplyChunk
{
    std::string req;
    uint32 index = 0;
    uint32 total = 0;
    std::string data;
};

std::optional<ReplyChunk> ParseReplyChunk(std::string_view message);

enum class ReplyState
{
    Unknown,
    Pending,
    Complete
};

struct ReplyStatus
{
    ReplyState state = ReplyState::Unknown;
    uint32 received = 0;
    uint32 total = 0;
    std::string body;
};

class ReplyBook
{
public:
    void Arm(uint64 player, std::string const& req, uint32 nowMs);
    bool Accept(uint64 player, ReplyChunk const& chunk, uint32 nowMs);
    ReplyStatus Status(uint64 player, std::string const& req, uint32 nowMs);
    void Forget(uint64 player);

private:
    struct Entry
    {
        uint64 player = 0;
        std::string req;
        uint32 armedMs = 0;
        uint32 total = 0;
        std::map<uint32, std::string> chunks;
    };

    void Expire(uint32 nowMs);
    Entry* Find(uint64 player, std::string_view req);

    std::vector<Entry> _entries;
};
}

#endif
