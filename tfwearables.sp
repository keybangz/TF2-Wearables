#include <sourcemod>
#include <tf2_stocks>
#include <tf2items>
#include <tf2attributes>
#include <morecolors>
#include <clientprefs>

#pragma newdecls required // Force Transitional Syntax
#pragma semicolon 1 // Force semicolon mode

#define PLUGIN_VERSION "1.0"

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

// temporary variables
// we are gonna use these to keep track of effect per slot in the menu handler
// once item is selected we can forget about these variables as they will be overwritten when player picks another option
// I don't know how else to implement slot selection via menu without creating two menu functions.
int tTier[MAXPLAYERS+1];
int tSheen[MAXPLAYERS+1];
int tEffect[MAXPLAYERS+1];

// In an attempt to keep away from multiple implementations of practically the same code, store main menu options here.
char wearableMenuItems[][] = {
    "Killstreak Menu",
    "Unusual Taunts Menu"
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
    "Poisonous Bubbles of Regret"
};

// These are the unusual taunt menu item id's as matched in items_game.txt of TF2
// REF: https://wiki.teamfortress.com/wiki/Item_schema
char unusualTauntMenuItemIds[][] = {
    "utaunt_firework_teamcolor_red", // Showstopper (RED)
    "utaunt_firework_teamcolor_blue", // Showstopper (BLUE)
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
    "utaunt_bubbles_glow_purple_parent" // Poisonous Bubbles of Regret
};

// All possible menus which can be created, I have given them an ID order of +1 to keep it simple.
enum wearablesOptions {
    wearablesMenu = 0,
    killStreakMenu = 1,
    unusualTauntMenu = 2,
    killStreakTierMenu = 3,
    killStreakSheenMenu = 4,
    killStreakEffectMenu = 5,
    slotSelectMenu = 6
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

    // In-game events the plugin should listen to.
    // If other plugins are manually invoking these events, THESE EVENTS WILL FIRE. (Bad practice to manually invoke events anyways)
    HookEvent("post_inventory_application", OnResupply); // When player touches resupply locker, respawns or manually invokes a refresh of player items.

    // Admin Commands
    RegAdminCmd("sm_wearables", WearablesCommand, ADMFLAG_RESERVATION, "Shows the wearables menu."); // Translates to /wearables in-game 
}

