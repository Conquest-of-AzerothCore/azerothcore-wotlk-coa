/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */
#ifndef COA_PTR_CHARACTER_COPY_H
#define COA_PTR_CHARACTER_COPY_H

#include <string>

namespace PtrCharacterCopy
{
class TestOverride
{
public:
    explicit TestOverride(std::string sourceSchema = {});
    ~TestOverride();
    TestOverride(TestOverride const&) = delete;
    TestOverride& operator=(TestOverride const&) = delete;
};
}

#endif
