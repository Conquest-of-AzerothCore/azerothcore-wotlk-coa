/*
 * The classic raids in four difficulties.
 *
 * The difficulty templates, the links between them and the spawn masks are
 * data and live in data/sql. The code is the boss AI that reads its fight out
 * of coa_boss_schedule, the bosses that keep their choreography with Ascension's
 * spells (Onyxia and the Blackwing Lair, Zul'Gurub and Ahn'Qiraj bosses), the flex health that sizes a boss to the raid, and
 * the corrections to broken spell values.
 *
 * modules/mod-coa-raid-difficulty -> Addmod_coa_raid_difficultyScripts.
 */
void AddCoaBossAIScripts();
void AddCoaFlexHealthScripts();
void AddCoaFlexLootScripts();
void AddCoaFlexItemsScripts();
void AddCoaOnyxiaScripts();
void AddCoaSpellFixScripts();
void AddCoaDamageInfoScripts();
void AddCoaRazorgoreScripts();
void AddCoaVaelastraszScripts();
void AddCoaBroodlordScripts();
void AddCoaGarrScripts();
void AddCoaSonOfFlameScripts();
void AddCoaSulfuronDisciplesScripts();
void AddCoaLucifronScripts();
void AddCoaMagmadarScripts();
void AddCoaGolemaggScripts();
void AddCoaGeddonScripts();
void AddCoaShazzrahScripts();
void AddCoaDrakeScripts();
void AddCoaChromaggusScripts();
void AddCoaNefarianScripts();
void AddCoaVenoxisScripts();
void AddCoaJeklikScripts();
void AddCoaMarliScripts();
void AddCoaThekalScripts();
void AddCoaArlokkScripts();
void AddCoaMandokirScripts();
void AddCoaJindoScripts();
void AddCoaHakkarScripts();
void AddCoaGrilekScripts();
void AddCoaKurinnaxxScripts();
void AddCoaRajaxxScripts();
void AddCoaBuruScripts();
void AddCoaMoamScripts();
void AddCoaOssirianScripts();
void AddCoaSkeramScripts();
void AddCoaSarturaScripts();
void AddCoaHuhuranScripts();
void AddCoaTwinEmperorsScripts();
void AddCoaOuroScripts();
void AddCoaCThunScripts();
void AddCoaWorldBossScripts();
void AddCoaEmeraldDragonScripts();
void AddCoaCustomWorldBossScripts();
void AddCoaSacrificialChainsScripts();

void Addmod_coa_raid_difficultyScripts()
{
    AddCoaBossAIScripts();
    AddCoaFlexHealthScripts();
    AddCoaFlexLootScripts();
    AddCoaFlexItemsScripts();
    AddCoaOnyxiaScripts();
    AddCoaSpellFixScripts();
    AddCoaDamageInfoScripts();
    AddCoaRazorgoreScripts();
    AddCoaVaelastraszScripts();
    AddCoaBroodlordScripts();
    AddCoaGarrScripts();
    AddCoaSonOfFlameScripts();
    AddCoaSulfuronDisciplesScripts();
    AddCoaLucifronScripts();
    AddCoaMagmadarScripts();
    AddCoaGolemaggScripts();
    AddCoaGeddonScripts();
    AddCoaShazzrahScripts();
    AddCoaDrakeScripts();
    AddCoaChromaggusScripts();
    AddCoaNefarianScripts();
    AddCoaVenoxisScripts();
    AddCoaJeklikScripts();
    AddCoaMarliScripts();
    AddCoaThekalScripts();
    AddCoaArlokkScripts();
    AddCoaMandokirScripts();
    AddCoaJindoScripts();
    AddCoaHakkarScripts();
    AddCoaGrilekScripts();
    AddCoaKurinnaxxScripts();
    AddCoaRajaxxScripts();
    AddCoaBuruScripts();
    AddCoaMoamScripts();
    AddCoaOssirianScripts();
    AddCoaSkeramScripts();
    AddCoaSarturaScripts();
    AddCoaHuhuranScripts();
    AddCoaTwinEmperorsScripts();
    AddCoaOuroScripts();
    AddCoaCThunScripts();
    AddCoaWorldBossScripts();
    AddCoaEmeraldDragonScripts();
    AddCoaCustomWorldBossScripts();
    AddCoaSacrificialChainsScripts();
}
