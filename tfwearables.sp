#include <sourcemod>
#include <tf2_stocks>
#include <tf2items>
#include <tf2attributes>
#include <morecolors>
#include <clientprefs>
#include <sdktools>

#pragma newdecls required // Force Transitional Syntax
#pragma semicolon 1 // Force semicolon mode

#define PLUGIN_VERSION "1.2"

// REF: https://developer.valvesoftware.com/wiki/Entity_limit
#define MAX_ENTITY_SIZE 4096

// GLOBALS
// Unforuantely methodmaps do not have the ability to define variables inside them, they are used as wrappers to keep data organized instead.
// MAXPLAYERS is a definition from SourceMod which will store players from 0 to 65 (This should be changed to MaxClients if server is over 65 slots, but that is a NO GO because SRCDS is not multithreaded and runs more than 32 players VERY POORLY)
int killStreakTier[MAXPLAYERS+1][MAX_ENTITY_SIZE]; // When setting or printing this value through our methodmap, we should add +1 to ensure it lines up correctly with slot range (starts at 1 not 0, ends at 3)
int killStreakSheen[MAXPLAYERS+1][MAX_ENTITY_SIZE];
int killStreakEffect[MAXPLAYERS+1][MAX_ENTITY_SIZE];
char unusualTauntEffect[MAXPLAYERS+1][64]; // Store selected unusual taunt affect in string array, we will be creating the particle manually and attaching it to the player.
int particleEntity[MAXPLAYERS+1]; // Used to track current particles created by our plugin, when player no longer needs them, we call DeleteParticle to ensure entity limit is not reached, see above.
Handle refireTimer[MAXPLAYERS+1]; // Handle to track unusual taunts with an expiry time.
int unusualHatEffect[MAXPLAYERS+1];

ArrayList hatIDList; // ArrayList to store all hat ids we can apply unusual effects too in-game

// temporary variables
// we are gonna use these to keep track of effect per slot in the menu handler
// once item is selected we can forget about these variables as they will be overwritten when player picks another option
// I don't know how else to implement slot selection via menu without creating two menu functions.
int tTier[MAXPLAYERS+1];
int tSheen[MAXPLAYERS+1];
int tEffect[MAXPLAYERS+1];

Database WearablesDB = null; // Setup database handle we will be using in our plugin.

// In an attempt to keep away from multiple implementations of practically the same code, store main menu options here.
char wearableMenuItems[][] = {
    "Killstreak Menu",
    "Unusual Taunts Menu",
    "Unusual Hats Menu"
};

// killStreakMenuItems showed on Killstreak Menu, does not need to match int array as we do nothing with the info other than display another menu.
char killStreakMenuItems[][] = {
    "Killstreak Tier",
    "Killstreak Sheen",
    "Killstreak Effect"
};

// killStreakTierMenuItems showed on Killstreak Tier Menu, matches killstreakType int array
char killStreakTierMenuItems[][] = {
    "Basic",
    "Specialized",
    "Professional"
};

// killStreakSheenMenuItems showed on Killstreak Effect menu, matches killStreakSheenSel int array
char killStreakSheenMenuItems[][] = {
    "Team Shine",
    "Deadly Daffodil",
    "Manndarin",
    "Mean Green",
    "Agonizing Emerald",
    "Villainous Violet",
    "Hot Rod"
};

// killStreakEffectMenuItems showed on Killstreak Effect menu, matches killStreakEffectSel int array
char killStreakEffectMenuItems[][] = {
    "Fire Horns",
    "Cerebral Discharge",
    "Tornado",
    "Flames",
    "Singularity",
    "Incinerator",
    "Hypno-Beam"
};

// weaponSlotMenuItems showed after selecting a killstreak tier, sheen or effect.
char weaponSlotMenuItems[][] = {
    "Primary",
    "Secondary",
    "Melee"
};

// unusualMenuItems showed when selecting Unusual Hat menu from main menu, all entries here are for display names only. Matches unusualHatSel int array.
char unusualMenuItems[][] = {
    "Green Confetti",
    "Purple Confetti",
    "Haunted Ghosts",
    "Green Energy",
    "Purple Energy",
    "Circling TF Logo",
    "Massed Flies",
    "Burning Flames",
    "Scorching Flames",
    "Sunbeams",
    "Map Stamps",
    "Stormy Storm",
    "Orbiting Fire",
    "Bubbling",
    "Smoking",
    "Steaming",
    "Cloudy Moon",
    "Kill-a-Watt",
    "Terror-Watt",
    "Cloud 9",
    "Time Warp",
    "Searing Plasma",
    "Vivid Plasma",
    "Circling Peace Sign",
    "Circling Heart",
    "Genteel Smoke",
    "Blizzardy Storm",
    "Nuts n' Bolts",
    "Orbiting Planets",
    "Flaming Lantern",
    "Cauldron Bubbles",
    "Eerie Orbiting Fire",
    "Knifestorm",
    "Misty Skull",
    "Harvest Moon",
    "It's a Secret to Everybody",
    "Stormy 13th Hour",
    "Aces High",
    "Dead Presidents",
    "Miami Nights",
    "Disco Beat Down",
    "Phosphorous",
    "Sulphurous",
    "Memory Leak",
    "Overclocked",
    "Electrostatic",
    "Power Surge",
    "Anti-Freeze",
    "Green Black Hole",
    "Roboactive",
    "Arcana",
    "Spellbound",
    "Chiroptera Venenata",
    "Poisoned Shadows",
    "Something Burning This Way Comes",
    "Hellfire",
    "Darkblaze",
    "Demonflame",
    "Bonzo The All-Gnawing",
    "Amaranthine",
    "Stare from Beyond",
    "The Ooze",
    "Ghastly Ghosts Jr",
    "Haunted Phantasm Jr",
    "Frostbite",
    "Molten Mallard",
    "Morning Glorly",
    "Death at Dusk",
    "Abduction",
    "Atomic",
    "Subatomic",
    "Electric Hat Protector",
    "Magnetic Hat Protector",
    "Voltaic Hat Protector",
    "Galactic Codex",
    "Ancient Codex",
    "Nebula",
    "Death by Disco",
    "It's a mystery to everyone",
    "It's a puzzle to me",
    "Ether Trail",
    "Nether Trail",
    "Ancient Eldritch",
    "Eldritch Flame",
    "Tesla Coil",
    "Neutron Star",
    "Starstorm Insomnia",
    "Starstorm Slumber",
    "Brain Drain",
    "Open Mind",
    "Head of Storm",
    "Galactic Gateway",
    "The Eldritch Opening",
    "The Dark Doorway",
    "Ring of Fire",
    "Vicious Circle",
    "White Lightning",
    "Omniscient Orb",
    "Clairvoyance",
    "Fifth Dimension",
    "Vicious Vortex",
    "Menacing Miasma",
    "Abyssal Aura",
    "Wicked Wood",
    "Ghastly Grove",
    "Mystical Medley",
    "Ethreal Essence",
    "Twisted Radiance",
    "Violet Vortex",
    "Verdant Vortex",
    "Valiant Vortex",
    "Sparkling Lights",
    "Frozen Icefall",
    "Fragmented Gluons",
    "Fragmented Quarks",
    "Fragmented Photons",
    "Defragmenting Reality",
    "Fragmenting Reality",
    "Refragmenting Reality",
    "Snowfallen",
    "Snowblinded",
    "Pyroland Daydream",
    "Verdatica",
    "Aromatica",
    "Chromatica",
    "Prismatica",
    "Bee Swarm",
    "Frisky Fireflies",
    "Smoldering Spirits",
    "Wandering Wasps",
    "Kaleidoscope",
    "Green Giggler",
    "Laugh-O-Lantern",
    "Plum Prankster",
    "Pyroland Nightmare",
    "Gravelly Ghoul",
    "Vexed Volcanics",
    "Gourdian Angel",
    "Pumpkin Party",
    "Frozen Fractals",
    "Lavender Landfall",
    "Special Snowfall",
    "Divine Desire",
    "Distant Dream",
    "Violent Wintertide",
    "Blighted Snowstorm",
    "Pale Nimbus",
    "Genus Plasmos",
    "Serenus Lumen",
    "Ventum Maris",
    "Mirthful Mistletoe",
    "Resonation",
    "Aggradation",
    "Lucidation",
    "Stunning",
    "Ardentum Saturnalis",
    "Fragrancium Elementalis",
    "Reverium Irregularis",
    "Perennial Petals",
    "Flavorsome Sunset",
    "Raspberry Bloom",
    "Iridescence",
    "Tempered Thorns",
    "Devilish Diablo",
    "Severed Serration",
    "Shrieking Shades",
    "Restless Wraiths",
    "Infernal Wraith",
    "Phantom Crown",
    "Ancient Specter",
    "Viridescent Peeper",
    "Eyes of Molten",
    "Ominous Stare",
    "Pumpkin Moon",
    "Frantic Spooker",
    "Frightened Poltergeist",
    "Energetic Haunter",
    "Smissmas Tree",
    "Hospitable Festivity",
    "Condescending Embrace",
    "Sparkling Spruce",
    "Glittering Juniper",
    "Prismatic Pine",
    "Spiraling Lights",
    "Twisting Lights",
    "Stardust Pathway",
    "Flurry Rush",
    "Spark of Smissmas",
    "Polar Forecast",
    "Shining Stag",
    "Holiday Horns",
    "Ardent Antlers",
    "Festive Lights",
    "Crustacean Sensation",
    "Frosted Decadence",
    "Sprinkled Delights",
    "Terrestrial Favor",
    "Tropical Thrill",
    "Flourishing Passion",
    "Dazzling Fireworks",
    "Blazing Fireworks",
    "Twinkling Fireworks",
    "Sparkling Fireworks",
    "Glowing Fireworks",
    "Flying Lights",
    "Limelight",
    "Shining Star",
    "Cold Cosmos",
    "Refracting Fractals",
    "Startrance",
    "Starlush",
    "Starfire",
    "Stardust",
    "Contagious Eruption",
    "Daydream Eruption",
    "Volcanic Eruption",
    "Divine Sunlight",
    "Audiophile",
    "Soundwave",
    "Synesthesia",
    "Haunted Kraken",
    "Eerie Kraken",
    "Soulful Slice",
    "Horsemann's Hack",
    "Haunted Forever!",
    "Forever And Forever!",
    "Cursed Forever!",
    "Moth Plague",
    "Malevolent Monoculi",
    "Haunted Wick",
    "Wicked Wick",
    "Spectral Wick",
    "Musical Maelstrom",
    "Verdant Virtuoso",
    "Silver Serenade",
    "Cosmic Constellations",
    "Dazzling Constellations",
    "Tainted Frost",
    "Starlight Haze",
    "Hard Carry",
    "Jellyfish Field",
    "Jellyfish Hunter",
    "Jellyfish Jam",
    "Global Clusters",
    "Celestial Starburst",
    "Sylicone Succiduous",
    "Sakura Smoke Bomb",
    "Treasure Trove",
    "Bubble Breeze",
    "Fireflies",
    "Mountain Halo",
};

