# 1103. A periodic dispel arm can tag its labels

- Status: accepted (provisional number, renumbered at merge)
- Date: 2026-11-21

## Context

`periodic_dispel` labels carry no variant, so a second arm of the same spell (the poison half of Cleansing Idol
504840, beside its disease arm) collides with the first (tool note T-pd).

## Decision

A `periodic_dispel` entry takes `label_tag`: its labels read `<spell> periodic_dispel <tag> <moment>[ <debuff>]`.
Without it the labels are unchanged.

## Consequences

Opt-in; the existing disease arm and classes 19 and 23 generate unchanged.
