#ifndef COA_ASCENSION_BLOODFORGED_H
#define COA_ASCENSION_BLOODFORGED_H

#include "Define.h"
#include <vector>

namespace Bloodforged
{
[[nodiscard]] std::vector<uint32> NewestReleasedHeroicGear();
[[nodiscard]] std::vector<uint32> ReleasedHeroicGear();
[[nodiscard]] uint32 HighRiskStage();
}

#endif
