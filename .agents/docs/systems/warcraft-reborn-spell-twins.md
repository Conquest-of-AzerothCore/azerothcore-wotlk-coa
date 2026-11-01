# Warcraft Reborn spell twins

Warcraft Reborn realms give the stock classes their own copies of the stock spells. Core and script code is
written against stock spell IDs, so the server maps between a stock spell and its Reborn copy instead of
duplicating every special case. This page describes that mapping and the rules that keep stock code working
for Reborn spells. Spell IDs below are examples.

## Twins, namesakes and crossover enchants

- A Reborn spell is its stock spell's ID plus 1,100,000 (Reborn Life Tap 1101454 for stock 1454).
- A **twin** has the same name and the same effect and aura types as its stock spell
  (`AscensionWarcraftReborn::SpellTwins`). Later ranks of a Reborn chain that keep the chain head's layout are
  twins of the stock head too (`RankTwins`).
- A **namesake** has the stock name but a different layout (Reborn Savage Defense 1162600, Reborn Setup
  1113983). It is a separate record and gets nothing copied from its stock spell.
- On a seasonal realm a crossover Mystic Enchant (stock ID plus 1,300,000) twins the stock spell or, when it
  copies the Reborn record instead, the Reborn spell.

Twins and namesakes are loaded only on a Warcraft Reborn realm; enchant twins only on a seasonal realm.

## Lookups

- `SpellMgr::GetSpellTwinSource(id)` returns the stock spell behind a twin or namesake, following at most two
  hops (crossover enchant to Reborn spell to stock spell), or `id` itself. Code that compares a spell against a
  stock ID compares `GetSpellTwinSource(id)`; comparisons against a first rank use the source of
  `GetFirstRankSpell()`.
- `SpellMgr::GetSpellTwinFor(stockId, relatedId)` returns the copy of `stockId` that belongs with
  `relatedId`, for example the Reborn Furor energize for the Reborn Furor talent. It adds the related spell's
  offset from its source to `stockId` and accepts the result only when it is a twin or namesake of `stockId`.
  When that fails:
  - a crossover enchant with no crossover copy of the result spell falls back to the Reborn copy (stock plus
    1,100,000);
  - a later rank retries with its chain's first rank, so a rank the Reborn chain added resolves like the chain;
  - otherwise the stock spell is returned. Stock characters always get the stock spell.
- `Unit::HasAuraOrTwin`, `GetAuraOfRankedSpellOrTwin`, `GetAuraEffectOfRankedSpellOrTwin`,
  `RemoveAurasDueToSpellOrTwin` and `Player::HasSpellOrTwin` accept a stock ID and match any relative.

## Data copied to twins

At load, the rows of a stock spell are copied to each twin that has none of its own: `spell_script_names`,
`spell_proc`, `spell_bonus_data`, threat, cones, mixology and cooldown overrides, `spell_pet_auras`,
`spell_linked_spell` and spell requirements.

- `spell_pet_auras` and `spell_linked_spell` copies name the twins of their auras and linked spells, so a Reborn
  talent applies the Reborn pet aura or linked buff, not the stock one.
- A twin with a script of its own does not receive its stock spell's scripts. Bind the stock script as well when
  both must run (Reborn Fire Ward and Frost Ward).
- A `spell_bonus_data` row copied to a later rank is dropped when that rank's first rank has its own row and the
  later rank has none, so the chain's row applies to every rank.
- Namesakes receive nothing. Give them their own rows (procs, links, scripts, bonus data) or a load contract.

## Stock scripts running for a Reborn spell

While a `SpellScript` or `AuraScript` hook runs, the thread records the twin it runs for: the script's own spell
when that is a twin or namesake, or, for a spell script, the Reborn aura that triggered its spell (Deep Wounds'
stock trigger). Nested hooks stack; the innermost recorded twin wins. While a twin is recorded:

- a cast of a stock ID is resolved to `GetSpellTwinFor(stockId, runningTwin)` before the `Spell` is built
  (`UnitScript::ResolveSpellCast`, through `AscensionWarcraftRebornScriptTwinCasts`), keeping targets, flags
  and forwarded values;
- aura queries by stock ID (`GetAuraEffect`, `GetAuraApplication`/`HasAura`, `HasAuraEffect`, `GetAuraCount`)
  and `GetGameObject` fall back to the twin when the stock spell is not found;
- `RemoveAurasDueToSpell` and `RemoveAuraFromStack` remove the twin as well;
- `CastDelayedSpellWithPeriodicAmount` resolves the spell when it is scheduled, since the delayed cast runs
  after the script has returned.

A cast triggered by an aura (`triggeredByAura` set) takes its twin from that aura instead: a Reborn aura
resolves the triggered spell to its own twin, and a stock aura's trigger stays stock even inside a Reborn
spell's script. `ResolveSpellCast` overrides receive the triggering aura effect, or null.

## Core casts and checks

Core code that casts a fixed stock ID on behalf of a spell or aura passes it through `GetSpellTwinFor` with that
spell, for example the creature interrupt cast by interrupting spells, Furor's energy and rage,
Kill Command's buffs, Rapture's returns, Reincarnation, Faerie Fire (Feral) in Bear Form, Improved Blizzard's
Chilled and the Master of Subtlety and Overkill trackers. Stock special cases keyed on an ID (Barkskin and
Hand of Freedom while stunned, Snake Trap's trap activation, Cloak of Shadows' purge, Healing Stream Totem's
glyph and Restorative Totems, Demonic Knowledge's pet aura) compare the twin source.

## Pets

- Reborn Summon Water Elemental (permanent, 1170908) summons a pet: its summon effect is changed to
  `SPELL_EFFECT_SUMMON_PET` at load.
- `Pet::IsPermanentPetFor` compares the stock pet entry (`GetStockPetEntry`), so the Reborn permanent Water
  Elemental counts as the mage's permanent pet like stock 37994.
- `Player::CanResummonPet` accepts Summon Water Elemental or its twin with Glyph of Eternal Water or its twin.
- Talents whose stock rows carry `spell_pet_auras` put the Reborn pet aura on the pet; a Reborn talent with no
  stock row of its own (Reborn Frost Mastery) needs its own row.
