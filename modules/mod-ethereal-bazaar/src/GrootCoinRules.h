/*
 * Groot Coins: the pure rules behind the award commands and the exchange,
 * kept free of game objects so the unit tests can drive them directly.
 */

#ifndef MOD_ETHEREAL_BAZAAR_GROOT_COIN_RULES_H
#define MOD_ETHEREAL_BAZAAR_GROOT_COIN_RULES_H

#include <algorithm>
#include <array>
#include <cstdint>
#include <limits>
#include <optional>
#include <string>
#include <string_view>
#include <vector>

namespace GrootCoin
{
    // Allocated once; the world migration, the client item registration and
    // the docs use the same numbers. Display 990001 is the custom INV_GrootCoin
    // icon; it needs the client patch in client-art/.
    constexpr uint32_t COIN_ITEM = 910001;
    constexpr uint32_t COIN_DISPLAY = 990001;
    constexpr uint32_t COIN_STACK_SIZE = 1000;

    constexpr uint32_t DEFAULT_TOKENS_PER_COIN = 100;
    constexpr uint32_t DEFAULT_MAX_AWARD = 25;
    constexpr uint32_t HISTORY_DEFAULT = 20;
    constexpr uint32_t HISTORY_MAX = 100;
    constexpr std::size_t REASON_MAX = 255;
    constexpr std::size_t ATTRIBUTION_MAX = 128;
    constexpr uint32_t MAIL_RETENTION_DAYS = 90;
    constexpr uint32_t QUOTE_LIFETIME_MS = 60 * 1000;

    constexpr std::array<uint32_t, 3> EXCHANGE_BUNDLES = { 1, 5, 10 };

    // Awards from outside the game (groot_coin_award_queue).
    constexpr std::string_view GM_SOURCE = "gm";
    constexpr std::size_t SOURCE_MAX = 32;
    constexpr std::size_t SOURCE_REF_MAX = 64;
    constexpr uint32_t DEFAULT_QUEUE_POLL_SECONDS = 60;
    constexpr uint32_t MIN_QUEUE_POLL_SECONDS = 5;
    constexpr uint32_t QUEUE_BATCH = 20;

    // Strictly decimal digits: no sign, no whitespace, no hex, no URL.
    inline std::optional<uint32_t> ParsePositive(std::string_view text)
    {
        if (text.empty() || text.size() > 10)
            return std::nullopt;

        uint64_t value = 0;
        for (char const c : text)
        {
            if (c < '0' || c > '9')
                return std::nullopt;
            value = value * 10 + static_cast<uint64_t>(c - '0');
        }

        if (value == 0 || value > std::numeric_limits<uint32_t>::max())
            return std::nullopt;
        return static_cast<uint32_t>(value);
    }

    inline std::optional<uint32_t> ParseAwardAmount(std::string_view text, uint32_t maxAward)
    {
        std::optional<uint32_t> const amount = ParsePositive(text);
        if (!amount || *amount > maxAward || *amount > COIN_STACK_SIZE)
            return std::nullopt;
        return amount;
    }

    inline std::optional<uint32_t> ParseIssueNumber(std::string_view text)
    {
        return ParsePositive(text);
    }

    // Required free text for the audit record: non-blank, bounded, printable.
    inline bool IsValidAuditText(std::string_view text, std::size_t maxLength)
    {
        if (text.empty() || text.size() > maxLength)
            return false;

        bool hasVisible = false;
        for (char const c : text)
        {
            unsigned char const u = static_cast<unsigned char>(c);
            if (u < 0x20 || u == 0x7F)
                return false;
            if (c != ' ')
                hasVisible = true;
        }
        return hasVisible;
    }

    // A requester name such as "website" or "github": lower-case letters, digits, '-' and '_'.
    inline bool IsValidSource(std::string_view source)
    {
        if (source.empty() || source.size() > SOURCE_MAX)
            return false;
        for (char const c : source)
            if (!((c >= 'a' && c <= 'z') || (c >= '0' && c <= '9') || c == '-' || c == '_'))
                return false;
        return true;
    }