// unusualTauntMenuItems showed when selecting Unusual Taunt menu from main menu, all entries here are for display names only. Matches unusualTauntMenuItemIds string array.
char unusualTauntMenuItems[][] = {
    "Showstopper (RED)",
    "Showstopper (BLU)",
    "Holy Grail",
    "'72",
    "Fountain of Delight",
    "Screaming Tiger",
    "Skill Gotten Gains",
    "Midnight Whirlwind",
    "Silver Cyclone",
    "Mega Strike",
    "Haunted Phantasm",
    "Ghastly Ghosts",
    "Hellish Inferno",
    "Roaring Rockets",
    "Acid Bubbles of Envy",
    "Flammable Bubbles of Attraction",
    "Poisonous Bubbles of Regret",
    "Bewitched",
    "Accursed",
    "Enchanted",
    "Static Mist",
    "Eerie Lightning",
    "Terrifying Thunder",
    "Jarate Shock",
    "Nether Void",
    "Good-Hearted Goodies",
    "Wintery Wisp",
    "Arctic Aurora",
    "Winter Spirit",
    "Festive Spirit",
    "Magical Spirit",
    "Spectral Escort", // May require TempEnt
    "Astral Presence", // May require TempEnt
    "Arcane Assistance (RED)", // May require TempEnt
    "Arcane Assistance (BLU)", // May require TempEnt
    "Emerald Allurement", // May require TempEnt
    "Pyrophoric Personality", // May require TempEnt
    "Spellbound Aspect", // May require TempEnt
    "Toxic Terrors", // May require TempEnt
    "Arachnid Assault", // May require TempEnt
    "Creepy Crawlies", // May require TempEnt
    "Delightful Star", // May require TempEnt
    "Frosted Star", // May require TempEnt
    "Apotheosis", 
    "Ascension", 
    "Twinkling Lights", // May require TempEnt 
    "Shimmering Lights", // May require TempEnt
    "Cavalier de Carte (RED)", 
    "Cavalier de Carte (BLU)",
    "Hollow Flourish", 
    "Magic Shuffle",
    "Vigorous Pulse",
    "Thundering Spirit",
    "Galvanic Defiance",
    "Wispy Halos", // May require TempEnt
    "Nether Wisps", // May require TempEnt
    "Aurora Borealis", // May require TempEnt
    "Aurora Australis", // May require TempEnt
    "Aurora Polaris", // May require TempEnt
    "Amethyst Winds", // May require TempEnt
    "Golden Gusts", // May require TempEnt
    "Smissmas Swirls (RED)", // May require TempEnt
    "Smissmas Swirls (BLU)", // May require TempEnt
    "Minty Cypress",
    "Pristine Pine",
    "Sparkly Spruce (RED)",
    "Sparkly Spruce (BLU)",
    "Festive Fever (RED)",
    "Festive Fever (BLU)",
    "Golden Glimmer",
    "Frosty Silver",
    "Glamorous Dazzle (RED)",
    "Glamorous Dazzle (BLU)",
    "Sublime Snowstorm",
    "Marigold Ritual (RED)",
    "Marigold Ritual (BLU)",
    "Linguistic Deviation",
    "Aurelian Seal",
    "Runic Imprisonment (RED)",
    "Runic Imprisonment (BLU)",
    "Prismatic Haze",
    "Rising Ritual (RED)",
    "Rising Ritual (BLU)",
    "Bloody Grip (RED)",
    "Bloody Grip (BLU)",
    "Toxic Grip",
    "Infernal Grip",
    "Death Grip",
    "Charged Arcane",
    "Thunderous Rage",
    "Convulsive Fiery",
    "Festivized Formation (RED)",
    "Festivized Formation (BLU)",
    "Boundless Blizzard",
    "Floppin' Frenzy",
    "Pastel Trance (RED)",
    "Pastel Trance (BLU)",
    "Wildflower Meadows"
};

// These are the unusual taunt menu item id's as matched in items_game.txt of TF2
// REF: https://wiki.teamfortress.com/wiki/Item_schema
char unusualTauntMenuItemIds[][] = {
    "utaunt_firework_teamcolor_red", // Showstopper (RED)
    "utaunt_firework_teamcolor_blue", // Showstopper (BLU)
    "utaunt_beams_yellow", // Holy Grail
    "utaunt_disco_party", // '72
    "utaunt_hearts_glow_parent", // Fountain of Delight
    "utaunt_meteor_parent", // Screaming Tiger
    "utaunt_cash_confetti", // Skill Gotten Gains
    "utaunt_tornado_parent_black", // Midnight Whirlwind
    "utaunt_tornado_parent_white", // Silver Cyclone
    "utaunt_lightning_parent", // Mega Strike
    "utaunt_souls_green_parent", // Haunted Phantasm
    "utaunt_souls_purple_parent", // Ghastly Ghosts
    "utaunt_hellpit_parent", // Hellish Inferno
    "utaunt_firework_dragon_parent", // Roaring Rockets
    "utaunt_bubbles_glow_green_parent", // Acid Bubbles of Envy
    "utaunt_bubbles_glow_orange_parent", // Flammable Bubbles of Attraction
    "utaunt_bubbles_glow_purple_parent", // Poisonous Bubbles of Regret
    "utaunt_arcane_purple_parent", // Bewitched
    "utaunt_arcane_green_parent", // Accursed
    "utaunt_arcane_yellow_parent", // Enchanted
    "utaunt_electric_mist_parent", // Static Mist
    "utaunt_electricity_cloud_parent_WP", // Eerie Lightning
    "utaunt_electricity_cloud_parent_WB", // Terrifying Thunder
    "utaunt_electricity_cloud_parent_WY", // Jarate Shock
    "utaunt_portalswirl_purple_parent", // Nether Void
    "utaunt_present_parent", // Good-Hearted Goodies
    "utaunt_snowring_icy_parent", // Wintery Wisp
    "utaunt_snowring_space_parent", // Arctic Aurora
    "utaunt_spirit_winter_parent", // Winter Spirit
    "utaunt_spirit_festive_parent", // Festive Spirit
    "utaunt_spirit_magical_parent", // Magical Spirit
    "utaunt_astralbodies_greenorange_parent", // Spectral Escort
    "utaunt_astralbodies_tealpurple_parent", // Astral Presence
    "utaunt_astralbodies_teamcolor_red", // Arcane Assistance (RED)
    "utaunt_astralbodies_teamcolor_blue", // Arcane Assistance (BLU)
    "utaunt_glowyplayer_green_parent", // Emerald Allurement
    "utaunt_glowyplayer_orange_parent", // Pyrophoric Personality
    "utaunt_glowyplayer_purple_parent", // Spellbound Aspect
    "utaunt_spider_green_parent", // Toxic Terrors
    "utaunt_spider_orange_parent", // Arachnid Assault
    "utaunt_spider_purple_parent", // Creepy Crawlies
    "utaunt_tf2smissmas_tree_parent", // Delightful Star
    "utaunt_tf2smissmas_tree_parent_w", // Frosted Star
    "utaunt_spirits_blue_parent", // Apotheosis
    "utaunt_spirits_purple_parent", // Ascension
    "utaunt_twinkling_rgb_parent", // Twinkling Lights
    "utaunt_twinkling_goldsilver_parent", // Shimmering Lights
    "utaunt_tarotcard_teamcolor_red", // Cavalier de Carte (RED)
    "utaunt_tarotcard_teamcolor_blue", // Cavalier de Carte (BLU)
    "utaunt_tarotcard_orange_parent", // Hollow Flourish
    "utaunt_tarotcard_purple_parent", // Magic Shuffle
    "utaunt_elebound_green_parent", // Vigorous Pulse
    "utaunt_elebound_purple_parent", // Thundering Spirit
    "utaunt_elebound_yellow_parent", // Galvanic Defiance
    "utaunt_wispy_parent_g", // Wispy Halos
    "utaunt_wispy_parent_p", // Nether Wisps
    "utaunt_auroraglow_green_parent", // Aurora Borealis
    "utaunt_auroraglow_orange_parent", // Aurora Australis
    "utaunt_auroraglow_purple_parent", // Aurora Polaris
    "utaunt_snowswirl_purple_parent", // Amethyst Winds
    "utaunt_snowswirl_yellow_parent", // Golden Gusts
    "utaunt_snowswirl_teamcolor_red", // Smissmas Swirls (RED)
    "utaunt_snowswirl_teamcolor_blue", // Smissmas Swirls (BLU)
    "utaunt_treespiral_green_parent", // Minty Cypress
    "utaunt_treespiral_purple_parent", // Pristine Pine
    "utaunt_treespiral_teamcolor_red", // Sparkly Spruce (RED)
    "utaunt_treespiral_teamcolor_blue", // Sparkly Spruce (BLU)
    "utaunt_gifts_teamcolor_red", // Festive Fever (RED)
    "utaunt_gifts_teamcolor_blue", // Festive Fever (BLU)
    "utaunt_glitter_parent_gold", // Golden Glimmer
    "utaunt_glitter_parent_silver", // Frosty Silver
    "utaunt_glitter_teamcolor_red", // Glamorous Dazzle (RED)
    "utaunt_glitter_teamcolor_blue", // Glamorous Dazzle (BLU)
    "utaunt_ice_parent", // Sublime Snowstorm
    "utaunt_marigoldritual_teamcolor_red", // Marigold Ritual (RED)
    "utaunt_marigoldritual_teamcolor_blue", // Marigold Ritual (BLU)
    "utaunt_runeprison_green_parent", // Linguistic Deviation
    "utaunt_runeprison_yellow_parent", // Aurelian Seal
    "utaunt_runeprison_teamcolor_red", // Runic Imprisonment (RED)
    "utaunt_runeprison_teamcolor_blue", // Runic Imprisonment (BLU)
    "utaunt_prismatichaze_parent", // Prismatic Haze
    "utaunt_risingsprit_teamcolor_red", // Rising Ritual (RED)
    "utaunt_risingsprit_teamcolor_blue", // Rising Ritual (BLU)
    "utaunt_hands_teamcolor_red", // Bloody Grip (RED)
    "utaunt_hands_teamcolor_blue", // Bloody Grip (BLU)
    "utaunt_hands_green_parent", // Toxic Grip
    "utaunt_hands_orange_parent", // Infernal Grip
    "utaunt_hands_purple_parent", // Death Grip
    "utaunt_storm_parent_g", // Charged Arcane
    "utaunt_storm_parent_k", // Thunderous Rage
    "utaunt_storm_parent_o", // Convulsive Fiery
    "utaunt_festivelights_teamcolor_red", // Festivized Formation (RED)
    "utaunt_festivelights_teamcolor_blue", // Festivized Formation (BLU)
    "utaunt_snowflakesaura_parent", // Boundless Blizzard
    "utaunt_fish_parent", // Floppin' Frenzy
    "utaunt_rainbow_teamcolor_red", // Pastel Trance (RED)
    "utaunt_rainbow_teamcolor_blue", // Pastel Trance (BLU)
    "utaunt_wild_meadows_parent" // Wildflower Meadows
};

