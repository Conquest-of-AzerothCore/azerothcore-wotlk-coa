from tooltip import CasterStats, Readout, Records, Tooltip, read_tooltip

TOOLTIP_CORRECTIONS = 'tooltip_corrections'
INSERTED = '+'


def only_inserted(original: str, corrected: str) -> bool:
    position = 0
    for character in corrected:
        if position < len(original) and character == original[position]:
            position += 1
        elif character != INSERTED:
            return False
    return position == len(original) and len(corrected) > len(original)


def corrected_description(class_file: dict, records: Records, spell: int) -> str | None:
    correction = class_file.get(TOOLTIP_CORRECTIONS, {}).get(str(spell))
    if correction is None:
        return None
    if set(correction) != {'text', 'ruling'} or not isinstance(correction['ruling'], str) \
            or not correction['ruling'].strip() or not isinstance(correction['text'], str):
        raise ValueError(f'{TOOLTIP_CORRECTIONS} of {spell} is {{"text": corrected text, "ruling": recorded ruling}}')
    original = records.field('Spell', spell, 'Description[enUS]') or ''
    if not only_inserted(original, correction['text']):
        raise ValueError(f'{TOOLTIP_CORRECTIONS} of {spell} ({correction["ruling"]}) differs from its DBC Description '
                         f'by more than inserted {INSERTED!r} operators')
    return correction['text']


def tooltip_readout(class_file: dict, records: Records, spell: int, caster: CasterStats) -> Readout:
    text = corrected_description(class_file, records, spell)
    if text is None:
        return read_tooltip(records.dbc, spell, caster)
    return Tooltip(Records(records.dbc), spell, caster).read(text)
