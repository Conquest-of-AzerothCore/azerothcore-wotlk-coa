/*
 * Copyright (C) 2016+ AzerothCore <www.azerothcore.org>, released under GNU AGPL v3 license.
 */

/*
 * Worldforged pickups - the CoA world object that hands out a Worldforged base item,
 * which every character may loot once per prestige cycle.
 *
 * The data (Database/Custom/worldforged-pickups.sql) restores the pickups themselves:
 * 1,555 objects - bags, buckets, bones, packets, caches - each one named after the base
 * item it holds, each holding exactly that item, spawned at the position the community
 * observed that object at. Two deliberate deviations from the captures support the rule:
 *
 *   * chest.consumable = 0, so a pickup stays spawned after it is emptied instead of
 *     despawning on a respawn timer (which would make it a realm-wide roll per respawn).
 *     The core already re-rolls a non-consumable chest's loot for the next opener:
 *     Player::SendLoot clears and fills while the object is GO_READY, and
 *     GameObject::Update returns it to GO_READY after a loot is released.
 *   * ScriptName 'worldforged_pickup', the marker this module keys on. The captures have
 *     an empty ScriptName.
 *
 * This module supplies what data cannot: the per-character memory for the current prestige cycle.
 *
 *   * 'looted' is remembered per (character, spawn) in the characters database table
 *     character_worldforged_loot and in memory for the session.
 *   * The ledger is read in Player::LoadFromDB, not on login. This matters: the core
 *     sends a player the gameobjects around them before CharacterHandler calls
 *     OnPlayerLogin, so a ledger loaded that late arrives after the client has already
 *     been told the pickup is sparkling and lootable - and nothing corrects it, because
 *     the object's own state never changes. Loading during LoadFromDB is early enough
 *     that the first values update a player receives already carries the right flags.
 *   * A pickup the character already looted stays in the world - as it does on the realm -
 *     but is inert for that character alone: no sparkle, not selectable, not interactable
 *     (GameObjectAI::BuildClientFlags). Every other character still sees it sparkling.
 *   * A pickup the character may still loot sparkles
 *     (GO_DYNFLAG_LO_ACTIVATE | GO_DYNFLAG_LO_SPARKLE), which is how they are found.
 *
 * Server-side the same rule is enforced in four places, because a client can always ask
 * again and the four answer different questions:
 *
 *   1. GameObjectAI::BuildClientFlags - what this viewer is shown.
 *   2. GameObjectAI::GossipHello - whether the use opens anything at all. GameObject::Use
 *      is not even reached for a viewer carrying GO_FLAG_NOT_SELECTABLE.
 *   3. OnAllowedForPlayerLootCheck (worldforged_pickup_loot_veto below) - whether this
 *      character may be handed the item, asked per item, at the moment of the award. This
 *      is the one that closes the door on a loot session that outlived its claim: the
 *      chest holds one shared Loot, so the next character's open re-rolls it under the
 *      first character's still-open window, and StoreLootItem would otherwise hand over a
 *      second copy to whoever clicks the slot first.
 *   4. GameObjectAI::OnStateChanged - repairs a pickup left GO_ACTIVATED with spent loot
 *      (someone closed the loot window by logging out), which would otherwise show the
 *      next character an empty window instead of their own item.
 *
 * The award itself and the record of it are one write: the item row, its place in the
 * inventory and the ledger row go into a single character-database transaction, so a crash
 * can leave neither rather than a claimed pickup whose item was never saved.
 *
 * Identity: a pickup is recorded by its *spawn id* (the `gameobject`.`guid` row), never by
 * the runtime object GUID. This core hands out map-local generated GUIDs
 * (Map::GenerateLowGuid), so a runtime GUID is neither the database row nor stable across
 * grid reloads - keying on it would lose or invent history. The restoration writes its
 * spawns in a fixed guid block, so the ids are stable across re-imports too.
 */

#include "Bag.h"
#include "CellImpl.h"
#include "DatabaseEnv.h"
#include "GameObject.h"
#include "GameObjectAI.h"
#include "GlobalScript.h"
#include "GridNotifiers.h"
#include "GridNotifiersImpl.h"
#include "Group.h"
#include "Item.h"
#include "LootMgr.h"
#include "Map.h"
#include "ObjectGuid.h"
#include "ObjectMgr.h"
#include "Player.h"
#include "ScriptMgr.h"
#include "SharedDefines.h"
#include "World.h"