// All possible menus which can be created, I have given them an ID order of +1 to keep it simple.
enum wearablesOptions {
    wearablesMenu = 0,
    killStreakMenu = 1,
    unusualTauntMenu = 2,
    killStreakTierMenu = 3,
    killStreakSheenMenu = 4,
    killStreakEffectMenu = 5,
    slotSelectMenu = 6,
    unusualMenu = 7
};

// These are all the different unusual effects which can be applied to a players hat. Matches with unusualMenuItems string array.
int unusualHatSel[] = {
    6, // Green Confetti
    7, // Purple Confetti
    8, // Haunted Ghosts
    9, // Green Energy
    10, // Purple Energy
    11, // Circling TF Logo
    12, // Massed Flies
    13, // Burning Flames
    14, // Scorching Flames
    17, // Sunbeams
    20, // Map Stamps
    29, // Stormy Storm
    33, // Orbiting Fire
    34, // Bubbling
    35, // Smoking
    36, // Steaming
    38, // Cloudy Moon
    56, // Kill-a-Watt,
    57, // Terror-Watt,
    58, // Cloud 9
    70, // Time Warp,
    15, // Searing Plasma
    16, // Vivid Plasma
    18, // Circling Peace Sign
    19, // Circling Heart
    28, // Genteel Smoke,
    30, // Blizzardy Storm,
    31, // Nuts n' Bolts,
    32, // Orbiting Planets,
    37, // Flaming Lantern,
    39, // Cauldron Bubbles
    40, // Eerie Orbiting Fire,
    43, // Knifestorm
    44, // Misty Skull
    45, // Harvest Moon
    46, // It's a Secret to Everybody
    47, // Stormy 13th Hour
    59, // Aces High
    60, // Dead Presidents
    61, // Miami Nights
    62, // Disco Beat Down
    63, // Phosphorous
    64, // Sulphurous
    65, // Memory Leak
    66, // Overclocked
    67, // Electrostatic
    68, // Power Surge
    69, // Anti-Freeze
    71, // Green Black Hole
    72, // Roboactive
    73, // Arcana
    74, // Spellbound
    75, // Chiroptera Venenata
    76, // Poisoned Shadows
    77, // Something Burning This Way Comes
    78, // Hellfire
    79, // Darkblaze
    80, // Demonflame
    81, // Bonzo The All-Gnawing,
    82, // Amaranthine
    83, // Stare from Beyond
    84, // The Ooze
    85, // Ghastly Ghosts Jr
    86, // Haunted Phantasm Jr
    87, // Frostbite
    88, // Molten Mallard
    89, // Morning Glory
    90, // Death at Dusk
    91, // Abduction
    92, // Atomic
    93, // Subatomic
    94, // Electric Hat Protector
    95, // Magnetic Hat Protector
    96, // Voltaic Hat Protector
    97, // Galactic Codex
    98, // Ancient Codex
    99, // Nebula
    100, // Death By Disco
    101, // It's a mystery to everyone
    102, // It's a puzzle to me
    103, // Ether Trail
    104, // Nether Trail
    105, // Ancient Eldritch
    106, // Eldritch Flame
    108, // Tesla Coil
    107, // Neutron Star
    109, // Starstorm Insomnia
    110, // Starstorm Slumber
    111, // Brain Drain
    112, // Open Mind
    113, // Head of Steam
    114, // Galactic Gateway
    115, // The Eldritch Opening
    116, // The Dark Doorway
    117, // Ring of Fire
    118, // Vicious Circle
    119, // White Lightning
    120, // Omniscient Orb
    121, // Clairvoyance
    122, // Fifth Dimension
    123, // Vicious Vortex
    124, // Menacing Miasma,
    125, // Abyssal Aura
    126, // Wicked Wood
    127, // Ghastly Grove
    128, // Mystical Medley
    129, // Ethereal Essence
    130, // Twisted Radiance
    131, // Violet Vortex
    132, // Verdant Vortex
    133, // Vallant Vortex
    134, // Sparkling Lights
    135, // Frozen Icefall
    136, // Fragmented Gluons
    137, // Fragmented Quarks
    138, // Fragmented Photons
    139, // Defragmenting Reality
    141, // Fragmenting Reality
    142, // Refragmenting Reality
    143, // Snowfallen
    144, // Snowblinded
    145, // Pyroland Daydream
    147, // Verdatica
    148, // Aromatica
    149, // Chromatica
    150, // Prismatica
    151, // Bee Swarm
    152, // Frisky Fireflies
    153, // Smoldering Spirits
    154, // Wandering Wisps
    155, // Kaleidoscope
    156, // Green Giggler
    157, // Laugh-O-Lantern
    158, // Plum Prankster
    159, // Pyroland Nightmare
    160, // Gravelly Ghoul
    161, // Vexed Volcanics
    162, // Gourdian Angel
    163, // Pumpkin Party
    164, // Frozen Fractals
    165, // Lavender Landfall
    166, // Special Snowfall
    167, // Divine Desire
    168, // Distant Dream
    169, // Violent Watertide
    170, // Blighted Snowstorm
    171, // Pale Nimbus
    172, // Genus Plasmos
    173, // Serenus Lumen
    174, // Ventum Maris
    175, // Mirthful Mistletoe
    177, // Resonation
    178, // Aggradation
    179, // Lucidation
    180, // Stunning
    181, // Ardentum Saturnalis 
    182, // Fragrancium Elementalis
    183, // Reverium Irregularis
    185, // Perennial Petals
    186, // Flavorsome Sunset
    187, // Raspberry Bloom
    188, // Iridescence
    189, // Tempered Thorns
    190, // Devilish Diablo
    191, // Severed Serration
    192, // Shrieking Shades
    193, // Restless Wraiths
    195, // Infernal Wraith
    196, // Phantom Crown
    197, // Ancient Specter,
    198, // Viridescent Peeper 
    199, // Eyes of Molten
    200, // Ominous Stare 
    201, // Pumpkin Moon
    202, // Frantic Spooker 
    203, // Frightened Poltergeist
    204, // Energetic Hunter
    205, // Smissmas Tree
    206, // Hospitable Festivity
    207, // Condescending Embrace
    209, // Sparkling Spruce
    210, // Glittering Juniper
    211, // Prismatic Pine
    212, // Spiraling Lights
    213, // Twisting Lights
    214, // Stardust Pathway
    215, // Flurry Rush
    216, // Spark of Smissmas
    218, // Polar Forecast
    219, // Shining Stag
    220, // Holiday Horns
    221, // Ardent Antlers
    223, // Festive Lights
    224, // Crustacean Sensation 
    226, // Frosted Decadence
    228, // Sprinkled Delights 
    229, // Terrestial Favor
    230, // Tropical Thrill
    231, // Flourishing Passion
    232, // Dazzling Fireworks
    233, // Blazing Fireworks
    235, // Twinkling Fireworks
    236, // Sparkling Fireworks
    237, // Glowing Fireworks
    239, // Flying Lights
    241, // Limelight
    242, // Shining Star
    243, // Cold Cosmos
    244, // Refracting Fractals
    245, // Startrance
    247, // Starlush
    248, // Starfire
    249, // Stardust
    250, // Contagious Eruption
    251, // Daydream Eruption
    252, // Volcanic Eruption
    253, // Divine Sunlight
    254, // Audiophile
    255, // Soundwave
    256, // Synesthesia
    257, // Haunted Kraken
    258, // Eerie Kraken
    259, // Soulful Slice
    260, // Horsemann's Hack
    261, // Haunted Forever!
    263, // Forever And Forever!
    264, // Cursed Forever!
    265, // Moth Plague
    266, // Malevolent Monoculi
    267, // Haunted Wick
    269, // Wicked Wick
    270, // Spectral Wick
    271, // Musical Maelstrom
    272, // Verdant Virtuoso
    273, // Silver Serenade
    274, // Cosmic Constellations
    276, // Dazzling Constellations
    277, // Tainted Frost
    278, // Starlight Haze 
    279, // Hard Carry
    281, // Jellyfish Field
    283, // Jellyfish Hunter
    284, // Jellyfish Jam
    285, // Global Clusters
    286, // Celestial Starburst
    287, // Sylicone Succiduous
    288, // Sakura Smoke Bomb
    289, // Treasure Trove
    290, // Bubble Breeze
    291, // Fireflies
    292, // Mountain Halo
};

