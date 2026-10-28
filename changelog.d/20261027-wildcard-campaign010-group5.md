## Campaign010 group5 — resumed session

- 270497 Treant Cultivation: partial. Existing Swiftmend cast rule dispatches native270496, reducing Force of Nature33831 and variant281618 by9000ms. No confirmed missing source path; static-only finding, no runtime or milestone claim.
- 270532 Words of Time: implemented. Borrowed Time haste was consumed by the standard charged cast-speed proc. With Words of Time present, only Priest Borrowed Time rejects that consumption event; native haste and expiration retained, unrelated haste buffs unchanged.
- 270561 Dominant Word: Shield: implemented. Added missing direct damaging Smite/Holy Fire/Penance stack proc with2000ms Penance-only throttle; native270634 supplies20%-per-stack absorb and-1000ms duration, capped10. PWS absorb gains75% below75%targethealth in both actual calculation and stronger-shield cast check; successful applied PWS consumes native stack buff.
- 270563 Raptured Essence: implemented. Native Rapture self-mana payout now doubles when270563 is active. Existing rank fractions, maximum-mana basis, shared12-second cooldown, shield-break requirements and ally resource payouts preserved.
- 277818 Molten Ammo: blocked. Retain user-selected pending-native-data status: helper277819 has50dummyamount pointing277820, but active tooltip does not establish damage basis. No unsupported50%damage inference or replacement mechanic; previous investigation reused.

Cumulative85/100. All implementations runtime-unverified. Formatting only; no builds/tests/SQL deployment/server changes/Git.
