#ifndef COA_PET_BATTLE_STORE_ACCOUNT_REFS_H
#define COA_PET_BATTLE_STORE_ACCOUNT_REFS_H

#include <cstddef>
#include <cstdint>
#include <map>
#include <set>

namespace CoAPetBattles::Store
{
    class AccountRefs
    {
    public:
        bool Acquire(uint32_t account, uint64_t character);
        bool Release(uint32_t account, uint64_t character);
        size_t Online(uint32_t account) const;

    private:
        std::map<uint32_t, std::set<uint64_t>> _online;
    };
}

#endif
