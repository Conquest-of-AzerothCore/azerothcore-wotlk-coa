/*
 * Per-spawn scale for game objects. `.goscale <guid> <scale>` resizes one placed object
 * and stores the size in `gameobject_scale`; the size is applied whenever that spawn
 * enters the world. `.goscale <guid>` reports the current scale and `.goscale <guid> 0`
 * returns the object to its template size.
 */

#include "AllGameObjectScript.h"
#include "Chat.h"
#include "CommandScript.h"
#include "DatabaseEnv.h"
#include "GameObject.h"
#include "Language.h"
#include "Map.h"
#include <cmath>
#include <mutex>
#include <unordered_map>

using namespace Acore::ChatCommands;

namespace
{
    constexpr float MIN_SCALE = 0.05f;
    constexpr float MAX_SCALE = 20.0f;

    std::mutex ScaleLock;
    std::unordered_map<ObjectGuid::LowType, float> Scales;
    bool ScalesLoaded = false;

    void LoadScales()
    {
        if (ScalesLoaded)
            return;

        ScalesLoaded = true;
        if (QueryResult result = WorldDatabase.Query("SELECT `guid`, `scale` FROM `gameobject_scale`"))
        {
            do
            {
                Field* fields = result->Fetch();
                Scales[fields[0].Get<uint32>()] = fields[1].Get<float>();
            } while (result->NextRow());
        }
    }

    bool FindScale(ObjectGuid::LowType spawnId, float& scale)
    {
        std::lock_guard<std::mutex> guard(ScaleLock);
        LoadScales();
        auto itr = Scales.find(spawnId);
        if (itr == Scales.end())
            return false;

        scale = itr->second;
        return true;
    }
}

class coa_gameobject_scale_apply : public AllGameObjectScript
{
public:
    coa_gameobject_scale_apply() : AllGameObjectScript("coa_gameobject_scale_apply") { }

    void OnGameObjectAddWorld(GameObject* go) override
    {
        float scale;
        if (go->GetSpawnId() && FindScale(go->GetSpawnId(), scale))
            go->SetObjectScale(scale);
    }
};

class coa_gameobject_scale_commandscript : public CommandScript
{
public:
    coa_gameobject_scale_commandscript() : CommandScript("coa_gameobject_scale_commandscript") { }

    ChatCommandTable GetCommands() const override
    {
        static ChatCommandTable commandTable =
        {
            { "goscale", HandleGoScaleCommand, SEC_GAMEMASTER, Console::No }
        };
        return commandTable;
    }

    static bool HandleGoScaleCommand(ChatHandler* handler, ObjectGuid::LowType guidLow, Optional<float> scale)
    {
        GameObject* object = handler->GetObjectFromPlayerMapByDbGuid(guidLow);
        if (!object)
        {
            handler->SendErrorMessage(LANG_COMMAND_OBJNOTFOUND, uint32(guidLow));
            return false;
        }

        float templateSize = object->GetGOInfo()->size;
        if (!scale)
        {
            float current = templateSize;
            FindScale(guidLow, current);
            handler->PSendSysMessage("Game Object (GUID: {}) scale {} (normal size {})", guidLow, current, templateSize);
            return true;
        }

        float newScale = *scale;
        if (newScale != 0.0f && (newScale < MIN_SCALE || newScale > MAX_SCALE))
        {
            handler->SendErrorMessage("Scale must be between {} and {}, or 0 to reset.", MIN_SCALE, MAX_SCALE);
            return false;
        }

        {
            std::lock_guard<std::mutex> guard(ScaleLock);
            LoadScales();
            if (newScale == 0.0f || std::fabs(newScale - templateSize) < 0.001f)
            {
                newScale = templateSize;
                Scales.erase(guidLow);
                WorldDatabase.Execute("DELETE FROM `gameobject_scale` WHERE `guid` = {}", guidLow);
            }
            else
            {
                Scales[guidLow] = newScale;
                WorldDatabase.Execute("REPLACE INTO `gameobject_scale` (`guid`, `scale`) VALUES ({}, {})", guidLow, newScale);
            }
        }

        // The 3.3.5a client keeps a removed object's old data for its guid, so respawn it from the database.
        Map* map = object->GetMap();
        object->Delete();
        object = new GameObject();
        if (!object->LoadGameObjectFromDB(guidLow, map, true))
        {
            delete object;
            return false;
        }

        handler->PSendSysMessage("Game Object (GUID: {}) scaled to {}", guidLow, newScale);
        return true;
    }
};

void AddSC_cs_coa_gameobject_scale()
{
    new coa_gameobject_scale_apply();
    new coa_gameobject_scale_commandscript();
}
