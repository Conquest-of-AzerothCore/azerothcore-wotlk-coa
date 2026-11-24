#include "Scheduler.h"
#include <utility>

namespace CoAPetBattles::Battle
{
    void Scheduler::After(uint64_t ms, Task task)
    {
        _entries.push_back({ _now + ms, ++_order, 0, std::move(task) });
    }

    void Scheduler::Every(uint64_t ms, Task task)
    {
        _entries.push_back({ _now + ms, ++_order, ms, std::move(task) });
    }

    std::optional<size_t> Scheduler::Next() const
    {
        std::optional<size_t> best;
        for (size_t i = 0; i < _entries.size(); ++i)
            if (!best || _entries[i].due < _entries[*best].due ||
                (_entries[i].due == _entries[*best].due && _entries[i].order < _entries[*best].order))
                best = i;
        return best;
    }

    std::optional<uint64_t> Scheduler::NextDue() const
    {
        std::optional<size_t> const next = Next();
        return next ? std::optional<uint64_t>(_entries[*next].due) : std::nullopt;
    }

    bool Scheduler::Step()
    {
        std::optional<size_t> const next = Next();
        if (!next)
            return false;
        Entry entry = std::move(_entries[*next]);
        _entries.erase(_entries.begin() + static_cast<std::ptrdiff_t>(*next));
        _now = entry.due;
        if (entry.every)
            _entries.push_back({ entry.due + entry.every, ++_order, entry.every, entry.task });
        entry.task();
        return true;
    }

    void Scheduler::RunUntil(uint64_t limit)
    {
        while (true)
        {
            std::optional<uint64_t> const due = NextDue();
            if (!due || *due > limit)
                break;
            Step();
        }
        if (_now < limit)
            _now = limit;
    }

    void Scheduler::SetNow(uint64_t now)
    {
        if (now > _now)
            _now = now;
    }

    size_t Scheduler::PendingOnce() const
    {
        size_t pending = 0;
        for (Entry const& entry : _entries)
            if (!entry.every)
                ++pending;
        return pending;
    }
}
