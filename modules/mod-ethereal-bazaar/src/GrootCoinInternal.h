#ifndef MOD_ETHEREAL_BAZAAR_GROOT_COIN_INTERNAL_H
#define MOD_ETHEREAL_BAZAAR_GROOT_COIN_INTERNAL_H

#include "DatabaseEnvFwd.h"
#include "ObjectGuid.h"

#include <string>
#include <vector>

namespace GrootCoin::Internal
{
    void AddQueryCallback(QueryCallback&& callback);
    void AddTransactionCallback(TransactionCallback&& callback);

    // Operations whose commit outcome could not be established. They are
    // logged and listed in `.groot status`; nobody retries them blindly.
    void RecordReconciliation(std::string line);
    std::vector<std::string> const& Reconciliations();

    void UpdateExchanges();
    std::size_t PendingAwards();

    // groot_coin_award_queue poller; a no-op unless external awards are on.
    void UpdateQueue();
    std::size_t QueuedInFlight();

    // Sends a system message to the character if it is in the world.
    void Notify(ObjectGuid character, std::string const& text);
}

#endif
