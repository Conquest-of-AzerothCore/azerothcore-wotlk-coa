/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#ifndef ASCENSION_RUNEMASTER_BRAND_H
#define ASCENSION_RUNEMASTER_BRAND_H

class SpellInfo;
class Unit;

void ApplyAscensionRunemasterBrandContracts(SpellInfo* spellInfo);
void TriggerRunemasterWeaponEngravings(Unit* caster, Unit* target);
void AddAscensionRunemasterBrandScripts();

#endif
