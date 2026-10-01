#include "Log.h"

void AddSC_manastorm();
void AddSC_manastorm_cache_loot();
void AddSC_manastorm_native_bridge();
void AddSC_manastorm_runtime_compat();

void Addmod_manastorm_endlessScripts()
{
    LOG_INFO(
        "module.manastorm.endless",
        "Registering mod-manastorm-endless.");

    AddSC_manastorm_native_bridge();
    AddSC_manastorm_cache_loot();
    AddSC_manastorm();
    AddSC_manastorm_runtime_compat();
}
