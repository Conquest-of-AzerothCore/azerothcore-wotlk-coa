/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */
#ifndef COA_PTR_CHARACTER_COPY_H
#define COA_PTR_CHARACTER_COPY_H

namespace PtrCharacterCopy
{
enum class Interruption
{
    None,
    BeforeLoad,
    AfterLoad,
};

class TestOverride
{
public:
    explicit TestOverride(Interruption firstLoadInterruption = Interruption::None);
    ~TestOverride();
    TestOverride(TestOverride const&) = delete;
    TestOverride& operator=(TestOverride const&) = delete;
};
}

#endif
