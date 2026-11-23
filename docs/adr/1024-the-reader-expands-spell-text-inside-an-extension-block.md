# 1024. The reader expands spell text inside an extension block

- Status: accepted (provisional number, renumbered at merge)
- Date: 2026-11-21

## Context

Witch Doctor tooltips embed other spells' text in extension blocks: Loa's Blessing 705848 lists its four blessings as
`@ext:@s:802207:0@:ext@`, and the Spirit and Shroom spells (500015, 500472, 501080 to 501088, 705850, 705851) carry
one each. The reader expands a bare `@s:` markup (`SPELL_MARKUP`), but consumed an `@ext:` block as two unreadable
pieces (`@ext:@` and `@:ext@`), so the embedded spells' stated values never reached a label (tool note T-b14-8).

The cycle 10 proposal also asked for a `$BH` (bonus healing) resolver. Its value is the caster's healing bonus, which
the harness does not read (the `healing_power` read of proposal-harness-reads.md, harness C++); a resolver from the
reference stats would state an amount no scenario can measure, so it is not built here.

## Decision

`Tooltip.read` matches an `@ext:...:ext@` block (`EXTENSION_BLOCK`) that holds an `@s:` markup and expands every
`@s:` inside it as a bare one would be expanded (`extension_block`). The rest of the block, if any text remains, is
one unreadable entry; a block without an `@s:` markup is read as before.

## Consequences

- Tooltip readings change only where an extension block holds an `@s:` markup. Generated scenarios of classes 19 (also
  `--stack`) and 23 are byte-identical (`diff -r`, 2026-11-21). In class 13 the value scenarios of 500015, 500472,
  501080 to 501088, 705848, 705850 and 705851 gain the embedded values (`effect_value <spell>e<n>`, `spell_duration`,
  `max_stacks`) and lose the unreadable `@ext:@` / `@:ext@` labels; the later labels of those spells are renumbered.
- The Witch Doctor ledger rows 705848 `@ext::ext@` (four rows) now link the readable data labels `705848 effect_value
  802207e0 #0` to `802216e0 #3`; their tool_gap stays for the behaviour route (a real Loa's Brew picks the blessing at
  random). No other ledger row named a dropped label.
- Seeded fixture case in `test_tooltip.py` (`test_spell_markup_inside_an_extension_block_expands`); the extension
  block without a markup stays unreadable (`test_unsupported_patterns_are_reported_verbatim`).
- `$BH` and `$bh` stay unreadable until the harness reads the healing bonus.
