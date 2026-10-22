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

#include "AreaTriggerScript.h"
#include "CreatureAI.h"
#include "EventMap.h"
#include "GameObject.h"
#include "GameObjectAI.h"
#include "GameObjectScript.h"
#include "InstanceMapScript.h"
#include "InstanceScript.h"
#include "Map.h"
#include "Player.h"
#include "SpellScript.h"
#include "SpellScriptLoader.h"
#include "Unit.h"
#include "sunken_temple.h"
#include <array>

namespace
{
    struct EranikusWarden
    {
        uint32 entry;
        uint8 group;
    };

    constexpr std::array<EranikusWarden, 7> EranikusWardens =
    {{
        { NPC_AVATAR_OF_HAKKAR, 0 },
        { NPC_JAMMAL_AN_THE_PROPHET, 1 },
        { NPC_OGOM_THE_WRETCHED, 1 },
        { NPC_DREAMSCYTHE, 2 },
        { NPC_WEAVER, 2 },
        { NPC_HAZZAS, 3 },
        { NPC_MORPHAZ, 3 },
    }};

    constexpr std::array<char const*, 4> EranikusWardenGroupNames =
    {
        "Avatar of Hakkar",
        "Jammal'an the Prophet & Ogom the Wretched",
        "Dreamscythe & Weaver",
        "Hazzas & Morphaz",
    };

    constexpr uint32 AllEranikusWardensKilled = (1u << EranikusWardens.size()) - 1;
    constexpr float EranikusSlumberNoticeRange = 40.0f;
    constexpr float EranikusSlumberNoticeResetRange = 70.0f;
    Position const ShadeOfHakkarSummonPosition = { -466.795f, 272.863f, -90.447f, 1.57f };
}

class instance_sunken_temple : public InstanceMapScript
{
public:
    instance_sunken_temple() : InstanceMapScript("instance_sunken_temple", MAP_SUNKEN_TEMPLE) { }

    struct instance_sunken_temple_InstanceMapScript : public InstanceScript
    {
        instance_sunken_temple_InstanceMapScript(Map* map) : InstanceScript(map)
        {
            SetHeaders(DataHeader);
        }

        void Initialize() override
        {
            _statuePhase = 0;
            _defendersKilled = 0;
            _eranikusWardensKilled = 0;
            memset(&_encounters, 0, sizeof(_encounters));
        }

        void OnCreatureCreate(Creature* creature) override
        {
            switch (creature->GetEntry())
            {
                case NPC_JAMMAL_AN_THE_PROPHET:
                    _jammalanGUID = creature->GetGUID();
                    break;
                case NPC_SHADE_OF_ERANIKUS:
                    _shadeOfEranikusGUID = creature->GetGUID();
                    if (!IsEranikusAwake())
                        creature->SetUnitFlag(UNIT_FLAG_NOT_SELECTABLE);
                    break;
            }

            if (creature->IsAlive() && creature->GetSpawnId() && creature->GetCreatureType() == CREATURE_TYPE_DRAGONKIN && creature->GetEntry() != NPC_SHADE_OF_ERANIKUS)
                _dragonkinList.push_back(creature->GetGUID());
        }

        void OnUnitDeath(Unit* unit) override
        {
            if (unit->IsCreature() && unit->GetCreatureType() == CREATURE_TYPE_DRAGONKIN && unit->GetEntry() != NPC_SHADE_OF_ERANIKUS)
                _dragonkinList.remove(unit->GetGUID());
            if (unit->IsCreature())
                OnEranikusWardenDeath(unit->GetEntry());
            if (unit->GetEntry() == NPC_HAKKARI_BLOODKEEPER && GetData(TYPE_HAKKAR_EVENT) == IN_PROGRESS)
                ExtinguishNearestEternalFlame(unit);
        }

        void ExtinguishNearestEternalFlame(Unit* bloodkeeper)
        {
            GameObject* nearestFlame = nullptr;
            for (ObjectGuid const& guid : _eternalFlameGUIDs)
            {
                GameObject* flame = instance->GetGameObject(guid);
                if (!flame || flame->GetGoState() != GO_STATE_READY)
                    continue;
                if (!nearestFlame || bloodkeeper->GetExactDist2d(flame) < bloodkeeper->GetExactDist2d(nearestFlame))
                    nearestFlame = flame;
            }

            if (!nearestFlame)
                return;

            nearestFlame->SetLootState(GO_READY);
            nearestFlame->UseDoorOrButton();
            Map::PlayerList const& players = instance->GetPlayers();
            if (!players.IsEmpty())
                nearestFlame->AI()->GossipHello(players.begin()->GetSource(), false);
        }

