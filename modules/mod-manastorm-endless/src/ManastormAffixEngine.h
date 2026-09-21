#ifndef MANASTORM_AFFIX_ENGINE_H
#define MANASTORM_AFFIX_ENGINE_H

#include "ManastormDefines.h"

#include <string>
#include <unordered_set>

class Creature;
class ManastormRun;

class ManastormAffixEngine
{
public:
    static ManastormAffixEngine& Instance();

    // Builds the affix side of a fresh disposable stage.
    //
    // IMPORTANT:
    // Automatic historical Ascension selection is deliberately
    // NOT enabled yet because its density/count/rank policy has
    // not been recovered with enough confidence.
    void InitializeStage(
        ManastormRun& run,
        std::unordered_set<uint32> const&
            unlockedAffixIds);

    // GM/debug path. Bypasses permanent progression ownership.
    bool ForceStageAffix(
        ManastormRun& run,
        uint32 affixId,
        std::string& error);

    void OnCreatureAdded(
        Creature* creature,
        ManastormRun& run);

    void OnCreatureRemoved(
        Creature* creature,
        ManastormRun& run);

    void OnCreatureDeath(
        Creature* creature,
        ManastormRun& run);

private:
    ManastormAffixEngine() = default;

    ManastormAffixDefinition const*
    GetDefinition(
        uint32 affixId) const;

    bool ValidateDefinition(
        ManastormAffixDefinition const& definition,
        std::string& error) const;

    bool IsEligibleStageCreature(
        Creature const* creature,
        ManastormRun const& run) const;

    bool IsEligibleForManaBomb(
        Creature const* creature,
        ManastormRun const& run) const;

    void AssignActiveAffixes(
        Creature* creature,
        ManastormRun& run);

    void DispatchOnDeath(
        Creature* creature,
        ManastormRun& run,
        uint32 affixId);

    void StartManaBomb(
        Creature* creature,
        ManastormRun& run);
};

#endif
