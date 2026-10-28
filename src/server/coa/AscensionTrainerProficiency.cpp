/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "AscensionTrainerProficiency.h"
#include "TrainerProficiencyFilter.h"

void AddSC_AscensionTrainerProficiency()
{
    TrainerProficiencyFilter::Owner.store(&AscensionTrainerProficiency::Refuses, std::memory_order_relaxed);
}
