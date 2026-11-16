#include "CoAChatLog.h"

#include "Config.h"
#include "DBCStores.h"
#include "DatabaseEnv.h"
#include "GameTime.h"
#include "ObjectAccessor.h"
#include "ObjectMgr.h"
#include "Player.h"
#include "ScriptMgr.h"
#include "SharedDefines.h"
#include "WorldSession.h"

#include <array>
#include <atomic>
#include <mutex>
#include <utility>
#include <vector>

namespace
{
    std::atomic<bool> s_enabled{false};
    std::mutex s_mutex;
    std::vector<CoAChatRow> s_rows;

    constexpr uint32 FlushIntervalMs = 1000;
    constexpr std::size_t NameLength = MAX_PLAYER_NAME;
    constexpr std::size_t ChannelLength = 64;
    constexpr std::size_t SubjectLength = 255;

    constexpr std::array<std::pair<std::string_view, uint8>, 16> TypeNames{{
        {"say", CHAT_MSG_SAY},
        {"yell", CHAT_MSG_YELL},
        {"emote", CHAT_MSG_EMOTE},
        {"text_emote", CHAT_MSG_TEXT_EMOTE},
        {"whisper", CHAT_MSG_WHISPER},
        {"party", CHAT_MSG_PARTY},
        {"party_leader", CHAT_MSG_PARTY_LEADER},
        {"raid", CHAT_MSG_RAID},
        {"raid_leader", CHAT_MSG_RAID_LEADER},
        {"raid_warning", CHAT_MSG_RAID_WARNING},
        {"battleground", CHAT_MSG_BATTLEGROUND},
        {"battleground_leader", CHAT_MSG_BATTLEGROUND_LEADER},
        {"guild", CHAT_MSG_GUILD},
        {"officer", CHAT_MSG_OFFICER},
        {"channel", CHAT_MSG_CHANNEL},
        {"mail", CoAChatLog::TypeMail},
    }};

    std::string Cut(std::string_view text, std::size_t characters)
    {
        std::size_t seen = 0;
        for (std::size_t i = 0; i < text.size(); ++i)
        {
            if ((uint8(text[i]) & 0xC0) == 0x80)
                continue;
            if (seen == characters)
                return std::string(text.substr(0, i));
            ++seen;
        }
        return std::string(text);
    }
}

bool CoAChatLog::Enabled()
{
    return s_enabled.load(std::memory_order_relaxed);
}

bool CoAChatLog::SetEnabled(bool enabled)
{
    return s_enabled.exchange(enabled);
}

bool CoAChatLog::ShouldLog(Player const* sender, uint32 lang)
{
    return Enabled() && lang != LANG_ADDON && sender && sender->GetSession() && !sender->GetSession()->IsBot();
}

CoAChatRow CoAChatLog::From(Player const* sender, uint8 type, uint32 lang, std::string_view message)
{
    CoAChatRow row;
    row.time = uint32(GameTime::GetGameTime().count());
    row.account = sender->GetSession()->GetAccountId();
    row.guid = sender->GetGUID().GetCounter();
    row.name = sender->GetName();
    row.type = type;
    row.lang = uint8(lang);
    row.team = uint8(sender->GetTeamId(true));
    row.map = uint16(sender->GetMapId());
    row.zone = uint16(sender->GetZoneId());
    row.message = std::string(message);
    return row;
}

void CoAChatLog::WithPosition(CoAChatRow& row, Player const* sender)
{
    row.x = sender->GetPositionX();
    row.y = sender->GetPositionY();
    row.z = sender->GetPositionZ();
}

void CoAChatLog::WithTarget(CoAChatRow& row, Player const* target)
{
    row.targetGuid = target->GetGUID().GetCounter();
    row.targetAccount = target->GetSession() ? target->GetSession()->GetAccountId() : 0;
    row.targetName = target->GetName();
}

void CoAChatLog::Record(CoAChatRow row)
{
    row.name = Cut(row.name, NameLength);
    row.targetName = Cut(row.targetName, NameLength);
    row.channel = Cut(row.channel, ChannelLength);
    row.subject = Cut(row.subject, SubjectLength);
    std::lock_guard lock(s_mutex);
    s_rows.push_back(std::move(row));
}

