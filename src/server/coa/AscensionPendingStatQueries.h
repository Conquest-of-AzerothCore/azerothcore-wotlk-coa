/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#ifndef COA_ASCENSION_PENDING_STAT_QUERIES_H
#define COA_ASCENSION_PENDING_STAT_QUERIES_H

#include <algorithm>
#include <atomic>
#include <cstddef>
#include <cstdint>
#include <mutex>
#include <unordered_map>
#include <vector>

namespace NativeItemScaling
{
class PendingStatQueries
{
public:
    static constexpr std::size_t MaxItemsPerAccount = 256;

    bool Add(std::uint32_t accountId, std::uint32_t itemId)
    {
        std::lock_guard lock(_mutex);
        std::vector<std::uint32_t>& items = _items[accountId];
        if (std::find(items.begin(), items.end(), itemId) != items.end())
            return true;
        if (items.size() >= MaxItemsPerAccount)
            return false;

        items.push_back(itemId);
        _pending.fetch_add(1, std::memory_order_release);
        return true;
    }

    [[nodiscard]] std::vector<std::uint32_t> Take(std::uint32_t accountId)
    {
        if (!_pending.load(std::memory_order_acquire))
            return {};

        std::lock_guard lock(_mutex);
        auto const found = _items.find(accountId);
        if (found == _items.end())
            return {};

        std::vector<std::uint32_t> items = std::move(found->second);
        _items.erase(found);
        _pending.fetch_sub(items.size(), std::memory_order_release);
        return items;
    }

    [[nodiscard]] std::size_t Size() const { return _pending.load(std::memory_order_acquire); }

private:
    std::mutex _mutex;
    std::unordered_map<std::uint32_t, std::vector<std::uint32_t>> _items;
    std::atomic<std::size_t> _pending{0};
};
}

#endif