// These are the three different type of effects which can be applied to a single weapon slot. Matches killStreakTierMenuItems string array.
int killStreakTierSel[] = {
    0, // Basic
    1, // Specialized
    2 // Professional
};

// These are all different types of Killstreak sheens which can be applied to a single weapon slot. Matches killStreakSheenMenuItems string array.
int killStreakSheenSel[] = {
    1, // Team Shine
    2, // Deadly Daffodil
    3, // Manndarin
    4, // Mean Green
    5, // Agonizing Emerald
    6, // Villainous Violet
    7 // Hot Rod
};

// These are all different types of Killstreak effects which can be applied to a single weapon slot. Matches killStreakEffectMenuItems string array.
int killStreakEffectSel[] = {
    2002, // Fire Horns
    2003, // Cerebral Discharge
    2004, // Tornado
    2005, // Flames
    2006, // Singularity
    2007, // Incinerator
    2008 // Hypno Beam
};

// ConVars
// These are server side settings which the server administrator can change to help tailor the plugin to their specific use case.
// Defined ConVars are just wrappers for handles which allow the plugin to manage the state of a ConVar
ConVar cEnabled; // Is the plugin enabled?
ConVar cDatabaseName; // Name of database to connect to inside of databases.cfg REF: https://wiki.alliedmods.net/SQL_(SourceMod_Scripting)#Connecting
ConVar cTableName; // Name of table created / read from inside the database.

public Plugin myinfo =  {
	name = "[TF2] Wearables", 
	author = "keybangz", 
	description = "Allows players to use a menu to pick custom attributes for there weapons or player.", 
	version = PLUGIN_VERSION, 
	url = "https://github.com/keybangz", 
};

public void OnPluginStart() {
    // Version ConVar, used on AlliedModders forum to check count of servers running this plugin.
    CreateConVar("tf_wearables_version", PLUGIN_VERSION, "Wearables Version (Do not touch).", FCVAR_NOTIFY | FCVAR_REPLICATED);
    cEnabled = CreateConVar("tf_wearables_enabled", "1", "Enable TF2 wearables plugin?", _, true, 0.0, true, 1.0);
    cDatabaseName = CreateConVar("tf_wearables_db", "wearables", "Name of the database connecting to store player data.", _, false, _, false, _);
    cTableName = CreateConVar("tf_wearables_table", "wearables", "Name of the table holding the player data in the database.", _, false, _, false, _);

    // In-game events the plugin should listen to.
    // If other plugins are manually invoking these events, THESE EVENTS WILL FIRE. (Bad practice to manually invoke events anyways)
    HookEvent("post_inventory_application", OnResupply); // When player touches resupply locker, respawns or manually invokes a refresh of player items.

    // Admin Commands
    RegAdminCmd("sm_wearables", WearablesCommand, ADMFLAG_RESERVATION, "Shows the wearables menu."); // Translates to /wearables in-game 

    // Initialize new ArrayList to store all hat id's inside game, used in ReadItemSchema()
    hatIDList = new ArrayList();

    ReadItemSchema();

    // Setup database connection.
    char dbname[64];
    cDatabaseName.GetString(dbname, sizeof(dbname)); // Grab database ConVar string value and store to buffer.

    // Connect to database here.
    Database.Connect(DatabaseHandler, dbname); // Pass string buffer to connect method.
}

// Here we will setup the SQL table to store player preferences.
// GOAL: Support MySQL and SQLite(?)
public void DatabaseHandler(Database db, const char[] error, any data) {
    if(!cEnabled.BoolValue) // If plugin is not enabled, do nothing.
        return;

    if(db == null) // Ensure databases.cfg settings are correct.
        LogError("Database failure: %s", error); // If anything fails, report back to server.

    WearablesDB = db; // Set global database handle to newly connected to database set out in databases.cfg

    char query[512]; // Buffer to store query in.
    char buffer[256]; // Alternative buffer used to store desired ConVar values and use with query.

    cTableName.GetString(buffer, sizeof(buffer));
    // TABLE LAYOUT
    // id - incremental id to append to each player
    // steamid - store unique player SteamID32 REF: https://steamid.io/
    // primaryTier - Primary weapon tier selected by player
    // primarySheen - Primary weapon sheen selected by player
    // primaryEffect - Priamry weapon effect selected by player
    // secondaryTier - Secondary weapon tier selected by player
    // secondarySheen - Secondary weapon sheen selected by player
    // secondaryEffect - Secondary weapon effect selected by player
    // meleeTier - Melee weapon tier selected by player
    // meleeSheen - Melee weapon sheen selected by player
    // meleeEffect - Melee weapon effect selected by player.
    // unusualTauntId - Unusual taunt effect selected by player.
    // unusualHatId - Unusual hat effect selected by player.
    FormatEx(query, sizeof(query), "CREATE TABLE IF NOT EXISTS %s (id int(11) NOT NULL AUTO_INCREMENT, steamid varchar(32) UNIQUE, primaryTier int(11), primarySheen int(11), primaryEffect int(11), secondaryTier int(11), secondarySheen int(11), secondaryEffect int(11), meleeTier int(11), meleeSheen int(11), meleeEffect int(11), unusualTauntId varchar(64), unusualHatId int(11), PRIMARY KEY (id))", buffer);
    WearablesDB.Query(SQLError, query); // Query to SQL error callback, since we do nothing with data when creating table.
}

// SQLError
// Standard SQL callback to process errors for any queries that are used throughout the plugin, any queries which take and redefine data will have their own callback.
public void SQLError(Database db, DBResultSet results, const char[] error, any data) {
    if(!cEnabled.BoolValue) // If plugin is not enabled, do nothing.
        return;

    if(results == null)
        LogError("Query failure: %s", error);
}

// Our main methodmap, this provides us with all functions required to assign desired effects to the desired player.
methodmap Player {
    public Player(int userid) { // Constructor of methodmap
        if(IsClientInGame(userid))
            return view_as<Player>(GetClientUserId(userid)); // Will return index of Player entry in methodmap, note this does not reflect the client unless we assign the client to the methodmap first.
        return view_as<Player>(-1); // We want to ensure we hold no null / disconnected players even in our constructor.
    }
    // Apparently this gets overwritten when player entity list ticks over max count
    // First player on server -> Server gets full -> First player leaves -> New player joins -> New player takes index of first player
    // From my own testing with just a single person, this doesn't seem to be the case?
    // If run into issues, get index by userid and convert when needed.
    property int index { // Returns player index so we can apply effects when needed.
        public get() { return view_as<int>(this); }
    }
    // Was previously using real methodmap setters and getters for this, however we want the ability to set effects to desired slot and we cannot pass more than 1 parameter to setters in SourceMod.
    // Update: .get methodmap function on property was not returning anything?, just use standard function for now.
    // Get players current killstreak tier on desired slot.
    public int GetKillstreakTierId(int slot) {
        return killStreakTier[this.index][slot];
    }
    // Get players current killstreak sheen on desired slot.
    public int GetKillstreakSheenId(int slot) {
        return killStreakSheen[this.index][slot];
    }
    // Get players current killstreak effect on desired slot.
    public int GetKillstreakEffectId(int slot) {
        return killStreakEffect[this.index][slot];
    }
    // Get players current unusual taunt effect and stores them into destination buffer.
    public void GetUnusualTauntEffectId(char[] val, int length) {
        strcopy(val, length, unusualTauntEffect[this.index]);
    }
    public int GetUnusualHatEffectId() {
        return unusualHatEffect[this.index];
    }
    // Set players selected killstreak tier on desired slot.
    public void SetKillstreakTierId(int val, int slot) {
        killStreakTier[this.index][slot] = val;
    }
    // Set players selected killstreak sheen on desired slot.
    public void SetKillstreakSheenId(int val, int slot) {
        killStreakSheen[this.index][slot] = val;
    }
    // Set players selected killstreak effect on desired slot.
    public void SetKillstreakEffectId(int val, int slot) {
        killStreakEffect[this.index][slot] = val;
    }
    // Set players selected unusual taunt effect.
    public void SetUnusualTauntEffectId(char[] val) {
        strcopy(unusualTauntEffect[this.index], sizeof(unusualTauntEffect), val);
    }
    public void SetUnusualHatEffectId(int val) {
        unusualHatEffect[this.index] = val;
    }
}

// Our goal here from version 1 is too minimize the amount of repitition the previous codebase had used.
// To do this we will strip a lot of logic into single functions and determine the use case based on the parameters passed.
// We want to organize our code into a methodmap or some sort of structured way to prevent recreation of variables that we don't need.
// Unlike the previous version, we will be using SQLite or MySQL to store player preferences, this will provide us with a cleaner codebase and remove the hassle of cookie caching and verification.

