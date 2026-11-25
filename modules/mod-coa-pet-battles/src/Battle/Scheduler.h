#ifndef COA_PET_BATTLE_BATTLE_SCHEDULER_H
#define COA_PET_BATTLE_BATTLE_SCHEDULER_H

#include <cstddef>
#include <cstdint>
#include <functional>
#include <optional>
#include <vector>

namespace CoAPetBattles::Battle
{
    class Scheduler
    {
    public:
        using Task = std::function<void()>;

        uint64_t Now() const { return _now; }
        void After(uint64_t ms, Task task);
        void Every(uint64_t ms, Task task);
        std::optional<uint64_t> NextDue() const;
        bool Step();
        void RunUntil(uint64_t limit);
        void SetNow(uint64_t now);
        size_t PendingOnce() const;

    private:
        struct Entry
        {
            uint64_t due = 0;
            uint64_t order = 0;
            uint64_t every = 0;
            Task task;
        };

        std::optional<size_t> Next() const;

        std::vector<Entry> _entries;
        uint64_t _now = 0;
        uint64_t _order = 0;
    };
}

#endif
