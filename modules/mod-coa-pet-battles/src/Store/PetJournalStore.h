#ifndef COA_PET_BATTLE_STORE_PET_JOURNAL_STORE_H
#define COA_PET_BATTLE_STORE_PET_JOURNAL_STORE_H

#include "AccountRefs.h"
#include "AsyncCallbackProcessor.h"
#include "Journal.h"
#include "LearnQueue.h"
#include "Transaction.h"
#include <map>
#include <memory>

class Player;

namespace CoAPetBattles::Store
{
    class PetJournalStore
    {
    public:
        static PetJournalStore* instance();

        Journal* Get(uint32_t account);
        Journal* For(Player* player);
        void Login(Player* player);
        void Logout(Player* player);
        void LearnSpell(Player* player, uint32_t spell);
        void SyncCompanions(Player* player);
        void Flush(Journal& journal, std::function<void(bool)> complete = {});
        size_t Pending(uint32_t account) const;
        bool Reload(uint32_t account);
        void DeleteAccount(uint32_t account);
        void Update();

    private:
        struct Entry
        {
            std::shared_ptr<Engine::Catalog const> catalog;
            std::unique_ptr<Journal> journal;
        };

        bool Load(uint32_t account);
        void Sync(Player* player, Journal& journal);

        AccountRefs _refs;
        std::map<uint32_t, Entry> _journals;
        LearnQueue _learned;
        AsyncCallbackProcessor<TransactionCallback> _callbacks;
    };
}

#define sPetJournals CoAPetBattles::Store::PetJournalStore::instance()

#endif
