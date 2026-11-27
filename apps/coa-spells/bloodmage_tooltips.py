import argparse
from pathlib import Path
import struct

FIELD_DESCRIPTION_ENUS = 170
FIELD_TOOLTIP_ENUS = 187

VAMPYR_BITE_UNTOUCHED = (803581, 803582, 803583, 803584, 803585)

DARK_LITURGY_OLD = (
    b"$?a802877[|cffff3232][|cffffffff]Requires Mortal Form|r\r\n"
    b"Form a blood bond, healing a friendly target for ${$m1+0+$SP*0.35+$SPI*0.25} "
    b"and applying |cffffffffBlood Rituals|r to them, bouncing to up to $i nearby allies, "
    b"healing for less for each target struck.@s:706624:0@"
)
DARK_LITURGY_NEW = (
    b"$?a802877[|cffff3232][|cffffffff]Requires Mortal Form|r\r\n"
    b"Form a blood bond, healing a friendly target for ${$m1+0+$SP*0.35+$SPI*0.25} "
    b"and applying |cffffffffBlood Rituals|r to them, bouncing to up to $i nearby allies.@s:706624:0@"
)

BLOODTHORNS_OLD = (
    b"Bloodthorns sprout from an ally for $d, causing ${$m1+0+$sps*0.035} Shadow damage "
    b"to attackers when hit.\r\n\r\nCan occur only once every half a second."
)
BLOODTHORNS_NEW = (
    b"Bloodthorns sprout from an ally for $d, causing ${$m1+0+$sps*0.035} Shadow damage "
    b"to attackers when hit."
)

GREATER_BLOODTHORNS_OLD = (
    b"Bloodthorns sprout from all party and raid members for $d, causing ${$m1+0+$sps*0.035} "
    b"Shadow damage to attackers when hit.\r\n\r\nCan occur only once every half a second."
)
GREATER_BLOODTHORNS_NEW = (
    b"Bloodthorns sprout from all party and raid members for $d, causing ${$m1+0+$sps*0.035} "
    b"Shadow damage to attackers when hit."
)

VAMPYRS_KISS_OLD = (
    b"Curse an enemy, causing them to bleed for $o1 Shadow damage over $d"
    b"$?s680731[ and instantly regenerate $805912s1% of your maximum Rage][].\r\n\r\n"
    b"All periodic damage dealt to an enemy affected by |cffffffffVampyr's Kiss|r is "
    b"replicated on them equal to $681395s1% of the value."
)
VAMPYRS_KISS_NEW = (
    b"Curse an enemy, causing them to bleed for $o1 Shadow damage over $d"
    b"$?s680731[ and instantly regenerate $681031s1% of your maximum Rage][].\r\n\r\n"
    b"All periodic damage dealt to an enemy affected by |cffffffffVampyr's Kiss|r is "
    b"replicated on them equal to $681395s1% of the value."
)

BLOODMOON_BLAST_OLD = (
    b"$?a802877[|cffff3232][|cffffffff]Requires Mortal Form|r\r\n"
    b"Blast an enemy for ${$m1+$sps*0.466229} Shadow damage and generates Rage"
    b"$?s500107[, and 1 stack of |cffffffffThirst|r.@s:706613:0@][.]"
    b"$?s807489[\r\n\r\nUsable while moving.][]"
)
BLOODMOON_BLAST_NEW = (
    b"$?a802877[|cffff3232][|cffffffff]Requires Mortal Form|r\r\n"
    b"Blast an enemy for ${$m1+$sps*0.466229} Shadow damage and generates Rage"
    b"$?s92112[, and 1 stack of |cffffffffThirst|r.@s:706613:0@][.]"
    b"$?s92113[\r\n\r\nUsable while moving.][]"
)

SANGUINE_RUPTURE_OLD = (
    b"$?a802877[|cffff3232][|cffffffff]Requires Mortal Form|r\r\n"
    b"Explode with boiling blood, dealing ${$m1+0+$sps*0.35} Shadow damage to enemies "
    b"and generating Rage for each enemy hit."
    b"$?s500107[\r\n\r\nGenerates 1 stack of |cffffffffThirst|r.][]"
)
SANGUINE_RUPTURE_NEW = (
    b"$?a802877[|cffff3232][|cffffffff]Requires Mortal Form|r\r\n"
    b"Explode with boiling blood, dealing ${$m1+0+$sps*0.35} Shadow damage to enemies "
    b"and generating Rage for each enemy hit."
    b"$?s92112[\r\n\r\nGenerates 1 stack of |cffffffffThirst|r.][]"
)

