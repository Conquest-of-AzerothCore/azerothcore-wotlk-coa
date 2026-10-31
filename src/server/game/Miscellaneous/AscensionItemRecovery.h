#ifndef ASCENSION_ITEM_RECOVERY_H
#define ASCENSION_ITEM_RECOVERY_H

#include "DatabaseEnvFwd.h"
#include <cstdint>

class Item;
class Player;

namespace AscensionItemRecovery
{
enum class Source : std::uint8_t
{
    Deleted = 1,
    Vendored = 2
};

inline bool (*Capture)(Player*, Item*, std::uint32_t, Source, std::uint32_t) = nullptr;
inline void (*ForgetVendor)(Player*, Item*) = nullptr;
inline void (*Persist)(Player*) = nullptr;
inline void (*Flush)(Player*, CharacterDatabaseTransaction) = nullptr;
}

#endif