#include <list>
#include <mutex>
#include <string>
#include <unordered_map>
#include <unordered_set>

namespace
{
// ScriptName on gameobject_template and gameobject rows of every pickup.
constexpr char const* WorldforgedPickupScript = "worldforged_pickup";
constexpr char const* WorldforgedLootTable = "character_worldforged_loot";

[[nodiscard]] bool IsWorldforgedPickup(GameObject const* go)
{
    if (!go || !go->GetGOInfo() || !go->GetSpawnId())
        return false;

    uint32 const scriptId = go->GetScriptId();
    return scriptId != 0 && sObjectMgr->GetScriptName(scriptId) == WorldforgedPickupScript;
}

// Per-character record of the pickups already looted, backed by the characters database.
class WorldforgedLootStore
{
public:
    static WorldforgedLootStore& Instance()
    {
        static WorldforgedLootStore store;
        return store;
    }

    [[nodiscard]] bool HasLooted(uint32 characterGuid, uint32 spawnId) const
    {
        std::lock_guard<std::mutex> lock(_mutex);
        auto itr = _looted.find(characterGuid);
        return itr != _looted.end() && itr->second.count(spawnId) != 0;
    }

    // Called from Player::LoadFromDB, before the player can be sent a single gameobject.
    // The whole ledger for a character is small (one row per pickup looted so far) and is
    // read once, not per pickup.
    void Load(uint32 characterGuid)
    {
        std::unordered_set<uint32> looted;
        if (QueryResult result = CharacterDatabase.Query(
                "SELECT `spawn_id` FROM `{}` WHERE `guid` = {}", WorldforgedLootTable, characterGuid))
        {
            do
            {
                looted.insert((*result)[0].Get<uint32>());
            } while (result->NextRow());
        }

        std::lock_guard<std::mutex> lock(_mutex);
        _looted[characterGuid] = std::move(looted);
    }

    void Unload(uint32 characterGuid)
    {
        std::lock_guard<std::mutex> lock(_mutex);
        _looted.erase(characterGuid);
    }

    void QueueReset(uint32 characterGuid, CharacterDatabaseTransaction trans)
    {
        CharacterDatabasePreparedStatement* stmt = CharacterDatabase.GetPreparedStatement(CHAR_DEL_WORLDFORGED_LOOT);
        stmt->SetData(0, characterGuid);
        trans->Append(stmt);
    }

    // The item and the fact that this pickup is now spent for this character are written
    // together: item_instance, character_inventory and the ledger row commit as one. The
    // item is still ITEM_NEW here - nothing has written it yet, because it is only flushed
    // with the next character save - so these are exactly the writes Player::_SaveInventory
    // would make, moved to the moment of the award. If the transaction fails, the pickup
    // stays unclaimed and the character can loot it again, which is the survivable outcome;
    // a ledger row on its own would mark the pickup spent and lose the item instead.
    void Claim(Player* player, Item* item, uint32 spawnId, uint32 entry)
    {
        uint32 const characterGuid = player->GetGUID().GetCounter();

        {
            std::lock_guard<std::mutex> lock(_mutex);
            if (!_looted[characterGuid].insert(spawnId).second)
                return;                                     // already known, nothing to write
        }

        CharacterDatabaseTransaction trans = CharacterDatabase.BeginTransaction();

        ObjectGuid::LowType bagGuid = 0;
        if (Bag* container = item->GetContainer())
            bagGuid = container->GetGUID().GetCounter();

        CharacterDatabasePreparedStatement* stmt = CharacterDatabase.GetPreparedStatement(CHAR_REP_INVENTORY_ITEM);
        stmt->SetData(0, characterGuid);
        stmt->SetData(1, bagGuid);
        stmt->SetData(2, item->GetSlot());
        stmt->SetData(3, item->GetGUID().GetCounter());
        trans->Append(stmt);

        // SaveToDB marks the item ITEM_UNCHANGED but leaves its pointer in the player's update queue.
        // Any later change (sold, destroyed, stacked) would queue it a second time, and the next
        // character save would then delete it on the first entry and read freed memory on the second.
        item->RemoveFromUpdateQueueOf(player);
        item->SaveToDB(trans);                              // item_instance, then ITEM_UNCHANGED

        trans->Append("INSERT IGNORE INTO `{}` (`guid`, `spawn_id`, `entry`) VALUES ({}, {}, {})",
                      WorldforgedLootTable, characterGuid, spawnId, entry);

        CharacterDatabase.AsyncCommitTransaction(trans).m_future.get();
    }

private:
    WorldforgedLootStore() = default;

