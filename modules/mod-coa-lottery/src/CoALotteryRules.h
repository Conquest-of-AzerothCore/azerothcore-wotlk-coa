#ifndef COA_LOTTERY_RULES_H
#define COA_LOTTERY_RULES_H

#include <algorithm>
#include <array>
#include <charconv>
#include <cstdint>
#include <string_view>
#include <utility>
#include <vector>

namespace CoALottery
{
    constexpr uint32_t GoldilocksEntry = 80539;
    constexpr uint32_t GallywixEntry = 80540;
    constexpr uint32_t NoBonusItem = 9000805;
    constexpr uint32_t TicketCost = 100000;
    constexpr uint32_t MaximumPot = 0x7FFFFFFE;
    constexpr uint32_t MaximumTickets = MaximumPot / TicketCost;

    struct PurchaseOption
    {
        std::string_view text;
        uint32_t tickets;
    };

    constexpr std::array<PurchaseOption, 4> Options = {{
        { "Get golden ticket x1 (10g0s0c)", 1 },
        { "Get golden ticket x10 (100g0s0c)", 10 },
        { "Get golden ticket x100 (1000g0s0c)", 100 },
        { "Get golden ticket x1000 (10000g0s0c)", 1000 }
    }};

    inline bool ParseDuration(std::string_view text, uint32_t& seconds)
    {
        if (text.empty())
            return false;
        uint32_t multiplier = 1;
        char suffix = text.back();
        if (suffix < '0' || suffix > '9')
        {
            switch (suffix)
            {
                case 's': multiplier = 1; break;
                case 'm': multiplier = 60; break;
                case 'h': multiplier = 3600; break;
                case 'd': multiplier = 86400; break;
                case 'w': multiplier = 604800; break;
                default: return false;
            }
            text.remove_suffix(1);
        }
        uint32_t value = 0;
        auto [end, error] = std::from_chars(text.data(), text.data() + text.size(), value);
        uint64_t duration = uint64_t(value) * multiplier;
        if (error != std::errc() || end != text.data() + text.size() || duration < 60 || duration > 365 * 86400)
            return false;
        seconds = uint32_t(duration);
        return true;
    }

    inline bool ParseBonusItems(std::string_view csv, std::vector<uint32_t>& items)
    {
        std::vector<uint32_t> parsed;
        auto trim = [](std::string_view text)
        {
            auto first = text.find_first_not_of(" \t\r\n");
            if (first == std::string_view::npos)
                return std::string_view();
            return text.substr(first, text.find_last_not_of(" \t\r\n") - first + 1);
        };
        csv = trim(csv);
        if (csv.empty())
        {
            items.clear();
            return true;
        }
        while (true)
        {
            auto comma = csv.find(',');
            auto token = trim(csv.substr(0, comma));
            if (token.empty())
                return false;
            uint32_t id = 0;
            auto [end, error] = std::from_chars(token.data(), token.data() + token.size(), id);
            if (error != std::errc() || end != token.data() + token.size() || !id)
                return false;
            if (std::find(parsed.begin(), parsed.end(), id) == parsed.end())
                parsed.push_back(id);
            if (comma == std::string_view::npos)
                break;
            csv.remove_prefix(comma + 1);
        }
        items = std::move(parsed);
        return true;
    }

    constexpr uint32_t HouseTickets(uint32_t seed, uint32_t requested)
    {
        return seed > MaximumPot ? 0 : std::min(requested, (MaximumPot - seed) / TicketCost);
    }

    constexpr uint32_t Contribution(uint32_t tickets, uint32_t percent)
    {
        return uint64_t(tickets) * TicketCost * percent / 100;
    }

    constexpr bool CanPurchase(uint32_t money, uint32_t pot, uint32_t totalTickets,
        uint32_t tickets, uint32_t percent)
    {
        if (!tickets || tickets > MaximumTickets || percent > 100 || pot > MaximumPot)
            return false;
        return money >= uint64_t(tickets) * TicketCost &&
            uint64_t(pot) + Contribution(tickets, percent) <= MaximumPot &&
            uint64_t(totalTickets) + tickets <= MaximumTickets;
    }

    template <typename Entries>
    uint32_t SelectWinner(Entries const& entries, uint32_t winningTicket)
    {
        for (auto const& [guid, tickets] : entries)
        {
            if (winningTicket < tickets)
                return guid;
            winningTicket -= tickets;
        }
        return 0;
    }
    template <typename Entries>
    uint32_t SelectDrawWinner(Entries const& entries, uint32_t fakeTickets, uint32_t winningTicket)
    {
        return winningTicket < fakeTickets ? 0 : SelectWinner(entries, winningTicket - fakeTickets);
    }
}

#endif
