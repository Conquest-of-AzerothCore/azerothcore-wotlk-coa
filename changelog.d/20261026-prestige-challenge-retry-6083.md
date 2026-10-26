---
area: modules
type: fixed
audience: players
title: A new Prestige run clears previous challenge failure locks
---
Fix #6083: prior failed challenges no longer permanently block new challenge attempts after a
successful Prestige. Previous failure records are cleared in the Prestige save transaction and
the client's failure list is refreshed after commit. Refused or failed saves do not clear the locks.

Completed challenges, rewards, active challenges, criteria, custom trials and interaction history
are preserved. No SQL migration or login-wide failure cleanup is added. The repair takes effect on
the next successful Prestige; relogging alone cannot erase a failure in the current run.
