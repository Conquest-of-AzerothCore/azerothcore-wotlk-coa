# XP hotspot in-game acceptance

Run this on the test realm after the combined client/server update. Record the tested source commit,
server binary hash, database migration name/hash and client archive hash. Keep production activation
and upstream PR publication separate from these tests.

| Check | Expected result |
| --- | --- |
| Feature disabled | No hotspot controls, bonus or rotations; ordinary map behavior is unchanged. |
| Azeroth-only configuration | No Outland/Northrend event can start, including one queued by a GM. |
| Ordinary account sends GM requests | Server rejects them; no location or announcement setting changes. |
| Two GM characters edit the same record | First save succeeds; stale second save is rejected. |
| Two characters on one GM account | Drafts remain separate; one logout does not discard the other's draft. |
| Create circle at character, then reposition on map | Saved world position matches map placement; ordinary clicks still zoom normally. |
| Polygon with CTRL clicks, undo, then save | Simple boundary saves; crossing or degenerate boundary is rejected. |
| Whole-zone hover | Highlight follows the sampled terrain boundary; XP uses actual zone membership. |
| Icon/highlight disabled | Visibility follows settings; GM catalog still permits selection/editing. |
| Search disabled and other-map locations | Name/ID search, pagination and selection work without losing records. |
| Enter/leave circle or polygon | Buff appears/removes promptly; an immediate outside kill receives no stale bonus. |
| Same creature reward inside/outside | Eligible kill XP increases by 150% once, accounting for other multipliers. |
| Overlapping 150% and 200% areas | Highest bonus is 200%; it does not stack to 350%. |
| Quest/profession XP | Hotspot does not increase these rewards. |
| Party members inside/outside | Each receives only the bonus applicable at their own location; normal group sharing remains. |
| No-bonus-XP challenge | No positive hotspot XP is applied. |
| Death, resurrection, teleport and instance entry | Buff remains presence-bound; no bonus leaks into instances/BGs. |
| Relog inside/outside and server restart | No persisted personal buff outside coverage; active event retains its original end time. |
| Expired event after downtime | It is retired; a fresh full duration is not granted to the old event. |
| Queue, stop, disable, cooldown, duration edit | Each obeys documented eligibility and updates clients once state commits. |
| Announcement toggle | One message per new start when enabled; none on restore or while disabled. |
| Multiple clients with map open | Changes converge; no packet/chat spam, errors, frozen map or stale editor state. |
| Combined client update | Existing client features and other included fixes remain present after packaging. |

Use short one-minute durations and nearby custom areas for the first rotation/boundary tests. Keep
the one-hour defaults for the seeded catalog. Reset test-only location settings after acceptance.

Source PR review uses the offline engineering checks and records their scope and limitations.
The multiplayer/lifecycle checks above are a separate tester acceptance checklist, not permission
to launch gameplay or a prerequisite for publishing this source-only PR. Deployment remains separate.
Do not include unrelated Area 52 client fixes, progression changes, launcher assets or private test data.
