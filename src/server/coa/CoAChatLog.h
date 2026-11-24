#ifndef COA_CHAT_LOG_H
#define COA_CHAT_LOG_H

#include "Define.h"

#include <cstddef>
#include <optional>
#include <string>
#include <string_view>

class Player;

struct CoAChatRow
{
    uint32 time = 0;
    uint32 account = 0;
    uint32 guid = 0;
    std::string name;
    uint8 type = 0;
    uint8 lang = 0;
    uint8 team = 0;
    std::string channel;
    uint32 targetGuid = 0;
    uint32 targetAccount = 0;
    std::string targetName;
    uint32 groupId = 0;
    uint32 guildId = 0;
    uint16 map = 0;
    uint16 zone = 0;
    float x = 0.0f;
    float y = 0.0f;
    float z = 0.0f;
    uint16 emote = 0;
    uint32 mailId = 0;
    std::string subject;
    std::string message;
};

namespace CoAChatLog
{
    constexpr uint8 TypeMail = 200;

    bool Enabled();
    bool SetEnabled(bool enabled);
    bool ShouldLog(Player const* sender, uint32 lang);
    CoAChatRow From(Player const* sender, uint8 type, uint32 lang, std::string_view message);
    void WithPosition(CoAChatRow& row, Player const* sender);
    void WithTarget(CoAChatRow& row, Player const* target);
    void Record(CoAChatRow row);
    bool Flush(bool wait);
    std::size_t Pending();
    uint64 Dropped();
    std::size_t SetMaxPending(std::size_t rows);
    void Cleanup(uint32 now, bool wait);
    std::optional<uint8> TypeByName(std::string_view name);
}

void AddSC_CoAChatLog();

#endif
