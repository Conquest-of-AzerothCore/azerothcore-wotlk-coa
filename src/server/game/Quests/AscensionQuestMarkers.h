#ifndef COA_ASCENSION_QUEST_MARKERS_H
#define COA_ASCENSION_QUEST_MARKERS_H

#include "Define.h"
#include "ObjectGuid.h"

class Creature;
class Player;

namespace AscensionQuestMarkers
{
void Send(Player* player, ObjectGuid guid, uint32 status);
void Refresh(Player* player, Creature* creature);
void RefreshVisible(Player* player);
}

#endif
