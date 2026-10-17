/*
 * Copyright (C) 2016+ AzerothCore <www.azerothcore.org>, released under GNU AGPL v3 license: https://github.com/azerothcore/azerothcore-wotlk/blob/master/LICENSE-AGPL3
 */

#include "AllGameObjectScript.h"
#include "Chat.h"
#include "ChatCommand.h"
#include "CommandScript.h"
#include "DatabaseEnv.h"
#include "GameObject.h"
#include "Language.h"
#include "Log.h"
#include "MapMgr.h"
#include "ObjectMgr.h"
#include "WorldScript.h"
#include <shared_mutex>
#include <unordered_map>
#include <vector>

using namespace Acore::ChatCommands;

namespace
{
    constexpr float MinimumScale = 0.1f;
    constexpr float MaximumScale = 10.0f;

    std::shared_mutex ScalesLock;
    std::unordered_map<ObjectGuid::LowType, float> Scales;

    Optional<float> FindScale(ObjectGuid::LowType spawnId)
    {
        std::shared_lock lock(ScalesLock);
        auto const itr = Scales.find(spawnId);
        if (itr == Scales.end())
            return {};
        return itr->second;
    }

    void LoadScales()
    {
        std::unordered_map<ObjectGuid::LowType, float> scales;
        if (QueryResult result = WorldDatabase.Query("SELECT `guid`, `scale` FROM `gameobject_scale`"))
        {
            do
            {
                Field* fields = result->Fetch();
                scales[fields[0].Get<uint32>()] = fields[1].Get<float>();
            } while (result->NextRow());
        }

        std::size_t const count = scales.size();
        {
            std::unique_lock lock(ScalesLock);
            Scales = std::move(scales);
        }
        LOG_INFO("server.loading", ">> Loaded {} game object spawn scales", count);
    }

    void StoreScale(ObjectGuid::LowType spawnId, float scale)
    {
        {
            std::unique_lock lock(ScalesLock);
            Scales[spawnId] = scale;
        }
        WorldDatabase.Execute("REPLACE INTO `gameobject_scale` (`guid`, `scale`) VALUES ({}, {})", spawnId, scale);
    }

    void RebuildCollisionModel(GameObject* object)
    {
        object->SetDisplayId(object->GetDisplayId());
        object->EnableCollision(object->GetGoState() == GO_STATE_READY || object->IsTransport());
    }

    uint32 ReloadLoadedSpawns(GameObjectData const& data, ObjectGuid::LowType spawnId)
    {
        std::vector<GameObject*> loaded;
        sMapMgr->DoForAllMapsWithMapId(data.mapid, [&loaded, spawnId](Map* map)
        {
            auto const bounds = map->GetGameObjectBySpawnIdStore().equal_range(spawnId);
            for (auto itr = bounds.first; itr != bounds.second; ++itr)
                loaded.push_back(itr->second);
        });

        uint32 reloaded = 0;
        for (GameObject* object : loaded)
        {
            Map* map = object->GetMap();
            object->Delete();

            GameObject* replacement = new GameObject();
            if (replacement->LoadGameObjectFromDB(spawnId, map, true))
                ++reloaded;
            else
                delete replacement;
        }
        return reloaded;
    }
}

class CoAGameObjectScaleWorld final : public WorldScript
{
public:
    CoAGameObjectScaleWorld() : WorldScript("CoAGameObjectScaleWorld", { WORLDHOOK_ON_LOAD_CUSTOM_DATABASE_TABLE }) { }

    void OnLoadCustomDatabaseTable() override
    {
        LoadScales();
    }
};

class CoAGameObjectScaleApply final : public AllGameObjectScript
{
public:
    CoAGameObjectScaleApply() : AllGameObjectScript("CoAGameObjectScaleApply") { }

    void OnGameObjectAddWorld(GameObject* object) override
    {
        if (!object->GetSpawnId())
            return;

        Optional<float> const scale = FindScale(object->GetSpawnId());
        if (!scale)
            return;

        object->SetObjectScale(*scale);
        RebuildCollisionModel(object);
    }
};

class CoAGameObjectScaleCommands final : public CommandScript
{
public:
    CoAGameObjectScaleCommands() : CommandScript("CoAGameObjectScaleCommands") { }

    ChatCommandTable GetCommands() const override
    {
        static ChatCommandTable gameObjectCommands =
        {
            { "set scale", HandleSetScale, SEC_GAMEMASTER, Console::Yes }
        };
        static ChatCommandTable commands =
        {
            { "gobject", gameObjectCommands }
        };
        return commands;
    }

    static bool HandleSetScale(ChatHandler* handler, Variant<Hyperlink<gameobject>, ObjectGuid::LowType> spawnId,
        float scale)
    {
        GameObjectData const* data = sObjectMgr->GetGameObjectData(spawnId);
        if (!data)
        {
            handler->SendErrorMessage(LANG_COMMAND_OBJNOTFOUND, uint32(spawnId));
            return false;
        }

        if (scale < MinimumScale || scale > MaximumScale)
        {
            handler->SendErrorMessage(LANG_BAD_VALUE);
            return false;
        }

        StoreScale(spawnId, scale);
        uint32 const reloaded = ReloadLoadedSpawns(*data, spawnId);
        handler->PSendSysMessage("Game object spawn {} now has scale {}; {} loaded copies were respawned.",
            uint32(spawnId), scale, reloaded);
        return true;
    }
};

void AddSC_CoAGameObjectScale()
{
    new CoAGameObjectScaleWorld();
    new CoAGameObjectScaleApply();
    new CoAGameObjectScaleCommands();
}