ANIMATED_R1_PREFIX = (
    b"Animate 2 blood worms to aid you in combat. Blood Worms bleed out over time, taking more "
    b"damage the longer they live. $?s681078[\r\n\r\n|cFFE53935Empowered|r: Duration increased "
    b"by $/1000;681398s2 sec and you summon 1 additional amalgam.][]"
)
ANIMATED_R2_PREFIX = (
    b"Animate $s1 blood parasites to aid you in combat for $d. "
    b"$?s681078[\r\n\r\n|cFFE53935Empowered|r: Duration increased by $/1000;681398s2 sec "
    b"and you summon 1 additional amalgam.][]"
)
ANIMATED_R3_PREFIX = (
    b"Animate a bloody amalgam to aid you in combat for $d. \r\n\r\nThe amalgam will "
    b"periodically unleash a |cffffffffBlood Strike|r on its target, dealing "
    b"${$589023m1*$<scalingbp>+$sps*.4+$AP*.15} Shadow damage, healing you for $504711s1% of "
    b"the damage dealt.$?s681078[\r\n\r\n|cFFE53935Empowered|r: Duration increased by "
    b"$/1000;681398s2 sec and you summon 1 additional amalgam.][]"
)
ANIMATED_THIRST_OLD = (
    b"$?s560259[ \r\n\r\nDuration increased by $/1000;570744s1 sec per stack of "
    b"|cFFFFFFFFThirst|r.][]"
)
ANIMATED_THIRST_NEW = (
    b"$?s561196[ \r\n\r\nDuration increased by $/1000;561196s1 sec per stack of "
    b"|cFFFFFFFFThirst|r.][]"
)

