#include "Log.h"

void AddSC_manastorm();
void AddSC_manastorm_cache_loot();
void AddSC_manastorm_native_bridge();
void AddSC_manastorm_runtime_compat();
void AddSC_manastorm_blackrock_spire_compat();
void AddSC_manastorm_deadmines_compat();
void AddSC_manastorm_razorfen_kraul_compat();
void AddSC_manastorm_scarlet_monastery_compat();
void AddSC_manastorm_dire_maul_compat();
void AddSC_manastorm_zul_farrak_compat();
void AddSC_manastorm_blackfathom_deeps_compat();
void AddSC_manastorm_molten_core_isolation();
void AddSC_manastorm_sunken_temple_compat();
void AddSC_manastorm_shadowfang_keep_compat();

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
    AddSC_manastorm_deadmines_compat();
    AddSC_manastorm_razorfen_kraul_compat();
    AddSC_manastorm_scarlet_monastery_compat();
    AddSC_manastorm_dire_maul_compat();
    AddSC_manastorm_zul_farrak_compat();
    AddSC_manastorm_blackfathom_deeps_compat();
    AddSC_manastorm_molten_core_isolation();
    AddSC_manastorm_sunken_temple_compat();
    AddSC_manastorm_shadowfang_keep_compat();
}