    mutable std::mutex _mutex;
    std::unordered_map<uint32, std::unordered_set<uint32>> _looted;
};

class WorldforgedPickupAI : public GameObjectAI
{
public:
    explicit WorldforgedPickupAI(GameObject* go) : GameObjectAI(go) { }

    // Sparkle marks a pickup this viewer may still loot; a viewer who already has must see
    // it as inert scenery - visible, like on the realm, but not openable.
    void BuildClientFlags(Player const* target, uint16& dynFlags, uint32& goFlags) override
    {
        if (!target)
            return;

        if (WorldforgedLootStore::Instance().HasLooted(target->GetGUID().GetCounter(), me->GetSpawnId()))
        {
            goFlags |= GO_FLAG_LOCKED | GO_FLAG_NOT_SELECTABLE;
            return;
        }

        if (sWorld->getBoolConfig(CONFIG_OBJECT_SPARKLES))
            dynFlags |= GO_DYNFLAG_LO_ACTIVATE | GO_DYNFLAG_LO_SPARKLE;
    }

    // The server-side refusal: a client that still has a spent pickup in memory (or a
    // macro) gets nothing to open.
    bool GossipHello(Player* player, bool /*reportUse*/) override
    {
        if (!player)
            return true;

        if (!WorldforgedLootStore::Instance().HasLooted(player->GetGUID().GetCounter(), me->GetSpawnId()))
            return false;

        if (me->loot.isLooted())
        {
            me->loot.clear();
            player->SendLootRelease(me->GetGUID());
        }

        return true;
    }

    void OnStateChanged(uint32 state, Unit* unit) override
    {
        if (state != GO_ACTIVATED || !unit)
            return;

        Player* player = unit->ToPlayer();
        if (!player)
            return;

        uint32 const characterGuid = player->GetGUID().GetCounter();
        uint32 const spawnId = me->GetSpawnId();

        // Spent for this character: hand out nothing, and do not leave an open loot.
        if (WorldforgedLootStore::Instance().HasLooted(characterGuid, spawnId))
        {
            if (me->loot.isLooted())
            {
                me->loot.clear();
                player->SendLootRelease(me->GetGUID());
            }
            return;
        }

        // Spent for someone else and left behind - a loot window closed by a logout never
        // released the object, so it is still GO_ACTIVATED with an empty loot. Re-arm it so
        // this character gets their own roll instead of an empty window. The flag guards the
        // nested state change this triggers: one re-arm per interaction, never a loop.
        if (!_rearming && me->loot.isLooted())
        {
            _rearming = true;
            me->loot.clear();
            me->SetLootState(GO_READY);
            player->SendLoot(me->GetGUID(), LOOT_CORPSE);
            _rearming = false;
        }
    }

private:
    bool _rearming = false;              // an empty loot table can never spin this
};

// The marker itself: the database says which gameobjects are pickups, this says what they do.
class worldforged_pickup_script : public GameObjectScript
{
public:
    worldforged_pickup_script() : GameObjectScript(WorldforgedPickupScript) { }

    GameObjectAI* GetAI(GameObject* go) const override
    {
        return new WorldforgedPickupAI(go);
    }
};

// The last word on whether a pickup hands over its item, asked through
// LootItem::AllowedForPlayer by every path that awards one: Player::StoreLootItem per slot of a
// request, Group when it decides who may roll for an item, and the master looter's give. A
// character who has spent this pickup cannot be handed it again, even while their old loot
// window is still open.
//
// The hook's name reads backwards, so read it with the macro: ScriptMgrMacros.h's
// CALL_ENABLED_BOOLEAN_HOOKS returns false as soon as any script returns true
// ("if (action) return false"), and AllowedForPlayer drops the item when that call returns
// false. Returning true here is therefore what withholds the item, and false is the
// do-nothing default for every other loot in the game.
class worldforged_pickup_loot_veto : public GlobalScript
{
public:
    worldforged_pickup_loot_veto() : GlobalScript("worldforged_pickup_loot_veto",
        {GLOBALHOOK_ON_ALLOWED_FOR_PLAYER_LOOT_CHECK}) { }