// Unusual effects cannot be fetched & applied fast enough to update before player spawns, here we'll grab Unusual Taunt + Unusual Hat Effect and set them since we can do that without any extra information. (such as weapon slots)
public void OnClientPutInServer(int client) {
    int userid = GetClientUserId(client); // Pass through client userid to validate & update player data in handler.
    char buffer[256]; // Buffer used to store temporary values in FetchWearables
    char query[256]; // Buffer used to store queries sent to database.

    // REF: https://sm.alliedmods.net/new-api/clients/AuthIdType
    char steamid[32]; // Buffer to store SteamID32
    if(!GetClientAuthId(client, AuthId_Steam2, steamid, sizeof(steamid))) // Grab player SteamID32, if fails do nothing.
        return;

    cTableName.GetString(buffer, sizeof(buffer)); // Grab table name string value
    FormatEx(query, sizeof(query), "SELECT unusualTauntId, unusualHatId FROM %s WHERE steamid='%s'", buffer, steamid); // Setup query to select effects only if matching steamid.
    WearablesDB.Query(updateEffectsEarly, query, userid);
}

// I would totally prefer not to do an early fetch and fetch all information at once, but hey not everything can be perfect.
// (Suggestions open)
void updateEffectsEarly(Database db, DBResultSet results, const char[] error, any data) {
    int client = 0;

    if(db == null || results == null || error[0] != '\0') { // If database handle or results are null, log error also check if error buffer has anything stored.
        LogError("Query failed! error: %s", error);
        return;
    }

    char buffer[64]; // Buffer to fetch unusualTauntId's

    // If userid passed to callback is invalid, do nothing.
    if((client = GetClientOfUserId(data)) == 0)
        return;

    Player player = Player(client);

    // Early update both unusualTauntId and unusualHatId if player is found in database.
    while(results.FetchRow()) {
        // unusualTauntId
        if(!SQL_IsFieldNull(results, 0)) {
            results.FetchString(0, buffer, sizeof(buffer));
            player.SetUnusualTauntEffectId(buffer);
        }

        // unusualHatId
        if(!SQL_IsFieldNull(results, 1))
            player.SetUnusualHatEffectId(results.FetchInt(1));
    }
}

// FetchWearables - Used to fetch all data that might be already stored for the player inside the database.
void FetchWearables(int client, char[] steamid) {
    int userid = GetClientUserId(client); // Pass through client userid to validate & update player data in handler.
    char buffer[256]; // Buffer used to store temporary values in FetchWearables
    char query[256]; // Buffer used to store queries sent to database.

    cTableName.GetString(buffer, sizeof(buffer)); // Grab table name string value
    FormatEx(query, sizeof(query), "SELECT primaryTier, primarySheen, primaryEffect, secondaryTier, secondarySheen, secondaryEffect, meleeTier, meleeSheen, meleeEffect, unusualTauntId, unusualHatId FROM %s WHERE steamid='%s'", buffer, steamid); // Setup query to select effects only if matching steamid.
    WearablesDB.Query(FetchWearablesHandler, query, userid);

    // If player does not exist in table, add players steamid to table.
    FormatEx(query, sizeof(query), "INSERT IGNORE INTO %s(steamid) VALUES('%s')", buffer, steamid);
    WearablesDB.Query(SQLError, query);
}

// FetchWearablesHandler - Callback used to set wearable effects set by player.
void FetchWearablesHandler(Database db, DBResultSet results, const char[] error, any data) {
    int client = 0; // We will need to pass through client with userid.

    if(db == null || results == null || error[0] != '\0') { // If database handle or results are null, log error also check if error buffer has anything stored.
        LogError("Query failed! error: %s", error);
        return;
    }

    char buffer[64]; // Buffer to fetch unusualTauntId's

    // If userid passed to callback is invalid, do nothing.
    if((client = GetClientOfUserId(data)) == 0)
        return;

    int primary = GetPlayerWeaponSlot(client, TFWeaponSlot_Primary);
    int secondary = GetPlayerWeaponSlot(client, TFWeaponSlot_Secondary);
    int melee = GetPlayerWeaponSlot(client, TFWeaponSlot_Melee);

    Player player = Player(client);

    // Grab row of data provided by SQL query.
    while(results.FetchRow()) {
        // Here we've got to check each individual field and check if it's null before attempting to grab or update data.
        // Goes in order with query, meaning primaryTier = 0, primarySheen = 1, primaryEffect = 2, and so on.
        // primaryTier
        if(!SQL_IsFieldNull(results, 0))
            player.SetKillstreakTierId(results.FetchInt(0), primary);

        // primarySheen
        if(!SQL_IsFieldNull(results, 1))
            player.SetKillstreakSheenId(results.FetchInt(1), primary);

        // primaryEffect
        if(!SQL_IsFieldNull(results, 2))
            player.SetKillstreakEffectId(results.FetchInt(2), primary);

        // secondaryTier
        if(!SQL_IsFieldNull(results, 3))
            player.SetKillstreakTierId(results.FetchInt(3), secondary);

        // secondarySheen
        if(!SQL_IsFieldNull(results, 4))
            player.SetKillstreakSheenId(results.FetchInt(4), secondary);

        // secondaryEffect
        if(!SQL_IsFieldNull(results, 5))
            player.SetKillstreakEffectId(results.FetchInt(5), secondary);

        // meleeTier
        if(!SQL_IsFieldNull(results, 6))
            player.SetKillstreakTierId(results.FetchInt(6), melee);

        // meleeSheen
        if(!SQL_IsFieldNull(results, 7))
            player.SetKillstreakSheenId(results.FetchInt(7), melee);

        // meleeEffect
        if(!SQL_IsFieldNull(results, 8))
            player.SetKillstreakEffectId(results.FetchInt(8), melee);

        // unusualTauntId
        if(!SQL_IsFieldNull(results, 9)) {
            results.FetchString(9, buffer, sizeof(buffer));
            player.SetUnusualTauntEffectId(buffer);
        }

        // unusualHatId
        if(!SQL_IsFieldNull(results, 10)) 
            player.SetUnusualHatEffectId(results.FetchInt(10));
    }
}

// UpdateWearables() - Responsible for updating effects per player to the database.
void UpdateWearables(int client, char[] steamid) {
    char query[512];
    char buffer[256];

    Player player = Player(client); // Initalize player methodmap

    // Since we are working off of player slots, the player must be alive when we update the database.
    int primary = GetPlayerWeaponSlot(client, TFWeaponSlot_Primary);
    int secondary = GetPlayerWeaponSlot(client, TFWeaponSlot_Secondary);
    int melee = GetPlayerWeaponSlot(client, TFWeaponSlot_Melee);

    char effect[MAXPLAYERS+1][64]; // String to store current unusual taunt effect into
    player.GetUnusualTauntEffectId(effect[client], sizeof(effect)); // Store unusual taunt effect to buffer to use below.

    cTableName.GetString(buffer, sizeof(buffer));
    // This formatting part is a little ugly, here's a quick rundown.
    // Updates the players selected effect in the database by grabbing the values from our Player methodmap.
    FormatEx(query, sizeof(query), "UPDATE %s SET primaryTier='%i', primarySheen='%i', primaryEffect='%i', secondaryTier='%i', secondarySheen='%i', secondaryEffect='%i', meleeTier='%i', meleeSheen='%i', meleeEffect='%i', unusualTauntId='%s', unusualHatId='%i' WHERE steamid='%s'", buffer, player.GetKillstreakTierId(primary), player.GetKillstreakSheenId(primary), player.GetKillstreakEffectId(primary), player.GetKillstreakTierId(secondary), player.GetKillstreakSheenId(secondary), player.GetKillstreakEffectId(secondary), player.GetKillstreakTierId(melee), player.GetKillstreakSheenId(melee), player.GetKillstreakEffectId(melee), effect[client], player.GetUnusualHatEffectId(), steamid);
    WearablesDB.Query(SQLError, query);
}

// TF2_OnConditionAdded is an event which SourceMod listens to natively, here we can check different player conditions (ex: jumping, taunting, etc etc)
// Check if player is taunting, if so add desired effect to player.
public void TF2_OnConditionAdded(int client, TFCond condition) {
    if(!cEnabled.BoolValue) // If plugin is not enabled, do nothing.
        return;

    if(!IsClientInGame(client) || !IsPlayerAlive(client)) // Self explanatory
        return;
    
    if(condition != TFCond_Taunting)
        return;

    Player player = Player(client); // Initalize player methodmap
    char effect[MAXPLAYERS+1][64]; // String to store current unusual taunt effect into
    player.GetUnusualTauntEffectId(effect[client], sizeof(effect)); // Grab player current unusual effect and store into destination buffer

    // AttachParticle(client, effect[client]); // Create and attach desired particle effect to player.
    CreateTempParticle(effect[client], client);

    DataPack pack; // Create a datapack which we will use for refire timings below.

    // Here we will re-attach any particles with an expiry time
    // I would much rather check the players taunt in the timer handler, however different taunts have different expiry times.
    // REF: https://wiki.teamfortress.com/wiki/Item_schema
    if(StrEqual(effect[client], "utaunt_firework_teamcolor_red")) { // Showstopper (RED) expires every 2.6 seconds according to latest items_game.txt
        refireTimer[client] = CreateDataTimer(2.6, HandleRefire, pack, TIMER_REPEAT);
        pack.WriteCell(client);
        pack.WriteString(effect[client]);
    } else if(StrEqual(effect[client], "utaunt_firework_teamcolor_blue")) { // Showstopper (BLU) expires every 2.6 seconds according to latest items_game.txt
        refireTimer[client] = CreateDataTimer(2.6, HandleRefire, pack, TIMER_REPEAT);
        pack.WriteCell(client);
        pack.WriteString(effect[client]);
    } else if(StrEqual(effect[client], "utaunt_lightning_parent")) { // Mega Strike expires every 0.9 seconds according to latest items_game.txt
        refireTimer[client] = CreateDataTimer(0.9, HandleRefire, pack, TIMER_REPEAT);
        pack.WriteCell(client);
        pack.WriteString(effect[client]);
    } else if(StrEqual(effect[client], "utaunt_firework_dragon_parent")) { // Roaring Rockets expires every 5.25 seconds according to latest items_game.txt
        refireTimer[client] = CreateDataTimer(5.25, HandleRefire, pack, TIMER_REPEAT);
        pack.WriteCell(client);
        pack.WriteString(effect[client]);
    }
}

