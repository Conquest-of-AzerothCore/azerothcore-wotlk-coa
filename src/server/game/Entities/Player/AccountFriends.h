#ifndef ACCOUNT_FRIENDS_H
#define ACCOUNT_FRIENDS_H

#include "SocialMgr.h"
#include <mutex>

namespace AccountFriends
{
    std::recursive_mutex& GetMutex();
    bool Has(ObjectGuid owner, ObjectGuid target);
    bool Add(ObjectGuid owner, ObjectGuid target);
    void Remove(ObjectGuid owner, ObjectGuid target);
    void SetNote(ObjectGuid owner, ObjectGuid target, std::string note);
    void SendMetadata(Player* player, std::map<ObjectGuid, FriendInfo> const& contacts);
}

#endif