// Our main methodmap, this provides us with all functions required to assign desired effects to the desired player.
methodmap Player {
    public Player(int index) { // Constructor of methodmap
        if(IsClientInGame(index))
            return view_as<Player>(index); // Will return index of Player entry in methodmap, note this does not reflect the client unless we assign the client to the methodmap first.
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
}

// Our goal here from version 1 is too minimize the amount of repitition the previous codebase had used.
// To do this we will strip a lot of logic into single functions and determine the use case based on the parameters passed.
// We want to organize our code into a methodmap or some sort of structured way to prevent recreation of variables that we don't need.
// Unlike the previous version, we will be using SQLite or MySQL to store player preferences, this will provide us with a cleaner codebase and remove the hassle of cookie caching and verification.

// Not a hooked event, SourceMod listens for this always, we'll intialize our methodmap and killstreak effects here.
// TODO: Fetch SQL db effects here.
public void OnClientPutInServer(int client) {
    Player player = Player(client);

    // Initialize values used in plugin
    // Loop through all weapon slots 0 - 3, this matches definition of killStreakTier, killStreakSheen & killStreakEffect @ top of file.
    for(int i = 0; i < 3; i++) {
        player.SetKillstreakTierId(0, i);
        player.SetKillstreakSheenId(0, i);
        player.SetKillstreakEffectId(0, i);
    }
}

// TF2_OnConditionAdded is an event which SourceMod listens to natively, here we can check different player conditions (ex: jumping, taunting, etc etc)
// Check if player is taunting, if so add desired effect to player.
public void TF2_OnConditionAdded(int client, TFCond condition) {
    if(!IsClientInGame(client) || !IsPlayerAlive(client)) // Self explanatory
        return;
    
    if(condition != TFCond_Taunting)
        return;

    Player player = Player(client); // Initalize player methodmap
    char effect[MAXPLAYERS+1][64]; // String to store current unusual taunt effect into
    player.GetUnusualTauntEffectId(effect[client], sizeof(effect)); // Grab player current unusual effect and store into destination buffer

    AttachParticle(client, effect[client]); // Create and attach desired particle effect to player.
}

// TF2_OnConditionRemoved is an event which SourceMod listens to natively, here we can check if different player conditions are no longer active (ex: jumping, taunting, etc etc)
// Check if player is no longer taunting and delete desired particle.
public void TF2_OnConditionRemoved(int client, TFCond condition) {
    if(!IsClientInGame(client))
        return;
    
    if(condition != TFCond_Taunting)
        return;

    // If the particle still exists when player is no longer taunting, get rid of it.
    if(IsValidEntity(particleEntity[client])) {
        DeleteParticle(particleEntity[client]);
    }
}

// Hooked Events

public Action OnResupply(Event event, const char[] name, bool dontBroadcast) {
    int client = GetClientOfUserId(GetEventInt(event, "userid"));
	
    if(!IsClientInGame(client))
        return Plugin_Handled;

    // These will be valid entities on resupply due to player has be alive for resupply to take place.
    int primary = GetPlayerWeaponSlot(client, TFWeaponSlot_Primary);
    int secondary = GetPlayerWeaponSlot(client, TFWeaponSlot_Secondary);
    int melee = GetPlayerWeaponSlot(client, TFWeaponSlot_Melee);

    Player player = Player(client);

    // Item attribute 2025 is a attribute definition for killstreak tiers
    // Item attribute 2014 is a attribute definition for killstreak sheens
    // Item attribute 2013 is a attribute definition for killstreak effects
    // REF: https://wiki.teamfortress.com/wiki/List_of_item_attributes 

    // OnResupply, ensure to override default item attributes again with desired attributes.
    // Primary Weapons
    if(player.GetKillstreakTierId(primary) > 0) // Only do if player has selected a killstreak tier
        TF2Attrib_SetByDefIndex(primary, 2025, float(player.GetKillstreakTierId(primary))); // Updates killstreak tier attribute to selected value
    else if(player.GetKillstreakSheenId(primary) > 0) 
        TF2Attrib_SetByDefIndex(primary, 2014, float(player.GetKillstreakSheenId(primary)));
    else if(player.GetKillstreakEffectId(primary) > 0)
        TF2Attrib_SetByDefIndex(primary, 2013, float(player.GetKillstreakEffectId(primary)));

     // Secondary Weapons
    if(player.GetKillstreakTierId(secondary) > 0) // Only do if player has selected a killstreak tier
        TF2Attrib_SetByDefIndex(secondary, 2025, float(player.GetKillstreakTierId(secondary))); // Updates killstreak tier attribute to selected value
    else if(player.GetKillstreakSheenId(secondary) > 0) 
        TF2Attrib_SetByDefIndex(secondary, 2014, float(player.GetKillstreakSheenId(secondary)));
    else if(player.GetKillstreakEffectId(secondary) > 0)
        TF2Attrib_SetByDefIndex(secondary, 2013, float(player.GetKillstreakEffectId(secondary)));

     // Melee Weapons
    if(player.GetKillstreakTierId(melee) > 0) // Only do if player has selected a killstreak tier
        TF2Attrib_SetByDefIndex(melee, 2025, float(player.GetKillstreakTierId(melee))); // Updates killstreak tier attribute to selected value
    else if(player.GetKillstreakSheenId(melee) > 0) 
        TF2Attrib_SetByDefIndex(melee, 2014, float(player.GetKillstreakSheenId(melee)));
    else if(player.GetKillstreakEffectId(melee) > 0)
        TF2Attrib_SetByDefIndex(melee, 2013, float(player.GetKillstreakEffectId(melee)));

    // Cleanup particles plugin has created, and reapply if selections have been updated.
    return Plugin_Handled;
}

// Command Handlers

public Action WearablesCommand(int client, int args) {
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

            if(StrEqual(info, "Primary")) {
                int slot = GetPlayerWeaponSlot(client, TFWeaponSlot_Primary);

                if(!IsValidEntity(slot))
                    return -1;

                if(tTier[client] > 0) {
                    TF2Attrib_SetByDefIndex(slot, 2025, float(tTier[client]));
                    player.SetKillstreakTierId(tTier[client], slot); // Update player killstreak tier effect to be used elsewhere.
                }

                if(tSheen[client] > 0) {
                    TF2Attrib_SetByDefIndex(slot, 2014, float(tSheen[client]));
                    player.SetKillstreakSheenId(tSheen[client], slot); // Update player killstreak sheen effect to be used elsewhere.
                }

                if(tEffect[client] > 0) {
                    TF2Attrib_SetByDefIndex(slot, 2013, float(tEffect[client]));
                    player.SetKillstreakEffectId(tEffect[client], slot); // Update player killstreak sheen effect to be used elsewhere.
                }
                
                // Display the main wearables menu after player has selected killstreak option.
                MenuCreate(client, wearablesMenu, "Wearables Menu");
            }

            if(StrEqual(info, "Secondary")) {
                int slot = GetPlayerWeaponSlot(client, TFWeaponSlot_Secondary);

                if(!IsValidEntity(slot))
                    return -1;

                if(tTier[client] > 0) {
                    TF2Attrib_SetByDefIndex(slot, 2025, float(tTier[client]));
                    player.SetKillstreakTierId(tTier[client], slot); // Update player killstreak tier effect to be used elsewhere.
                }

                if(tSheen[client] > 0) {
                    TF2Attrib_SetByDefIndex(slot, 2014, float(tSheen[client]));
                    player.SetKillstreakSheenId(tSheen[client], slot); // Update player killstreak sheen effect to be used elsewhere.
                }

                if(tEffect[client] > 0) {
                    TF2Attrib_SetByDefIndex(slot, 2013, float(tEffect[client]));
                    player.SetKillstreakEffectId(tEffect[client], slot); // Update player killstreak sheen effect to be used elsewhere.
                }

                // Display the main wearables menu after player has selected killstreak option.
                MenuCreate(client, wearablesMenu, "Wearables Menu");
            }

            if(StrEqual(info, "Melee")) {
                int slot = GetPlayerWeaponSlot(client, TFWeaponSlot_Melee);

                if(!IsValidEntity(slot))
                    return -1;

                if(tTier[client] > 0) {
                    TF2Attrib_SetByDefIndex(slot, 2025, float(tTier[client]));
                    player.SetKillstreakTierId(tTier[client], slot); // Update player killstreak tier effect to be used elsewhere.
                }

                if(tSheen[client] > 0) {
                    TF2Attrib_SetByDefIndex(slot, 2014, float(tSheen[client]));
                    player.SetKillstreakSheenId(tSheen[client], slot); // Update player killstreak sheen effect to be used elsewhere.
                }

                if(tEffect[client] > 0) {
                    TF2Attrib_SetByDefIndex(slot, 2013, float(tEffect[client]));
                    player.SetKillstreakEffectId(tEffect[client], slot); // Update player killstreak sheen effect to be used elsewhere.
                }

                // Display the main wearables menu after player has selected killstreak option.
                MenuCreate(client, wearablesMenu, "Wearables Menu");
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
                }
            }

            // Loop through killStreakSheenMenuItems string array
            for(int i = 0; i < sizeof(killStreakSheenMenuItems); i++) {
                // If value picked on the menu matches our string value, then set item attribute index to value matching at same index.
                // Item attribute 2014 is a attribute definition for killstreak sheens, reference link at OnResupply
                if(StrEqual(info, killStreakSheenMenuItems[i])) {
                    MenuCreate(client, slotSelectMenu, "Apply to slot: ");
                    tSheen[client] = killStreakSheenSel[i]; // Set our temporary variable to value of our selected killstreak sheen.
                }
            }

            // Loop through killStreakEffectMenuItems string array
            for(int i = 0; i < sizeof(killStreakEffectMenuItems); i++) {
                // If value picked on the menu matches our string value, then set item attribute index to value matching at same index.
                // Item attribute 2013 is a attribute definition for killstreak effects, reference link at OnResupply
                if(StrEqual(info, killStreakEffectMenuItems[i])) {
                    MenuCreate(client, slotSelectMenu, "Apply to slot: ");
                    tEffect[client] = killStreakEffectSel[i]; // Set our temporary variable to value of our selected killstreak effect.
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
                    PrintToServer("unusualTaunt: %s", unusualTauntMenuItemIds[i]);
                    // Set unusualTauntMenuId to desired effect by matching index of display name with id.
                    player.SetUnusualTauntEffectId(unusualTauntMenuItemIds[i]);
                    break;
                }
            }
        }
    }

    return 0; // 0 means our menu returned without any issues.
}

