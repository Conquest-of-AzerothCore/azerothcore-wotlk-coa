## Campaign011 group3 — resumed session

- 289261 Vampiric Tonic: implemented. Shared354nativephysical-damage branch heals owner for10%resolved damage. Dedicated existing pre-absorb heal hook clamps final heal after bonuses/critical calculation to10%maximumhealth without fake absorbs. Native180-second sharedToniccategorycooldown retained; self-damage/nonphysical events excluded, zero extra stat coefficient.
- 277162 Bloody Business: blocked. Three-Mangle counter/window and up-to7Pounce-spread contract known; helper169mode3withBP5/MaxAffected7stilldoesnotestablishsnapshot/duration/radius behavior. Reused shared169analysis; no grant-only implementation or guessed spreadmode.
- 281492 Corrupted Blade: blocked. Shared169failure confirmed. Parent10-yardspread/CC-player/totem exclusions known, helper usesradius14(8yards),5value/6cap andtwoCorruptionvariants. General169transfer/cap/variant semantics unresolved; no automatic replay of other caster debuffs.
- 281749 Blaze: blocked. FireBlast-spreadImmolate10-yardcontract includes explicit prohibition of periodic crits on spread copy. Helper169mode3andsecondaryability variants require per-copy crit suppression and supported transfer lifecycle. Remains reconstruction queued with shared169rather than fabricated copy semantics.
- 270033 Eldritch Weapon: blocked. Prior enchant951->270032->270044chain evidence reused. Explosion high-threat factor/cadence and secondary270048semantics remain unresolved; no partial proc enabling counted.

Cumulative108/100. All implementations runtime-unverified. Formatting only; no builds/tests/SQL deployment/server changes/Git.
