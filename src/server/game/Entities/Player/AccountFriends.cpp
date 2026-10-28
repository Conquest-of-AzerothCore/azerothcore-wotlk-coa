#include "AccountFriends.h"
#include "CharacterCache.h"
#include "Player.h"
#include "Util.h"
#include "World.h"
#include "WorldPacket.h"
#include "WorldSession.h"
#include "WorldSessionMgr.h"
#include <mutex>

namespace AccountFriends
{
    struct Entry
    {
        ObjectGuid OriginalGuid;
        std::string OriginalName;
        std::string Note;
    };

    using Friends = std::map<uint32, Entry>;
    std::recursive_mutex Mutex;
    std::map<uint32, Friends> Loaded;

    std::recursive_mutex& GetMutex()
    {
        return Mutex;
    }

    uint32 Account(ObjectGuid guid)
    {
        return sCharacterCache->GetCharacterAccountIdByGuid(guid);
    }

    bool EnsureMigrated(uint32 account)
    {
        auto* check = CharacterDatabase.GetPreparedStatement(CHAR_SEL_ACCOUNT_FRIEND_MIGRATION);
        check->SetData(0, account);
        auto marker = CharacterDatabase.Query(check);
        if (!marker)
            return false;
        if (marker->Fetch()[0].Get<uint32>())
            return true;

        auto* legacy = CharacterDatabase.GetPreparedStatement(CHAR_SEL_ACCOUNT_FRIEND_LEGACY);
        legacy->SetData(0, account);
        auto rows = CharacterDatabase.Query(legacy);
        if (!rows)
            return false;
        Friends friends;
        do
        {
            Field* fields = rows->Fetch();
            uint32 other = fields[0].Get<uint32>();
            if (!other || other == account)
                continue;
            Entry entry{ObjectGuid::Create<HighGuid::Player>(fields[1].Get<uint32>()),
                fields[2].Get<std::string>(), fields[3].Get<std::string>()};
            auto [found, inserted] = friends.emplace(other, entry);
            if ((!inserted && found->second.Note != entry.Note) || friends.size() > SOCIALMGR_FRIEND_LIMIT)
            {
                LOG_ERROR("entities.player", "Account friends migration requires note/limit reconciliation for {}", account);
                return false;
            }
        } while (rows->NextRow());

        auto transaction = CharacterDatabase.BeginTransaction();
        for (auto const& [other, entry] : friends)
        {
            auto* insert = CharacterDatabase.GetPreparedStatement(CHAR_INS_ACCOUNT_FRIEND);
            insert->SetData(0, account);
            insert->SetData(1, other);
            insert->SetData(2, entry.OriginalGuid.GetCounter());
            insert->SetData(3, entry.OriginalName);
            insert->SetData(4, entry.Note);
            transaction->Append(insert);
        }
        auto* complete = CharacterDatabase.GetPreparedStatement(CHAR_INS_ACCOUNT_FRIEND_MIGRATION);
        complete->SetData(0, account);
        transaction->Append(complete);
        CharacterDatabase.DirectCommitTransaction(transaction);
        check = CharacterDatabase.GetPreparedStatement(CHAR_SEL_ACCOUNT_FRIEND_MIGRATION);
        check->SetData(0, account);
        marker = CharacterDatabase.Query(check);
        return marker && marker->Fetch()[0].Get<uint32>() == 1;
    }

    bool Reload(uint32 account)
    {
        std::lock_guard lock(Mutex);
        if (!Loaded.count(account) && !EnsureMigrated(account))
            return false;
        auto* statement = CharacterDatabase.GetPreparedStatement(CHAR_SEL_ACCOUNT_FRIENDS);
        statement->SetData(0, account);
        auto result = CharacterDatabase.Query(statement);
        if (!result)
        {
            Loaded.erase(account);
            LOG_ERROR("entities.player", "Account friends could not be loaded");
            return false;
        }

        Friends friends;
        do
        {
            Field* fields = result->Fetch();
            uint32 target = fields[0].Get<uint32>();
            if (target && target != account)
                friends.emplace(target, Entry{ObjectGuid::Create<HighGuid::Player>(fields[1].Get<uint32>()),
                    fields[2].Get<std::string>(), fields[3].Get<std::string>()});
        } while (result->NextRow());
        Loaded[account] = std::move(friends);
        return true;
    }

    Friends const* Get(uint32 account)
    {
        std::lock_guard lock(Mutex);
        if (!account || (!Loaded.count(account) && !Reload(account)))
            return nullptr;
        return &Loaded.at(account);
    }

    bool Has(ObjectGuid owner, ObjectGuid target)
    {
        std::lock_guard lock(Mutex);
        auto const* friends = Get(Account(owner));
        return friends && friends->count(Account(target));
    }

