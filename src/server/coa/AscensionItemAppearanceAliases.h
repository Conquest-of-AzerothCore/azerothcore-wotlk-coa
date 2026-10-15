#ifndef AZEROTHCORE_ASCENSION_ITEM_APPEARANCE_ALIASES_H
#define AZEROTHCORE_ASCENSION_ITEM_APPEARANCE_ALIASES_H

#include "Define.h"
#include <unordered_map>

namespace AscensionItemAppearanceAliases
{
void AddAliases(std::unordered_map<uint32, uint32>& mappings, std::unordered_map<uint32, uint32> const& sources);
}

#endif
