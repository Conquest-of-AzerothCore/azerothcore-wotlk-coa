#ifndef MANASTORM_VOICE_OF_MILLHOUSE_H
#define MANASTORM_VOICE_OF_MILLHOUSE_H

#include "Define.h"

class ManastormRun;
class Player;

namespace ManastormVoiceOfMillhouse
{
    // Season-10 creaturecache.wdb:
    //   80911 -> Voice of Millhouse Manastorm
    //
    // The later client also knows 254339 with the same name, but the
    // shutdown-era Season-10 cache used 80911. Keep the reconstruction on
    // that proven identity until later server-side evidence says otherwise.
    constexpr uint32 EmitterCreatureEntry = 80911;

    // Register/clear per-run presentation state.
    void RegisterRun(
        uint64 runId,
        bool firstManastorm);

    void ClearRun(
        uint64 runId);

    // Drives delayed narration and per-run anti-overlap cooldowns.
    void Update(
        uint32 diff);

    // Presentation hooks owned by the Manastorm manager.
    //
    // Recovered behavior: global Manastorm introduction dialogue belongs to
    // the protected arrival window, before the stage becomes ACTIVE.
    void OnPlayerEnteredProtection(
        ManastormRun const& run,
        Player* player);

    void OnStageActivated(
        ManastormRun const& run);

    void OnPlayerDeath(
        ManastormRun const& run);

    void OnObjectiveComplete(
        ManastormRun const& run);
}

#endif
