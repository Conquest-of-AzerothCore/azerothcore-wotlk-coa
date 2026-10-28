## Campaign010 group8 — resumed session

- 270704 Battle Fervor: partial. Existing Charge cast rule with6000ms cooldown grants native270695 haste15%/movement30% buff for native duration. No missing effect path established, no edit or implementation credit.
- 270706 Crushing Impact: partial. Existing Charge proc reaches delayed helper270700 (500ms) then native area270698. Both caster-owned damage modifiers have native dispatch. No confirmed static activation gap; arrival/area semantics require runtime check, no speculative delay rewrite.
- 270766 Purification By Light: blocked. Native weapon-spell proc flags65808 and trigger/ground/stun payloads identified. Parent proc chance0 and no live proc/PPM row; tooltip gives only a chance, no numeric chance. Must establish original rate before enabling; no15%inference from Exorcism child field. Ground destination and exact coefficients recorded for reconstruction.
- 270804 Spell Slinger: implemented. Removed donor cast-while-Clearcasting-present proc. Native Clearcasting AfterProc now triggers Arcane Burst only on accepted final-charge consumption, after Missile Barrage priority/native eligibility checks. Targets consuming spell enemy or selected enemy; explicit0.45SP/0.30AP coefficients and native level/base values retained. Shared native consumption lifecycle reused; no blanket cast hook.
- 281467 Soulbender: blocked. Reused previous Shadowburn/SoulEnergy/SoulMending chain: stack counts and2%healing perstack established, but party heal basis281469 remains unspecified. No grant-only implementation or fabricated healing amount.

Cumulative91/100. All implementations runtime-unverified. Formatting only; no builds/tests/SQL deployment/server changes/Git.
