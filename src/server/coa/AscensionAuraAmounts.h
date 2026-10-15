/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */

#ifndef ASCENSION_AURA_AMOUNTS_H
#define ASCENSION_AURA_AMOUNTS_H

class AuraApplication;
class Player;
class Unit;

void SendAscensionAuraAmounts(Unit* target, Player* receiver,
    AuraApplication const* application, bool remove);

#endif