bool CoAChatLog::Flush(bool wait)
{
    std::vector<CoAChatRow> rows;
    {
        std::lock_guard lock(s_mutex);
        rows.swap(s_rows);
    }
    if (rows.empty())
        return true;

    CharacterDatabaseTransaction trans = CharacterDatabase.BeginTransaction();
    for (CoAChatRow const& row : rows)
    {
        CharacterDatabasePreparedStatement* stmt = CharacterDatabase.GetPreparedStatement(CHAR_INS_COA_CHAT_LOG);
        stmt->SetData(0, row.time);
        stmt->SetData(1, row.account);
        stmt->SetData(2, row.guid);
        stmt->SetData(3, row.name);
        stmt->SetData(4, row.type);
        stmt->SetData(5, row.lang);
        stmt->SetData(6, row.team);
        stmt->SetData(7, row.channel);
        stmt->SetData(8, row.targetGuid);
        stmt->SetData(9, row.targetAccount);
        stmt->SetData(10, row.targetName);
        stmt->SetData(11, row.groupId);
        stmt->SetData(12, row.guildId);
        stmt->SetData(13, row.map);
        stmt->SetData(14, row.zone);
        stmt->SetData(15, row.x);
        stmt->SetData(16, row.y);
        stmt->SetData(17, row.z);
        stmt->SetData(18, row.emote);
        stmt->SetData(19, row.mailId);
        stmt->SetData(20, row.subject);
        stmt->SetData(21, row.message);
        trans->Append(stmt);
    }

    if (!wait)
    {
        CharacterDatabase.CommitTransaction(trans);
        return true;
    }
    TransactionCallback committed = CharacterDatabase.AsyncCommitTransaction(trans);
    return committed.m_future.get();
}

std::size_t CoAChatLog::Pending()
{
    std::lock_guard lock(s_mutex);
    return s_rows.size();
}

std::optional<uint8> CoAChatLog::TypeByName(std::string_view name)
{
    for (auto const& [typeName, type] : TypeNames)
        if (typeName == name)
            return type;
    return std::nullopt;
}

namespace
{
    class CoAChatLogPlayer : public PlayerScript
    {
    public:
        CoAChatLogPlayer() : PlayerScript("CoAChatLogPlayer", { PLAYERHOOK_ON_AFTER_CHAT, PLAYERHOOK_ON_AFTER_PRIVATE_CHAT,
            PLAYERHOOK_ON_TEXT_EMOTE }) { }

        void OnPlayerAfterChat(Player* player, uint32 type, uint32 lang, std::string const& msg) override
        {
            if (!CoAChatLog::ShouldLog(player, lang))
                return;
            CoAChatRow row = CoAChatLog::From(player, uint8(type), lang, msg);
            CoAChatLog::WithPosition(row, player);
            CoAChatLog::Record(std::move(row));
        }

        void OnPlayerAfterChat(Player* player, uint32 type, uint32 lang, std::string const& msg, Player* receiver) override
        {
            if (!receiver || !CoAChatLog::ShouldLog(player, lang))
                return;
            CoAChatRow row = CoAChatLog::From(player, uint8(type), lang, msg);
            CoAChatLog::WithTarget(row, receiver);
            CoAChatLog::Record(std::move(row));
        }

        void OnPlayerTextEmote(Player* player, uint32 textEmote, uint32, ObjectGuid guid) override
        {
            if (!CoAChatLog::ShouldLog(player, LANG_UNIVERSAL) || !guid.IsPlayer() || !sEmotesTextStore.LookupEntry(textEmote))
                return;
            Player* target = ObjectAccessor::FindPlayer(guid);
            if (!target)
                return;
            CoAChatRow row = CoAChatLog::From(player, CHAT_MSG_TEXT_EMOTE, LANG_UNIVERSAL, "");
            CoAChatLog::WithPosition(row, player);
            CoAChatLog::WithTarget(row, target);
            row.emote = uint16(textEmote);
            CoAChatLog::Record(std::move(row));
        }
    };

    class CoAChatLogWorld : public WorldScript
    {
    public:
        CoAChatLogWorld() : WorldScript("CoAChatLogWorld", { WORLDHOOK_ON_AFTER_CONFIG_LOAD, WORLDHOOK_ON_UPDATE,
            WORLDHOOK_ON_SHUTDOWN }) { }

        void OnAfterConfigLoad(bool) override
        {
            s_enabled = sConfigMgr->GetOption<bool>("CoA.ChatLog.Enable", false);
        }

        void OnUpdate(uint32 diff) override
        {
            _sinceFlush += diff;
            if (_sinceFlush < FlushIntervalMs)
                return;
            _sinceFlush = 0;
            CoAChatLog::Flush(false);
        }

        void OnShutdown() override
        {
            CoAChatLog::Flush(true);
        }

    private:
        uint32 _sinceFlush = 0;
    };
}

void AddSC_CoAChatLog()
{
    new CoAChatLogPlayer();
    new CoAChatLogWorld();
}
