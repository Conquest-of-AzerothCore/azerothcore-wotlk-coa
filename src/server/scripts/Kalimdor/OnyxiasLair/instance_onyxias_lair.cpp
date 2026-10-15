/*
 * This file is part of the AzerothCore Project. See AUTHORS file for Copyright information
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
 * FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for
 * more details.
 *
 * You should have received a copy of the GNU General Public License along
 * with this program. If not, see <http://www.gnu.org/licenses/>.
 */

#include "InstanceMapScript.h"
#include "ScriptedCreature.h"
#include "onyxias_lair.h"

ObjectData const creatureData[] =
{
    { NPC_ONYXIA, DATA_ONYXIA },
    { 0,          0           }
};

class instance_onyxias_lair : public InstanceMapScript
{
public:
    instance_onyxias_lair() : InstanceMapScript("instance_onyxias_lair", MAP_ONYXIAS_LAIR) { }

    InstanceScript* GetInstanceScript(InstanceMap* pMap) const override
    {
        return new instance_onyxias_lair_InstanceMapScript(pMap);
    }

    struct instance_onyxias_lair_InstanceMapScript : public InstanceScript
    {
        instance_onyxias_lair_InstanceMapScript(Map* pMap) : InstanceScript(pMap) {Initialize();};

        std::string str_data;
        uint16 ManyWhelpsCounter;
        bool bDeepBreath;

        // CONFIRMED 2026-10-02 (external review): Basalthane's shattered pillars need
        // to stay down for the boss's FULL instance lockout, not just a long in-memory
        // timer (which doesn't survive a worldserver restart). Persisted through the
        // instance's own save data - survives restarts (loaded from the `instance`
        // table like every other piece of instance state) and clears itself on a real
        // instance reset (the whole save-data row gets wiped then, same as everything
        // else in it). Wipe/evade restoration is unaffected - that's still handled
        // immediately and independently in spell_basalthane.cpp via Map::ProcessCreatureRespawn,
        // this flag only ever gets set true on an actual kill (see OnUnitDeath below).
        bool basalthanePillarsShattered = false;

        void Initialize() override
        {
            SetHeaders(DataHeader);
            SetBossNumber(MAX_ENCOUNTER);
            ManyWhelpsCounter = 0;
            bDeepBreath = true;
            LoadObjectData(creatureData, nullptr);
        }

        void ReadSaveDataMore(std::istringstream& data) override
        {
            data >> basalthanePillarsShattered;
        }

        void WriteSaveDataMore(std::ostringstream& data) override
        {
            data << uint32(basalthanePillarsShattered);
        }

        void OnUnitDeath(Unit* unit) override
        {
            if (unit->GetEntry() == NPC_BASALTHANE && !basalthanePillarsShattered)
            {
                basalthanePillarsShattered = true;
                SaveToDB();
            }
        }

        void OnCreatureCreate(Creature* creature) override
        {
            switch (creature->GetEntry())
            {
                case NPC_BASALTHANE_PILLAR_1:
                case NPC_BASALTHANE_PILLAR_2:
                case NPC_BASALTHANE_PILLAR_3:
                    // A fresh load (worldserver restart, grid reload, etc.) spawns the
                    // pillar alive by default - if Basalthane is still dead for this
                    // lockout, immediately re-assert the shattered state instead of
                    // letting it stand. Same technique as ShatterPillar() in
                    // spell_basalthane.cpp (force the corpse to decay immediately, no
                    // lingering model).
                    if (basalthanePillarsShattered && creature->IsAlive())
                    {
                        creature->KillSelf();
                        creature->SetCorpseRemoveTime(0);
                    }
                    break;
            }
            InstanceScript::OnCreatureCreate(creature);
        }

        void OnGameObjectCreate(GameObject* go) override
        {
            switch (go->GetEntry())
            {
                case GO_WHELP_SPAWNER:
                    go->CastSpell((Unit*)nullptr, 17646);
                    if (Creature* onyxia = GetCreature(DATA_ONYXIA))
                    {
                        onyxia->AI()->DoAction(ACTION_WHELP_SUMMONED);
                    }
                    break;
            }
        }

        bool SetBossState(uint32 type, EncounterState state) override
        {
            if (!InstanceScript::SetBossState(type, state))
            {
                return false;
            }

            if (type == DATA_ONYXIA && state == NOT_STARTED)
            {
                ManyWhelpsCounter = 0;
                bDeepBreath = true;
            }

            return true;
        }

        void SetData(uint32 uiType, uint32 /*uiData*/) override
        {
            switch (uiType)
            {
                case DATA_WHELP_SUMMONED:
                    ++ManyWhelpsCounter;
                    break;
                case DATA_DEEP_BREATH_FAILED:
                    bDeepBreath = false;
                    break;
            }
        }

        bool CheckAchievementCriteriaMeet(uint32 criteria_id, Player const*  /*source*/, Unit const*  /*target*/, uint32  /*miscvalue1*/) override
        {
            switch (criteria_id)
            {
                case ACHIEV_CRITERIA_MANY_WHELPS_10_PLAYER:
                case ACHIEV_CRITERIA_MANY_WHELPS_25_PLAYER:
                    return ManyWhelpsCounter >= 50;
                case ACHIEV_CRITERIA_DEEP_BREATH_10_PLAYER:
                case ACHIEV_CRITERIA_DEEP_BREATH_25_PLAYER:
                    return bDeepBreath;
            }
            return false;
        }
    };
};

void AddSC_instance_onyxias_lair()
{
    new instance_onyxias_lair();
}
