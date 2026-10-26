---
area: game
type: added
audience: players
title: Recruited players earn starter bags and an heirloom weapon token
---
Recruited accounts now receive four12-slot Mageweave Bags at level10 and one Heirloom Weapon Token
at level60, mailed automatically without grouping/proximity requirements. Each milestone pays once
per recruited account on each realm. Existing qualifying recruits and saved Prestige characters
are included; relogging, alts and additional Prestige cycles do not repeat the same claim.

Use .raf rewards to see the configured recruit milestones. Existing recruiter rewards, validation,
XP rules and native summon/teleport remain unchanged. Administrators can configure or disable each
milestone in recruit_milestone_rewards; seed reruns preserve customizations. Separate claim/delivery
records reuse the existing staged mail recovery and do not replace recruiter entitlements.

Requires the new auth, characters and world recruit-milestone migrations. Delivery is checked by
the existing RaF update cycle, normally on login/update and within about a minute of reaching a level.
