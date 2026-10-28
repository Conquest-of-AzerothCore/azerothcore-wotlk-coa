/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#ifndef ASCENSION_CLASS_TUNING_H
#define ASCENSION_CLASS_TUNING_H

#include "Player.h"
#include "SpellAuras.h"
#include "SpellInfo.h"
#include <array>

namespace AscensionClassTuning
{
struct Entry
{
    uint32 SpellId;
    uint8 ClassId;
    uint32 SpecId;
};

inline constexpr std::array<Entry, 91> Entries = {{
    { 887000, 12, 0 },
    { 887001, 13, 0 },
    { 887002, 14, 0 },
    { 887003, 15, 0 },
    { 887004, 16, 0 },
    { 887005, 17, 0 },
    { 887006, 18, 0 },
    { 887007, 19, 0 },
    { 887008, 20, 0 },
    { 887009, 21, 0 },
    { 887010, 22, 0 },
    { 887011, 23, 0 },
    { 887012, 24, 0 },
    { 887013, 25, 0 },
    { 887014, 26, 0 },
    { 887015, 27, 0 },
    { 887016, 28, 0 },
    { 887017, 29, 0 },
    { 887018, 30, 0 },
    { 887019, 31, 0 },
    { 887020, 32, 0 },
    { 887021, 12, 2 },
    { 887022, 12, 1 },
    { 887023, 12, 3 },
    { 887024, 13, 5 },
    { 887025, 13, 6 },
    { 887026, 13, 4 },
    { 887027, 14, 8 },
    { 887028, 14, 7 },
    { 887029, 14, 9 },
    { 887030, 15, 10 },
    { 887031, 15, 11 },
    { 887032, 15, 97 },
    { 887033, 15, 12 },
    { 887034, 16, 15 },
    { 887035, 16, 13 },
    { 887036, 16, 14 },
    { 887037, 17, 18 },
    { 887038, 17, 16 },
    { 887039, 17, 17 },
    { 887040, 18, 21 },
    { 887041, 18, 20 },
    { 887042, 18, 19 },
    { 887043, 19, 23 },
    { 887044, 19, 22 },
    { 887045, 19, 24 },
    { 887046, 20, 26 },
    { 887047, 20, 27 },
    { 887048, 20, 25 },
    { 887049, 20, 99 },
    { 887050, 21, 28 },
    { 887051, 21, 30 },
    { 887052, 21, 29 },
    { 887053, 22, 32 },
    { 887054, 22, 31 },
    { 887055, 22, 33 },
    { 887056, 23, 34 },
    { 887057, 23, 36 },
    { 887058, 23, 35 },
    { 887059, 24, 38 },
    { 887060, 24, 37 },
    { 887061, 24, 39 },
    { 887062, 25, 42 },
    { 887063, 25, 41 },
    { 887064, 25, 96 },
    { 887065, 25, 40 },
    { 887066, 26, 100 },
    { 887067, 26, 44 },
    { 887068, 26, 43 },
    { 887069, 26, 45 },
    { 887070, 27, 46 },
    { 887071, 27, 47 },
    { 887072, 27, 98 },
    { 887073, 27, 48 },
    { 887074, 28, 49 },
    { 887075, 28, 51 },
    { 887076, 28, 50 },
    { 887077, 29, 54 },
    { 887078, 29, 53 },
    { 887079, 29, 52 },
    { 887080, 29, 101 },
    { 887081, 30, 56 },
    { 887082, 30, 55 },
    { 887083, 30, 57 },
    { 887084, 31, 59 },
    { 887085, 31, 60 },
    { 887086, 31, 95 },
    { 887087, 31, 58 },
    { 887088, 32, 62 },
    { 887089, 32, 61 },
    { 887090, 32, 63 },
}};

inline constexpr uint32 PvpSpellOffset = 100;

inline bool IsPvpTuningSpell(uint32 spellId)
{
    return spellId >= Entries.front().SpellId + PvpSpellOffset && spellId <= Entries.back().SpellId + PvpSpellOffset;
}

inline void DisablePvpHealingTuning(SpellInfo* info)
{
    if (!info || !IsPvpTuningSpell(info->Id))
        return;

    for (SpellEffectInfo& effect : info->Effects)
        if (effect.IsAura(SPELL_AURA_MOD_HEALING_DONE_PERCENT))
            effect.ApplyAuraName = SPELL_AURA_DUMMY;
}

inline void Synchronize(Player* player, uint32 specId, bool refreshAmounts)
{
    if (!player || !player->IsAlive() || !player->FindMap())
        return;

    for (Entry const& entry : Entries)
        for (uint32 spellId : { entry.SpellId, entry.SpellId + PvpSpellOffset })
        {
            if (entry.ClassId != player->getClass() || (entry.SpecId && entry.SpecId != specId))
            {
                player->RemoveAurasDueToSpell(spellId);
                continue;
            }

            if (Aura* aura = player->GetAura(spellId))
            {
                if (refreshAmounts)
                    aura->RecalculateAmountOfEffects();
            }
            else
                player->AddAura(spellId, player);
        }
}
}

#endif
