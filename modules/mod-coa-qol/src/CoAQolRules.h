#ifndef COA_QOL_RULES_H
#define COA_QOL_RULES_H

#include <algorithm>
#include <charconv>
#include <cstdint>
#include <set>
#include <string_view>

namespace CoAQol
{
    constexpr uint32_t MaximumStackSize = 100000;

    struct ItemFacts
    {
        uint32_t entry = 0;
        uint32_t itemClass = 0;
        int32_t stackable = 1;
    };

    struct StackPolicy
    {
        uint32_t size = 0;
        std::set<uint32_t> classes;
        std::set<uint32_t> included;
        std::set<uint32_t> excluded;
    };

    inline bool ParseIdList(std::string_view csv, std::set<uint32_t>& ids)
    {
        auto trim = [](std::string_view text)
        {
            auto first = text.find_first_not_of(" \t\r\n");
            if (first == std::string_view::npos)
                return std::string_view();
            return text.substr(first, text.find_last_not_of(" \t\r\n") - first + 1);
        };
        csv = trim(csv);
        std::set<uint32_t> parsed;
        while (!csv.empty())
        {
            auto comma = csv.find(',');
            auto token = trim(csv.substr(0, comma));
            uint32_t id = 0;
            auto [end, error] = std::from_chars(token.data(), token.data() + token.size(), id);
            if (token.empty() || error != std::errc() || end != token.data() + token.size())
                return false;
            parsed.insert(id);
            if (comma == std::string_view::npos)
                break;
            csv.remove_prefix(comma + 1);
            if (trim(csv).empty())
                return false;
        }
        ids = std::move(parsed);
        return true;
    }

    inline int32_t PlannedStackSize(StackPolicy const& policy, ItemFacts const& item)
    {
        uint32_t const target = std::min(policy.size, MaximumStackSize);
        if (target <= 1 || item.stackable <= 1 || uint32_t(item.stackable) >= target)
            return item.stackable;
        if (policy.excluded.count(item.entry))
            return item.stackable;
        if (policy.included.count(item.entry) || policy.classes.count(item.itemClass))
            return int32_t(target);
        return item.stackable;
    }
}

#endif
