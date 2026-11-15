/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#include "AscensionResilientConstitution.h"
#include "Config.h"
#include "ScriptMgr.h"

namespace ResilientConstitution
{
class Configuration : public WorldScript
{
public:
    Configuration() : WorldScript("ResilientConstitutionConfiguration") { }

    void OnAfterConfigLoad(bool) override
    {
        damageReductionPct.store(Percent("CoA.ResilientConstitution.DamageReductionPct", DefaultDamageReductionPct));
        criticalReductionPct.store(
            Percent("CoA.ResilientConstitution.CriticalReductionPct", DefaultCriticalReductionPct));
        petSharePct.store(Percent("CoA.ResilientConstitution.PetSharePct", DefaultPetSharePct));
    }

private:
    static std::uint32_t Percent(std::string const& key, std::uint32_t fallback)
    {
        return std::min<std::uint32_t>(sConfigMgr->GetOption<std::uint32_t>(key, fallback), 100);
    }
};
}

void AddSC_AscensionResilientConstitution()
{
    new ResilientConstitution::Configuration();
}