// HandleRefire
// Timer callback handled per client to reissue any unusual taunt effects which have an expiry time.
public Action HandleRefire(Handle timer, DataPack pack) {
    char buffer[64]; // Unusual taunt effect passed through
    int client; // Client passed through

    // Datapacks require the data that is written to them be read in the same order it was written to.
    pack.Reset(); // Reset datapack incase there is data left over.
    client = pack.ReadCell(); // Get client index passed through
    pack.ReadString(buffer, sizeof(buffer)); // Get unusual effect passed through.

    // AttachParticle(client, buffer); // Attach the particle to player.
    CreateTempParticle(buffer, client);

    return Plugin_Handled;
}

// TF2_OnConditionRemoved is an event which SourceMod listens to natively, here we can check if different player conditions are no longer active (ex: jumping, taunting, etc etc)
// Check if player is no longer taunting and delete desired particle.
public void TF2_OnConditionRemoved(int client, TFCond condition) {
    if(!cEnabled.BoolValue) // If plugin is not enabled, do nothing.
        return;

    if(!IsClientInGame(client))
        return;
    
    if(condition != TFCond_Taunting)
        return;

    Player player = Player(client);

    char effect[MAXPLAYERS+1][64]; // String to store current unusual taunt effect into
    player.GetUnusualTauntEffectId(effect[client], sizeof(effect)); // Grab player current unusual effect and store into destination buffer

    // These will be valid entities on resupply due to player has be alive for resupply to take place.
    int primary = GetPlayerWeaponSlot(client, TFWeaponSlot_Primary);

    ClearTempParticles(client);

    if(player.GetKillstreakTierId(primary) > 0) // Only do if player has selected a killstreak tier
        TF2Attrib_SetByDefIndex(primary, 2025, float(player.GetKillstreakTierId(primary))); // Updates killstreak tier attribute to selected value
    if(player.GetKillstreakSheenId(primary) > 0) 
        TF2Attrib_SetByDefIndex(primary, 2014, float(player.GetKillstreakSheenId(primary)));
    if(player.GetKillstreakEffectId(primary) > 0)
        TF2Attrib_SetByDefIndex(primary, 2013, float(player.GetKillstreakEffectId(primary)));

    delete refireTimer[client]; // Stop timer from refiring if player is no longer taunting.
}

// Hooked Events

public Action OnResupply(Event event, const char[] name, bool dontBroadcast) {
    if(!cEnabled.BoolValue) // If plugin is not enabled, do nothing.
        return Plugin_Handled; 

    int client = GetClientOfUserId(GetEventInt(event, "userid"));
	
    if(!IsClientInGame(client))
        return Plugin_Handled;

    // REF: https://sm.alliedmods.net/new-api/clients/AuthIdType
    char steamid[32]; // Buffer to store SteamID32
    if(!GetClientAuthId(client, AuthId_Steam2, steamid, sizeof(steamid))) // Grab player SteamID32, if fails do nothing.
        return Plugin_Handled;

    FetchWearables(client, steamid); // Fetch the wearable set from the database.

    Player player = Player(client);

    // These will be valid entities on resupply due to player has be alive for resupply to take place.
    int primary = GetPlayerWeaponSlot(client, TFWeaponSlot_Primary);
    int secondary = GetPlayerWeaponSlot(client, TFWeaponSlot_Secondary);
    int melee = GetPlayerWeaponSlot(client, TFWeaponSlot_Melee);

    if(!IsValidEntity(primary) || !IsValidEntity(secondary) || !IsValidEntity(melee))
        return Plugin_Handled;

    // Item attribute 2025 is a attribute definition for killstreak tiers
    // Item attribute 2014 is a attribute definition for killstreak sheens
    // Item attribute 2013 is a attribute definition for killstreak effects
    // REF: https://wiki.teamfortress.com/wiki/List_of_item_attributes

    // OnResupply, ensure to override default item attributes again with desired attributes.
    // Primary Weapons
    if(player.GetKillstreakTierId(primary) > 0) // Only do if player has selected a killstreak tier
        TF2Attrib_SetByDefIndex(primary, 2025, float(player.GetKillstreakTierId(primary))); // Updates killstreak tier attribute to selected value
    if(player.GetKillstreakSheenId(primary) > 0) 
        TF2Attrib_SetByDefIndex(primary, 2014, float(player.GetKillstreakSheenId(primary)));
    if(player.GetKillstreakEffectId(primary) > 0)
        TF2Attrib_SetByDefIndex(primary, 2013, float(player.GetKillstreakEffectId(primary)));

     // Secondary Weapons
    if(player.GetKillstreakTierId(secondary) > 0) // Only do if player has selected a killstreak tier
        TF2Attrib_SetByDefIndex(secondary, 2025, float(player.GetKillstreakTierId(secondary))); // Updates killstreak tier attribute to selected value
    if(player.GetKillstreakSheenId(secondary) > 0) 
        TF2Attrib_SetByDefIndex(secondary, 2014, float(player.GetKillstreakSheenId(secondary)));
    if(player.GetKillstreakEffectId(secondary) > 0)
        TF2Attrib_SetByDefIndex(secondary, 2013, float(player.GetKillstreakEffectId(secondary)));

     // Melee Weapons
    if(player.GetKillstreakTierId(melee) > 0) // Only do if player has selected a killstreak tier
        TF2Attrib_SetByDefIndex(melee, 2025, float(player.GetKillstreakTierId(melee))); // Updates killstreak tier attribute to selected value
    if(player.GetKillstreakSheenId(melee) > 0) 
        TF2Attrib_SetByDefIndex(melee, 2014, float(player.GetKillstreakSheenId(melee)));
    if(player.GetKillstreakEffectId(melee) > 0)
        TF2Attrib_SetByDefIndex(melee, 2013, float(player.GetKillstreakEffectId(melee)));

    return Plugin_Continue;
}

// Command Handlers

public Action WearablesCommand(int client, int args) {
    if(!cEnabled.BoolValue) // If plugin is not enabled, do nothing.
        return Plugin_Handled; 

    // Validate client is actually in-game for menu to display
    if(!IsClientInGame(client))
        return Plugin_Handled;
    
    // Call our menu create function, on command /wearables run, we display the base menu.
    MenuCreate(client, wearablesMenu, "Wearables Menu");

    return Plugin_Handled; // Return Plugin_Handled to prevent "unknown command issues."
}

// Menu Constructors
// Switch cases are not fall-through in SourceMod, once a condition is met it will stop the switch at desired case and run block of code.
// FIXME: Use default: keyword for error handling(?) Not sure if required here, need to test.
public void MenuCreate(int client, wearablesOptions menuOptions, char[] menuTitle) {
    if(!cEnabled.BoolValue) // If plugin is not enabled, do nothing.
        return; 

    if(!IsClientInGame(client)) // MenuCreate is called multiple times throughout this plugin, the client could potentionally disconnect after the initial menu creation.
        return;

    Menu menu = new Menu(Menu_Handler, MENU_ACTIONS_ALL);

    menu.SetTitle("%s", menuTitle); // Set menu title passed from function call

    switch(menuOptions) { // Which menu should be created?
        case wearablesMenu: { // Wearables Main Menu
            // Loop through wearableMenuItems string array to add correct options.
            for(int i = 0; i < sizeof(wearableMenuItems); i++) {
                menu.AddItem(wearableMenuItems[i], wearableMenuItems[i]);
            }
        }
        case killStreakMenu: { // Killstreaks Main Menu
            // Loop through killstreaksMenuItems string array to add correct options.
            for(int i = 0; i < sizeof(killStreakMenuItems); i++) {
                menu.AddItem(killStreakMenuItems[i], killStreakMenuItems[i]);
            }
        }
        case unusualTauntMenu: { // Unusual Taunts Main Menu
            // Loop through unusualTauntMenuItems string array to add correct options.
            for(int i = 0; i < sizeof(unusualTauntMenuItems); i++) {
                menu.AddItem(unusualTauntMenuItems[i], unusualTauntMenuItems[i]);
            }
        }
        case killStreakTierMenu: { // Killstreaks Tier Menu 
            // Loop through killstreaksTierMenuItems string array to add correct options.
            for(int i = 0; i < sizeof(killStreakTierMenuItems); i++) {
                menu.AddItem(killStreakTierMenuItems[i], killStreakTierMenuItems[i]);
            }
        }

        case killStreakSheenMenu: { // Killstreaks Sheen Menu
            // Loop through killstreaksSheenMenuItems string array to add correct options.
            for(int i = 0; i < sizeof(killStreakSheenMenuItems); i++) {
                menu.AddItem(killStreakSheenMenuItems[i], killStreakSheenMenuItems[i]);
            }
        }

        case killStreakEffectMenu: { // Killstreaks Effect Menu
            // Loop through killstreaksEffectMenuItems string array to add correct options.
            for(int i = 0; i < sizeof(killStreakEffectMenuItems); i++) {
                menu.AddItem(killStreakEffectMenuItems[i], killStreakEffectMenuItems[i]);
            }
        }

        case slotSelectMenu: { // Weapon Slot Selection Menu
            // Loop through killstreaksEffectMenuItems string array to add correct options.
            for(int i = 0; i < sizeof(weaponSlotMenuItems); i++) {
                menu.AddItem(weaponSlotMenuItems[i], weaponSlotMenuItems[i]);
            }
        }

        case unusualMenu: { // Unusual Hat Selection Menu
             // Loop through unusualHatMenuItems string array to add correct options.
            for(int i = 0; i < sizeof(unusualMenuItems); i++) {
                menu.AddItem(unusualMenuItems[i], unusualMenuItems[i]);
            }
        }
    }

    menu.ExitButton = true;
    menu.Display(client, MENU_TIME_FOREVER);
}