    bool Add(ObjectGuid owner, ObjectGuid target)
    {
        std::lock_guard lock(Mutex);
        uint32 account = Account(owner);
        uint32 other = Account(target);
        auto const* friends = Get(account);
        auto const* character = sCharacterCache->GetCharacterCacheByGuid(target);
        if (!friends || !character || !other || account == other)
            return false;
        if (friends->count(other))
            return true;
        if (friends->size() >= SOCIALMGR_FRIEND_LIMIT)
            return false;

        auto* statement = CharacterDatabase.GetPreparedStatement(CHAR_INS_ACCOUNT_FRIEND);
        statement->SetData(0, account);
        statement->SetData(1, other);
        statement->SetData(2, target.GetCounter());
        statement->SetData(3, character->Name);
        statement->SetData(4, std::string());
        CharacterDatabase.DirectExecute(statement);
        return Reload(account) && Loaded.at(account).count(other);
    }

    void Remove(ObjectGuid owner, ObjectGuid target)
    {
        std::lock_guard lock(Mutex);
        uint32 account = Account(owner);
        auto* statement = CharacterDatabase.GetPreparedStatement(CHAR_DEL_ACCOUNT_FRIEND);
        statement->SetData(0, account);
        statement->SetData(1, Account(target));
        CharacterDatabase.DirectExecute(statement);
        Reload(account);
    }

    void SetNote(ObjectGuid owner, ObjectGuid target, std::string note)
    {
        std::lock_guard lock(Mutex);
        utf8truncate(note, 48);
        uint32 account = Account(owner);
        auto* statement = CharacterDatabase.GetPreparedStatement(CHAR_UPD_ACCOUNT_FRIEND_NOTE);
        statement->SetData(0, note);
        statement->SetData(1, account);
        statement->SetData(2, Account(target));
        CharacterDatabase.DirectExecute(statement);
        Reload(account);
    }

    ObjectGuid Display(Player* observer, uint32 account, Entry const& entry, ObjectGuid excluded)
    {
        if (WorldSession* session = sWorldSessionMgr->FindSession(account))
            if (Player* current = session->GetPlayer())
                if (current->GetGUID() != excluded && current->IsInWorld())
                {
                    FriendInfo info;
                    SocialMgr::GetFriendInfo(observer, current->GetGUID(), info);
                    if (info.Status != FRIEND_STATUS_OFFLINE)
                        return current->GetGUID();
                }

        if (Account(entry.OriginalGuid) == account)
            return entry.OriginalGuid;

        auto* statement = CharacterDatabase.GetPreparedStatement(CHAR_SEL_FRIEND_FALLBACK);
        statement->SetData(0, account);
        if (auto result = CharacterDatabase.Query(statement))
        {
            auto guid = ObjectGuid::Create<HighGuid::Player>(result->Fetch()[0].Get<uint32>());
            if (Account(guid) == account)
                return guid;
        }
        return ObjectGuid::Empty;
    }

    void String(WorldPacket& packet, std::string const& value)
    {
        packet << uint32(value.size());
        packet.append(value.data(), value.size());
    }

    void SendMetadata(Player* player, std::map<ObjectGuid, FriendInfo> const& contacts)
    {
        std::lock_guard lock(Mutex);
        auto const* friends = Get(player->GetSession()->GetAccountId());
        if (!friends)
            return;
        WorldPacket packet(0x9C0, 128);
        packet << uint32(0);
        uint32 count = 0;
        for (auto const& [guid, info] : contacts)
        {
            if (!(info.Flags & SOCIAL_FLAG_FRIEND) || count >= SOCIALMGR_FRIEND_LIMIT)
                continue;
            auto const* character = sCharacterCache->GetCharacterCacheByGuid(guid);
            if (!character)
                continue;
            auto found = friends->find(character->AccountId);
            if (found == friends->end())
                continue;
            String(packet, character->Name);
            String(packet, found->second.OriginalName);
            ++count;
        }
        packet.put<uint32>(0, count);
        player->SendDirectMessage(&packet);
    }
}

bool PlayerSocial::UsesAccountFriends() const
{
    return sWorld->getBoolConfig(CONFIG_ACCOUNT_WIDE_FRIENDS);
}

void PlayerSocial::ProjectAccountFriends(Player* player, ObjectGuid excluded)
{
    std::lock_guard lock(AccountFriends::Mutex);
    auto const* friends = AccountFriends::Get(player->GetSession()->GetAccountId());
    if (!friends)
        return;
    for (auto itr = m_playerSocialMap.begin(); itr != m_playerSocialMap.end();)
    {
        itr->second.Flags &= ~SOCIAL_FLAG_FRIEND;
        if (!itr->second.Flags)
            itr = m_playerSocialMap.erase(itr);
        else
            ++itr;
    }
    for (auto const& [account, entry] : *friends)
    {
        ObjectGuid guid = AccountFriends::Display(player, account, entry, excluded);
        if (!guid)
            continue;
        auto& info = m_playerSocialMap[guid];
        info.Flags |= SOCIAL_FLAG_FRIEND;
        info.Note = entry.Note;
    }
}
