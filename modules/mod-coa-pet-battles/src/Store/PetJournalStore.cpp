#include "PetJournalStore.h"
#include "DatabaseEnv.h"
#include "Field.h"
#include "JournalSql.h"
#include "Log.h"
#include "ObjectAccessor.h"
#include "PetBattleDataStore.h"
#include "Player.h"
#include "QueryResult.h"
#include "WorldSession.h"

namespace CoAPetBattles::Store
{
    namespace
    {
        bool Eligible(Player* player)
        {
            return player && player->GetSession() && !player->GetSession()->IsBot();
        }

        std::multimap<uint32_t, uint32_t> CompanionSpecies()
        {
            std::multimap<uint32_t, uint32_t> species;
            for (auto const& [spell, companion] : sPetBattleData->Data().companions)
                species.emplace(companion.species, spell);
            return species;
        }
    }

    PetJournalStore* PetJournalStore::instance()
    {
        static PetJournalStore store;
        return &store;
    }

    Journal* PetJournalStore::Get(uint32_t account)
    {
        auto const found = _journals.find(account);
        return found == _journals.end() ? nullptr : found->second.journal.get();
    }

    Journal* PetJournalStore::For(Player* player)
    {
        return Eligible(player) ? Get(player->GetSession()->GetAccountId()) : nullptr;
    }

    bool PetJournalStore::Load(uint32_t account)
    {
        std::shared_ptr<Engine::Catalog const> catalog = sPetBattleData->Catalog();
        if (!sPetBattleData->IsLoaded() || !catalog)
            return false;

        std::vector<OwnedPet> pets;
        if (QueryResult result = CharacterDatabase.Query("SELECT `species`, `level`, `xp`, `ability1`, `ability2`, "
            "`ability3`, `quality`, `display`, `health`, `health_at`, `revision`, `pet_id`, `breed`, `source` "
            "FROM `coa_pet_journal` WHERE `account` = {}", account))
        {
            do
            {
                Field* fields = result->Fetch();
                OwnedPet pet;
                pet.species = fields[0].Get<uint32>();
                pet.level = fields[1].Get<uint8>();
                pet.xp = fields[2].Get<uint32>();
                pet.picks = { fields[3].Get<uint8>(), fields[4].Get<uint8>(), fields[5].Get<uint8>() };
                pet.quality = fields[6].Get<uint8>();
                pet.display = fields[7].Get<uint32>();
                pet.health = fields[8].Get<uint32>();
                pet.healthAt = fields[9].Get<uint32>();
                pet.revision = fields[10].Get<uint32>();
                pet.id = fields[11].Get<uint32>();
                pet.breed = fields[12].Get<uint8>();
                pet.source = static_cast<PetSource>(fields[13].Get<uint8>());
                pets.push_back(pet);
            } while (result->NextRow());
        }

        std::array<Team, TeamCount> teams {};
        if (QueryResult result = CharacterDatabase.Query("SELECT `team`, `slot1`, `slot2`, `slot3`, `revision` "
            "FROM `coa_pet_team` WHERE `account` = {}", account))
        {
            do
            {
                Field* fields = result->Fetch();
                uint8 const team = fields[0].Get<uint8>();
                if (team < 1 || team > TeamCount)
                    continue;
                teams[team - 1].slots = { fields[1].Get<uint32>(), fields[2].Get<uint32>(), fields[3].Get<uint32>() };
                teams[team - 1].revision = fields[4].Get<uint32>();
            } while (result->NextRow());
        }

        uint8 active = 1;
        uint32 activeRevision = 0;
        if (QueryResult result = CharacterDatabase.Query("SELECT `active_team`, `revision` FROM `coa_pet_account` "
            "WHERE `account` = {}", account))
        {
            active = result->Fetch()[0].Get<uint8>();
            activeRevision = result->Fetch()[1].Get<uint32>();
        }

        auto journal = std::make_unique<Journal>(account, *catalog, std::move(pets), teams, active, activeRevision);
        for (std::string const& rejected : journal->Rejected())
            LOG_WARN("module", "Pet journal row kept but unusable: {}", rejected);
        _journals[account] = { std::move(catalog), std::move(journal) };
        return true;
    }