TEXTS = {
    500126: {
        FIELD_DESCRIPTION_ENUS: (
            b"Leap behind an enemy, dealing ${$804866m2+$804866ppl2+$AP*0.2} Physical Damage, "
            b"dazing them for $/1000;s3 sec, and generating $/10;804864s1 Rage.",
            b"Leap behind an enemy, dealing ${$m2+$ppl2} Physical Damage, "
            b"dazing them for $/1000;s3 sec, and generating $/10;804864s1 Rage.",
        ),
    },
    **{
        spell_id: {FIELD_DESCRIPTION_ENUS: (DARK_LITURGY_OLD, DARK_LITURGY_NEW)}
        for spell_id in (800781, 501623, 501624, 503611, 503612, 572575)
    },
    **{
        spell_id: {FIELD_DESCRIPTION_ENUS: (BLOODTHORNS_OLD, BLOODTHORNS_NEW)}
        for spell_id in (802313, 501662, 501663, 501664, 501665, 501666, 501667, 501668, 501669, 501670)
    },
    572116: {FIELD_DESCRIPTION_ENUS: (GREATER_BLOODTHORNS_OLD, GREATER_BLOODTHORNS_NEW)},
    803392: {
        FIELD_DESCRIPTION_ENUS: (
            b"Deals ${$m1+0+$sps*.15+$AP*.1} Shadow Damage and increases the damage the target takes "
            b"from subsequent applications of |cffffffffHematoma|r by $s2%, stacking $803392u times. "
            b"Generates Rage based on damage dealt.",
            b"Deals ${$m1+0+$sps*.15+$AP*.1} Shadow Damage and increases the damage the target takes "
            b"from subsequent applications of |cffffffffHematoma|r by $s2%, stacking $803392u times.",
        ),
    },
    **{
        spell_id: {FIELD_DESCRIPTION_ENUS: (VAMPYRS_KISS_OLD, VAMPYRS_KISS_NEW)}
        for spell_id in (504275, 504276, 504277, 504278, 504279, 504280, 504281)
    },
    681792: {
        FIELD_DESCRIPTION_ENUS: (
            b"Increases the damage dealt and spell power scaling of |cffffffffBloodbolt|r, "
            b"|cffffffffBloodmoon Blast|r, and |cffffffffCrimson Tide|r by $s2%.\r\n\r\n"
            b"In addition, damage dealt by |cffffffffBloodbolt|r now reduces all resistances by "
            b"${-($803722m1+$803722ppl1)} and increases the target's Magic damage taken by "
            b"$803722s2% for $803722d.",
            b"Increases the damage dealt of |cffffffffBloodbolt|r, |cffffffffBloodmoon Blast|r, "
            b"and |cffffffffCrimson Tide|r by $s2%.\r\n\r\nIn addition, damage dealt by "
            b"|cffffffffBloodbolt|r now reduces all resistances by ${-($803722m1+$803722ppl1)} "
            b"and increases the target's Magic damage taken by $803722s2% for $803722d.",
        ),
    },
    704115: {
        FIELD_DESCRIPTION_ENUS: (
            b"At the end of |CffffffffAortic Assault|r's duration, all enemies in a $806214a1 yd "
            b"frontal cone suffer ${$806214m1*$<scalingbp>+$AP*0.5} Physical damage.\r\n\r\n"
            b"Damage dealt by this effect is increased by $s2% against bleeding targets.",
            b"At the end of |CffffffffAortic Assault|r's duration, all enemies in a $806214a1 yd "
            b"frontal cone suffer ${$806214m1*$<scalingbp>+$AP*0.6} Physical damage.\r\n\r\n"
            b"Damage dealt by this effect is increased by $s2% against bleeding targets.",
        ),
    },
    532623: {
        FIELD_TOOLTIP_ENUS: (
            b"Damage taken by the Bloodmage's Veinbursts and Vital Shreds increased by ${$w1}%.",
            b"Damage taken from the Bloodmage increased by ${$w1}%.",
        ),
    },
    801076: {
        FIELD_DESCRIPTION_ENUS: (
            b"Enter a unique |cffa966f0Cursed Form|r for $d that does not disable the use of "
            b"|cffffffffMortal Form|r abilities$?s560073[, granting spell damage equal to $s1% "
            b"of your Spirit][].\r\n\r\nWhile active, direct spell damage triggers a "
            b"|cffffffffVampiric Feast|r, dealing $801076s3% additional Shadow damage to enemies, "
            b"healing you equal to 50% of the damage dealt.\r\n\r\n@ext:While in a "
            b"|cffa966f0Cursed Form|r you are treated as if you were a Demon.:ext@",
            b"Enter a unique |cffa966f0Cursed Form|r for $d that does not disable the use of "
            b"|cffffffffMortal Form|r abilities$?s560073[, granting spell damage equal to "
            b"$560073s2% of your Spirit][].\r\n\r\nWhile active, direct spell damage triggers a "
            b"|cffffffffVampiric Feast|r, dealing $801076s3% additional Shadow damage to enemies, "
            b"healing you equal to 50% of the damage dealt.\r\n\r\n@ext:While in a "
            b"|cffa966f0Cursed Form|r you are treated as if you were a Demon.:ext@",
        ),
    },
    524907: {
        FIELD_DESCRIPTION_ENUS: (
            b"Coalesce a powerful sanguine orb above you, healing up to $524906i allies within "
            b"$524906a1 yds for ${($524907d*1000/$524907t1)*($524906m1+$524906ppl1+$bh*0.1125+"
            b"$SPI*0.45+$STA*0.35)} over $524907d.\r\n\r\nGenerates 2 stacks of "
            b"|cFFE53935Pooled Vitality|r, and $/10;t3 Rage every $t3 sec.\r\n\r\n"
            b"@ext:Healing scales with Stamina and Spirit:ext@",
            b"Coalesce a powerful sanguine orb above you, healing up to $524906i allies within "
            b"$524906a1 yds for ${($524907d*1000/$524907t1)*($524906m1+$524906ppl1+$bh*0.1125+"
            b"$SPI*0.45+$STA*0.35)} over $524907d.\r\n\r\nGenerates 2 stacks of "
            b"|cFFE53935Pooled Vitality|r, and $/10;s3 Rage every $t3 sec.\r\n\r\n"
            b"@ext:Healing scales with Stamina and Spirit:ext@",
        ),
        FIELD_TOOLTIP_ENUS: (
            b"Healing nearby allies. Generating 2 stacks of |cFFE53935Pooled Vitality|r and "
            b"$/10;s2 Rage every $t1 sec.",
            b"Healing nearby allies. Generating 2 stacks of |cFFE53935Pooled Vitality|r and "
            b"$/10;s3 Rage every $t1 sec.",
        ),
    },
    804602: {
        FIELD_DESCRIPTION_ENUS: (
            b"Every $/1000;T1 second you remain in a |cffa966f0Cursed Form|r now reduces the "
            b"cooldown of your |cffffffffBloodsurge|r by $/1000;804603s1 sec.",
            b"Every $t1 seconds you remain in a |cffa966f0Cursed Form|r now reduces the "
            b"cooldown of your |cffffffffBloodsurge|r by $/1000;804603s1 sec.",
        ),
    },
    **{
        spell_id: {FIELD_DESCRIPTION_ENUS: (BLOODMOON_BLAST_OLD, BLOODMOON_BLAST_NEW)}
        for spell_id in (500125, 501607, 501608, 501609, 501610, 501611, 501612, 501613, 501614, 572332)
    },
    **{
        spell_id: {FIELD_DESCRIPTION_ENUS: (SANGUINE_RUPTURE_OLD, SANGUINE_RUPTURE_NEW)}
        for spell_id in (800774, 802456, 802457, 802458, 802459, 802460, 802461, 572907)
    },
    573299: {
        FIELD_DESCRIPTION_ENUS: (
            ANIMATED_R1_PREFIX + ANIMATED_THIRST_OLD,
            ANIMATED_R1_PREFIX + ANIMATED_THIRST_NEW,
        ),
    },
    573356: {
        FIELD_DESCRIPTION_ENUS: (
            ANIMATED_R2_PREFIX + ANIMATED_THIRST_OLD,
            ANIMATED_R2_PREFIX + ANIMATED_THIRST_NEW,
        ),
    },
    573357: {
        FIELD_DESCRIPTION_ENUS: (
            ANIMATED_R3_PREFIX + ANIMATED_THIRST_OLD,
            ANIMATED_R3_PREFIX + ANIMATED_THIRST_NEW,
        ),
    },
}


