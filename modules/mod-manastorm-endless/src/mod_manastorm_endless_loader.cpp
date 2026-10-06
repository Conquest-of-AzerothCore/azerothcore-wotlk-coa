#include "Log.h"

void AddSC_manastorm();
void AddSC_manastorm_cache_loot();
void AddSC_manastorm_native_bridge();
void AddSC_manastorm_runtime_compat();
void AddSC_manastorm_blackrock_spire_compat();
void AddSC_manastorm_blackrock_spire_rend_compat();
void AddSC_manastorm_molten_core_isolation();

void Addmod_manastorm_endlessScripts()
{
    LOG_INFO(
        "module.manastorm.endless",
        "Registering mod-manastorm-endless.");

    AddSC_manastorm_native_bridge();
    AddSC_manastorm_cache_loot();
    AddSC_manastorm();
    AddSC_manastorm_runtime_compat();
    AddSC_manastorm_blackrock_spire_compat();
    AddSC_manastorm_blackrock_spire_rend_compat();
    AddSC_manastorm_molten_core_isolation();
}