    // "gm" is reserved for in-game awards, which have no reference.
    inline bool IsValidExternalSource(std::string_view source)
    {
        return IsValidSource(source) && source != GM_SOURCE;
    }

    inline bool IsValidSourceRef(std::string_view ref)
    {
        return IsValidAuditText(ref, SOURCE_REF_MAX) && ref.front() != ' ' && ref.back() != ' ';
    }

    enum class QueuedAwardCheck : uint8_t
    {
        Ok,
        InvalidSource,
        InvalidSourceRef,
        InvalidAmount,
        InvalidReason,
        InvalidCharacter,
        NoRequester
    };

    // The checks a queue row must pass before any database lookup.
    inline QueuedAwardCheck CheckQueuedAward(std::string_view source, std::string_view ref, uint32_t characterGuid,
        uint32_t amount, uint32_t maxAward, std::string_view reason, uint32_t requesterAccountId)
    {
        if (!IsValidExternalSource(source))
            return QueuedAwardCheck::InvalidSource;
        if (!IsValidSourceRef(ref))
            return QueuedAwardCheck::InvalidSourceRef;
        if (!amount || amount > maxAward || amount > COIN_STACK_SIZE)
            return QueuedAwardCheck::InvalidAmount;
        if (!IsValidAuditText(reason, REASON_MAX))
            return QueuedAwardCheck::InvalidReason;
        if (!characterGuid)
            return QueuedAwardCheck::InvalidCharacter;
        if (!requesterAccountId)
            return QueuedAwardCheck::NoRequester;
        return QueuedAwardCheck::Ok;
    }

    inline std::string_view DescribeQueuedAwardCheck(QueuedAwardCheck check)
    {
        switch (check)
        {
            case QueuedAwardCheck::Ok: return "ok";
            case QueuedAwardCheck::InvalidSource: return "source must be 1-32 of a-z, 0-9, '-', '_' and not 'gm'";
            case QueuedAwardCheck::InvalidSourceRef: return "source_ref must be 1-64 printable characters";
            case QueuedAwardCheck::InvalidAmount: return "amount must be 1 to GrootCoin.MaxAward";
            case QueuedAwardCheck::InvalidReason: return "reason must be 1-255 printable characters";
            case QueuedAwardCheck::InvalidCharacter: return "character_guid is 0";
            case QueuedAwardCheck::NoRequester: return "requested_by_account is 0";
        }
        return "invalid";
    }

    // What an award already stored under the same key means for a new request.
    enum class ExistingAward : uint8_t
    {
        None,
        SameRequest,
        Conflict
    };

    inline ExistingAward ClassifyExisting(bool exists, uint32_t existingCharacter, uint32_t existingAmount,
        uint32_t character, uint32_t amount)
    {
        if (!exists)
            return ExistingAward::None;
        return existingCharacter == character && existingAmount == amount ? ExistingAward::SameRequest
            : ExistingAward::Conflict;
    }

    // The queue is read only while awards and external awards are both on.
    inline bool ShouldPollQueue(bool awardsAvailable, bool externalAwardsEnable)
    {
        return awardsAvailable && externalAwardsEnable;
    }

    inline uint32_t QueuePollSeconds(uint32_t configured)
    {
        return configured < MIN_QUEUE_POLL_SECONDS ? MIN_QUEUE_POLL_SECONDS : configured;
    }

    inline std::optional<uint32_t> ParseHistoryCount(std::string_view text)
    {
        if (text.empty())
            return HISTORY_DEFAULT;

        std::optional<uint32_t> const count = ParsePositive(text);
        if (!count)
            return std::nullopt;
        return *count > HISTORY_MAX ? HISTORY_MAX : *count;
    }

    // A fixed bundle, or every coin the player carries ("exchange all").
    inline bool IsExchangeAmount(uint32_t coins, uint32_t carried)
    {
        for (uint32_t const bundle : EXCHANGE_BUNDLES)
            if (bundle == coins)
                return true;
        return coins != 0 && coins == carried;
    }