def read_cstring(strings: bytearray, offset: int) -> bytes:
    return bytes(strings[offset:strings.index(b"\0", offset)])


def transform(raw: bytes) -> bytes:
    magic, count, fields, size, strings_size = struct.unpack_from("<4s4I", raw)
    if magic != b"WDBC" or fields != 234 or size != 936 or len(raw) != 20 + count * size + strings_size:
        raise ValueError("Expected a complete 234-field CoA Spell.dbc")
    strings_at = 20 + count * size
    records = bytearray(raw[20:strings_at])
    strings = bytearray(raw[strings_at:])
    row_offsets = {
        struct.unpack_from("<I", records, index * size)[0]: index * size
        for index in range(count)
    }
    for spell_id in VAMPYR_BITE_UNTOUCHED:
        if spell_id not in row_offsets:
            raise ValueError(f"Missing untouched Vampyr Bite row {spell_id}")
        desc = read_cstring(strings, struct.unpack_from("<I", records, row_offsets[spell_id] + FIELD_DESCRIPTION_ENUS * 4)[0])
        if b"$s1%" not in desc:
            raise ValueError(f"Vampyr Bite {spell_id} lost $s1% unexpectedly: {desc!r}")
    for spell_id, updates in TEXTS.items():
        if spell_id not in row_offsets:
            raise ValueError(f"Missing Spell.dbc row for spell {spell_id}")
        base = row_offsets[spell_id]
        for field, (old, new) in updates.items():
            at = base + field * 4
            current = read_cstring(strings, struct.unpack_from("<I", records, at)[0])
            if current == new:
                continue
            if current != old:
                raise ValueError(f"Unexpected text in field {field} of spell {spell_id}: {current!r}")
            struct.pack_into("<I", records, at, len(strings))
            strings += new + b"\0"
    return struct.pack("<4s4I", magic, count, fields, size, len(strings)) + bytes(records) + bytes(strings)


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Apply the 53 O-10 Bloodmage client tooltip updates into a separate Spell.dbc candidate.",
        epilog="This never modifies an installed client, packages an MPQ, or alters Vampyr Bite 803581..803585.")
    parser.add_argument("--input", required=True, type=Path)
    parser.add_argument("--output", required=True, type=Path)
    args = parser.parse_args()
    if args.input.resolve() == args.output.resolve():
        parser.error("Use a separate output path; never overwrite the input")
    candidate = transform(args.input.read_bytes())
    with args.output.open("xb") as output:
        output.write(candidate)
    print(f"Prepared Bloodmage client Spell.dbc candidate ({len(TEXTS)} spells updated): {args.output}")


if __name__ == "__main__":
    main()
