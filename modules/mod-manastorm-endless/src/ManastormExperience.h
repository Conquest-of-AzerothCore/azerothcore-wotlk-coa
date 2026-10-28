#ifndef MANASTORM_EXPERIENCE_H
#define MANASTORM_EXPERIENCE_H

#include "DatabaseEnv.h"
#include "ObjectGuid.h"
#include <string>
#include <unordered_set>

class ManastormRun;
class Player;

class ManastormExperience
{
public:
    static ManastormExperience& Instance();
    bool Load();
    bool PrepareCompletion(ManastormRun const& run, CharacterDatabaseTransaction const& transaction,
        std::string& error) const;
    void Settle(Player* player);
    void OnMapEntry(Player* player);

private:
    bool _loaded = false;
    bool _enabled = false;
    uint32 _dungeonId = 258;
    double _multiplier = 1.0;
    std::unordered_set<ObjectGuid::LowType> _failedClaims;
    std::unordered_set<ObjectGuid::LowType> _deferredClaims;
};

#endif
