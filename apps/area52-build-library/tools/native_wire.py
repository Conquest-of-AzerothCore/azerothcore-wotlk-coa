"""Read bounded server build records without importing account or character identity."""
import portable_dependency
from library import require, validate_build, SPELL_ROLES
import struct

CATEGORIES = {1:'Leveling',2:'Level60PvE',3:'Level60PvP',5:'Level70PvE',6:'Level70PvP',8:'BuildDraft'}
ROLES = {0:'NONE',1:'LEADER',2:'TANK',4:'HEALER',8:'DAMAGE',14:'ANY'}
STATS = {0:'STRENGTH',1:'AGILITY',3:'INTELLECT',4:'SPIRIT'}
DIFFICULTY = {0:'EASY',1:'NORMAL',2:'HARD',3:'VERY_HARD',4:'IMPOSSIBLE'}
WEAPONS = {0:'AXE',1:'AXE2',2:'BOW',3:'GUN',4:'MACE',5:'MACE2',6:'POLEARM',7:'SWORD',8:'SWORD2',10:'STAFF',13:'FIST',15:'DAGGER',16:'THROWN',18:'CROSSBOW',19:'WAND'}
ARMOR = {1:'CLOTH',2:'LEATHER',3:'MAIL',4:'PLATE',6:'SHIELD',7:'LIBRAM',8:'IDOL',9:'TOTEM',10:'SIGIL'}


def decode_wire(raw):
    require(isinstance(raw, bytes) and len(raw) <= 24576, 'Native record exceeds limit')
    cursor = 0

    def number(size=4):
        nonlocal cursor
        require(cursor + size <= len(raw), 'Truncated native number')
        value = int.from_bytes(raw[cursor:cursor + size], 'little')
        cursor += size
        return value

    def text(limit):
        nonlocal cursor
        end = raw.find(b'\0', cursor, min(len(raw), cursor + limit + 1))
        require(end >= cursor, 'Invalid native string')
        value = raw[cursor:end].decode('utf-8')
        cursor = end + 1
        return value

    text(64)
    for _ in range(3):
        text(64)
    native_class = number()
    text(128)
    result = {key: text(limit) for key, limit in (('Name',128), ('Subtext',512), ('Description',8192), ('Icon',256))}
    result['Class'] = native_class
    number(); number(8)
    result['Updated'] = number(8)
    for key in ('Category', 'Roles', 'PrimaryStat'):
        result[key] = number()
    count = number(); require(count <= 512, 'Too many native spells')
    result['Spells'] = []
    seen = set()
    for _ in range(count):
        spell, level = number(), number()
        require(spell > 0 and spell not in seen, 'Invalid native spell')
        seen.add(spell)
        roles = [number(1) for _ in range(4)]
        require(all(value in (0,1) for value in roles), 'Invalid native spell roles')
        result['Spells'].append({'Spell': spell, 'Level': level, 'Roles': roles, 'Flags': number(), 'Comment': text(128)})
    count = number(); require(count <= 64, 'Too many native enchants')
    result['RandomEnchants'] = []
    seen = set()
    for _ in range(count):
        enchant, stacks, level, flags = number(), number(), number(), number()
        require(enchant > 0 and enchant not in seen and 1 <= stacks <= 17, 'Invalid native enchant')
        seen.add(enchant)
        result['RandomEnchants'].append({'Enchant': enchant, 'Stacks': stacks, 'Level': level, 'Flags': flags, 'Comment': text(128)})
    for key in ('WeaponTypes', 'ArmorTypes'):
        count = number(); require(count <= 32, 'Too many native equipment preferences')
        rows, seen = [], set()
        for _ in range(count):
            kind = number(); require(kind not in seen, 'Duplicate native equipment type');seen.add(kind)
            rows.append({'Type': kind, 'Comment': text(128)})
        result[key] = rows
    require(number(1) <= 1, 'Invalid native repair flag')
    number()
    result['DifficultyRating'] = number()
    require(cursor == len(raw), 'Trailing native record')
    return result