// Menu Handlers

public int Menu_Handler(Menu menu, MenuAction menuAction, int client, int menuItem) {
    // We will only be worrying about handling the display of menu & the selection of the menu's items, rest can be ignored unless debugging.
    switch(menuAction) {
        case MenuAction_Select: {
            Player player = Player(client); // Initialize our player method map to save, store and update wearable effects.
            
            // SourceMod uses strings as selectors for menus, we will grab our selected menu item string and compare with our available options to give the menu functionality.
            char info[32];
            menu.GetItem(menuItem, info, sizeof(info));

            // REF: https://sm.alliedmods.net/new-api/clients/AuthIdType
            char steamid[32]; // Buffer to store SteamID32
            if(!GetClientAuthId(client, AuthId_Steam2, steamid, sizeof(steamid))) // Grab player SteamID32, if fails do nothing.
                return -1;

            // Main Menu Handling
            // If item selected is killstreaks, show client killstreak menu.
            if(StrEqual(info, "Killstreak Menu")) {
                MenuCreate(client, killStreakMenu, "Killstreak Menu");
            }

            // Unusual Taunt Menu Handling
            // If selected, display available Unusual Taunts for player to choose from.
            if(StrEqual(info, "Unusual Taunts Menu")) {
                MenuCreate(client, unusualTauntMenu, "Unusual Taunts Menu");
            }

            // Unusual Hat Menu Handling
            // IF selected, display all available unusual effects for player to choose from.
            if(StrEqual(info, "Unusual Hats Menu")) {
                MenuCreate(client, unusualMenu, "Unusual Hats Menu");
            }

            // Killstreak Menu Handling
            // If selected, display available Killstreak Tiers for player to choose from.
            if(StrEqual(info, "Killstreak Tier")) {
                MenuCreate(client, killStreakTierMenu, "Killstreak Tier Menu");
            }

            // If selected, display available Killstreak Sheens for player to choose from.
            if(StrEqual(info, "Killstreak Sheen")) {
                MenuCreate(client, killStreakSheenMenu, "Killstreak Sheens Menu");
            }

            // If selected, display available Killstreak Effects for player to choose from.
            if(StrEqual(info, "Killstreak Effect")) {
                MenuCreate(client, killStreakEffectMenu, "Killstreak Effects Menu");
            }

            // After selecting a killstreak attribute, player must select which weapon slot to apply the effect too.
            if(StrEqual(info, "Primary")) {
                int slot = GetPlayerWeaponSlot(client, TFWeaponSlot_Primary);

                if(!IsValidEntity(slot))
                    return -1;

                if(tTier[client] > 0) { // If temporary variable has been set, update values.
                    TF2Attrib_SetByDefIndex(slot, 2025, float(tTier[client])); // Updates killstreak tier to temporary value, permanent value used in OnResupply
                    player.SetKillstreakTierId(tTier[client], slot); // Update player killstreak tier to be used elsewhere.
                }

                if(tSheen[client] > 0) {
                    TF2Attrib_SetByDefIndex(slot, 2014, float(tSheen[client])); // Updates killstreak sheen to temporary value, permanent value used in OnResupply
                    player.SetKillstreakSheenId(tSheen[client], slot); // Update player killstreak sheen to be used elsewhere.
                }

                if(tEffect[client] > 0) {
                    TF2Attrib_SetByDefIndex(slot, 2013, float(tEffect[client])); // Updates killstreak effect to temporary value, permanent value used in OnResupply
                    player.SetKillstreakEffectId(tEffect[client], slot); // Update player killstreak effect to be used elsewhere.
                }
                
                // Display the main wearables menu after player has selected killstreak option.
                MenuCreate(client, wearablesMenu, "Wearables Menu");
                UpdateWearables(client, steamid); // Update the wearable attributes set by player by writing changes to database.
            }

            // If player chose second weapon slot
            if(StrEqual(info, "Secondary")) {
                int slot = GetPlayerWeaponSlot(client, TFWeaponSlot_Secondary);

                if(!IsValidEntity(slot))
                    return -1;

                if(tTier[client] > 0) {
                    TF2Attrib_SetByDefIndex(slot, 2025, float(tTier[client])); // Updates killstreak tier to temporary value, permanent value used in OnResupply
                    player.SetKillstreakTierId(tTier[client], slot); // Update player killstreak tier effect to be used elsewhere.
                }

                if(tSheen[client] > 0) {
                    TF2Attrib_SetByDefIndex(slot, 2014, float(tSheen[client])); // Updates killstreak sheen to temporary value, permanent value used in OnResupply
                    player.SetKillstreakSheenId(tSheen[client], slot); // Update player killstreak sheen to be used elsewhere.
                }

                if(tEffect[client] > 0) {
                    TF2Attrib_SetByDefIndex(slot, 2013, float(tEffect[client])); // Updates killstreak effect to temporary value, permanent value used in OnResupply
                    player.SetKillstreakEffectId(tEffect[client], slot); // Update player killstreak effect to be used elsewhere.
                }

                // Display the main wearables menu after player has selected killstreak option.
                MenuCreate(client, wearablesMenu, "Wearables Menu");
                UpdateWearables(client, steamid); // Update the wearable attributes set by player by writing changes to database.
            }

            // If player chose melee weapon slot
            if(StrEqual(info, "Melee")) {
                int slot = GetPlayerWeaponSlot(client, TFWeaponSlot_Melee);

                if(!IsValidEntity(slot))
                    return -1;

                if(tTier[client] > 0) {
                    TF2Attrib_SetByDefIndex(slot, 2025, float(tTier[client])); // Updates killstreak tier to temporary value, permanent value used in OnResupply
                    player.SetKillstreakTierId(tTier[client], slot); // Update player killstreak tier to be used elsewhere.
                }

                if(tSheen[client] > 0) {
                    TF2Attrib_SetByDefIndex(slot, 2014, float(tSheen[client])); // Updates killstreak sheen to temporary value, permanent value used in OnResupply
                    player.SetKillstreakSheenId(tSheen[client], slot); // Update player killstreak sheen to be used elsewhere.
                }

                if(tEffect[client] > 0) {
                    TF2Attrib_SetByDefIndex(slot, 2013, float(tEffect[client])); // Updates killstreak effect to temporary value, permanent value used in OnResupply
                    player.SetKillstreakEffectId(tEffect[client], slot); // Update player killstreak effect to be used elsewhere.
                }

                // Display the main wearables menu after player has selected killstreak option.
                MenuCreate(client, wearablesMenu, "Wearables Menu");
                UpdateWearables(client, steamid); // Update the wearable attributes set by player by writing changes to database.
            }

            // Killstreak Tiers, Sheens, Effects Handlers (We give players the effects selected here!)

            // Let's handle killStreakTiers first.
            // Loop through killStreakTierMenuItems string array
            for(int i = 0; i < sizeof(killStreakTierMenuItems); i++) {
                // If value picked on the menu matches our string value, then set item attribute index to value matching at same index.
                // Item attribute 2025 is a attribute definition for killstreak tiers, reference link at OnResupply
                if(StrEqual(info, killStreakTierMenuItems[i])) {
                    MenuCreate(client, slotSelectMenu, "Apply to slot: ");
                    tTier[client] = killStreakTierSel[i]+1; // Set our temporary variable to value of our selected killstreak tier.
                    break;
                }
            }

            // Loop through killStreakSheenMenuItems string array
            for(int i = 0; i < sizeof(killStreakSheenMenuItems); i++) {
                // If value picked on the menu matches our string value, then set item attribute index to value matching at same index.
                // Item attribute 2014 is a attribute definition for killstreak sheens, reference link at OnResupply
                if(StrEqual(info, killStreakSheenMenuItems[i])) {
                    MenuCreate(client, slotSelectMenu, "Apply to slot: ");
                    tSheen[client] = killStreakSheenSel[i]; // Set our temporary variable to value of our selected killstreak sheen.
                    break;
                }
            }

            // Loop through killStreakEffectMenuItems string array
            for(int i = 0; i < sizeof(killStreakEffectMenuItems); i++) {
                // If value picked on the menu matches our string value, then set item attribute index to value matching at same index.
                // Item attribute 2013 is a attribute definition for killstreak effects, reference link at OnResupply
                if(StrEqual(info, killStreakEffectMenuItems[i])) {
                    MenuCreate(client, slotSelectMenu, "Apply to slot: ");
                    tEffect[client] = killStreakEffectSel[i]; // Set our temporary variable to value of our selected killstreak effect.
                    break;
                }
            }

            // Loop through unusualTauntMenuItems string array
            for(int i = 0; i < sizeof(unusualTauntMenuItems); i++) {
                // If value picked on menu matches our string value, then set item attribute index to value matching at same index.
                // Unusual taunt particles are extracted from TF2's packed in items_game.txt file (pak01.vpk), we will be using the string name of particle from the items_game.txt document to add our unusual taunt to the player.
                // REF: https://wiki.teamfortress.com/wiki/Item_schema

                // Here we've got to think a little differently than the others, since we cannot append a attribute index to each individual taunt, we must use the string name of unusual taunt found in items_game.txt and attach the particle to the player manually.
                // This also means for particles which require a refire timer (Showstopper for example) will need magic numbers in order to function properly. These will be defined at the top of the file for readability.
                // Loop through unusual taunt menu item id list and match display name with item id.
                // Check if unusualTauntMenu matches selected by player
                if(StrEqual(info, unusualTauntMenuItems[i])) {
                    // Set unusualTauntMenuId to desired effect by matching index of display name with id.
                    player.SetUnusualTauntEffectId(unusualTauntMenuItemIds[i]);
                    MenuCreate(client, wearablesMenu, "Wearables Menu");
                    UpdateWearables(client, steamid); // Update the wearable attributes set by player by writing changes to database.
                    break;
                }
            }

             // Loop through unusualMenuItems string array
            for(int i = 0; i < sizeof(unusualMenuItems); i++) {
                // If value picked on the menu matches our string value, then set item attribute index to value matching at same index.
                if(StrEqual(info, unusualMenuItems[i])) {
                    player.SetUnusualHatEffectId(unusualHatSel[i]);
                    MenuCreate(client, wearablesMenu, "Wearables Menu");
                    UpdateWearables(client, steamid); // Update the wearable attributes set by player by writing changes to database.
                    break;
                }
            }
        }
    }

    return 0; // 0 means our menu returned without any issues.
}

