/* Copyright (C) 2016+ AzerothCore, GNU AGPL v3. */
#ifndef ASCENSION_WITCH_DOCTOR_COMPLETION_H
#define ASCENSION_WITCH_DOCTOR_COMPLETION_H

#include "ObjectGuid.h"
#include "SpellInfo.h"
#include <list>
#include <vector>

class Player;
class Unit;
class Creature;
class Aura;
class Spell;

namespace AscensionWitchDoctor
{
enum DoctorSpells : uint32
{
    Puppeteer = 92084,
    Brewer = 92085,
    Shadowhunter = 92086,
    ShadowhunterCost = 680880,
    Spirit = 561136,
    SpiritStats = 561299,
    SpiritCast = 561137,
    SpiritChance = 561361,
    SpiritVisual = 561298,
    SpiritOrbOne = 561378,
    SpiritOrbTwo = 561379,
    SpiritOrbThree = 561380,
    SpiritOrbFour = 561381,
    SpiritOrbFive = 561382,
    SpiritSpeed = 561071,
    SpiritWalk = 707335,
    SpiritPickup = 561068,
    SpiritPickupBuff = 561067,
    SpiritDevotee = 503727,
    SpiritMana = 705941,
    LoaSpiritsOne = 804620,
    LoaSpiritsTwo = 807904,
    LoaEcho = 705843,
    Reclamation = 806288,
    Volley = 504582,
    VolleyTalent = 503712,
    VolleyReady = 505158,
    VolleyTrigger = 504583,
    VolleyCooldown = 504584,
    Umbral = 501134,
    UmbralTalent = 681242,
    UmbralReady = 504588,
    Hex = 801693,
    Wrath = 807037,
    Arrow = 801674,
    Hexfire = 807042,
    HexfireWrath = 807480,
    HexfireReady = 503626,
    HexfireAdept = 704500,
    BadJuju = 802087,
    PuppeteersGrasp = 707209,
    MarkOfMalice = 802926,
    Shadowflare = 801669,
    ShadowflareHit = 802704,
    OverflowingJuju = 707405,
    DarkIncantation = 525377,
    Puppets = 500015,
    PuppetHit = 801797,
    PuppetVisual = 802745,
    Threads = 572836,
    ThreadsDamage = 572837,
    ThreadsSnap = 572838,
    VoodooSpirits = 704511,
    Strings = 705910,
    StringsDamage = 706898,
    Guile = 705928,
    GuileDamage = 705929,
    Glaive = 806289,
    GlaiveExplosion = 806616,
    Godslayer = 802714,
    Eclipse = 801607,
    EclipseHit = 802717,
    EclipseSplash = 802712,
    Frenzy = 560748,
    FrenzyHeal = 560747,
    FrenzyRegen = 561077,
    SoulFeeder = 705894,
    VoodooMind = 504462,
    JujuSpirits = 807296,
    PriceToPay = 705948,
    PriceReady = 707326,
    PriceCooldown = 712372,
    Dambala = 712312,
    DambalaReady = 712375,
    TrueSpirit = 802268,
    TrueSpiritReady = 681233,
    SpiritHunting = 707504,
    Traditionalist = 503707,
    SpiritWarden = 503774,
    SpiritWardenBuff = 503775,
    Hexplosion = 704495,
    HasteBuff = 504458,
    Eye = 503714,
    EyeDebuff = 802707,
    Malignant = 704503,
    Overflow = 705844,
    OverflowBuff = 705845,
    MojoMadness = 705871,
    MojoFree = 503693,
    Unleashed = 705901,
    MaliciousGolems = 705912,
    GolemHaste = 705913,
    HollowSpirit = 705917,
    HollowDebuff = 503706,
    Berserking = 705925,
    WardHaste = 705926,
    SerpentHandler = 705939,
    GrowingMalice = 706551,
    GrowingDebuff = 582257,
    HexOfDeath = 706557,
    HealingDebuff = 706559,
    Voice = 801716,
    VoiceExplosion = 504452,
    PriceOfPower = 705916,
    OtherSide = 802092,
    OtherSideBuff = 570066,
    Devotion = 802756,
    DevotionHeal = 570156,
    VoodooFireOne = 802262,
    VoodooFireTwo = 803846,
    VoodooFire = 500473,
    HexfireMass = 807450,
    SerpentMass = 504777,
    WrathWard = 808004,
    RitualOne = 705840,
    RitualTwo = 705841,
    DarkEffigy = 707331,
    Gift = 707650,
    LoaBrew = 801670,
    LoaBlessing = 705848,
    LoaEchoHeal = 899906,
    JungleSecrets = 707212,
    JungleSecretsHeal = 712348,
    BlessingOne = 802207,
    BlessingTwo = 802208,
    BlessingThree = 802215,
    BlessingFour = 802216,
    Bottle = 801696,
    BottleDamage = 504606,
    BottleLink = 707172,
    OutOfBottle = 301175,
    Touch = 578295,
    TouchDebuff = 578296,
    Senjin = 560544,
    SenjinBuff = 561017,
    Beam = 500950,
    BeamCost = 573288,
    BeamMarker = 578112,
    Wave = 707617,
    WaveHeal = 712453,
    Replenishment = 1257670,
    SplashOnEm = 802219,
    Potion = 801661,
    Splash = 802710,
    Shrooms = 801660,
    Fish = 801662,
    Bones = 801663,
    Thistle = 801664,
    Mixologist = 561069,
    IngredientMarker = 801702,
    IngredientBlocker = 800524,
    ShroomsField = 802703,
    FishField = 803269,
    BonesField = 803697,
    ThistleField = 802771,
    PotionShrooms = 802973,
    PotionFish = 802969,
    PotionBones = 802971,
    PotionThistle = 802975,
    SplashShrooms = 803698,
    SplashFish = 803273,
    SplashBones = 803699,
    SplashThistle = 803271,
    SplashRouteOne = 803272,
    SplashRouteTwo = 803275,
    SplashRouteThree = 803277,
    SplashRouteFour = 803289,
    MojoThistle = 500472,
    MojoFish = 705850,
    MojoShrooms = 705851,
    JungleBooms = 705859,
    JungleThistle = 500508,
    FrogShrooms = 500509,
    FishBones = 500594,
    MasterConcoctions = 801690,
    ConcoctionsBuff = 570064,
    ConcoctionsHeal = 570185,
    Unstable = 802487,
    UnstableDebuff = 802488,
    UnstableHeal = 802489,
    ThistleHeal = 803287,
    Crystal = 500962,
    CrystalShield = 547574,
    Beast = 705870,
    BeastShield = 547573,
    TikiTalent = 500053,
    Tiki = 500478,
    TikiReady = 500515,
    TikiHeal = 500514,
    TikiShield = 500747,
    TikiCrit = 500598,
    MassAllcureTalent = 705906,
    MassAllcure = 706555,
    HealingWard = 500957,
    WardHeal = 805403,
    SerpentWard = 500960,
    SpiritIdol = 500961,
    SereneIdol = 504759,
    SereneField = 504760,
    CleansingIdol = 504840,
    Cleanse = 505348,
    ShadowEffigy = 505339,
    ShadowField = 504761,
    ShadowSlow = 504909,
    HexingEffigy = 506634,
    Hexed = 504762,
    GravenEffigy = 506635,
    GravenField = 504767,
    DarkIdol = 507082,
    DarkField = 505195,
    JungleIdol = 507084,
    SwiftIdol = 804226,
    SwiftField = 804645,
    SpiritLink = 706369,
    SpiritManaTick = 805282,
    SentryWard = 674303,
    CallSseratus = 572899,
    CallSseratusChannel = 681222,
    ViperTalent = 707329,
    ViperWard = 712373,
    ViperProc = 712374,
    ViperFire = 712415,
    CursedEffigy = 706542,
    CursedField = 506820,
    Mimic = 707162,
    ChosenOne = 503742,
    MojoHigh = 706488,
    WarGolem = 800330,
    StasisWard = 801678,
    Stasis = 801677,
    BigVoodoo = 802719,
    BigVoodooField = 802718,
    BigVoodooLock = 803495,
    VoodooCauldron = 804684,
    CauldronBuff = 504419,
    MojoCauldron = 807908,
    Mirage = 501136,
    CloneMe = 45204,
    SenjinSwiftness = 504426,
    SenjinWisdom = 504774,
    Slither = 500947,
    SlitherAvoid = 806295,
    Shadowstalker = 807040,
    StalkerSpeed = 807214,
    Hunger = 705942,
    HungerBuff = 807213,
    Vigil = 504465,
    VigilHeal = 681004,
    RageBrew = 503750,
    RageBrewBuff = 503751,
    Shock = 807743,
    ShockInterrupt = 807772,
    Shrinking = 806285,
    LatentCurse = 806283,
    Misery = 806346,
    MalignantJinx = 803678,
    JinxSilence = 803732,
    Marionette = 704497,
    MarionetteStacks = 807057,
    MarionetteStackCast = 807038,
    MarionetteTransform = 807044,
    MarionetteExplosion = 706553,
    FoolsPlay = 681007,
    Avatar = 705943,
    Residual = 706543,
    LesserAvatar = 706544,
    VoljinBlessing = 706577,
    SpiritWalkerOne = 504459,
    SpiritWalkerTwo = 504636,
    ArrowTalent = 707854,
    JungleFieldSpell = 505212,
    SentryRevealSpell = 505173,
    Allcure = 804049,
    LinkTimer = 500992,
    SerpentAttackSpell = 573055,
    Veil = 802100,
    VeilDamage = 806473,
    JungleProtection = 572872,
    Amphibimorph = 500952,
    AutoShot = 75
};

enum DoctorCreatures : uint32
{
    NpcHealing = 50104,
    NpcSerpent = 50105,
    NpcSpiritIdol = 50106,
    NpcStasis = 50108,
    NpcSerene = 50116,
    NpcDark = 50117,
    NpcSwift = 50118,
    NpcShadow = 50119,
    NpcHexing = 50120,
    NpcCursed = 50121,
    NpcGraven = 50122,
    NpcGolem = 50129,
    NpcCleanse = 50217,
    NpcMassSerpent = 50587,
    NpcSentry = 51104,
    NpcViper = 51105,
    NpcJungle = 55117,
    NpcMimic = 300659,
    NpcFool = 300660,
    NpcMarionette = 300661,
    NpcBwonsamdi = 310659,
    NpcCauldron = 506011,
    NpcLink = 522106,
    NpcSpirit = 554239,
    NpcMirage = 840000
};
enum DoctorSlots : uint8
{
    WardSlot,
    IdolSlot,
    EffigySlot,
    MimicSlot,
    GolemSlot,
    CauldronSlot,
    VoodooSlot,
    NoSlot
};
enum DoctorAI : int32
{
    ActionMirror = 1,
    ActionExplode,
    DataSpell = 1,
    DataTarget,
    DataSource
};
struct DoctorState
{
    ObjectGuid previousBrew;
    std::vector<uint32> ingredients;
    std::vector<ObjectGuid> summons;
    uint32 update = 0;
    bool swapping = false;
    bool mojoPair = false;
};
inline bool Family(SpellInfo const* info, uint8 word, uint32 mask)
{
    return info && info->SpellFamilyName == 19 && (info->SpellFamilyFlags[word] & mask);
}
inline bool IsBeam(SpellInfo const* info)
{
    return Family(info, 1, 4194304);
}
inline bool IsHex(SpellInfo const* info)
{
    return Family(info, 1, 33554432) && info->Id != Umbral;
}
inline bool IsArrow(SpellInfo const* info)
{
    return Family(info, 1, 2147483648);
}
inline bool IsJuju(SpellInfo const* info)
{
    return Family(info, 2, 2);
}
inline bool IsBottle(SpellInfo const* info)
{
    return Family(info, 2, 1) && info->Id != Tiki;
}
inline bool IsPotion(SpellInfo const* info)
{
    return Family(info, 1, 2048);
}
inline bool IsSplash(SpellInfo const* info)
{
    return Family(info, 2, 536870912);
}
inline bool IsIngredient(uint32 id)
{
    return id == Shrooms || id == Fish || id == Bones || id == Thistle;
}
Player* Owner(Unit const* unit);
DoctorState& State(Player* player);
void Forget(Player* player);
std::list<Unit*> Nearby(Unit* center, float range);
std::list<Unit*> Allies(Player* player, Unit* center, float range, uint32 cap = 0);
bool Friendly(Player* player, Unit* target);
int32 Amount(uint32 id, uint8 effect = 0, Unit* caster = nullptr);
void Cast(Unit* caster, Unit* target, uint32 id);
void Copy(Unit* caster, Unit* target, uint32 id, uint32 amount);
uint8 Spirits(Player* player);
void GainSpirit(Player* player, uint8 count = 1);
void SyncSpirits(Player* player);
void Reduce(Player* player, uint32 root, int32 milliseconds);
uint32 KnownRank(Player* player, uint32 root);
Aura* OwnedHex(Player* player, Unit* target);
void SpreadHex(Player* player, Unit* target);
void IngredientChanged(Player* player, uint32 id, bool apply);
void SyncIngredients(Player* player);
void Mix(Player* player, uint32 mojo);
uint32 IngredientMask(Player* player);
void PotionEffects(Player* player, Unit* target, bool splash, uint32 mojo, uint32 ingredients);
void PruneSummons(Player* player);
void HealThroughEffigies(Player* player, Unit* primary, uint32 healing);
void Summon(Player* player, uint32 spell, Unit* target, Position const& position);
void Mirror(Player* player, Unit* target, uint32 spell);
bool HasSummon(Player* player, uint32 entry);
void WardBuff(Player* player, uint32 spell);
void ExplodeClones(Player* player);
void SyncReplacements(Player* player);
void ApplyContracts(SpellInfo* info);
}
#endif
