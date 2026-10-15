/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */
#ifndef ASCENSION_GUARDIAN_COMPLETION_H
#define ASCENSION_GUARDIAN_COMPLETION_H

#include <cstdint>

class SpellInfo;
class Player;

namespace AscensionGuardian
{
inline bool Ram(std::uint32_t id) { return id == 802284 || (id >= 573204 && id <= 573211); }
inline bool Pulverize(std::uint32_t id)
{
    return id == 800311 || (id >= 802439 && id <= 802443) || id == 573286 || id == 573292;
}
inline bool HeavyBlow(std::uint32_t id) { return id == 803129 || (id >= 503119 && id <= 503126); }
inline bool Centurion(std::uint32_t id) { return id == 802286 || (id >= 802734 && id <= 802738); }
inline bool Advance(std::uint32_t id) { return id == 500170 || (id >= 503344 && id <= 503351); }
inline bool Ballad(std::uint32_t id)
{
    return id == 801776 || id == 801772 || (id >= 501066 && id <= 501074) ||
        (id >= 572717 && id <= 572719) || (id >= 574340 && id <= 574341) ||
        (id >= 574363 && id <= 574364);
}
void AddParagon(Player* player, std::uint8_t amount);
void ApplyContracts(SpellInfo* info);
}

#endif
