/*
 * Groot Coins: the pure rules behind the award commands and the exchange,
 * kept free of game objects so the unit tests can drive them directly.
 */

#ifndef MOD_ETHEREAL_BAZAAR_GROOT_COIN_RULES_H
#define MOD_ETHEREAL_BAZAAR_GROOT_COIN_RULES_H

#include <array>
#include <cstdint>
#include <limits>
#include <optional>
#include <string>
#include <string_view>

namespace GrootCoin
{
    // Allocated once; the world migration, the client item registration and
    // the docs use the same numbers. Display 30015 is the Bazaar Token icon.
    constexpr uint32_t COIN_ITEM = 910001;
    constexpr uint32_t COIN_FALLBACK_DISPLAY = 30015;
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

    inline std::optional<uint32_t> ParseHistoryCount(std::string_view text)
    {
        if (text.empty())
            return HISTORY_DEFAULT;

        std::optional<uint32_t> const count = ParsePositive(text);
        if (!count)
            return std::nullopt;
        return *count > HISTORY_MAX ? HISTORY_MAX : *count;
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
