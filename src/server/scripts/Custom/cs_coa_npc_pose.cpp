/*
 * Placement tools for spawned NPCs, used by the SpawnHelper addon:
 *   .npcpose <state>        stand state (sit, chair heights, sleep, dead, kneel)
 *   .npcemote <id>          looping emote state
 *   .npcnudge <dx> <dy> <dz> move by an exact offset from the current spawn point
 *   .npcface [orientation]  turn to an angle, or to the player's facing
 * Every change applies at once and is saved for that spawn, so it survives a restart.
 */

#include "Chat.h"
#include "CommandScript.h"
#include "Creature.h"
#include "DatabaseEnv.h"
#include "Language.h"
#include "MotionMaster.h"
#include "ObjectMgr.h"
#include "Player.h"
#include "UnitDefines.h"

using namespace Acore::ChatCommands;

class coa_npc_pose_commandscript : public CommandScript
{
public:
    coa_npc_pose_commandscript() : CommandScript("coa_npc_pose_commandscript") { }

    ChatCommandTable GetCommands() const override
    {
        static ChatCommandTable commandTable =
        {
            { "npcpose",  HandleNpcPoseCommand,  SEC_GAMEMASTER, Console::No },
            { "npcemote", HandleNpcEmoteCommand, SEC_GAMEMASTER, Console::No },
            { "npcnudge", HandleNpcNudgeCommand, SEC_GAMEMASTER, Console::No },
            { "npcface",  HandleNpcFaceCommand,  SEC_GAMEMASTER, Console::No }
        };
        return commandTable;
    }

    static Creature* SelectedSpawn(ChatHandler* handler)
    {
        Creature* creature = handler->getSelectedCreature();
        if (!creature || !creature->GetSpawnId() || !sObjectMgr->GetCreatureData(creature->GetSpawnId()))
        {
            handler->SendErrorMessage(LANG_SELECT_CREATURE);
            return nullptr;
        }
        return creature;
    }

    // Keeps the loaded addon data in step with the database so a respawn shows the saved pose.
    static void RememberAddon(ObjectGuid::LowType spawnId, Optional<uint32> bytes1, Optional<uint32> emote)
    {
        if (CreatureAddon const* addon = sObjectMgr->GetCreatureAddon(spawnId))
        {
            if (bytes1)
                const_cast<CreatureAddon*>(addon)->bytes1 = *bytes1;
            if (emote)
                const_cast<CreatureAddon*>(addon)->emote = *emote;
        }
    }

    static bool HandleNpcPoseCommand(ChatHandler* handler, uint32 state)
    {
        if (state > UNIT_STAND_STATE_SUBMERGED)
        {
            handler->SendErrorMessage("Pose must be 0 (stand) to {}.", uint32(UNIT_STAND_STATE_SUBMERGED));
            return false;
        }

        Creature* creature = SelectedSpawn(handler);
        if (!creature)
            return false;

        creature->SetStandState(uint8(state));
        RememberAddon(creature->GetSpawnId(), state, {});
        WorldDatabase.Execute("INSERT INTO `creature_addon` (`guid`, `bytes1`, `bytes2`) VALUES ({}, {}, 1) "
            "ON DUPLICATE KEY UPDATE `bytes1` = {}", creature->GetSpawnId(), state, state);
        handler->PSendSysMessage("Creature (GUID: {}) pose {} saved", creature->GetSpawnId(), state);
        return true;
    }

    static bool HandleNpcEmoteCommand(ChatHandler* handler, uint32 emote)
    {
        Creature* creature = SelectedSpawn(handler);
        if (!creature)
            return false;

        creature->SetUInt32Value(UNIT_NPC_EMOTESTATE, emote);
        RememberAddon(creature->GetSpawnId(), {}, emote);
        WorldDatabase.Execute("INSERT INTO `creature_addon` (`guid`, `bytes2`, `emote`) VALUES ({}, 1, {}) "
            "ON DUPLICATE KEY UPDATE `emote` = {}", creature->GetSpawnId(), emote, emote);
        handler->PSendSysMessage("Creature (GUID: {}) animation {} saved", creature->GetSpawnId(), emote);
        return true;
    }

    static void PlaceAt(ChatHandler* handler, Creature* creature, float x, float y, float z, float o)
    {
        ObjectGuid::LowType spawnId = creature->GetSpawnId();
        CreatureData* data = const_cast<CreatureData*>(sObjectMgr->GetCreatureData(spawnId));
        data->posX = x;
        data->posY = y;
        data->posZ = z;
        data->orientation = o;

        uint8 stand = creature->getStandState();
        uint32 emote = creature->GetUInt32Value(UNIT_NPC_EMOTESTATE);

        creature->SetHomePosition(x, y, z, o);
        creature->SetPosition(x, y, z, o);
        creature->GetMotionMaster()->Initialize();
        if (creature->IsAlive())
        {
            creature->setDeathState(DeathState::JustDied);
            creature->Respawn();
        }
        creature->SetStandState(stand);
        creature->SetUInt32Value(UNIT_NPC_EMOTESTATE, emote);

        WorldDatabase.Execute("UPDATE `creature` SET `position_x` = {}, `position_y` = {}, `position_z` = {}, "
            "`orientation` = {} WHERE `guid` = {}", x, y, z, o, spawnId);
        handler->PSendSysMessage("Creature (GUID: {}) placed at {} {} {} facing {}", spawnId, x, y, z, o);
    }

    static bool HandleNpcNudgeCommand(ChatHandler* handler, float dx, float dy, float dz)
    {
        Creature* creature = SelectedSpawn(handler);
        if (!creature)
            return false;

        CreatureData const* data = sObjectMgr->GetCreatureData(creature->GetSpawnId());
        PlaceAt(handler, creature, data->posX + dx, data->posY + dy, data->posZ + dz, data->orientation);
        return true;
    }

    static bool HandleNpcFaceCommand(ChatHandler* handler, Optional<float> orientation)
    {
        Creature* creature = SelectedSpawn(handler);
        if (!creature)
            return false;

        CreatureData const* data = sObjectMgr->GetCreatureData(creature->GetSpawnId());
        float o = orientation ? *orientation : handler->GetSession()->GetPlayer()->GetOrientation();
        PlaceAt(handler, creature, data->posX, data->posY, data->posZ, Position::NormalizeOrientation(o));
        return true;
    }
};

void AddSC_cs_coa_npc_pose()
{
    new coa_npc_pose_commandscript();
}
