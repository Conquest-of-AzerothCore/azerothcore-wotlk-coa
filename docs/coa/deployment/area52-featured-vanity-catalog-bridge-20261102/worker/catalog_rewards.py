import struct
from catalog_worker import DEFAULT, CATEGORIES, dbc

HUNTERS={1042:1042,24747:24747,35189:35189,6554:9906554}
PET_APPEARANCES={74491:61374,16941:47677,18683:51229,80854:51230}


def render(sets,vanity,appearances,assigned,mounts,defaults):
    set_rows=dbc(sets,53)
    appearance_rows={row[0]:row for row in dbc(appearances,17)}
    magic,count,fields,size,strings=struct.unpack_from('<4s4I',vanity)
    if (magic,fields,size)!=(b'WDBC',76,308) or len(vanity)!=20+count*size+strings:
        raise ValueError('VanityCollection layout mismatch')
    bundle_rows=[list(struct.unpack_from('<76I',vanity,20+index*size)) for index in range(count)]
    output_sets,output_vanity=bytearray(sets),bytearray(vanity)
    indexed_sets={row[0]:index for index,row in enumerate(set_rows)}
    indexed_bundles={row[1]:index for index,row in enumerate(bundle_rows)}
    if len(indexed_sets)!=len(set_rows) or len(indexed_bundles)!=len(bundle_rows):
        raise ValueError('Duplicate reward catalog identity')
    rewards={}
    for archetype,record in assigned.items():
        if 90000+archetype not in indexed_sets or 9901000+archetype not in indexed_bundles:
            raise ValueError('Missing Featured wardrobe set or reward bundle')
        si,bi=indexed_sets[90000+archetype],indexed_bundles[9901000+archetype]
        selected=record['items']
        if selected is not None:
            for index,kind in ((12,'ground'),(13,'flying')):
                if selected[index] and mounts.get(str(selected[index]))!=kind:
                    raise ValueError('Mount reward category mismatch')
            set_rows[si][18:35]=selected[:12]+[0]*5
            struct.pack_into('<53I',output_sets,20+si*212,*set_rows[si])
            item_rewards=list(dict.fromkeys(item for item in selected if item))
        else:
            item_rewards=list(dict.fromkeys(item for item in bundle_rows[bi][18:42] if item))
        default_appearances=list(defaults.get(str(9901000+archetype),[]))
        default_pet={24:61374,26:47677,33:51229,95:51230}.get(archetype)
        if default_pet:
            default_appearances.append(default_pet)
        for appearance in default_appearances:
            row=appearance_rows.get(appearance)
            if row and row[5] in (*CATEGORIES,25,26,27,28,29) and row[1]:
                item_rewards.append(row[1])
        effects=record['effects'] or [DEFAULT]*4
        pet=effects[0]
        if pet not in (0,DEFAULT) and pet not in HUNTERS and pet not in PET_APPEARANCES:
            raise ValueError('Unsupported combat pet reward')
        overrides=dict(zip(CATEGORIES,record['incarnations'] or [DEFAULT]*4))
        if pet!=DEFAULT:
            overrides.update({category:0 for category in range(25,30)})
            if pet in PET_APPEARANCES:
                row=appearance_rows[PET_APPEARANCES[pet]]
                if row[5] not in range(25,30) or not row[8]:
                    raise ValueError('Pet appearance category mismatch')
                overrides[row[5]]=row[0]
        item_categories={row[1]:row[5] for row in appearance_rows.values() if row[1]}
        for category,appearance in overrides.items():
            if appearance==DEFAULT:
                continue
            item_rewards=[item for item in item_rewards if item_categories.get(item)!=category]
            if appearance:
                row=appearance_rows.get(appearance)
                if row is None or row[5]!=category or not row[1]:
                    raise ValueError('Reward appearance has no client item mapping')
                item_rewards.append(row[1])
        item_rewards=list(dict.fromkeys(item_rewards))
        if len(item_rewards)>24:
            raise ValueError('Reward bundle exceeds native capacity')
        bundle_rows[bi][18:42]=item_rewards+[0]*(24-len(item_rewards))
        struct.pack_into('<24I',output_vanity,20+bi*308+18*4,*bundle_rows[bi][18:42])
        rewards[archetype]={'items':selected,'pet':pet,'hunter_pet':HUNTERS.get(pet,0),'incarnations':record['incarnations']}
    return bytes(output_sets),bytes(output_vanity),rewards
