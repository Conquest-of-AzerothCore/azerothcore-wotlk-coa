/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */
#ifndef ASCENSION_RUNEMASTER_TALENTS_H
#define ASCENSION_RUNEMASTER_TALENTS_H

class SpellInfo;
void ApplyAscensionRunemasterTalentContracts(SpellInfo* info);
void ApplyAscensionManuscriptionContracts(SpellInfo* info);
void ApplyAscensionRunemasterTravelContracts(SpellInfo* info);
void AddSC_AscensionRunemasterTalents();
void AddSC_AscensionRunemasterManuscription();

#endif
