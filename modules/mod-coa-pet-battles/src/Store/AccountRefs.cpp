#include "AccountRefs.h"

namespace CoAPetBattles::Store
{
    bool AccountRefs::Held(uint32_t account) const
    {
        return Online(account) || Pending(account);
    }

    bool AccountRefs::Acquire(uint32_t account, uint64_t character)
    {
        bool const load = !Held(account);
        _online[account].insert(character);
        return load;
    }

    bool AccountRefs::Release(uint32_t account, uint64_t character)
    {
        auto const found = _online.find(account);
        if (found == _online.end() || !found->second.erase(character))
            return false;
        if (found->second.empty())
            _online.erase(found);
        return !Held(account);
    }

    void AccountRefs::WriteStarted(uint32_t account)
    {
        ++_pending[account];
    }

    bool AccountRefs::WriteFinished(uint32_t account)
    {
        auto const found = _pending.find(account);
        if (found == _pending.end())
            return false;
        if (--found->second)
            return false;
        _pending.erase(found);
        return !Held(account);
    }

    size_t AccountRefs::Online(uint32_t account) const
    {
        auto const found = _online.find(account);
        return found == _online.end() ? 0 : found->second.size();
    }

    size_t AccountRefs::Pending(uint32_t account) const
    {
        auto const found = _pending.find(account);
        return found == _pending.end() ? 0 : found->second;
    }
}
