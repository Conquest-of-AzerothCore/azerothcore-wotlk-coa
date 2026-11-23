/*
 * This file is part of the AzerothCore Project. See AUTHORS file for Copyright information
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
 * FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for
 * more details.
 *
 * You should have received a copy of the GNU General Public License along
 * with this program. If not, see <http://www.gnu.org/licenses/>.
 */

// This is where scripts' loading functions should be declared:
// void MyExampleScript()
void AddSC_spell_basalthane();
void AddSC_spell_infernos_items();
void AddSC_spell_coa_stormwind_quests();
void AddSC_instance_guardians_library();
void AddSC_wisdomball_velthessa();
void AddSC_wisdomball_khadgar_voice();
void AddSC_wisdomball_leash();
void AddSC_wisdomball_escort_wait();
void AddSC_wisdomball_memory_blizzard();
void AddSC_wisdomball_normal_difficulty();

// The name of this function should match:
// void Add${NameOfDirectory}Scripts()
void AddCustomScripts()
{
    // MyExampleScript()
    AddSC_spell_basalthane();
    AddSC_spell_infernos_items();
    AddSC_spell_coa_stormwind_quests();
    AddSC_instance_guardians_library();
    AddSC_wisdomball_velthessa();
    AddSC_wisdomball_khadgar_voice();
    AddSC_wisdomball_leash();
    AddSC_wisdomball_escort_wait();
    AddSC_wisdomball_memory_blizzard();
    AddSC_wisdomball_normal_difficulty();
}
