/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */
#ifndef ASCENSION_VANITY_OWNERSHIP_H
#define ASCENSION_VANITY_OWNERSHIP_H

#include <string>

namespace AscensionVanityOwnership
{
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
