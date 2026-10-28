/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */
#ifndef ASCENSION_RANGER_TALENTS_H
#define ASCENSION_RANGER_TALENTS_H

class Player;
class Spell;
class SpellInfo;
void HandleAscensionRangerStonemason(Spell* spell, Player* player);
void HandleAscensionRangerPhoenixPlumes(Spell* spell, Player* player);
void ApplyAscensionRangerTalentContracts(SpellInfo* info);
void AddSC_AscensionRangerTalents();

#endif
