---
area: game
type: changed
audience: admins
title: Allow a 30-level gap for linked RaF XP
---
RecruitAFriend.MaxDifference now defaults to30instead of4 in the shipped config and core fallback.
The higher-level linked player can retain RaF XP with a gap up to30. The lower-level player's
existing level-gap exemption remains unchanged. Group, map, proximity, direct-link and RaF level-cap
checks still apply. This setting does not control level grants.

Existing installations must update any explicit value in worldserver.conf; defaults do not override
configured values. No SQL migration is needed.

Existing configurations using the old value 4 automatically use 30 on startup or config reload. Other custom values remain unchanged; config files are not rewritten.
