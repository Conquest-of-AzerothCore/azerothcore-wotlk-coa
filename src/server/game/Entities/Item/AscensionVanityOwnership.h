/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */
#ifndef ASCENSION_VANITY_OWNERSHIP_H
#define ASCENSION_VANITY_OWNERSHIP_H

#include "Define.h"
#include <string>

class Item;
class Player;

namespace AscensionVanityOwnership
{
bool OwnsItem(Player const* player, uint32 itemId);

void CollectItem(Player* player, Item* item);

void ForgetItemForTest(Player* player, uint32 itemId);

class TestOverride
{
public:
    TestOverride(bool unlockAll, std::string const& starterItems);
    ~TestOverride();
    TestOverride(TestOverride const&) = delete;
    TestOverride& operator=(TestOverride const&) = delete;

private:
    bool _unlockAll;
    std::string _starterItems;
};
}

#endif