    // The pop-up the player accepted named these tokens; the exchange runs only
    // if the coins and the current rate still give exactly that payout.
    inline bool MatchesOffer(uint32_t coins, uint32_t tokensPerCoin, uint32_t offeredTokens)
    {
        return coins != 0 && tokensPerCoin != 0 && uint64_t(coins) * tokensPerCoin == offeredTokens;
    }

    // The exchange relies on one character's saves committing in the order
    // they were queued, which only a single characters-database worker gives.
    constexpr uint32_t REQUIRED_CHARACTER_DB_WORKERS = 1;

    inline bool ExchangeSafeWithWorkers(uint32_t characterDbWorkers)
    {
        return characterDbWorkers == REQUIRED_CHARACTER_DB_WORKERS;
    }

    // Coins to take from each carried stack, aligned with `stacks`: smallest
    // stacks first (ties by position), so partial stacks are used up before
    // full ones. Empty when the stacks hold fewer than `coins` or coins is 0.
    inline std::vector<uint32_t> PlanDebits(std::vector<uint32_t> const& stacks, uint32_t coins)
    {
        if (!coins)
            return {};
        std::vector<std::size_t> order(stacks.size());
        for (std::size_t i = 0; i < order.size(); ++i)
            order[i] = i;
        std::stable_sort(order.begin(), order.end(),
            [&stacks](std::size_t a, std::size_t b) { return stacks[a] < stacks[b]; });

        std::vector<uint32_t> takes(stacks.size(), 0);
        uint32_t remaining = coins;
        for (std::size_t const index : order)
        {
            if (!remaining)
                break;
            takes[index] = std::min(stacks[index], remaining);
            remaining -= takes[index];
        }
        if (remaining)
            return {};
        return takes;
    }

    inline bool IsExchangeBundle(uint32_t coins)
    {
        for (uint32_t const bundle : EXCHANGE_BUNDLES)
            if (bundle == coins)
                return true;
        return false;
    }

    // The payout for `coins`, or nothing when it overflows or cannot fit one
    // stack of the token item.
    inline std::optional<uint32_t> TokensFor(uint32_t coins, uint32_t tokensPerCoin, uint32_t tokenStackSize)
    {
        if (!coins || !tokensPerCoin)
            return std::nullopt;

        uint64_t const tokens = static_cast<uint64_t>(coins) * tokensPerCoin;
        if (tokens > std::numeric_limits<uint32_t>::max())
            return std::nullopt;
        if (tokenStackSize && tokens > tokenStackSize)
            return std::nullopt;
        return static_cast<uint32_t>(tokens);
    }

    inline bool IsValidRate(uint32_t tokensPerCoin, uint32_t tokenStackSize)
    {
        for (uint32_t const bundle : EXCHANGE_BUNDLES)
            if (!TokensFor(bundle, tokensPerCoin, tokenStackSize))
                return false;
        return true;
    }

    // RFC 4122 version 4 text form of 16 random bytes.
    inline std::string FormatUuid(std::array<uint8_t, 16> bytes)
    {
        bytes[6] = static_cast<uint8_t>((bytes[6] & 0x0F) | 0x40);
        bytes[8] = static_cast<uint8_t>((bytes[8] & 0x3F) | 0x80);

        static constexpr char HEX[] = "0123456789abcdef";
        std::string text;
        text.reserve(36);
        for (std::size_t i = 0; i < bytes.size(); ++i)
        {
            if (i == 4 || i == 6 || i == 8 || i == 10)
                text.push_back('-');
            text.push_back(HEX[bytes[i] >> 4]);
            text.push_back(HEX[bytes[i] & 0x0F]);
        }
        return text;
    }

    inline bool IsUuid(std::string_view text)
    {
        if (text.size() != 36)
            return false;

        for (std::size_t i = 0; i < text.size(); ++i)
        {
            char const c = text[i];
            if (i == 8 || i == 13 || i == 18 || i == 23)
            {
                if (c != '-')
                    return false;
            }
            else if (!((c >= '0' && c <= '9') || (c >= 'a' && c <= 'f')))
                return false;
        }
        return true;
    }
}

#endif