        bool IsEranikusAwake() const
        {
            return _eranikusWardensKilled == AllEranikusWardensKilled;
        }

        void OnEranikusWardenDeath(uint32 entry)
        {
            for (std::size_t i = 0; i < EranikusWardens.size(); ++i)
                if (EranikusWardens[i].entry == entry)
                    _eranikusWardensKilled |= 1u << i;

            if (IsEranikusAwake())
                if (Creature* eranikus = instance->GetCreature(_shadeOfEranikusGUID))
                    eranikus->RemoveUnitFlag(UNIT_FLAG_NOT_SELECTABLE);

            SaveToDB();
        }

        std::string EranikusSlumberNotice() const
        {
            std::string notice = "Shade of Eranikus still slumbers, to awaken him defeat:";
            for (std::size_t group = 0; group < EranikusWardenGroupNames.size(); ++group)
            {
                bool groupAlive = false;
                for (std::size_t i = 0; i < EranikusWardens.size(); ++i)
                    if (EranikusWardens[i].group == group && !(_eranikusWardensKilled & (1u << i)))
                        groupAlive = true;

                if (groupAlive)
                    notice += std::string("\n") + EranikusWardenGroupNames[group];
            }
            return notice;
        }

        void NotifyPlayersNearSlumberingEranikus()
        {
            Creature* eranikus = instance->GetCreature(_shadeOfEranikusGUID);
            if (!eranikus || IsEranikusAwake())
                return;

            instance->DoForAllPlayers([&](Player* player)
            {
                float const distance = player->GetDistance(eranikus);
                if (distance > EranikusSlumberNoticeResetRange)
                    _playersToldEranikusSlumbers.erase(player->GetGUID());
                else if (distance <= EranikusSlumberNoticeRange && _playersToldEranikusSlumbers.insert(player->GetGUID()).second)
                    eranikus->Whisper(EranikusSlumberNotice(), LANG_UNIVERSAL, player, true);
            });
        }

        void AwakenSoulflayer()
        {
            if (GetData(TYPE_HAKKAR_EVENT) != NOT_STARTED)
                return;

            if (TempSummon* summon = instance->SummonCreature(NPC_SHADE_OF_HAKKAR, ShadeOfHakkarSummonPosition))
            {
                summon->SetTempSummonType(TEMPSUMMON_MANUAL_DESPAWN);
                SetData(TYPE_HAKKAR_EVENT, IN_PROGRESS);
            }
        }

        void OnGameObjectCreate(GameObject* gameobject) override
        {
            switch (gameobject->GetEntry())
            {
                case GO_ATALAI_STATUE1:
                case GO_ATALAI_STATUE2:
                case GO_ATALAI_STATUE3:
                case GO_ATALAI_STATUE4:
                case GO_ATALAI_STATUE5:
                case GO_ATALAI_STATUE6:
                    if (gameobject->GetEntry() < GO_ATALAI_STATUE1 + _statuePhase)
                    {
                        instance->SummonGameObject(GO_ATALAI_LIGHT2, gameobject->GetPositionX(), gameobject->GetPositionY(), gameobject->GetPositionZ(), 0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f);
                        gameobject->ReplaceAllGameObjectFlags(GO_FLAG_NOT_SELECTABLE);
                    }
                    break;
                case GO_ATALAI_IDOL:
                    if (_statuePhase == MAX_STATUE_PHASE)
                        gameobject->SummonGameObject(GO_IDOL_OF_HAKKAR, -476.269317626953125f, 94.4119873046875f, -189.729660034179687f, 1.588248729705810546f, 0.0f, 0.0f, 0.713250160217285156f, 0.700909554958343505f, 0); // VerifiedBuild 50250

                    break;
                case GO_IDOL_OF_HAKKAR:
                    if (_encounters[TYPE_ATAL_ALARION] == DONE)
                        gameobject->RemoveGameObjectFlag(GO_FLAG_NOT_SELECTABLE);
                    break;
                case GO_FORCEFIELD:
                    _forcefieldGUID = gameobject->GetGUID();
                    gameobject->SetGoState(GO_STATE_ACTIVE);
                    break;
                case GO_ETERNAL_FLAME1:
                case GO_ETERNAL_FLAME2:
                case GO_ETERNAL_FLAME3:
                case GO_ETERNAL_FLAME4:
                    _eternalFlameGUIDs.push_back(gameobject->GetGUID());
                    gameobject->SetGameObjectFlag(GO_FLAG_NOT_SELECTABLE);
                    break;
                case GO_HAKKAR_WORSHIP_ALTAR:
                    _worshipAltarGUID = gameobject->GetGUID();
                    if (_encounters[TYPE_HAKKAR_EVENT] == DONE)
                        gameobject->SetGameObjectFlag(GO_FLAG_NOT_SELECTABLE);
                    break;
            }
        }

