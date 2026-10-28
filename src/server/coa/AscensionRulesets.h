/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#ifndef ASCENSION_RULESETS_H
#define ASCENSION_RULESETS_H

class Player;

namespace AscensionRulesets
{
enum class Ruleset
{
    WarMode,
    HighRisk,
    PvE
};

void Apply(Player* player, Ruleset ruleset);
bool Has(Player* player, Ruleset ruleset);
}

#endif
