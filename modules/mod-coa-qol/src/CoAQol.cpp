#include "CoAQolRules.h"
#include "Config.h"
#include "ItemTemplate.h"
#include "Log.h"
#include "ObjectMgr.h"
#include "ScriptMgr.h"

#include <string>

using namespace CoAQol;

namespace
{
    constexpr char DefaultStackClasses[] = "7";

    std::set<uint32> ReadIdList(char const* key, char const* fallback)
    {
        std::set<uint32> ids;
        std::string const csv = sConfigMgr->GetOption<std::string>(key, fallback);
        if (!ParseIdList(csv, ids))
            LOG_ERROR("module.coa_qol", "Invalid {} list \"{}\"; ignoring it", key, csv);
        return ids;
    }

    void ApplyStackSizes(StackPolicy const& policy)
    {
        uint32 raised = 0;
        for (ItemTemplate* proto : *sObjectMgr->GetItemTemplateStoreFast())
        {
            if (!proto)
                continue;
            ItemFacts facts;
            facts.entry = proto->ItemId;
            facts.itemClass = proto->Class;
            facts.stackable = proto->Stackable;
            int32 const planned = PlannedStackSize(policy, facts);
            if (planned == proto->Stackable)
                continue;
            proto->Stackable = planned;
            ++raised;
        }
        LOG_INFO("server.loading", ">> CoA QoL: raised the stack size of {} item templates to {}", raised,
            std::min(policy.size, MaximumStackSize));
    }

    class CoAQolWorld : public WorldScript
    {
    public:
        CoAQolWorld() : WorldScript("coa_qol_world", { WORLDHOOK_ON_STARTUP }) { }

        void OnStartup() override
        {
            if (!sConfigMgr->GetOption<bool>("CoAQol.StackSize.Enable", true))
                return;

            StackPolicy policy;
            policy.size = sConfigMgr->GetOption<uint32>("CoAQol.StackSize.Materials", 2000);
            if (policy.size > MaximumStackSize)
                LOG_ERROR("module.coa_qol", "CoAQol.StackSize.Materials {} exceeds {}; using {}", policy.size,
                    MaximumStackSize, MaximumStackSize);
            policy.classes = ReadIdList("CoAQol.StackSize.ItemClasses", DefaultStackClasses);
            policy.included = ReadIdList("CoAQol.StackSize.IncludedItems", "");
            policy.excluded = ReadIdList("CoAQol.StackSize.ExcludedItems", "");
            ApplyStackSizes(policy);
        }
    };
}

void AddSC_coa_qol()
{
    new CoAQolWorld();
}
