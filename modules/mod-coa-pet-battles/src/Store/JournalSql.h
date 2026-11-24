#ifndef COA_PET_BATTLE_STORE_JOURNAL_SQL_H
#define COA_PET_BATTLE_STORE_JOURNAL_SQL_H

#include "Journal.h"
#include <string>

namespace CoAPetBattles::Store
{
    std::string UpsertStatement(Journal const& journal, RowWrite const& write);
}

#endif
