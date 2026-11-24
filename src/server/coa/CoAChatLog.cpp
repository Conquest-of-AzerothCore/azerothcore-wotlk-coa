#include "CoAChatLog.h"

#include "Channel.h"
#include "Config.h"
#include "DBCStores.h"
#include "DatabaseEnv.h"
#include "GameTime.h"
#include "Group.h"
#include "Guild.h"
#include "Log.h"
#include "ObjectAccessor.h"
#include "ObjectMgr.h"
#include "Player.h"
#include "QueryCallback.h"
#include "ScriptMgr.h"
#include "SharedDefines.h"
#include "Tokenize.h"
#include "Util.h"
#include "WorldSession.h"

#include <algorithm>
#include <array>
#include <atomic>
#include <chrono>
#include <deque>
#include <future>
#include <iterator>
#include <mutex>
#include <utility>
#include <vector>

namespace
{
    constexpr uint32 FlushIntervalMs = 1000;
    constexpr uint32 DropReportIntervalMs = MINUTE * IN_MILLISECONDS;
    constexpr std::size_t RowsPerWrite = 500;
    constexpr std::size_t DefaultMaxPendingRows = 20000;
    constexpr uint32 CleanupBatch = 2000;

    std::atomic<bool> s_enabled{false};
    std::atomic<uint32> s_keepDays{30};
    std::atomic<std::size_t> s_maxPendingRows{DefaultMaxPendingRows};
    std::atomic<uint64> s_droppedRows{0};
    std::mutex s_mutex;
    std::deque<CoAChatRow> s_rows;
    std::mutex s_writeMutex;
    std::optional<TransactionFuture> s_write;
    std::optional<uint32> s_cleanupCutoff;
    std::optional<bool> s_cleanupRowsLeft;
    std::optional<QueryCallback> s_cleanupProbe;
    std::optional<TransactionFuture> s_cleanupDelete;
    std::mutex s_ignoreMutex;
    std::vector<std::string> s_ignoredChannels;
    std::vector<std::string> s_ignoredChannelMessageStarts;
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

    std::vector<std::string> Words(std::string const& text)
    {
        std::vector<std::string> words;
        for (std::string_view word : Acore::Tokenize(text, ' ', false))
            words.emplace_back(word);
        return words;
    }

    bool IsIgnoredChannelChat(std::string_view channel, std::string_view message)
    {
        std::lock_guard lock(s_ignoreMutex);
        for (std::string const& name : s_ignoredChannels)
            if (StringEqualI(name, channel))
                return true;
        for (std::string const& start : s_ignoredChannelMessageStarts)
            if (StringStartsWith(message, start))
                return true;
        return false;
    }

    CharacterDatabaseTransaction TakeWrite()
    {
        std::vector<CoAChatRow> rows;
        {
            std::lock_guard lock(s_mutex);
            std::size_t const count = std::min(s_rows.size(), RowsPerWrite);
            rows.reserve(count);
            std::move(s_rows.begin(), s_rows.begin() + count, std::back_inserter(rows));
            s_rows.erase(s_rows.begin(), s_rows.begin() + count);
        }
        if (rows.empty())
            return nullptr;

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
        return trans;
    }

    bool Written(TransactionFuture& write)
    {
        if (write.get())
            return true;
        LOG_ERROR("coa", "CoA chat log: a write of up to {} coa_chat_log rows failed", RowsPerWrite);
        return false;
    }

    bool WriteInFlight()
    {
        if (!s_write)
            return false;
        if (s_write->wait_for(std::chrono::seconds(0)) != std::future_status::ready)
            return true;
        Written(*s_write);
        s_write.reset();
        return false;
    }

    bool FinishWrite()
    {
        if (!s_write)
            return true;
        bool const written = Written(*s_write);
        s_write.reset();
        return written;
    }

