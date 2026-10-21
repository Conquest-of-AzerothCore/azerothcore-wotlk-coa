/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */
#include "AscensionQuestClues.h"
#include "GameObjectScript.h"
#include "ScriptMgr.h"

namespace
{
constexpr Ascension::QuestClues IdealsArePoisonClues{ 175035, 2300646, "core.coa_ideals_are_poison_clues", true };

struct go_coa_ideals_are_poison_clue : public Ascension::QuestClueAI
{
    explicit go_coa_ideals_are_poison_clue(GameObject* go) : QuestClueAI(go, IdealsArePoisonClues) { }
};
}

void AddSC_AscensionIdealsArePoisonClues()
{
    RegisterGameObjectAI(go_coa_ideals_are_poison_clue);
}
