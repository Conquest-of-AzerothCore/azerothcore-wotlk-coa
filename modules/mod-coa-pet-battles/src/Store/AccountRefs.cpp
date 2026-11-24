#include "AccountRefs.h"

namespace CoAPetBattles::Store
{
    bool AccountRefs::Acquire(uint32_t account, uint64_t character)
    {
        std::set<uint64_t>& characters = _online[account];
        bool const first = characters.empty();
        characters.insert(character);
        return first;
    }

    bool AccountRefs::Release(uint32_t account, uint64_t character)
    {
        auto const found = _online.find(account);
        if (found == _online.end() || !found->second.erase(character))
            return false;
        if (!found->second.empty())
            return false;
        _online.erase(found);
        return true;
    }

    size_t AccountRefs::Online(uint32_t account) const
    {
        auto const found = _online.find(account);
        return found == _online.end() ? 0 : found->second.size();
    }
}
