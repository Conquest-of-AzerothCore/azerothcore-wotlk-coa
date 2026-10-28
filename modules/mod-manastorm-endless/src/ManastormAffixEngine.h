#ifndef MANASTORM_AFFIX_ENGINE_H
#define MANASTORM_AFFIX_ENGINE_H

#include "ManastormDefines.h"

#include <string>
#include <unordered_set>

class Creature;
class ManastormRun;
class Player;

class ManastormAffixEngine
{
public:
    static ManastormAffixEngine& Instance();

    void InitializeStage(
        ManastormRun& run,
        std::unordered_set<uint32> const& unlockedAffixIds);

    bool ForceStageAffix(
        ManastormRun& run,
        uint32 affixId,
        std::string& error);

    bool ForceAffixOnCreature(
        Creature* creature,
        ManastormRun& run,
        uint32 affixId);

    void ApplyActivePlayerAffixes(
        Player* player,
        ManastormRun& run);

    void RemoveActivePlayerAffixes(
        Player* player,
        ManastormRun const& run);

    bool IsAffixHelperCreature(
        uint32 creatureEntry) const;

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
    GetDefinition(uint32 affixId) const;

    bool ValidateDefinition(
        ManastormAffixDefinition const& definition,
        std::string& error) const;

    bool IsEligibleStageCreature(
        Creature const* creature,
        ManastormRun const& run) const;

    bool IsEligibleTrashTarget(
        Creature const* creature,
        ManastormRun const& run) const;

    bool IsEligibleBossTarget(
        Creature const* creature,
        ManastormRun const& run) const;

    bool IsEligibleForManaBomb(
        Creature const* creature,
        ManastormRun const& run) const;

    bool AssignAffixToCreature(
        Creature* creature,
        ManastormRun& run,
        ManastormAffixDefinition const& definition,
        bool force);

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
