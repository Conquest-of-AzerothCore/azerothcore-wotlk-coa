#ifndef COA_PET_BATTLE_DATA_STORE_H
#define COA_PET_BATTLE_DATA_STORE_H

#include "PetBattleData.h"

namespace CoAPetBattles
{
    class PetBattleDataStore
    {
    public:
        static PetBattleDataStore* instance();

        void LoadSettings();
        void Load();

        bool IsLoaded() const { return _loaded; }
        DataSet const& Data() const { return _data; }
        Settings const& Config() const { return _settings; }

        Species const* FindSpecies(uint32_t entry) const;
        Ability const* FindAbility(uint32_t id) const;
        Zone const* FindZone(uint32_t zone) const;
        std::vector<Presentation const*> PresentationsOf(uint32_t species) const;
        uint32_t StandInEntry(uint32_t species) const;

    private:
        bool _enabled = true;
        bool _loaded = false;
        DataSet _data;
        Settings _settings;
    };
}

#define sPetBattleData CoAPetBattles::PetBattleDataStore::instance()

#endif
