/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */
#include "AscensionClientSpellPatches.h"

namespace
{
constexpr uint32 SPELL_FEED_YAK = 9978001;
constexpr uint32 SPELL_CLEAN_STABLE = 9978002;
}

void AddSC_AscensionWoollyPride()
{
    Ascension::ClientSpellPatches::Instance().Register(SPELL_FEED_YAK);
    Ascension::ClientSpellPatches::Instance().Register(SPELL_CLEAN_STABLE);
}