        void SetData(uint32 type, uint32 data) override
        {
            switch (type)
            {
                case DATA_STATUES:
                    _events.ScheduleEvent(DATA_STATUES, 0ms);
                    break;
                case DATA_AWAKEN_SOULFLAYER:
                    AwakenSoulflayer();
                    return;
                case DATA_DEFENDER_KILLED:
                    ++_defendersKilled;
                    if (_defendersKilled == DEFENDERS_COUNT)
                    {
                        if (Creature* jammal = instance->GetCreature(_jammalanGUID))
                            jammal->AI()->Talk(0);
                        if (GameObject* forcefield = instance->GetGameObject(_forcefieldGUID))
                            forcefield->SetGoState(GO_STATE_ACTIVE);
                    }
                    break;
                case DATA_ERANIKUS_FIGHT:
                    for (ObjectGuid const& guid : _dragonkinList)
                    {
                        if (Creature* creature = instance->GetCreature(guid))
                            if (instance->IsGridLoaded(creature->GetPositionX(), creature->GetPositionY()))
                                creature->SetInCombatWithZone();
                    }
                    break;
                case TYPE_HAKKAR_EVENT:
                    _encounters[type] = data;
                    if (data == DONE)
                        if (GameObject* altar = instance->GetGameObject(_worshipAltarGUID))
                            altar->SetGameObjectFlag(GO_FLAG_NOT_SELECTABLE);
                    break;
                case TYPE_ATAL_ALARION:
                case TYPE_JAMMAL_AN:
                    _encounters[type] = data;
                    break;
            }

            SaveToDB();
        }

        uint32 GetData(uint32 type) const override
        {
            switch (type)
            {
                case DATA_STATUES:
                    return _statuePhase;
                case DATA_DEFENDER_KILLED:
                    return DEFENDERS_COUNT;
                case TYPE_ATAL_ALARION:
                case TYPE_JAMMAL_AN:
                case TYPE_HAKKAR_EVENT:
                    return _encounters[type];
            }

            return 0;
        }

        void Update(uint32 diff) override
        {
            _events.Update(diff);

            _eranikusSlumberNoticeTimer += diff;
            if (_eranikusSlumberNoticeTimer >= 1000)
            {
                _eranikusSlumberNoticeTimer = 0;
                NotifyPlayersNearSlumberingEranikus();
            }

            switch (_events.ExecuteEvent())
            {
                case DATA_STATUES:
                    ++_statuePhase;
                    if (_statuePhase == MAX_STATUE_PHASE)
                        instance->SummonGameObject(GO_IDOL_OF_HAKKAR, -476.269317626953125f, 94.4119873046875f, -189.729660034179687f, 1.588248729705810546f, 0.0f, 0.0f, 0.713250160217285156f, 0.700909554958343505f, 0); // VerifiedBuild 50250

                    break;
            }
        }

        void ReadSaveDataMore(std::istringstream& data) override
        {
            data >> _encounters[0];
            data >> _encounters[1];
            data >> _encounters[2];
            data >> _statuePhase;
            data >> _defendersKilled;
            data >> _eranikusWardensKilled;
        }

        void WriteSaveDataMore(std::ostringstream& data) override
        {
            data << _encounters[0] << ' '
                << _encounters[1] << ' '
                << _encounters[2] << ' '
                << _statuePhase << ' '
                << _defendersKilled << ' '
                << _eranikusWardensKilled;
        }

    private:
        uint32 _statuePhase;
        uint32 _defendersKilled;
        uint32 _eranikusWardensKilled;
        uint32 _eranikusSlumberNoticeTimer = 0;
        uint32 _encounters[MAX_ENCOUNTERS];
        GuidSet _playersToldEranikusSlumbers;

