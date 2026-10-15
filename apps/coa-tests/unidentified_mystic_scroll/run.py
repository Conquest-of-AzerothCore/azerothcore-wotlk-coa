import re
from pathlib import Path

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[2]
SQL = ROOT / 'data/sql/updates/pending_db_world/rev_20261008_80_coa_unidentified_mystic_scroll.sql'


def block(source, start, end):
    begin = source.index(start)
    return source[begin:source.index(end, begin)]


def main():
    rules = (ROOT / 'src/server/coa/AscensionMysticEnchantRules.h').read_text(encoding='utf-8')
    assert 'constexpr std::uint32_t UNIDENTIFIED_MYSTIC_SCROLL = 97866;' in rules
    assert 'constexpr double REVEAL_FAVORED_CHANCE = 0.33;' in rules

    enchant = (ROOT / 'src/server/coa/AscensionMysticEnchant.cpp').read_text(encoding='utf-8')
    check = block(enchant, 'SpellCastResult CheckReveal()', 'void Reveal(')
    assert 'scroll->GetEntry() != UNIDENTIFIED_MYSTIC_SCROLL' in check, 'only the Common scroll reveals'
    assert '!AscensionFreepick::RealmOffersMysticAltars() || IsConquestOfAzerothClass(player->getClass())' in check, \
        'nothing is revealed where Mystic Enchants are not played'
    assert '!player->GetFreeInventorySpace()' in check, 'a full bag keeps the scroll'

    reveal = block(enchant, 'Enchant const* RevealScroll(Player* player)', 'class spell_ascension_unidentified_mystic_scroll')
    assert 'ClassAllowed(enchant, character.Class)' in reveal, 'Warcraft Reborn favors the own class'
    assert 'AffectsKnownSpell(known, enchant)' in reveal, 'free-pick favors scrolls that modify a known spell'

    drops = block(enchant, 'class AscensionMysticEnchantScrollDrops', 'class AscensionMysticEnchantWorld')
    assert 'constexpr float SCROLL_DROP_CHANCE = 4.0f;' in enchant and 'constexpr uint8 SCROLL_DROP_MIN_LEVEL = 10;' in enchant
    assert '!AscensionFreepick::RealmOffersMysticAltars()' in drops, 'scrolls drop only where Mystic Enchants are played'
    assert '&store != &LootTemplates_Creature' in drops and 'LootTemplates_Creature.HaveLootFor(creatureTemplate->lootid)' in drops, \
        'only creatures that drop loot add a scroll'
    assert 'uint32 const level = creatureTemplate->minlevel;' in drops, 'the natural level, not a scaled one'
    assert re.search(r'if \(creature->IsDungeonBoss\(\) \|\| creatureTemplate->rank == CREATURE_ELITE_WORLDBOSS\)\s*'
                     r'count = std::max<uint32>\(1, level / 10\);', drops), 'a boss drops one scroll per ten levels, at least one'
    assert re.search(r'else if \(level > SCROLL_DROP_MIN_LEVEL && roll_chance_f\(SCROLL_DROP_CHANCE\)\)\s*count = 1;', drops), \
        'a creature above level 10 drops one 4% of the time'
    assert 'loot->AddItem(LootStoreItem(UNIDENTIFIED_MYSTIC_SCROLL, 0, 100.0f, false, LOOT_MODE_DEFAULT, 0, count, count));' in drops, \
        'the scroll is added to the loot, nothing is replaced'

    assert 'new AscensionMysticEnchant::AscensionMysticEnchantScrollDrops();' in enchant
    assert 'RegisterSpellScriptWithArgs(AscensionMysticEnchant::spell_ascension_unidentified_mystic_scroll,' in enchant
    sql = SQL.read_text(encoding='utf-8')
    assert "(93228, 'spell_ascension_unidentified_mystic_scroll')" in sql

    levels = {9: 1, 10: 1, 19: 1, 20: 2, 29: 2, 30: 3, 63: 6, 80: 8}
    assert all(max(1, level // 10) == count for level, count in levels.items())
    print('PASS: Unidentified Mystic Scrolls drop and reveal only where Mystic Enchants are played')


if __name__ == '__main__':
    main()