// AttachParticle - Used to manually create and attach particles to player.
// Labelled as stock as we are not currently using this in the plugin, but have plans to in the future. (Prevents compiler warnings.)
stock void AttachParticle(int client, char[] particle) {
    // Here we will implement Temporary Entity system for particles which either 1. Don't disappear when the parent entity is killed or 2. Don't follow player model body pattern like they should in official taunts.
    // REF: https://wiki.alliedmods.net/Temp_Entity_Lists_(Source)
    
    // Create info_particle_system entity
    // REF: https://developer.valvesoftware.com/wiki/Info_particle_system
    int particleSystem = CreateEntityByName("info_particle_system");

    char name[128];
    if(IsValidEntity(particleSystem)) {
        float pos[3]; // Create position vector (x, y, z)
        float ang[3]; // Angle vector

        GetEntPropVector(client, Prop_Send, "m_vecOrigin", pos); // Update position vector with default position values 
        GetEntPropVector(client, Prop_Data, "m_angRotation", ang);
        
        TeleportEntity(particleSystem, pos, ang, NULL_VECTOR); // Teleport entity to new position vectors (All setup to be attached to player)

        //Format(name, sizeof(name), "target%i", client); // Set target to client which is creating the particle
        //DispatchKeyValue(client, "targetname", name); // Dispatch KeyValue "targetname" into client.
        SetVariantString("!activator");
        AcceptEntityInput(particleSystem, "SetParent", client);  

        DispatchKeyValue(particleSystem, "targetname", "tf2particle"); // Dispatch KeyValue "targetname" with value "tf2particle" into partice entity, this tells the game we are trying to create a default in-game particle effect.
        DispatchKeyValue(particleSystem, "parentname", name); // Set / dispatch parent of particle system to target client.
        DispatchKeyValue(particleSystem, "effect_name", particle); // Set particle name, this is where we change the particle we want to spawn.
        DispatchSpawn(particleSystem); // Remove it from it's 0,0 world center position.
        SetVariantString("0"); // Ensure no more variant strings are being sent to cause issues
        AcceptEntityInput(particleSystem, "SetParentAttachment", particleSystem, particleSystem, 0); 

        ActivateEntity(particleSystem); // Make the particle start doing it's thing!
        AcceptEntityInput(particleSystem, "start"); // Same thing as above essentially, some particles don't listen to ActivateEntity

        particleEntity[client] = particleSystem; // Set particle entity client picked with newly created particle.
    }
}

// DeleteParticle - Deletes particle entity when called
// Labelled as stock as we are not currently using this in the plugin, but have plans to in the future. (Prevents compiler warnings.)
stock void DeleteParticle(int particle) {
	if (IsValidEntity(particle)) { // If particle exists as an entity.
		char classname[64]; 
		GetEdictClassname(particle, classname, sizeof(classname)); // Store classname of particle entity grabbed, (this case: info_particle_system)
		if (StrEqual(classname, "info_particle_system", false)) { // Check if entity classname matches info_particle_system
            AcceptEntityInput(particle, "Stop"); // We're trying our best to get rid of stubborn particles.
            AcceptEntityInput(particle, "DestroyImmediately"); // Some particles don't disappear without this
            AcceptEntityInput(particle, "Kill"); // Hotfix to destroy some particles from server on next game frame.
            RemoveEdict(particle); // Remove it from the server to reduce entity count.
		}
	}
}

// This creates a temporary entity as a TFParticleEffect which allows the unusual taunts to be wrapped around the client model / take the client model sizing correctly.
// The downside to this is in ThirdPerson mode, killstreak effects are also wiped as they are also temporary entities
// Temporary entities do not have an index or ID, meaning we must clear all at once.
// REF: https://developer.valvesoftware.com/wiki/Temporary_Entity
void CreateTempParticle(char[] particle, int entity = -1, float origin[3] = NULL_VECTOR, float angles[3] = {0.0, 0.0, 0.0}, bool resetparticles = false) {
    int tblidx = FindStringTable("ParticleEffectNames"); // Grab particle effect string table

    char tmp[256];
    int stridx = INVALID_STRING_INDEX;

    for (int i = 0; i < GetStringTableNumStrings(tblidx); i++) { // Loop through particle effect string table
        ReadStringTable(tblidx, i, tmp, sizeof(tmp)); // Store particle at index into temporary value
        if(StrEqual(tmp, particle, false)) {  // If the value matches our particle we wish to create, assign string index.
            stridx = i;
            break;
        }
    }

    TE_Start("TFParticleEffect"); // Start temporary entity as TFParticleEffect
    TE_WriteFloat("m_vecOrigin[0]", origin[0]); // Set origin vector for TFParticleEffect
    TE_WriteFloat("m_vecOrigin[1]", origin[1]);
    TE_WriteFloat("m_vecOrigin[2]", origin[2]);
    TE_WriteFloat("m_vecStart[0]", origin[0]); // Set start vector for TFParticleEffect
    TE_WriteFloat("m_vecStart[1]", origin[1]);
    TE_WriteFloat("m_vecStart[2]", origin[2]);
    TE_WriteVector("m_vecAngles", angles); // Set angle vector for TFParticleEffect
    TE_WriteNum("m_iParticleSystemIndex", stridx); // Set temporary entity particle index in TempEnt to match the particle from our string table.
    TE_WriteNum("entindex", entity); // Assign the temporary entity to the entity passed in parameter 2.
    TE_WriteNum("m_iAttachType", 0); // AttachType 1 sets origin of temporary entity to the map world origin point (0, 0), we don't want that.
    TE_WriteNum("m_bResetParticles", resetparticles); // This is called to reset all particles attached to that entity, unfortunately there's no other to clear temporary entities.
    TE_SendToAll(); // Send temporary entity to all players.
}

// ClearTempParticles()
// Dummy function used to easier remove all temporary entities from target entity.
void ClearTempParticles(int client) {
	float empty[3];
	CreateTempParticle("sandwich_fx", client, empty, empty, true); // Creates a empty sandwich_fx particle and passes true on m_bResetParticles, deleting all particles attached to entity.
}

// TF2Items_OnGiveNamedItem - from <tf2items>, called whenever a player gets a fresh set of items (when changing class, respawning(?), etc)
public Action TF2Items_OnGiveNamedItem(int client, char[] className, int itemIndex, Handle &hItem) {
    Player player = Player(client); // Initialize our player method map to save, store and update wearable effects.

    if(hatIDList.FindValue(itemIndex) == -1) // If player is not wearing a hat, do nothing
        return Plugin_Continue;

    hItem = TF2Items_CreateItem(OVERRIDE_ATTRIBUTES | PRESERVE_ATTRIBUTES); // Assign our item to be changing, we want to be keeping the old attributes of the players item but also overriding any we wish.

    TF2Items_SetNumAttributes(hItem, 1); // Set number of attributes to change

    TF2Items_SetQuality(hItem, 5); // Set to unusual quality.
    TF2Items_SetAttribute(hItem, 0, 134, float(player.GetUnusualHatEffectId())); // Set "attach particle (134) attribute to players desired unusual effect."

    return Plugin_Changed; // Update the players item.
}

// ReadItemSchema
// Function made to traverse the items_game schema and grab all "hat" item indexes so we can only give unusual effects to hats.
// FIXME: Update for unusual weapon effects.
public void ReadItemSchema() {
    KeyValues kv = new KeyValues("items_game");
    kv.ImportFromFile("scripts/items/items_game.txt");

    kv.JumpToKey("items");
    kv.GotoFirstSubKey();

    char itemID[64];
    char itemSlot[64];

    do {
        kv.GetSectionName(itemID, sizeof(itemID));
        kv.GetString("item_slot", itemSlot, sizeof(itemSlot));

        // If wearable is on head, add to wearable array list.
        if(strcmp(itemSlot, "head") == 0) {
            hatIDList.Push(StringToInt(itemID));
        } else { // If that fails, check any other cosmetic we might be able to apply an unusual effect too.
            kv.GetString("prefab", itemSlot, sizeof(itemSlot));

            if(strcmp(itemSlot, "hat") == 0 || strcmp(itemSlot, "base_hat") == 0 || strcmp(itemSlot, "no_craft hat marketable") == 0 || strcmp(itemSlot, "valve base_hat") == 0) { // Check if "prefab" key has value of hat, base_hat, no_craft hat marketable or valve base_hat
                hatIDList.Push(StringToInt(itemID));
            } else { // If not, let's triple check the equip_region
                kv.GetString("equip_region", itemSlot, sizeof(itemSlot));

                if(strcmp(itemSlot, "hat") == 0) // If equip_region key has value of hat, push to hatID arrayList
                    hatIDList.Push(StringToInt(itemID));
            }
        }
    } while (kv.GotoNextKey());

    delete kv;
}