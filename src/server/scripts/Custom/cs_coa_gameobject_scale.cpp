/*
 * Per-spawn scale for game objects: the size stored for a spawn in `gameobject_scale`
 * is applied whenever that spawn enters the world.
 */

#include "AllGameObjectScript.h"
#include "DatabaseEnv.h"
#include "GameObject.h"
#include <mutex>
#include <unordered_map>

namespace
{
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

void AddSC_cs_coa_gameobject_scale()
{
    new coa_gameobject_scale_apply();
}
