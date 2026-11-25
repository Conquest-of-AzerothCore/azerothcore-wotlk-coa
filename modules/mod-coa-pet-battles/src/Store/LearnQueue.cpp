#include "LearnQueue.h"

namespace CoAPetBattles::Store
{
    void LearnQueue::Push(LearnedSpell learned)
    {
        std::lock_guard<std::mutex> guard(_lock);
        _queue.push_back(learned);
    }

    std::vector<LearnedSpell> LearnQueue::Drain()
    {
        std::vector<LearnedSpell> drained;
        std::lock_guard<std::mutex> guard(_lock);
        drained.swap(_queue);
        return drained;
    }
}
