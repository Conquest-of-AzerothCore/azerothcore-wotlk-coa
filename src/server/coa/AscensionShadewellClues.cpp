/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */
#include "AscensionQuestClues.h"
#include "GameObjectScript.h"
#include "ScriptMgr.h"

namespace
{
constexpr Ascension::QuestClues ShadewellClues{ 175069, 2300672, "core.coa_shadewell_clues" };
constexpr Ascension::QuestClues ShadewellCaveClues{ 175071, 2300677, "core.coa_shadewell_cave_clues", true };

struct go_coa_shadewell_clue : public Ascension::QuestClueAI
{
    explicit go_coa_shadewell_clue(GameObject* go) : QuestClueAI(go, ShadewellClues) { }
};

struct go_coa_shadewell_cave_clue : public Ascension::QuestClueAI
{
    explicit go_coa_shadewell_cave_clue(GameObject* go) : QuestClueAI(go, ShadewellCaveClues) { }
};
}

void AddSC_AscensionShadewellClues()
{
    RegisterGameObjectAI(go_coa_shadewell_clue);
    RegisterGameObjectAI(go_coa_shadewell_cave_clue);
}