    void ContinueCleanup()
    {
        if (s_cleanupProbe)
        {
            if (!s_cleanupProbe->InvokeIfReady())
                return;
            s_cleanupProbe.reset();
        }
        if (s_cleanupDelete)
        {
            if (s_cleanupDelete->wait_for(std::chrono::seconds(0)) != std::future_status::ready)
                return;
            if (!s_cleanupDelete->get())
                LOG_ERROR("coa", "CoA chat log: a cleanup batch of up to {} coa_chat_log rows failed", CleanupBatch);
            s_cleanupDelete.reset();
        }
        if (!s_cleanupCutoff)
            return;
        if (s_cleanupRowsLeft == false)
        {
            s_cleanupCutoff.reset();
            s_cleanupRowsLeft.reset();
            return;
        }
        uint32 const cutoff = *s_cleanupCutoff;
        if (s_cleanupRowsLeft == true)
        {
            s_cleanupRowsLeft.reset();
            CharacterDatabaseTransaction trans = CharacterDatabase.BeginTransaction();
            trans->Append("DELETE FROM coa_chat_log WHERE time < {} LIMIT {}", cutoff, CleanupBatch);
            s_cleanupDelete.emplace(std::move(CharacterDatabase.AsyncCommitTransaction(trans).m_future));
            return;
        }
        s_cleanupProbe.emplace(CharacterDatabase.AsyncQuery(
            Acore::StringFormat("SELECT 1 FROM coa_chat_log WHERE time < {} LIMIT 1", cutoff))
            .WithCallback([cutoff](QueryResult result)
            {
                s_cleanupRowsLeft = s_cleanupCutoff == cutoff ? std::optional<bool>(bool(result)) : std::nullopt;
            }));
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
    if (s_rows.size() >= s_maxPendingRows.load(std::memory_order_relaxed))
    {
        s_droppedRows.fetch_add(1, std::memory_order_relaxed);
        return;
    }
    s_rows.push_back(std::move(row));
}

bool CoAChatLog::Flush(bool wait)
{
    std::lock_guard lock(s_writeMutex);
    if (!wait)
    {
        if (!WriteInFlight())
            if (CharacterDatabaseTransaction trans = TakeWrite())
                s_write.emplace(std::move(CharacterDatabase.AsyncCommitTransaction(trans).m_future));
        return true;
    }

    bool written = FinishWrite();
    while (CharacterDatabaseTransaction trans = TakeWrite())
        written = CharacterDatabase.AsyncCommitTransaction(trans).m_future.get() && written;
    return written;
}

std::size_t CoAChatLog::Pending()
{
    std::lock_guard lock(s_mutex);
    return s_rows.size();
}

uint64 CoAChatLog::Dropped()
{
    return s_droppedRows.load(std::memory_order_relaxed);
}

std::size_t CoAChatLog::SetMaxPending(std::size_t rows)
{
    return s_maxPendingRows.exchange(rows);
}

void CoAChatLog::Cleanup(uint32 now, bool wait)
{
    uint64 const keep = uint64(s_keepDays.load()) * DAY;
    if (!keep || now <= keep)
        return;
    uint32 const cutoff = uint32(now - keep);
    if (!wait)
    {
        if (!s_cleanupCutoff || *s_cleanupCutoff < cutoff)
        {
            s_cleanupCutoff = cutoff;
            s_cleanupRowsLeft.reset();
        }
        return;
    }
    QueryResult result = CharacterDatabase.Query("SELECT COUNT(*) FROM coa_chat_log WHERE time < {}", cutoff);
    uint64 const old = result ? result->Fetch()[0].Get<uint64>() : 0;
    for (uint64 deleted = 0; deleted < old; deleted += CleanupBatch)
        CharacterDatabase.DirectExecute("DELETE FROM coa_chat_log WHERE time < {} LIMIT {}", cutoff, CleanupBatch);
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
            PLAYERHOOK_ON_AFTER_GROUP_CHAT, PLAYERHOOK_ON_AFTER_GUILD_CHAT, PLAYERHOOK_ON_AFTER_CHANNEL_CHAT, PLAYERHOOK_ON_TEXT_EMOTE,
            PLAYERHOOK_ON_AFTER_SEND_MAIL }) { }

        void OnPlayerAfterSendMail(Player* player, ObjectGuid receiverGuid, uint32 receiverAccount, std::string const& receiverName,
            uint32 mailId, std::string const& subject, std::string const& body) override
        {
            if (!mailId || (subject.empty() && body.empty()) || !CoAChatLog::ShouldLog(player, LANG_UNIVERSAL))
                return;
            CoAChatRow row = CoAChatLog::From(player, CoAChatLog::TypeMail, LANG_UNIVERSAL, body);
            row.targetGuid = receiverGuid.GetCounter();
            row.targetAccount = receiverAccount;
            row.targetName = receiverName;
            row.mailId = mailId;
            row.subject = subject;
            CoAChatLog::Record(std::move(row));
        }

        void OnPlayerAfterChat(Player* player, uint32 type, uint32 lang, std::string const& msg, Group* group) override
        {
            if (!group || !CoAChatLog::ShouldLog(player, lang))
                return;
            CoAChatRow row = CoAChatLog::From(player, uint8(type), lang, msg);
            row.groupId = group->GetGUID().GetCounter();
            CoAChatLog::Record(std::move(row));
        }

        void OnPlayerAfterChat(Player* player, uint32 type, uint32 lang, std::string const& msg, Guild* guild) override
        {
            if (!guild || !CoAChatLog::ShouldLog(player, lang))
                return;
            CoAChatRow row = CoAChatLog::From(player, uint8(type), lang, msg);
            row.guildId = guild->GetId();
            CoAChatLog::Record(std::move(row));
        }

        void OnPlayerAfterChat(Player* player, uint32 type, uint32 lang, std::string const& msg, Channel* channel) override
        {
            if (!channel || !CoAChatLog::ShouldLog(player, lang) || IsIgnoredChannelChat(channel->GetName(), msg))
                return;
            CoAChatRow row = CoAChatLog::From(player, uint8(type), lang, msg);
            row.channel = channel->GetName();
            CoAChatLog::Record(std::move(row));
        }

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
        CoAChatLogWorld() : WorldScript("CoAChatLogWorld", { WORLDHOOK_ON_AFTER_CONFIG_LOAD, WORLDHOOK_ON_STARTUP,
            WORLDHOOK_ON_UPDATE, WORLDHOOK_ON_SHUTDOWN }) { }

        void OnAfterConfigLoad(bool) override
        {
            s_enabled = sConfigMgr->GetOption<bool>("CoA.ChatLog.Enable", false);
            s_keepDays = sConfigMgr->GetOption<uint32>("CoA.ChatLog.KeepDays", 30);
            s_maxPendingRows = std::max<uint32>(1, sConfigMgr->GetOption<uint32>("CoA.ChatLog.MaxPendingRows",
                DefaultMaxPendingRows));
            std::vector<std::string> channels = Words(sConfigMgr->GetOption<std::string>("CoA.ChatLog.IgnoreChannels",
                "BBLC25C KLCE25C questiecomm FSK FSK-EVT xtensionxtooltip2 ConquestFinder JohnnysAddons "
                "CoARUru ALCSync K_LFGForwarder2IIll"));
            std::vector<std::string> starts = Words(sConfigMgr->GetOption<std::string>(
                "CoA.ChatLog.IgnoreChannelMessagesStartingWith",
                "LC1: LCPOI1: LCR1 LCRD1 LCS3; PFQ6: DCOAS3; DCOAL31; DCOAR2"));
            std::lock_guard lock(s_ignoreMutex);
            s_ignoredChannels = std::move(channels);
            s_ignoredChannelMessageStarts = std::move(starts);
        }

        void OnStartup() override
        {
            CoAChatLog::Cleanup(uint32(GameTime::GetGameTime().count()), false);
        }

        void OnUpdate(uint32 diff) override
        {
            _sinceFlush += diff;
            _sinceCleanup += diff;
            _sinceDropReport += diff;
            if (_sinceCleanup >= DAY * IN_MILLISECONDS)
            {
                _sinceCleanup = 0;
                CoAChatLog::Cleanup(uint32(GameTime::GetGameTime().count()), false);
            }
            ContinueCleanup();
            if (_sinceDropReport >= DropReportIntervalMs)
            {
                _sinceDropReport = 0;
                ReportDrops();
            }
            if (_sinceFlush < FlushIntervalMs && CoAChatLog::Pending() < RowsPerWrite)
                return;
            _sinceFlush = 0;
            CoAChatLog::Flush(false);
        }

        void OnShutdown() override
        {
            CoAChatLog::Flush(true);
            ReportDrops();
        }

    private:
        void ReportDrops()
        {
            uint64 const dropped = CoAChatLog::Dropped();
            if (dropped == _reportedDrops)
                return;
            LOG_WARN("coa", "CoA chat log: {} rows were not logged because {} rows were already waiting for the database "
                "(CoA.ChatLog.MaxPendingRows)", dropped - _reportedDrops, s_maxPendingRows.load());
            _reportedDrops = dropped;
        }

        uint32 _sinceFlush = 0;
        uint32 _sinceCleanup = 0;
        uint32 _sinceDropReport = 0;
        uint64 _reportedDrops = 0;
    };
}

void AddSC_CoAChatLog()
{
    new CoAChatLogPlayer();
    new CoAChatLogWorld();
}