    bool OnAllowedForPlayerLootCheck(Player const* player, ObjectGuid source) override
    {
        if (!player || !source.IsGameObject())
            return false;

        GameObject* go = player->GetMap()->GetGameObject(source);
        return IsWorldforgedPickup(go) &&
            WorldforgedLootStore::Instance().HasLooted(player->GetGUID().GetCounter(), go->GetSpawnId());
    }
};

// The moment the base item reaches a character, that pickup is spent for them.
void RecordAward(Player* player, Item* item, ObjectGuid source)
{
    if (!player || !item || !source.IsGameObject())
        return;

    GameObject* go = player->GetMap()->GetGameObject(source);
    if (!IsWorldforgedPickup(go))
        return;

    WorldforgedLootStore::Instance().Claim(player, item, go->GetSpawnId(), go->GetEntry());

    // Make this client re-read the flags, so the pickup goes inert for this viewer now.
    go->ForceValuesUpdateAtIndex(GAMEOBJECT_FLAGS);
    go->ForceValuesUpdateAtIndex(GAMEOBJECT_DYNAMIC);
}

class worldforged_pickup_lifecycle : public PlayerScript
{
public:
    worldforged_pickup_lifecycle() : PlayerScript("worldforged_pickup_lifecycle",
        {PLAYERHOOK_ON_LOAD_FROM_DB, PLAYERHOOK_ON_LOGOUT, PLAYERHOOK_ON_LOOT_ITEM,
            PLAYERHOOK_ON_GROUP_ROLL_REWARD_ITEM, PLAYERHOOK_ON_MASTER_LOOT_ITEM,
            PLAYERHOOK_ON_COA_PRESTIGE, PLAYERHOOK_ON_COA_PRESTIGE_SAVED}) { }

    // Early enough that no gameobject has been sent to this client yet.
    void OnPlayerLoadFromDB(Player* player) override
    {
        WorldforgedLootStore::Instance().Load(player->GetGUID().GetCounter());
    }

    void OnPlayerLogout(Player* player) override
    {
        WorldforgedLootStore::Instance().Unload(player->GetGUID().GetCounter());
    }

    void OnPlayerCoAPrestige(Player* player, CharacterDatabaseTransaction trans) override
    {
        if (player && trans)
            WorldforgedLootStore::Instance().QueueReset(player->GetGUID().GetCounter(), trans);
    }

    void OnPlayerCoAPrestigeSaved(Player* player) override
    {
        if (!player)
            return;

        WorldforgedLootStore::Instance().Unload(player->GetGUID().GetCounter());
        if (!player->IsInWorld())
            return;

        std::list<GameObject*> pickups;
        float const range = player->GetVisibilityRange();
        Acore::GameObjectInRangeCheck check(player->GetPositionX(), player->GetPositionY(),
            player->GetPositionZ(), range);
        Acore::GameObjectListSearcher<Acore::GameObjectInRangeCheck> searcher(player, pickups, check);
        Cell::VisitObjects(player, searcher, range);
        for (GameObject* go : pickups)
            if (IsWorldforgedPickup(go) && player->HaveAtClient(go))
            {
                go->ForceValuesUpdateAtIndex(GAMEOBJECT_FLAGS);
                go->ForceValuesUpdateAtIndex(GAMEOBJECT_DYNAMIC);
            }
    }

    // Clicked, auto-stored or picked from the group window.
    void OnPlayerLootItem(Player* player, Item* item, uint32 /*count*/, ObjectGuid lootguid) override
    {
        RecordAward(player, item, lootguid);
    }

    // A pickup with group loot rules (Data15) hands its item to a group's roll winner, never
    // through StoreLootItem.
    void OnPlayerGroupRollRewardItem(Player* player, Item* item, uint32 /*count*/, RollVote /*voteType*/,
        Roll* roll) override
    {
        if (Loot* loot = roll ? roll->getLoot() : nullptr)
            RecordAward(player, item, loot->sourceWorldObjectGUID);
    }

    void OnPlayerMasterLootItem(Player* player, Item* item, uint32 /*count*/, ObjectGuid lootguid) override
    {
        RecordAward(player, item, lootguid);
    }
};
}

void AddWorldforgedPickupsScripts()
{
    new worldforged_pickup_script();
    new worldforged_pickup_loot_veto();
    new worldforged_pickup_lifecycle();
}