        ObjectGuid _forcefieldGUID;
        ObjectGuid _worshipAltarGUID;
        GuidVector _eternalFlameGUIDs;
        ObjectGuid _jammalanGUID;
        ObjectGuid _shadeOfEranikusGUID;
        GuidList _dragonkinList;
        EventMap _events;
    };

    InstanceScript* GetInstanceScript(InstanceMap* map) const override
    {
        return new instance_sunken_temple_InstanceMapScript(map);
    }
};

enum MalfurionMisc
{
    QUEST_ERANIKUS_TYRANT_OF_DREAMS   = 8733,
    QUEST_THE_CHARGE_OF_DRAGONFLIGHTS = 8555,
};

class at_malfurion_stormrage : public AreaTriggerScript
{
public:
    at_malfurion_stormrage() : AreaTriggerScript("at_malfurion_stormrage") { }

    bool OnTrigger(Player* player, AreaTrigger const* /*at*/) override
    {
        if (player->GetInstanceScript() && !player->FindNearestCreature(NPC_MALFURION_STORMRAGE, 15.0f) &&
                player->GetQuestStatus(QUEST_THE_CHARGE_OF_DRAGONFLIGHTS) == QUEST_STATUS_REWARDED && player->GetQuestStatus(QUEST_ERANIKUS_TYRANT_OF_DREAMS) != QUEST_STATUS_REWARDED)
            player->SummonCreature(NPC_MALFURION_STORMRAGE, player->GetPositionX(), player->GetPositionY(), player->GetPositionZ(), -1.52f, TEMPSUMMON_TIMED_OR_DEAD_DESPAWN, 100000);
        return false;
    }
};

class spell_temple_of_atal_hakkar_hex_of_jammal_an_aura : public AuraScript
{
    PrepareAuraScript(spell_temple_of_atal_hakkar_hex_of_jammal_an_aura);

    bool Validate(SpellInfo const* /*spellInfo*/) override
    {
        return ValidateSpellInfo({ HEX_OF_JAMMAL_AN, HEX_OF_JAMMAL_AN_CHARM });
    }

    void OnRemove(AuraEffect const* /*aurEff*/, AuraEffectHandleModes /*mode*/)
    {
        if (Unit* caster = GetCaster())
            if (caster->IsAlive() && caster->IsInCombat())
            {
                caster->CastSpell(GetTarget(), HEX_OF_JAMMAL_AN, true);
                caster->CastSpell(GetTarget(), HEX_OF_JAMMAL_AN_CHARM, true);
            }
    }

    void Register() override
    {
        OnEffectRemove += AuraEffectRemoveFn(spell_temple_of_atal_hakkar_hex_of_jammal_an_aura::OnRemove, EFFECT_0, SPELL_AURA_DUMMY, AURA_EFFECT_HANDLE_REAL);
    }
};

class spell_temple_of_atal_hakkar_awaken_the_soulflayer : public SpellScript
{
    PrepareSpellScript(spell_temple_of_atal_hakkar_awaken_the_soulflayer);

    void HandleSendEvent(SpellEffIndex effIndex)
    {
        PreventHitDefaultEffect(effIndex);
        if (InstanceScript* instanceScript = GetCaster()->GetInstanceScript())
            instanceScript->SetData(DATA_AWAKEN_SOULFLAYER, 0);
    }

    void Register() override
    {
        OnEffectHit += SpellEffectFn(spell_temple_of_atal_hakkar_awaken_the_soulflayer::HandleSendEvent, EFFECT_0, SPELL_EFFECT_SEND_EVENT);
    }
};

class go_hakkar_worship_altar : public GameObjectScript
{
public:
    go_hakkar_worship_altar() : GameObjectScript("go_hakkar_worship_altar") { }

    bool OnGossipHello(Player* /*player*/, GameObject* go) override
    {
        if (InstanceScript* instanceScript = go->GetInstanceScript())
            instanceScript->SetData(DATA_AWAKEN_SOULFLAYER, 0);
        return false;
    }
};

void AddSC_instance_sunken_temple()
{
    new instance_sunken_temple();
    new at_malfurion_stormrage();
    new go_hakkar_worship_altar();
    RegisterSpellScript(spell_temple_of_atal_hakkar_hex_of_jammal_an_aura);
    RegisterSpellScript(spell_temple_of_atal_hakkar_awaken_the_soulflayer);
}