// AttachParticle - Used to manually create and attach particles to player.
void AttachParticle(int client, char[] particle) {
    // Create info_particle_system entity
    // REF: https://developer.valvesoftware.com/wiki/Info_particle_system
    int particleSystem = CreateEntityByName("info_particle_system");

    char name[128];
    if(IsValidEntity(particleSystem)) {
        float pos[3]; // Create position vector (x, y, z)

        GetEntPropVector(client, Prop_Send, "m_vecOrigin", pos); // Update position vector with default position values 
        pos[2] += 10; // z axis often points down to map center, point it up a bit.
        TeleportEntity(particleSystem, pos, NULL_VECTOR, NULL_VECTOR); // Teleport entity to new position vectors (All setup to be attached to player)

        Format(name, sizeof(name), "target%i", client); // Set target to client which is creating the particle
        DispatchKeyValue(client, "targetname", name); // Dispatch KeyValue "targetname" into client.

        DispatchKeyValue(particleSystem, "targetname", "tf2particle"); // Dispatch KeyValue "targetname" with value "tf2particle" into partice entity, this tells the game we are trying to create a default in-game particle effect.
        DispatchKeyValue(particleSystem, "parentname", name); // Set / dispatch parent of particle system to target client.
        DispatchKeyValue(particleSystem, "effect_name", particle); // Set particle name, this is where we change the particle we want to spawn.
        DispatchSpawn(particleSystem); // Remove it from it's 0,0 world center position.
        SetVariantString(name); // Set name string in entity to line up with client.
        AcceptEntityInput(particleSystem, "SetParent", particleSystem, particleSystem, 0); // Important for entity heirachy, will produce errors in console otherwise. REF: https://developer.valvesoftware.com/wiki/Entity_Hierarchy_(parenting)
        SetVariantString(""); // Ensure no more variant strings are being sent to cause issues

        ActivateEntity(particleSystem); // Make the particle start doing it's thing!
        AcceptEntityInput(particleSystem, "start"); // Same thing as above essentially, some particles don't listen to ActivateEntity

        particleEntity[client] = particleSystem; // Set particle entity client picked with newly created particle.
    }
}

// DeleteParticle - Deletes particle entity when called
void DeleteParticle(int particle)
{
	if (IsValidEntity(particle)) // If the particle exists
	{
		char classname[64]; 
		GetEdictClassname(particle, classname, sizeof(classname)); // Store classname of particle entity grabbed, (this case: info_particle_system)
		if (StrEqual(classname, "info_particle_system", false)) // Check it
		{
			AcceptEntityInput(particle, "DestroyImmediately"); // Some particles don't disappear without this
			RemoveEdict(particle); // Remove it from the server to reduce entity count.
		}
	}
}