def portable(raw):
    native = decode_wire(raw)
    require(native['Class'] == 10, 'Expected an Area 52 Hero build')
    def lookup(mapping, value):
        require(value in mapping, 'Unsupported native enum; explicit review required')
        return mapping[value]
    build = {key:native[key] for key in ('Name','Icon','Description','RandomEnchants')}
    build['Category'] = lookup(CATEGORIES, native['Category'])
    build['Roles'] = 'PLAYER_ROLE_' + lookup(ROLES, native['Roles'])
    build['PrimaryStat'] = 'STAT_' + lookup(STATS, native['PrimaryStat'])
    build['DifficultyRating'] = 'BUILD_DIFFICULTY_RATING_' + lookup(DIFFICULTY, native['DifficultyRating'])
    build['Spells'] = []
    for spell in native['Spells']:
        row = {key:spell[key] for key in ('Spell','Level','Flags','Comment')}
        row.update({key:bool(value) for key,value in zip(SPELL_ROLES,spell['Roles'])})
        build['Spells'].append(row)
    for key, mapping, prefix in (('ArmorTypes',ARMOR,'ITEM_SUBCLASS_ARMOR_'),('WeaponTypes',WEAPONS,'ITEM_SUBCLASS_WEAPON_')):
        build[key] = [{'Type':prefix+lookup(mapping,row['Type']),'Comment':row['Comment']} for row in native[key]]
    return validate_build(build)


def encode_wire(build, local_id, author, created, updated, shared_copy=True):
    build = validate_build(build)
    require(str(local_id).isdecimal() and 0 < int(local_id) < 2**64, 'Invalid local identity')
    require(type(created) is int and type(updated) is int and 0 <= created <= updated < 2**64, 'Invalid timestamps')
    data = bytearray()
    def text(value, limit):
        raw = value.encode('utf-8')
        require(len(raw) <= limit and b'\0' not in raw, 'Invalid native text')
        data.extend(raw + b'\0')
    def number(value, size=4):
        require(type(value) is int and 0 <= value < 2**(size*8), 'Invalid native number')
        data.extend(value.to_bytes(size,'little'))
    def inverse(mapping, value):
        reverse = {v:k for k,v in mapping.items()}
        require(value in reverse, 'Unsupported portable enum')
        return reverse[value]
    text(str(local_id),64)
    for _ in range(3):text('',64)
    number(10);text(author,128);text(build['Name'],128);text('',512)
    description = build['Description']
    category = build['Category']
    if shared_copy:
        import re
        description = re.sub(r'\n*###AREA52_ARCHETYPE_ID[^#]*', '', description)
        if category.startswith('BuildDraft'):category='Leveling'
    text(description,8192);text(build['Icon'],256)
    number(0);number(created,8);number(updated,8)
    number(inverse(CATEGORIES,category));number(inverse(ROLES,build['Roles'].removeprefix('PLAYER_ROLE_')))
    number(inverse(STATS,build['PrimaryStat'].removeprefix('STAT_')))
    number(len(build['Spells']))
    require(bool(build['Spells']), 'A server build needs at least one spell')
    for spell in build['Spells']:
        require(1 <= spell['Level'] <= 80, 'Invalid learning level')
        number(spell['Spell']);number(spell['Level'])
        for key in SPELL_ROLES:number(int(spell[key]),1)
        number(spell['Flags']);text(spell['Comment'],128)
    number(len(build['RandomEnchants']))
    for enchant in build['RandomEnchants']:
        require(1 <= enchant['Level'] <= 80, 'Invalid enchant learning level')
        for key in ('Enchant','Stacks','Level','Flags'):number(enchant[key])
        text(enchant['Comment'],128)
    for key,mapping,prefix in (('WeaponTypes',WEAPONS,'ITEM_SUBCLASS_WEAPON_'),('ArmorTypes',ARMOR,'ITEM_SUBCLASS_ARMOR_')):
        number(len(build[key]))
        for item in build[key]:number(inverse(mapping,item['Type'].removeprefix(prefix)));text(item['Comment'],128)
    number(0,1);number(0);number(inverse(DIFFICULTY,build['DifficultyRating'].removeprefix('BUILD_DIFFICULTY_RATING_')))
    require(len(data) <= 24576, 'Native build exceeds packet limit')
    return bytes(data)
