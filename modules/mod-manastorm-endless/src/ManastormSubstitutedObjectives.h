#ifndef MANASTORM_SUBSTITUTED_OBJECTIVES_H
#define MANASTORM_SUBSTITUTED_OBJECTIVES_H

#include "Define.h"

namespace ManastormSubstitutedObjectives
{
    struct NativeTemplate
    {
        uint32 NativeEntry;
        float HealthModifier;
        float ManaModifier;
    };

    // Native Manastorm objective templates that our world database lacks, so their segments run a stock stand-in.
    // HealthModifier/ManaModifier come from the AscensionDB client captures (2026-07-02 to 2026-09-09, AscensionDB
    // revision d6494ceb3150).
    inline constexpr NativeTemplate NATIVE_TEMPLATES[] =
    {
        {83261, 78.120003f, 1.0f},  // Muckrake (stand-in 2421)
        {83617, 97.656197f, 1.0f},  // Grol the Destroyer (stand-in 7665)
        {83618, 97.656197f, 20.0f}, // Archmage Allistarj (stand-in 7666)
        {83619, 97.656197f, 12.0f}, // Lady Sevine (stand-in 7667)
        {83668, 78.120003f, 1.0f},  // Andre Firebeard (stand-in 7883)
        {83859, 97.650002f, 2.0f},  // Manaclaw (stand-in 10663)
        {84270, 60.6562f, 8.0f},    // Marisa du'Paige (stand-in 599)
        {84272, 97.656197f, 10.0f}, // Razelikh the Defiler (stand-in 7664)
    };

    constexpr NativeTemplate const* Find(uint32 nativeEntry, uint32 runtimeEntry)
    {
        if (!nativeEntry || nativeEntry == runtimeEntry)
            return nullptr;

        for (NativeTemplate const& nativeTemplate : NATIVE_TEMPLATES)
            if (nativeTemplate.NativeEntry == nativeEntry)
                return &nativeTemplate;

        return nullptr;
    }

    constexpr double Ratio(float nativeModifier, float runtimeModifier)
    {
        return runtimeModifier > 0.0f ? double(nativeModifier) / double(runtimeModifier) : 1.0;
    }
}

#endif
