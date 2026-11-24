#ifndef COA_PET_BATTLE_STORE_LEARN_QUEUE_H
#define COA_PET_BATTLE_STORE_LEARN_QUEUE_H

#include <cstdint>
#include <mutex>
#include <vector>

namespace CoAPetBattles::Store
{
    struct LearnedSpell
    {
        uint32_t account = 0;
        uint64_t character = 0;
        uint32_t spell = 0;
    };

    class LearnQueue
    {
    public:
        void Push(LearnedSpell learned);
        std::vector<LearnedSpell> Drain();

    private:
        std::mutex _lock;
        std::vector<LearnedSpell> _queue;
    };
}

#endif