    void PetJournalStore::Sync(Player* player, Journal& journal)
    {
        std::vector<uint32_t> const added = journal.SyncCompanions(CompanionSpecies(),
            [player](uint32_t spell) { return player->HasSpell(spell); });
        if (added.empty())
        {
            Flush(journal);
            return;
        }
        std::string species;
        for (uint32_t entry : added)
            species += (species.empty() ? "" : " ") + std::to_string(entry);
        LOG_INFO("module", "Pet journal of account {}: {} companion pet(s) added for {}: {}", journal.Account(),
            added.size(), player->GetName(), species);
        Flush(journal);
    }

    void PetJournalStore::Login(Player* player)
    {
        if (!Eligible(player))
            return;
        uint32 const account = player->GetSession()->GetAccountId();
        _refs.Acquire(account, player->GetGUID().GetCounter());
        if (!Get(account) && !Load(account))
            return;
        Sync(player, *Get(account));
    }

    void PetJournalStore::Logout(Player* player)
    {
        if (!Eligible(player))
            return;
        uint32 const account = player->GetSession()->GetAccountId();
        if (_refs.Release(account, player->GetGUID().GetCounter()))
            _journals.erase(account);
    }

    void PetJournalStore::SyncCompanions(Player* player)
    {
        if (Journal* journal = For(player))
            Sync(player, *journal);
    }

    void PetJournalStore::LearnSpell(Player* player, uint32_t spell)
    {
        if (!Eligible(player) || !sPetBattleData->Data().companions.count(spell))
            return;
        _learned.Push({ player->GetSession()->GetAccountId(), player->GetGUID().GetCounter(), spell });
    }

    void PetJournalStore::Flush(Journal& journal, std::function<void(bool)> complete)
    {
        std::vector<RowWrite> const writes = journal.TakeWrites();
        if (writes.empty())
            return;
        uint32_t const account = journal.Account();
        CharacterDatabaseTransaction transaction = CharacterDatabase.BeginTransaction();
        for (RowWrite const& write : writes)
        {
            std::string const sql = UpsertStatement(journal, write);
            if (sql.empty())
                continue;
            transaction->Append(std::string_view(sql));
            if (write.kind == RowKind::Release)
                transaction->Append("DELETE f FROM `coa_pet_follower` f JOIN `characters` c ON c.`guid` = f.`guid` "
                    "WHERE c.`account` = {} AND f.`pet_id` = {}", account, write.key);
        }
        if (transaction->GetSize() == 0)
            return;
        _refs.WriteStarted(account);
        _callbacks.AddCallback(CharacterDatabase.AsyncCommitTransaction(transaction)).AfterComplete(
            [this, account, complete = std::move(complete)](bool success)
            {
                if (!success)
                    LOG_ERROR("module", "Pet journal write for account {} failed", account);
                if (_refs.WriteFinished(account))
                    _journals.erase(account);
                if (complete)
                {
                    if (!success && !Pending(account) && Get(account))
                        Reload(account);
                    complete(success);
                }
            });
    }

    size_t PetJournalStore::Pending(uint32_t account) const
    {
        return _refs.Pending(account);
    }

    bool PetJournalStore::Reload(uint32_t account)
    {
        if (Pending(account) || !Get(account))
            return false;
        return Load(account);
    }

    void PetJournalStore::DeleteAccount(uint32_t account)
    {
        _journals.erase(account);
        for (char const* table : { "coa_pet_journal", "coa_pet_team", "coa_pet_account" })
            CharacterDatabase.Execute("DELETE FROM `{}` WHERE `account` = {}", table, account);
    }

    void PetJournalStore::Update()
    {
        for (LearnedSpell const& learned : _learned.Drain())
        {
            Player* player = ObjectAccessor::FindConnectedPlayer(ObjectGuid::Create<HighGuid::Player>(
                static_cast<ObjectGuid::LowType>(learned.character)));
            if (!Eligible(player) || player->GetSession()->GetAccountId() != learned.account)
                continue;
            if (Journal* journal = Get(learned.account))
                Sync(player, *journal);
        }
        _callbacks.ProcessReadyCallbacks();
    }
}
