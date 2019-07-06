#include <sourcemod>
#include <tf2_stocks>
#include <tf2items>
#include <tf2attributes>
#include <morecolors>
#include <clientprefs>

#pragma newdecls required // Force Transitional Syntax
#pragma semicolon 1 // Force Semicolon, should use in every plugin.

#define PLUGIN_VERSION "1.1.0"

int g_Ent[MAXPLAYERS + 1];
int g_WepEnt[MAXPLAYERS + 1];
bool g_bIsTaunting[MAXPLAYERS + 1];

bool iPrimarySlotSheenChosen[MAXPLAYERS + 1];
bool iPrimarySlotTiersChosen[MAXPLAYERS + 1];
bool iPrimarySlotEffectsChosen[MAXPLAYERS + 1];

bool iSecondarySlotSheenChosen[MAXPLAYERS + 1];
bool iSecondarySlotTiersChosen[MAXPLAYERS + 1];
bool iSecondarySlotEffectsChosen[MAXPLAYERS + 1];

bool iMeleeSlotSheenChosen[MAXPLAYERS + 1];
bool iMeleeSlotTiersChosen[MAXPLAYERS + 1];
bool iMeleeSlotEffectsChosen[MAXPLAYERS + 1];

bool bNeedsWarPaint[MAXPLAYERS + 1];

ConVar g_bLogToConsole;

// Wearables menu

#define KILLSTREAKS "0"
#define UNUSUALS "1"
#define UNUSUALTAUNTS "2"
#define AUSTRALIUMS "3"
#define WARPAINTS "4"

#define iKILLSTREAKS 0
#define iUNUSUALS 1
#define iUNUSUALTAUNTS 2
#define iAUSTRALIUMS 3
#define iWARPAINTS 4



// Killstreaks Menu

#define KILLSTREAKSHEEN "0"
#define KILLSTREAKTIERS "1"
#define KILLSTREAKEFFECT "2"

#define iKILLSTREAKSHEEN 0
#define iKILLSTREAKTIERS 1
#define iKILLSTREAKEFFECT 2

#define PRIMARYWEP "0"
#define SECONDARYWEP "1"
#define MELEEWEP "2"

#define iPRIMARYWEP 0
#define iSECONDARYWEP 1
#define iMELEEWEP 0

float KillstreakTierID[MAXPLAYERS + 1];
float KillstreakEffectID[MAXPLAYERS + 1];
float KillstreakSheenID[MAXPLAYERS + 1];

// Unusual Taunts Menu
char UnusualTauntID[MAXPLAYERS + 1][64];
float WeaponUnusualID[MAXPLAYERS + 1];
char strWeaponUnusual[MAXPLAYERS + 1][64];
bool HasPickedUnusualTaunt[MAXPLAYERS + 1];
bool HasPickedWeaponUnusual[MAXPLAYERS + 1];
//Handle CheckTaunt[MAXPLAYERS + 1];

// REFIRE TAUNTS
Handle RefireShowStopperRed[MAXPLAYERS + 1];
Handle RefireShowStopperBlue[MAXPLAYERS + 1];
Handle RefireMegaStrike[MAXPLAYERS + 1];
Handle RefireRoaringRockets[MAXPLAYERS + 1];

// COOOKIESS!!!!

Handle UnusualTauntCookie = null;
Handle UnusualWeaponCookie = null;
Handle UnusualWeaponFloatCookie = null;
Handle UnusualWeaponBoolCookie = null;
Handle PrimaryKillstreakTierCookie = null;
Handle PrimaryKillstreakSheenCookie = null;
Handle PrimaryKillstreakEffectCookie = null;
Handle SecondaryKillstreakTierCookie = null;
Handle SecondaryKillstreakSheenCookie = null;
Handle SecondaryKillstreakEffectCookie = null;
Handle MeleeKillstreakTierCookie = null;
Handle MeleeKillstreakSheenCookie = null;
Handle MeleeKillstreakEffectCookie = null;

// ConVars

ConVar RegeneratePlayer;

// Thanks 404
int g_iPaintKitable[][] =  {
	37,  // Ubersaw
	172,  // Scotsman's Skullcutter
	194,  // Knife (Strange/Renamed)
	197,  // Wrench (Strange/Renamed)
	199,  // Shotgun (Primary) (Strange/Renamed)
	200,  // Scattergun (Strange/Renamed)
	201,  // Sniper Rifle (Strange/Renamed)
	202,  // Minigun (Strange/Renamed)
	203,  // SMG (Strange/Renamed)
	205,  // Rocket Launcher (Strange/Renamed)
	206,  // Grenade Launcher (Strange/Renamed)
	207,  // Stickybomb Launcher (Strange/Renamed)
	208,  // Flamethrower (Strange/Renamed)
	209,  // Pistol (Strange/Renamed)
	210,  // Revolver (Strange/Renamed)
	211,  // Medi Gun (Strange/Renamed)
	214,  // Powerjack
	215,  // Degreaser
	220,  // Shortstop
	221,  // Holy Mackerel
	228,  // Black Box
	304,  // Amputator
	305,  // Crusader's Crossbow
	308,  // Loch-n-Load
	312,  // Brass Beast
	326,  // Back Scratcher
	327,  // Claidheamohmor
	329,  // Jag
	351,  // Detonator
	401,  // Shahanshah
	402,  // Bazaar Bargain
	404,  // Persian Persuader
	415,  // Reserve Shooter
	424,  // Tomislav
	425,  // Family Business
	447,  // Disciplinary Action
	448,  // Soda Popper
	449,  // Winger
	740,  // Scorch Shot
	996,  // Loose Cannon
	997,  // Rescue Ranger
	1104,  // Air Strike
	1151,  // Iron Bomber
	1153,  // Panic Attack
	1178,  // Dragon's Fury
};

// This is pretty self explanatory.
public Plugin myinfo = 
{
	name = "[TF2] Wearables", 
	author = "blood", 
	description = "Allows players to use a menu to pick custom attributes for there weapons or player.", 
	version = PLUGIN_VERSION, 
	url = "https://sanctuary.tf", 
};

public void OnPluginStart()
{
	// ConVars
	CreateConVar("tf_wearables_version", PLUGIN_VERSION, "Wearables Version (Do not touch).", FCVAR_NOTIFY | FCVAR_REPLICATED);
	RegeneratePlayer = CreateConVar("sm_wearables_rg", "0", "Regenerate player on wearable update?", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_bLogToConsole = CreateConVar("sm_wearables_log", "0", "Log the given killstreak id's to console'", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	
	// These cookies are stale, gross.
	UnusualTauntCookie = RegClientCookie("UnusualTauntID", "A cookie for reading the saved Unusual Taunt ID", CookieAccess_Private); // Make a client cookie, make sure cookie cannot be written over by client, by making it private.
	UnusualWeaponCookie = RegClientCookie("WeaponUnusualID", "A cookie for reading the saved Unusual Weapon ID", CookieAccess_Private);
	UnusualWeaponFloatCookie = RegClientCookie("WeaponUnusualIDFloat", "A cookie for reading the saved Unusual Weapon ID Float", CookieAccess_Private);
	UnusualWeaponBoolCookie = RegClientCookie("WeaponUnusualIDBool", "A cookie for reading the saved Unusual Weapon ID Bool", CookieAccess_Private);
	PrimaryKillstreakTierCookie = RegClientCookie("PrimaryKillstreakTier", "A cookie for reading the saved Killstreak Cookie", CookieAccess_Private);
	PrimaryKillstreakSheenCookie = RegClientCookie("PrimaryKillstreakSheen", "A cookie for reading the saved Killstreak Sheen", CookieAccess_Private);
	PrimaryKillstreakEffectCookie = RegClientCookie("PrimaryKillstreakEffect", "A cookie for reading the saved Killstreak Effect", CookieAccess_Private);
	SecondaryKillstreakTierCookie = RegClientCookie("SecondaryKillstreakTier", "A cookie for reading the saved Killstreak Cookie", CookieAccess_Private);
	SecondaryKillstreakSheenCookie = RegClientCookie("SecondaryKillstreakSheen", "A cookie for reading the saved Killstreak Sheen", CookieAccess_Private);
	SecondaryKillstreakEffectCookie = RegClientCookie("SecondaryKillstreakEffect", "A cookie for reading the saved Killstreak Effect", CookieAccess_Private);
	MeleeKillstreakTierCookie = RegClientCookie("MeleeKillstreakTier", "A cookie for reading the saved Killstreak Cookie", CookieAccess_Private);
	MeleeKillstreakSheenCookie = RegClientCookie("MeleeKillstreakSheen", "A cookie for reading the saved Killstreak Sheen", CookieAccess_Private);
	MeleeKillstreakEffectCookie = RegClientCookie("MeleeKillstreakEffect", "A cookie for reading the saved Killstreak Effect", CookieAccess_Private);
	
	// Hooks
	HookEvent("player_spawn", PlayerSpawn, EventHookMode_Post);
	HookEvent("player_death", PlayerDeath, EventHookMode_Pre);
	HookEvent("post_inventory_application", OnResupply);
	
	// Admin Commands
	RegAdminCmd("sm_wearables", WearablesMenu, ADMFLAG_RESERVATION, "Shows the wearables menu.");
	//RegAdminCmd("sm_warpaint", WarPaintTest, ADMFLAG_RESERVATION, "Tests warpaints");
	
	// Player Commands
	
	// Command Listeners
	//AddCommandListener(Command_Taunt, "taunt"); // +taunt and taunt_by_name both turn out as just "taunt" to the server.
}

// Simple command to show menu.
public Action WearablesMenu(int client, int args)
{
	Menu menu = new Menu(WearablesMenu_Handler, MENU_ACTIONS_ALL);
	
	menu.SetTitle("Wearables Menu");
	
	menu.AddItem(KILLSTREAKS, "Killstreaks");
	menu.AddItem(UNUSUALS, "Weapon Unusuals");
	menu.AddItem(UNUSUALTAUNTS, "Unusual Taunts");
	menu.AddItem(AUSTRALIUMS, "Item Attributes");
	//menu.AddItem(WARPAINTS, "War Paints");
	
	menu.ExitButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
	
	return Plugin_Handled; // Return Plugin_Handled to prevent "unknown command issues."
}

/*public Action WarPaintTest(int client, int args)
{
	static const float WEAR_LEVELS[] = {
		0.200, 0.400, 0.600, 0.800, 1.00
	};
	
	int weapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
	
	int hOwnerEntity = GetEntPropEnt(weapon, Prop_Send, "m_hOwnerEntity");
	//SetEntProp(weapon, Prop_Send, "m_iEntityQuality", TF2ItemQuality_Rarity2);
	int itemid = GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex");
	int itemidlow = GetEntProp(weapon, Prop_Send, "m_iItemIDLow");
	int userid = IsValidEntity(hOwnerEntity) ? GetClientUserId(hOwnerEntity) : 0;
	
	//int seed[3];
	//seed[0] = itemIDLow;
	//seed[1] = defindex;
	//seed[2] = userid;
	
	//SetURandomSeed(seed, sizeof(seed));
	
	
	if(IsValidEntity(weapon))
		SetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex", 15000);
	
	return Plugin_Handled;
}*/

// Next, make the handler.
public int WearablesMenu_Handler(Menu menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_Start:
		{
			// It's important to log anything in any way, the best is printtoserver, but if you just want to log to client to make it easier to get progress done, feel free.
			PrintToServer("Displaying menu"); // Log it
		}
		
		case MenuAction_Display:
		{
			PrintToServer("Client %d was sent menu with panel %x", param1, param2); // Log so you can check if it gets sent.
		}
		
		case MenuAction_Select:
		{
			char sInfo[32];
			menu.GetItem(param2, sInfo, sizeof(sInfo));
			
			switch (param2)
			{
				case iKILLSTREAKS:
				{
					DrawKillstreaksMenu(param1);
				}
				case iUNUSUALS:
				{
					DrawWeaponUnusualMenu(param1);
				}
				case iUNUSUALTAUNTS:
				{
					DrawUnusualTauntMenu(param1);
				}
				case iAUSTRALIUMS:
				{
					DrawItemAttributesMenu(param1);
				}
				case iWARPAINTS:
				{
					DrawToggleWarPaint(param1);
				}
			}
		}
		
		case MenuAction_Cancel:
		{
			PrintToServer("Client %d's menu was cancelled for reason %d", param1, param2); // Logging once again.
		}
		
		case MenuAction_End:
		{
			delete menu;
		}
		
		case MenuAction_DrawItem:
		{
			int style;
			char info[32];
			menu.GetItem(param2, info, sizeof(info), style);
		}
		
		case MenuAction_DisplayItem:
		{
			char info[32];
			menu.GetItem(param2, info, sizeof(info));
		}
	}
}

public Action PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	int weapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
	
	//CheckTaunt[client] = CreateTimer(3.0, Timer_CheckTaunt, GetClientSerial(client), TIMER_REPEAT);
	
	if (AreClientCookiesCached(client))
	{
		// Weapon Effect Float Cooie
		char sCookieFloat[64];
		GetClientCookie(client, UnusualWeaponFloatCookie, sCookieFloat, sizeof(sCookieFloat));
		
		float fCookie = StringToFloat(sCookieFloat);
		
		// Weapon Effect String Cookie
		char sCookieValue[64];
		GetClientCookie(client, UnusualWeaponCookie, sCookieValue, sizeof(sCookieValue));
		
		// Weapon Effect Bool Cookie
		char sCookieBool[2];
		GetClientCookie(client, UnusualWeaponBoolCookie, sCookieBool, sizeof(sCookieBool));
		
		int iCookie = StringToInt(sCookieBool);
		
		if (iCookie == 1) // Check bool
		{
			if (IsValidEntity(weapon))
			{
				TF2Attrib_SetByDefIndex(weapon, 134, fCookie); // Set weapon effect index
				AttachParticleWeapon(weapon, sCookieValue, _); // Attach weapon effect string
			}
		}
	}
}

public Action OnResupply(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	//if (IsClientInGame(client) && bNeedsWarPaint[client])
	//	ApplyWarPaint(client);
		
	int slot1 = GetPlayerWeaponSlot(client, TFWeaponSlot_Primary);
	int slot2 = GetPlayerWeaponSlot(client, TFWeaponSlot_Secondary);
	int slot3 = GetPlayerWeaponSlot(client, TFWeaponSlot_Melee);
		
	if (AreClientCookiesCached(client))
	{
		// KS Tiers
		
		// Primary	
		char sPrimaryCookieTierValue[64];
		GetClientCookie(client, PrimaryKillstreakTierCookie, sPrimaryCookieTierValue, sizeof(sPrimaryCookieTierValue));
		
		float fPrimaryCookieTierValue = StringToFloat(sPrimaryCookieTierValue);
		
		if (fPrimaryCookieTierValue > 0.0) // If tier cookie is higher than 0.0
		{
			if(IsValidEntity(slot1))
				TF2Attrib_SetByDefIndex(slot1, 2025, fPrimaryCookieTierValue); // Set it to choice picked in menu.
		}
		
		if(g_bLogToConsole.BoolValue)
			PrintToServer("Retrieved %N's PrimaryKillstreakTierCookie with %s", client, sPrimaryCookieTierValue);
		
		// Secondary
		char sSecondaryCookieTierValue[64];
		GetClientCookie(client, SecondaryKillstreakTierCookie, sSecondaryCookieTierValue, sizeof(sSecondaryCookieTierValue));
		
		float fSecondaryCookieTierValue = StringToFloat(sSecondaryCookieTierValue);
		
		if (fSecondaryCookieTierValue > 0.0) // If tier cookie is higher than 0.0
		{
			if(IsValidEntity(slot2))
				TF2Attrib_SetByDefIndex(slot2, 2025, fSecondaryCookieTierValue); // Set it to choice picked in menu.
		}
		
		if(g_bLogToConsole.BoolValue)
			PrintToServer("Retrieved %N's SecondaryKillstreakTierCookie with %s", client, sSecondaryCookieTierValue);
		
		// Melee
		char sMeleeCookieTierValue[64];
		GetClientCookie(client, MeleeKillstreakTierCookie, sMeleeCookieTierValue, sizeof(sMeleeCookieTierValue));
		
		float fMeleeCookieTierValue = StringToFloat(sMeleeCookieTierValue);
		
		if (fMeleeCookieTierValue > 0.0) // If tier cookie is higher than 0.0
		{
			if(IsValidEntity(slot3))
				TF2Attrib_SetByDefIndex(slot3, 2025, fMeleeCookieTierValue); // Set it to choice picked in menu.
		}
		
		if(g_bLogToConsole.BoolValue)
			PrintToServer("Retrieved %N's MeleeKillstreakTierCookie with %s", client, sPrimaryCookieTierValue);
		
		// KS Effects
		
		// Primary	
		char sPrimaryCookieEffectValue[64];
		GetClientCookie(client, PrimaryKillstreakEffectCookie, sPrimaryCookieEffectValue, sizeof(sPrimaryCookieEffectValue));
		
		float fPrimaryCookieEffectValue = StringToFloat(sPrimaryCookieEffectValue);
		
		if (fPrimaryCookieEffectValue > 0.0) // If tier cookie is higher than 0.0
		{
			if(IsValidEntity(slot1))
				TF2Attrib_SetByDefIndex(slot1, 2025, fPrimaryCookieEffectValue); // Set it to choice picked in menu.
		}
		
		if(g_bLogToConsole.BoolValue)
			PrintToServer("Retrieved %N's PrimaryKillstreakEffectCookie with %s", client, sPrimaryCookieEffectValue);
		
		// Secondary
		char sSecondaryCookieEffectValue[64];
		GetClientCookie(client, SecondaryKillstreakEffectCookie, sSecondaryCookieEffectValue, sizeof(sSecondaryCookieEffectValue));
		
		float fSecondaryCookieEffectValue = StringToFloat(sSecondaryCookieEffectValue);
		
		if (fSecondaryCookieEffectValue > 0.0) // If tier cookie is higher than 0.0
		{
			if(IsValidEntity(slot2))
				TF2Attrib_SetByDefIndex(slot2, 2025, fSecondaryCookieEffectValue); // Set it to choice picked in menu.
		}
		
		if(g_bLogToConsole.BoolValue)
			PrintToServer("Retrieved %N's SecondaryKillstreakEffectCookie with %s", client, sPrimaryCookieEffectValue);
		
		// Melee
		char sMeleeCookieEffectValue[64];
		GetClientCookie(client, MeleeKillstreakEffectCookie, sMeleeCookieEffectValue, sizeof(sMeleeCookieEffectValue));
		
		float fMeleeCookieEffectValue = StringToFloat(sMeleeCookieEffectValue);
		
		if (fMeleeCookieEffectValue > 0.0) // If tier cookie is higher than 0.0
		{
			if(IsValidEntity(slot3))
				TF2Attrib_SetByDefIndex(slot3, 2025, fMeleeCookieEffectValue); // Set it to choice picked in menu.
		}
		
		if(g_bLogToConsole.BoolValue)
			PrintToServer("Retrieved %N's MeleeKillstreakEffectCookie with %s", client, sMeleeCookieEffectValue);
		
		// KS Sheen
		
		// Primary	
		char sPrimaryCookieSheenValue[64];
		GetClientCookie(client, PrimaryKillstreakSheenCookie, sPrimaryCookieSheenValue, sizeof(sPrimaryCookieSheenValue));
		
		float fPrimaryCookieSheenValue = StringToFloat(sPrimaryCookieSheenValue);
		
		if (fPrimaryCookieSheenValue > 0.0) // If tier cookie is higher than 0.0
		{
			if(IsValidEntity(slot1))
				TF2Attrib_SetByDefIndex(slot1, 2025, fPrimaryCookieSheenValue); // Set it to choice picked in menu.
		}
		
		if(g_bLogToConsole.BoolValue)
			PrintToServer("Retrieved %N's PrimaryKillstreakSheenCookie with %s", client, sPrimaryCookieSheenValue);
		
		// Secondary
		char sSecondaryCookieSheenValue[64];
		GetClientCookie(client, SecondaryKillstreakSheenCookie, sSecondaryCookieSheenValue, sizeof(sSecondaryCookieSheenValue));
		
		float fSecondaryCookieSheenValue = StringToFloat(sSecondaryCookieSheenValue);
		
		if (fSecondaryCookieSheenValue > 0.0) // If tier cookie is higher than 0.0
		{
			if(IsValidEntity(slot2))
				TF2Attrib_SetByDefIndex(slot2, 2025, fSecondaryCookieSheenValue); // Set it to choice picked in menu.
		}
		
		if(g_bLogToConsole.BoolValue)
			PrintToServer("Retrieved %N's SecondaryKillstreakSheenCookie with %s", client, sSecondaryCookieSheenValue);
		
		// Melee
		char sMeleeCookieSheenValue[64];
		GetClientCookie(client, MeleeKillstreakSheenCookie, sMeleeCookieSheenValue, sizeof(sMeleeCookieSheenValue));
		
		float fMeleeCookieSheenValue = StringToFloat(sMeleeCookieSheenValue);
		
		if (fMeleeCookieSheenValue > 0.0) // If tier cookie is higher than 0.0
		{
			if(IsValidEntity(slot3))
				TF2Attrib_SetByDefIndex(slot3, 2025, fMeleeCookieSheenValue); // Set it to choice picked in menu.
		}
		
		if(g_bLogToConsole.BoolValue)
			PrintToServer("Retrieved %N's MeleeKillstreakSheenCookie with %s", client, sMeleeCookieSheenValue);
	}
}

public Action PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	DeleteParticle(g_Ent[client]);
	DeleteParticle(g_WepEnt[client]);
	
	g_bIsTaunting[client] = false;
	
	//if (CheckTaunt[client] != null)
	//KillTimer(CheckTaunt[client]);
}

public void TF2_OnConditionAdded(int client, TFCond condition)
{
	if (condition == TFCond_Taunting)
	{
		if (IsClientInGame(client) && IsPlayerAlive(client))
		{
			g_bIsTaunting[client] = true;
			
			if (AreClientCookiesCached(client))
			{
				char sCookieValue[64];
				GetClientCookie(client, UnusualTauntCookie, sCookieValue, sizeof(sCookieValue));
				
				DeleteParticle(g_Ent[client]);
				AttachParticle(client, sCookieValue);
				
				// Check if taunt needs to be refired.
				if (StrEqual(sCookieValue, "utaunt_firework_teamcolor_red"))
					RefireShowStopperRed[client] = CreateTimer(2.6, RefireShowStopperRedTimer, GetClientSerial(client), TIMER_REPEAT);
				else if (StrEqual(sCookieValue, "utaunt_firework_teamcolor_blue"))
					RefireShowStopperBlue[client] = CreateTimer(2.6, RefireShowStopperBlueTimer, GetClientSerial(client), TIMER_REPEAT);
				else if (StrEqual(sCookieValue, "utaunt_lightning_parent"))
					RefireMegaStrike[client] = CreateTimer(0.9, RefireMegaStrikeTimer, GetClientSerial(client), TIMER_REPEAT);
				else if (StrEqual(sCookieValue, "utaunt_firework_dragon_parent"))
					RefireRoaringRockets[client] = CreateTimer(5.25, RefireRoaringRocketsTimer, GetClientSerial(client), TIMER_REPEAT);
			}
		}
	}
}

public void TF2_OnConditionRemoved(int client, TFCond condition)
{
	if (condition == TFCond_Taunting)
	{
		if (IsClientInGame(client) && IsPlayerAlive(client))
		{
			g_bIsTaunting[client] = false;
			
			DeleteParticle(g_Ent[client]);
			
			//REFIRE TIMERS
			if (RefireShowStopperRed[client] != null)
			{
				KillTimer(RefireShowStopperRed[client]);
				RefireShowStopperRed[client] = null;
			}
			else if (RefireShowStopperBlue[client] != null)
			{
				KillTimer(RefireShowStopperBlue[client]);
				RefireShowStopperBlue[client] = null;
			}
			else if (RefireMegaStrike[client] != null)
			{
				KillTimer(RefireMegaStrike[client]);
				RefireMegaStrike[client] = null;
			}
			else if (RefireRoaringRockets[client] != null)
			{
				KillTimer(RefireRoaringRockets[client]);
				RefireRoaringRockets[client] = null;
			}
		}
	}
}

// REFIRE TIMERS

public Action RefireShowStopperRedTimer(Handle timer, any serial)
{
	int client = GetClientFromSerial(serial); // Validate the client serial
	
	if (client != 0)
	{
		if (IsClientInGame(client) && IsPlayerAlive(client))
		{
			if (AreClientCookiesCached(client))
			{
				char sCookieValue[64];
				GetClientCookie(client, UnusualTauntCookie, sCookieValue, sizeof(sCookieValue));
				
				AttachParticle(client, sCookieValue);
			}
		}
	}
}

public Action RefireShowStopperBlueTimer(Handle timer, any serial)
{
	int client = GetClientFromSerial(serial); // Validate the client serial
	
	if (client != 0)
	{
		if (IsClientInGame(client) && IsPlayerAlive(client))
		{
			if (AreClientCookiesCached(client))
			{
				char sCookieValue[64];
				GetClientCookie(client, UnusualTauntCookie, sCookieValue, sizeof(sCookieValue));
				
				AttachParticle(client, sCookieValue);
			}
		}
	}
}

public Action RefireMegaStrikeTimer(Handle timer, any serial)
{
	int client = GetClientFromSerial(serial); // Validate the client serial
	
	if (client != 0)
	{
		if (IsClientInGame(client) && IsPlayerAlive(client))
		{
			if (AreClientCookiesCached(client))
			{
				char sCookieValue[64];
				GetClientCookie(client, UnusualTauntCookie, sCookieValue, sizeof(sCookieValue));
				
				AttachParticle(client, sCookieValue);
			}
		}
	}
}

public Action RefireRoaringRocketsTimer(Handle timer, any serial)
{
	int client = GetClientFromSerial(serial); // Validate the client serial
	
	if (client != 0)
	{
		if (IsClientInGame(client) && IsPlayerAlive(client))
		{
			if (AreClientCookiesCached(client))
			{
				char sCookieValue[64];
				GetClientCookie(client, UnusualTauntCookie, sCookieValue, sizeof(sCookieValue));
				
				AttachParticle(client, sCookieValue);
			}
		}
	}
}

public int UnusualTauntMenu_Handler(Menu menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_Start:
		{
			PrintToServer("Displaying menu"); // Log it
		}
		
		case MenuAction_Display:
		{
			PrintToServer("Client %d was sent menu with panel %x", param1, param2);
		}
		
		case MenuAction_Select:
		{
			char info[24];
			GetMenuItem(menu, param2, info, sizeof(info));
			
			if (!g_bIsTaunting[param1])
			{
				switch (param2)
				{
					case 0:
					{
						HasPickedUnusualTaunt[param1] = false;
						DeleteParticle(g_Ent[param1]);
						CPrintToChat(param1, "{magenta}Sanctuary.TF {white}| You have reset your effect.");
					}
					case 1:
					{
						HasPickedUnusualTaunt[param1] = true;
						//Format(UnusualTauntID[param1], sizeof(UnusualTauntID[]), "%s", "utaunt_firework_teamcolor_red"); // Thank you Techno
						UnusualTauntID[param1] = "utaunt_firework_teamcolor_red";
						CPrintToChat(param1, "{magenta}Sanctuary.TF {white}| You have picked effect Showstopper (RED)");
					}
					case 2:
					{
						HasPickedUnusualTaunt[param1] = true;
						UnusualTauntID[param1] = "utaunt_firework_teamcolor_blue";
						//Format(UnusualTauntID[param1], sizeof(UnusualTauntID[]), "%s", "utaunt_firework_teamcolor_blue");
						CPrintToChat(param1, "{magenta}Sanctuary.TF {white}| You have picked effect Showstopper (BLU)");
					}
					case 3:
					{
						HasPickedUnusualTaunt[param1] = true;
						UnusualTauntID[param1] = "utaunt_beams_yellow";
						CPrintToChat(param1, "{magenta}Sanctuary.TF {white}| You have picked effect Holy Grail");
					}
					case 4:
					{
						HasPickedUnusualTaunt[param1] = true;
						UnusualTauntID[param1] = "utaunt_disco_party";
						CPrintToChat(param1, "{magenta}Sanctuary.TF {white}| You have picked effect '72");
					}
					case 5:
					{
						HasPickedUnusualTaunt[param1] = true;
						UnusualTauntID[param1] = "utaunt_hearts_glow_parent";
						CPrintToChat(param1, "{magenta}Sanctuary.TF {white}| You have picked effect Fountain Of Delight");
					}
					case 6:
					{
						HasPickedUnusualTaunt[param1] = true;
						UnusualTauntID[param1] = "utaunt_meteor_parent";
						CPrintToChat(param1, "{magenta}Sanctuary.TF {white}| You have picked effect Screaming Tiger", info);
					}
					case 7:
					{
						HasPickedUnusualTaunt[param1] = true;
						UnusualTauntID[param1] = "utaunt_cash_confetti";
						CPrintToChat(param1, "{magenta}Sanctuary.TF {white}| You have picked effect Skill Gotten Gains", info);
					}
					case 8:
					{
						HasPickedUnusualTaunt[param1] = true;
						UnusualTauntID[param1] = "utaunt_tornado_parent_black";
						CPrintToChat(param1, "{magenta}Sanctuary.TF {white}| You have picked effect Midnight Whirlwind", info);
					}
					case 9:
					{
						HasPickedUnusualTaunt[param1] = true;
						UnusualTauntID[param1] = "utaunt_tornado_parent_white";
						CPrintToChat(param1, "{magenta}Sanctuary.TF {white}| You have picked effect Silver Cyclone", info);
					}
					case 10:
					{
						HasPickedUnusualTaunt[param1] = true;
						UnusualTauntID[param1] = "utaunt_lightning_parent";
						CPrintToChat(param1, "{magenta}Sanctuary.TF {white}| You have picked effect Mega Strike", info);
					}
					case 11:
					{
						HasPickedUnusualTaunt[param1] = true;
						UnusualTauntID[param1] = "utaunt_souls_green_parent";
						CPrintToChat(param1, "{magenta}Sanctuary.TF {white}| You have picked effect Haunted Phantasm", info);
					}
					case 12:
					{
						HasPickedUnusualTaunt[param1] = true;
						UnusualTauntID[param1] = "utaunt_souls_purple_parent";
						CPrintToChat(param1, "{magenta}Sanctuary.TF {white}| You have picked effect Ghastly Ghosts", info);
					}
					case 13:
					{
						HasPickedUnusualTaunt[param1] = true;
						UnusualTauntID[param1] = "utaunt_hellpit_parent";
						CPrintToChat(param1, "{magenta}Sanctuary.TF {white}| You have picked effect Hellish Inferno", info);
					}
					case 14:
					{
						HasPickedUnusualTaunt[param1] = true;
						UnusualTauntID[param1] = "utaunt_firework_dragon_parent";
						CPrintToChat(param1, "{magenta}Sanctuary.TF {white}| You have picked effect Roaring Rockets", info);
					}
					case 15:
					{
						HasPickedUnusualTaunt[param1] = true;
						UnusualTauntID[param1] = "utaunt_bubbles_glow_green_parent";
						CPrintToChat(param1, "{magenta}Sanctuary.TF {white}| You have picked effect Acid Bubbles of Envy", info);
					}
					case 16:
					{
						HasPickedUnusualTaunt[param1] = true;
						UnusualTauntID[param1] = "utaunt_bubbles_glow_orange_parent";
						CPrintToChat(param1, "{magenta}Sanctuary.TF {white}| You have picked effect Flammable Bubbles of Attraction", info);
					}
					case 17:
					{
						HasPickedUnusualTaunt[param1] = true;
						UnusualTauntID[param1] = "utaunt_bubbles_glow_purple_parent";
						CPrintToChat(param1, "{magenta}Sanctuary.TF {white}| You have picked effect Poisonous Bubbles of Regret", info);
					}
				}
			}
			else
			{
				CPrintToChat(param1, "{magenta}Sanctuary.TF {white}| You may not change effect when taunting.");
				DrawUnusualTauntMenu(param1);
			}
			
			if (AreClientCookiesCached(param1))
			{
				char sCookieValue[64];
				GetClientCookie(param1, UnusualTauntCookie, sCookieValue, sizeof(sCookieValue));
				
				sCookieValue = UnusualTauntID[param1];
				
				SetClientCookie(param1, UnusualTauntCookie, sCookieValue);
			}
		}
		
		case MenuAction_Cancel:
		{
			PrintToServer("Client %d's menu was cancelled for reason %d", param1, param2);
		}
		
		case MenuAction_End:
		{
			delete menu;
		}
		
		case MenuAction_DrawItem:
		{
			int style;
			char info[32];
			menu.GetItem(param2, info, sizeof(info), style);
		}
		
		case MenuAction_DisplayItem:
		{
			char info[32];
			menu.GetItem(param2, info, sizeof(info));
		}
	}
}

public int UnusualWeaponMenu_Handler(Menu menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_Start:
		{
			PrintToServer("Displaying menu"); // Log it
		}
		
		case MenuAction_Display:
		{
			PrintToServer("Client %d was sent menu with panel %x", param1, param2);
		}
		
		case MenuAction_Select:
		{
			char info[24];
			GetMenuItem(menu, param2, info, sizeof(info));
			int weapon = GetEntPropEnt(param1, Prop_Send, "m_hActiveWeapon");
			float effect = StringToFloat(info);
			WeaponUnusualID[param1] = effect;
			
			switch (param2)
			{
				case 0:
				{
					if (IsValidEntity(weapon))
					{
						TF2Attrib_SetByDefIndex(weapon, 370, effect);
						AttachParticleWeapon(weapon, "", _);
					}
					HasPickedWeaponUnusual[param1] = false;
					CPrintToChat(param1, "{magenta}Sanctuary.TF {white}| You have reset your weapon effect.");
				}
				case 1:
				{
					if (IsValidEntity(weapon))
					{
						TF2Attrib_SetByDefIndex(weapon, 370, effect);
						AttachParticleWeapon(weapon, "weapon_unusual_hot", _);
						strWeaponUnusual[param1] = "weapon_unusual_hot";
					}
					HasPickedWeaponUnusual[param1] = true;
					CPrintToChat(param1, "{magenta}Sanctuary.TF {white}| You have chosen weapon effect Hot");
				}
				case 2:
				{
					if (IsValidEntity(weapon))
					{
						TF2Attrib_SetByDefIndex(weapon, 370, effect);
						AttachParticleWeapon(weapon, "weapon_unusual_isotope", _);
						strWeaponUnusual[param1] = "weapon_unusual_isotope";
					}
					HasPickedWeaponUnusual[param1] = true;
					CPrintToChat(param1, "{magenta}Sanctuary.TF {white}| You have chosen weapon effect Isotope");
				}
				case 3:
				{
					if (IsValidEntity(weapon))
					{
						HasPickedWeaponUnusual[param1] = true;
						TF2Attrib_SetByDefIndex(weapon, 370, effect);
						AttachParticleWeapon(weapon, "weapon_unusual_cool", _);
						strWeaponUnusual[param1] = "weapon_unusual_cool";
					}
					HasPickedWeaponUnusual[param1] = true;
					CPrintToChat(param1, "{magenta}Sanctuary.TF {white}| You have chosen weapon effect Cool");
				}
				case 4:
				{
					if (IsValidEntity(weapon))
					{
						TF2Attrib_SetByDefIndex(weapon, 370, effect);
						AttachParticleWeapon(weapon, "weapon_unusual_energyorb", _);
						strWeaponUnusual[param1] = "weapon_unusual_energyorb";
					}
					HasPickedWeaponUnusual[param1] = true;
					CPrintToChat(param1, "{magenta}Sanctuary.TF {white}| You have chosen weapon effect Energy Orb");
				}
			}
			
			if (AreClientCookiesCached(param1))
			{
				char sCookieValue[64];
				GetClientCookie(param1, UnusualWeaponCookie, sCookieValue, sizeof(sCookieValue));
				
				sCookieValue = strWeaponUnusual[param1];
				
				SetClientCookie(param1, UnusualWeaponCookie, sCookieValue);
				
				char sCookieFloat[64];
				GetClientCookie(param1, UnusualWeaponFloatCookie, sCookieFloat, sizeof(sCookieFloat));
				
				float fCookie = StringToFloat(sCookieFloat);
				
				fCookie = effect;
				
				FloatToString(fCookie, sCookieFloat, sizeof(sCookieFloat));
				
				SetClientCookie(param1, UnusualWeaponFloatCookie, sCookieFloat);
				
				char sCookieBool[2];
				GetClientCookie(param1, UnusualWeaponBoolCookie, sCookieBool, sizeof(sCookieBool));
				
				int iCookie = StringToInt(sCookieBool);
				
				if (HasPickedWeaponUnusual[param1])
					iCookie = 1;
				else
					iCookie = 0;
				
				IntToString(iCookie, sCookieBool, sizeof(sCookieBool));
				
				SetClientCookie(param1, UnusualWeaponBoolCookie, sCookieBool);
			}
		}
		
		case MenuAction_Cancel:
		{
			PrintToServer("Client %d's menu was cancelled for reason %d", param1, param2);
		}
		
		case MenuAction_End:
		{
			delete menu;
		}
		
		case MenuAction_DrawItem:
		{
			int style;
			char info[32];
			menu.GetItem(param2, info, sizeof(info), style);
		}
		
		case MenuAction_DisplayItem:
		{
			char info[32];
			menu.GetItem(param2, info, sizeof(info));
		}
	}
}


public int KillstreaksMenu_Handler(Menu menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_Start:
		{
			PrintToServer("Displaying menu"); // Log it
		}
		
		case MenuAction_Display:
		{
			PrintToServer("Client %d was sent menu with panel %x", param1, param2);
		}
		
		case MenuAction_Select:
		{
			char sInfo[32];
			menu.GetItem(param2, sInfo, sizeof(sInfo));
			
			switch (param2)
			{
				case iKILLSTREAKSHEEN:
				{
					DrawSheenSelectionMenu(param1);
				}
				case iKILLSTREAKTIERS:
				{
					DrawTiersSelectionMenu(param1);
				}
				case iKILLSTREAKEFFECT:
				{
					DrawEffectsSelectionMenu(param1);
				}
			}
		}
		
		case MenuAction_Cancel:
		{
			PrintToServer("Client %d's menu was cancelled for reason %d", param1, param2);
		}
		
		case MenuAction_End:
		{
			delete menu;
		}
		
		case MenuAction_DrawItem:
		{
			int style;
			char info[32];
			menu.GetItem(param2, info, sizeof(info), style);
		}
		
		case MenuAction_DisplayItem:
		{
			char info[32];
			menu.GetItem(param2, info, sizeof(info));
		}
	}
}

public int KillstreakTiersMenu_Handler(Menu menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_Start:
		{
			PrintToServer("Displaying menu"); // Log it
		}
		
		case MenuAction_Display:
		{
			PrintToServer("Client %d was sent menu with panel %x", param1, param2);
		}
		
		case MenuAction_Select:
		{
			int weapon;
			char sSlot[32];
			
			if (iPrimarySlotTiersChosen[param1])
			{
				weapon = GetPlayerWeaponSlot(param1, TFWeaponSlot_Primary);
				sSlot = "Primary";
			}
			else if (iSecondarySlotTiersChosen[param1])
			{
				weapon = GetPlayerWeaponSlot(param1, TFWeaponSlot_Secondary);
				sSlot = "Secondary";
			}
			else if (iMeleeSlotTiersChosen[param1])
			{
				weapon = GetPlayerWeaponSlot(param1, TFWeaponSlot_Melee);
				sSlot = "Melee";
			}
			
			char sInfo[32];
			menu.GetItem(param2, sInfo, sizeof(sInfo));
			float tier = StringToFloat(sInfo);
			KillstreakTierID[param1] = tier;
			
			if (IsValidEntity(weapon))
			{
				TF2Attrib_SetByDefIndex(weapon, 2025, tier);
			}
			
			CPrintToChat(param1, "{magenta}Sanctuary.TF {white}| You have selected killstreak tier %f, on slot %s", tier, sSlot);
			if (GetConVarBool(RegeneratePlayer))
				TF2_RegeneratePlayer(param1);
			
			sSlot = "";
			
			if (AreClientCookiesCached(param1))
			{
				if (iPrimarySlotTiersChosen[param1])
				{
					char sPrimaryCookieValue[64];
					GetClientCookie(param1, PrimaryKillstreakTierCookie, sPrimaryCookieValue, sizeof(sPrimaryCookieValue));
					
					float fPrimaryCookieValue = StringToFloat(sPrimaryCookieValue);
					
					fPrimaryCookieValue = tier;
					
					FloatToString(fPrimaryCookieValue, sPrimaryCookieValue, sizeof(sPrimaryCookieValue));
					
					SetClientCookie(param1, PrimaryKillstreakTierCookie, sPrimaryCookieValue);
					
					PrintToServer("Updated %N's PrimaryKillstreakTierCookie with %s", param1, sPrimaryCookieValue);
				}
				else if (iSecondarySlotTiersChosen[param1])
				{
					char sSecondaryCookieValue[64];
					GetClientCookie(param1, SecondaryKillstreakTierCookie, sSecondaryCookieValue, sizeof(sSecondaryCookieValue));
					
					float fSecondaryCookieValue = StringToFloat(sSecondaryCookieValue);
					
					fSecondaryCookieValue = tier;
					
					FloatToString(fSecondaryCookieValue, sSecondaryCookieValue, sizeof(sSecondaryCookieValue));
					
					SetClientCookie(param1, SecondaryKillstreakTierCookie, sSecondaryCookieValue);
					
					PrintToServer("Updated %N's SecondaryKillstreakTierCookie with %s", param1, sSecondaryCookieValue);
				}
				else if (iMeleeSlotTiersChosen[param1])
				{
					char sMeleeCookieValue[64];
					GetClientCookie(param1, MeleeKillstreakTierCookie, sMeleeCookieValue, sizeof(sMeleeCookieValue));
					
					float fMeleeCookieValue = StringToFloat(sMeleeCookieValue);
					
					fMeleeCookieValue = tier;
					
					FloatToString(fMeleeCookieValue, sMeleeCookieValue, sizeof(sMeleeCookieValue));
					
					SetClientCookie(param1, MeleeKillstreakTierCookie, sMeleeCookieValue);
					
					PrintToServer("Updated %N's MeleeKillstreakTierCookie with %s", param1, sMeleeCookieValue);
				}
			}
			
			// Reset Values
			iPrimarySlotTiersChosen[param1] = false;
			iSecondarySlotTiersChosen[param1] = false;
			iMeleeSlotTiersChosen[param1] = false;
		}
		
		case MenuAction_Cancel:
		{
			PrintToServer("Client %d's menu was cancelled for reason %d", param1, param2);
			
			// Reset Values
			iPrimarySlotTiersChosen[param1] = false;
			iSecondarySlotTiersChosen[param1] = false;
			iMeleeSlotTiersChosen[param1] = false;
		}
		
		case MenuAction_End:
		{
			delete menu;
		}
		
		case MenuAction_DrawItem:
		{
			int style;
			char info[32];
			menu.GetItem(param2, info, sizeof(info), style);
		}
		
		case MenuAction_DisplayItem:
		{
			char info[32];
			menu.GetItem(param2, info, sizeof(info));
		}
	}
}

public int KillstreakEffectMenu_Handler(Menu menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_Start:
		{
			PrintToServer("Displaying menu"); // Log it
		}
		
		case MenuAction_Display:
		{
			PrintToServer("Client %d was sent menu with panel %x", param1, param2);
		}
		
		case MenuAction_Select:
		{
			int weapon;
			char sSlot[32];
			
			if (iPrimarySlotEffectsChosen[param1])
			{
				weapon = GetPlayerWeaponSlot(param1, TFWeaponSlot_Primary);
				sSlot = "Primary";
			}
			else if (iSecondarySlotEffectsChosen[param1])
			{
				weapon = GetPlayerWeaponSlot(param1, TFWeaponSlot_Secondary);
				sSlot = "Secondary";
			}
			else if (iMeleeSlotEffectsChosen[param1])
			{
				weapon = GetPlayerWeaponSlot(param1, TFWeaponSlot_Melee);
				sSlot = "Melee";
			}
			
			char sInfo[32];
			menu.GetItem(param2, sInfo, sizeof(sInfo));
			float effect = StringToFloat(sInfo);
			KillstreakEffectID[param1] = effect;
			
			if (IsValidEntity(weapon))
			{
				TF2Attrib_SetByDefIndex(weapon, 2013, effect);
			}
			
			CPrintToChat(param1, "{magenta}Sanctuary.TF {white}| You have selected killstreak effect %f, on slot %s", effect, sSlot);
			if (GetConVarBool(RegeneratePlayer))
				TF2_RegeneratePlayer(param1);
			
			sSlot = "";
			
			if (AreClientCookiesCached(param1))
			{
				if (iPrimarySlotEffectsChosen[param1])
				{
					char sPrimaryCookieValue[64];
					GetClientCookie(param1, PrimaryKillstreakEffectCookie, sPrimaryCookieValue, sizeof(sPrimaryCookieValue));
					
					float fPrimaryCookieValue = StringToFloat(sPrimaryCookieValue);
					
					fPrimaryCookieValue = effect;
					
					FloatToString(fPrimaryCookieValue, sPrimaryCookieValue, sizeof(sPrimaryCookieValue));
					
					SetClientCookie(param1, PrimaryKillstreakEffectCookie, sPrimaryCookieValue);
					
					PrintToServer("Updated %N's PrimaryKillstreakEffectCookie with %s", param1, sPrimaryCookieValue);
				}
				else if (iSecondarySlotEffectsChosen[param1])
				{
					char sSecondaryCookieValue[64];
					GetClientCookie(param1, SecondaryKillstreakEffectCookie, sSecondaryCookieValue, sizeof(sSecondaryCookieValue));
					
					float fSecondaryCookieValue = StringToFloat(sSecondaryCookieValue);
					
					fSecondaryCookieValue = effect;
					
					FloatToString(fSecondaryCookieValue, sSecondaryCookieValue, sizeof(sSecondaryCookieValue));
					
					SetClientCookie(param1, SecondaryKillstreakEffectCookie, sSecondaryCookieValue);
					
					PrintToServer("Updated %N's SecondaryKillstreakEffectCookie with %s", param1, sSecondaryCookieValue);
				}
				else if (iMeleeSlotEffectsChosen[param1])
				{
					char sMeleeCookieValue[64];
					GetClientCookie(param1, MeleeKillstreakEffectCookie, sMeleeCookieValue, sizeof(sMeleeCookieValue));
					
					float fMeleeCookieValue = StringToFloat(sMeleeCookieValue);
					
					fMeleeCookieValue = effect;
					
					FloatToString(fMeleeCookieValue, sMeleeCookieValue, sizeof(sMeleeCookieValue));
					
					SetClientCookie(param1, MeleeKillstreakEffectCookie, sMeleeCookieValue);
					
					PrintToServer("Updated %N's MeleeKillstreakEffectCookie with %s", param1, sMeleeCookieValue);
				}
			}
			
			// Reset Values
			iPrimarySlotEffectsChosen[param1] = false;
			iSecondarySlotEffectsChosen[param1] = false;
			iMeleeSlotEffectsChosen[param1] = false;
		}
		
		case MenuAction_Cancel:
		{
			PrintToServer("Client %d's menu was cancelled for reason %d", param1, param2);
			
			iPrimarySlotEffectsChosen[param1] = false;
			iSecondarySlotEffectsChosen[param1] = false;
			iMeleeSlotEffectsChosen[param1] = false;
		}
		
		case MenuAction_End:
		{
			delete menu;
		}
		
		case MenuAction_DrawItem:
		{
			int style;
			char info[32];
			menu.GetItem(param2, info, sizeof(info), style);
		}
		
		case MenuAction_DisplayItem:
		{
			char info[32];
			menu.GetItem(param2, info, sizeof(info));
		}
	}
}

public int KillstreakSheenMenu_Handler(Menu menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_Start:
		{
			PrintToServer("Displaying menu"); // Log it
		}
		
		case MenuAction_Display:
		{
			PrintToServer("Client %d was sent menu with panel %x", param1, param2);
		}
		
		case MenuAction_Select:
		{
			int weapon;
			
			char sSlot[32];
			
			if (iPrimarySlotSheenChosen[param1])
			{
				weapon = GetPlayerWeaponSlot(param1, TFWeaponSlot_Primary);
				sSlot = "Primary";
			}
			else if (iSecondarySlotSheenChosen[param1])
			{
				weapon = GetPlayerWeaponSlot(param1, TFWeaponSlot_Secondary);
				sSlot = "Secondary";
			}
			else if (iMeleeSlotSheenChosen[param1])
			{
				weapon = GetPlayerWeaponSlot(param1, TFWeaponSlot_Melee);
				sSlot = "Melee";
			}
			
			char sInfo[32];
			menu.GetItem(param2, sInfo, sizeof(sInfo));
			float sheen = StringToFloat(sInfo);
			KillstreakSheenID[param1] = sheen;
			
			if (IsValidEntity(weapon))
			{
				TF2Attrib_SetByDefIndex(weapon, 2014, sheen);
			}
			
			CPrintToChat(param1, "{magenta}Sanctuary.TF {white}| You have selected killstreak effect %f, on slot %s", sheen, sSlot);
			if (GetConVarBool(RegeneratePlayer))
				TF2_RegeneratePlayer(param1);
			
			sSlot = "";
			
			if (AreClientCookiesCached(param1))
			{
				if (iPrimarySlotSheenChosen[param1])
				{
					char sPrimaryCookieValue[64];
					GetClientCookie(param1, PrimaryKillstreakSheenCookie, sPrimaryCookieValue, sizeof(sPrimaryCookieValue));
					
					float fPrimaryCookieValue = StringToFloat(sPrimaryCookieValue);
					
					fPrimaryCookieValue = sheen;
					
					FloatToString(fPrimaryCookieValue, sPrimaryCookieValue, sizeof(sPrimaryCookieValue));
					
					SetClientCookie(param1, PrimaryKillstreakSheenCookie, sPrimaryCookieValue);
					
					PrintToServer("Updated %N's PrimaryKillstreakSheenCookie with %s", param1, sPrimaryCookieValue);
				}
				else if (iSecondarySlotSheenChosen[param1])
				{
					char sSecondaryCookieValue[64];
					GetClientCookie(param1, SecondaryKillstreakSheenCookie, sSecondaryCookieValue, sizeof(sSecondaryCookieValue));
					
					float fSecondaryCookieValue = StringToFloat(sSecondaryCookieValue);
					
					fSecondaryCookieValue = sheen;
					
					FloatToString(fSecondaryCookieValue, sSecondaryCookieValue, sizeof(sSecondaryCookieValue));
					
					SetClientCookie(param1, SecondaryKillstreakSheenCookie, sSecondaryCookieValue);
					
					PrintToServer("Updated %N's SecondaryKillstreakSheenCookie with %s", param1, sSecondaryCookieValue);
				}
				else if (iMeleeSlotSheenChosen[param1])
				{
					char sMeleeCookieValue[64];
					GetClientCookie(param1, MeleeKillstreakSheenCookie, sMeleeCookieValue, sizeof(sMeleeCookieValue));
					
					float fMeleeCookieValue = StringToFloat(sMeleeCookieValue);
					
					fMeleeCookieValue = sheen;
					
					FloatToString(fMeleeCookieValue, sMeleeCookieValue, sizeof(sMeleeCookieValue));
					
					SetClientCookie(param1, MeleeKillstreakSheenCookie, sMeleeCookieValue);
					
					PrintToServer("Updated %N's MeleeKillstreakSheenCookie with %s", param1, sMeleeCookieValue);
				}
			}
			
			iPrimarySlotSheenChosen[param1] = false;
			iSecondarySlotSheenChosen[param1] = false;
			iMeleeSlotSheenChosen[param1] = false;
		}
		
		case MenuAction_Cancel:
		{
			PrintToServer("Client %d's menu was cancelled for reason %d", param1, param2);
			
			iPrimarySlotSheenChosen[param1] = false;
			iSecondarySlotSheenChosen[param1] = false;
			iMeleeSlotSheenChosen[param1] = false;
		}
		
		case MenuAction_End:
		{
			delete menu;
		}
		
		case MenuAction_DrawItem:
		{
			int style;
			char info[32];
			menu.GetItem(param2, info, sizeof(info), style);
		}
		
		case MenuAction_DisplayItem:
		{
			char info[32];
			menu.GetItem(param2, info, sizeof(info));
		}
	}
}

public int ItemAttributes_Handler(Menu menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_Start:
		{
			PrintToServer("Displaying menu"); // Log it
		}
		
		case MenuAction_Display:
		{
			PrintToServer("Client %d was sent menu with panel %x", param1, param2);
		}
		
		case MenuAction_Select:
		{
			int weapon = GetEntPropEnt(param1, Prop_Send, "m_hActiveWeapon");
			char sInfo[32];
			menu.GetItem(param2, sInfo, sizeof(sInfo));
			float choice = StringToFloat(sInfo);
			
			if (IsValidEntity(weapon))
			{
				if (choice == 2027.0)
					TF2Attrib_SetByDefIndex(weapon, 2027, 1.0);
				else if (choice == 2053)
					TF2Attrib_SetByDefIndex(weapon, 2053, 1.0);
			}
			
			CPrintToChat(param1, "{magenta}Sanctuary.TF {white}| You have selected item attribute %f", choice);
			if (GetConVarBool(RegeneratePlayer))
				TF2_RegeneratePlayer(param1);
		}
		
		case MenuAction_Cancel:
		{
			PrintToServer("Client %d's menu was cancelled for reason %d", param1, param2);
		}
		
		case MenuAction_End:
		{
			delete menu;
		}
		
		case MenuAction_DrawItem:
		{
			int style;
			char info[32];
			menu.GetItem(param2, info, sizeof(info), style);
		}
		
		case MenuAction_DisplayItem:
		{
			char info[32];
			menu.GetItem(param2, info, sizeof(info));
		}
	}
}

public int DrawToggleWarPaint_Handler(Menu menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_Start:
		{
			PrintToServer("Displaying menu"); // Log it
		}
		
		case MenuAction_Display:
		{
			PrintToServer("Client %d was sent menu with panel %x", param1, param2);
		}
		
		case MenuAction_Select:
		{
			char sInfo[32];
			menu.GetItem(param2, sInfo, sizeof(sInfo));
			float choice = StringToFloat(sInfo);
			
			if (choice == 0)
			{
				if (!bNeedsWarPaint[param1])
					bNeedsWarPaint[param1] = true;
				else if (bNeedsWarPaint[param1])
					bNeedsWarPaint[param1] = false;
			}
			
			CPrintToChat(param1, "{magenta}Sanctuary.TF {white}| You have toggled war paint.");
		}
		
		case MenuAction_Cancel:
		{
			PrintToServer("Client %d's menu was cancelled for reason %d", param1, param2);
		}
		
		case MenuAction_End:
		{
			delete menu;
		}
		
		case MenuAction_DrawItem:
		{
			int style;
			char info[32];
			menu.GetItem(param2, info, sizeof(info), style);
		}
		
		case MenuAction_DisplayItem:
		{
			char info[32];
			menu.GetItem(param2, info, sizeof(info));
		}
	}
}

// Let's make functions to use instead of doing massive lines of code just to draw menus.

void DrawKillstreaksMenu(int client)
{
	// Make the weapon paints menu.
	Menu menu = new Menu(KillstreaksMenu_Handler, MENU_ACTIONS_ALL);
	
	menu.SetTitle("Killstreaks"); // Self explanatory
	
	// Add the items
	menu.AddItem(KILLSTREAKSHEEN, "Killstreak Sheens");
	menu.AddItem(KILLSTREAKTIERS, "Killstreak Tiers");
	menu.AddItem(KILLSTREAKEFFECT, "Killstreak Effects");
	
	menu.ExitButton = true; // Self explanatory
	menu.Display(client, MENU_TIME_FOREVER); // Draw the menu to the client.
}

void DrawKillstreakTierMenu(int client)
{
	// Make the weapon paints menu.
	Menu menu = new Menu(KillstreakTiersMenu_Handler, MENU_ACTIONS_ALL);
	
	menu.SetTitle("Killstreak Tiers"); // Self explanatory
	
	// Add the items
	menu.AddItem("1", "Standard");
	menu.AddItem("2", "Specialized");
	menu.AddItem("3", "Professional");
	
	menu.ExitButton = true; // Self explanatory
	menu.Display(client, MENU_TIME_FOREVER); // Draw the menu to the client.
}

void DrawKillstreakEffectMenu(int client)
{
	// Make the weapon paints menu.
	Menu menu = new Menu(KillstreakEffectMenu_Handler, MENU_ACTIONS_ALL);
	
	menu.SetTitle("Killstreak Effects"); // Self explanatory
	
	// Add the items
	menu.AddItem("2002", "Fire Horns");
	menu.AddItem("2003", "Cerebral Discharge");
	menu.AddItem("2004", "Tornado");
	menu.AddItem("2005", "Flames");
	menu.AddItem("2006", "Singularity");
	menu.AddItem("2007", "Incinerator");
	menu.AddItem("2008", "Hypno-Beam");
	
	menu.ExitButton = true; // Self explanatory
	menu.Display(client, MENU_TIME_FOREVER); // Draw the menu to the client.
}

void DrawKillstreakSheenMenu(int client)
{
	// Make the weapon paints menu.
	Menu menu = new Menu(KillstreakSheenMenu_Handler, MENU_ACTIONS_ALL);
	
	menu.SetTitle("Killstreak Sheens"); // Self explanatory
	
	// Add the items
	menu.AddItem("1", "Team Shine");
	menu.AddItem("2", "Deadly Daffodil");
	menu.AddItem("3", "Manndarin");
	menu.AddItem("4", "Mean Green");
	menu.AddItem("5", "Agonizing Emerald");
	menu.AddItem("6", "Villainous Violet");
	menu.AddItem("7", "Hot Rod");
	
	menu.ExitButton = true; // Self explanatory
	menu.Display(client, MENU_TIME_FOREVER); // Draw the menu to the client.
}

void DrawUnusualTauntMenu(int client)
{
	// Make the weapon paints menu.
	Menu menu = new Menu(UnusualTauntMenu_Handler, MENU_ACTIONS_ALL);
	
	menu.SetTitle("Unusual Taunts"); // Self explanatory
	
	// Add the items
	menu.AddItem("0", "None");
	menu.AddItem("1", "Showstopper (RED)");
	menu.AddItem("2", "Showstopper (BLU)");
	menu.AddItem("3", "Holy Grail");
	menu.AddItem("4", "'72");
	menu.AddItem("5", "Fountain of Delight");
	menu.AddItem("6", "Screaming Tiger");
	menu.AddItem("7", "Skill Gotten Gains");
	menu.AddItem("8", "Midnight Whirlwind");
	menu.AddItem("9", "Silver Cyclone");
	menu.AddItem("10", "Mega Strike");
	menu.AddItem("11", "Haunted Phantasm");
	menu.AddItem("12", "Ghastly Ghosts");
	menu.AddItem("13", "Hellish Inferno");
	menu.AddItem("14", "Roaring Rockets");
	menu.AddItem("15", "Acid Bubbles of Envy");
	menu.AddItem("16", "Flammable Bubbles of Attraction");
	menu.AddItem("17", "Poisonous Bubbles of Regret");
	
	menu.ExitButton = true; // Self explanatory
	menu.Display(client, MENU_TIME_FOREVER); // Draw the menu to the client.
}

void DrawWeaponUnusualMenu(int client)
{
	// Make the weapon paints menu.
	Menu menu = new Menu(UnusualWeaponMenu_Handler, MENU_ACTIONS_ALL);
	
	menu.SetTitle("Weapon Unusuals"); // Self explanatory
	
	// Add the items
	menu.AddItem("0", "None");
	menu.AddItem("701", "Hot");
	menu.AddItem("702", "Isotope");
	menu.AddItem("703", "Cool");
	menu.AddItem("704", "Energy Orb");
	
	menu.ExitButton = true; // Self explanatory
	menu.Display(client, MENU_TIME_FOREVER); // Draw the menu to the client.
}

void DrawItemAttributesMenu(int client)
{
	// Make the weapon paints menu.
	Menu menu = new Menu(ItemAttributes_Handler, MENU_ACTIONS_ALL);
	
	menu.SetTitle("Item Attributes"); // Self explanatory
	
	// Add the items
	menu.AddItem("2027", "Australium");
	menu.AddItem("2053", "Festive");
	
	menu.ExitButton = true; // Self explanatory
	menu.Display(client, MENU_TIME_FOREVER); // Draw the menu to the client.
}

void DrawSheenSelectionMenu(int client)
{
	// Make the weapon paints menu.
	Menu menu = new Menu(SheenSelection_Handler, MENU_ACTIONS_ALL);
	
	menu.SetTitle("Choose a slot"); // Self explanatory
	
	// Add the items
	menu.AddItem("0", "Primary");
	menu.AddItem("1", "Secondary");
	menu.AddItem("2", "Melee");
	
	menu.ExitButton = true; // Self explanatory
	menu.Display(client, MENU_TIME_FOREVER); // Draw the menu to the client.
}

void DrawTiersSelectionMenu(int client)
{
	// Make the weapon paints menu.
	Menu menu = new Menu(TiersSelection_Handler, MENU_ACTIONS_ALL);
	
	menu.SetTitle("Choose a slot"); // Self explanatory
	
	// Add the items
	menu.AddItem("0", "Primary");
	menu.AddItem("1", "Secondary");
	menu.AddItem("2", "Melee");
	
	menu.ExitButton = true; // Self explanatory
	menu.Display(client, MENU_TIME_FOREVER); // Draw the menu to the client.
}

void DrawEffectsSelectionMenu(int client)
{
	// Make the weapon paints menu.
	Menu menu = new Menu(EffectsSelection_Handler, MENU_ACTIONS_ALL);
	
	menu.SetTitle("Choose a slot"); // Self explanatory
	
	// Add the items
	menu.AddItem("0", "Primary");
	menu.AddItem("1", "Secondary");
	menu.AddItem("2", "Melee");
	
	menu.ExitButton = true; // Self explanatory
	menu.Display(client, MENU_TIME_FOREVER); // Draw the menu to the client.
}

public int SheenSelection_Handler(Menu menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_Start:
		{
			// It's important to log anything in any way, the best is printtoserver, but if you just want to log to client to make it easier to get progress done, feel free.
			PrintToServer("Displaying menu"); // Log it
		}
		
		case MenuAction_Display:
		{
			PrintToServer("Client %d was sent menu with panel %x", param1, param2); // Log so you can check if it gets sent.
		}
		
		case MenuAction_Select:
		{
			char sInfo[32];
			menu.GetItem(param2, sInfo, sizeof(sInfo));
			
			switch (param2)
			{
				case 0: // Primary
				{
					iPrimarySlotSheenChosen[param1] = true;
					DrawKillstreakSheenMenu(param1);
				}
				case 1: // Secondary
				{
					iSecondarySlotSheenChosen[param1] = true;
					DrawKillstreakSheenMenu(param1);
				}
				case 2: // Melee
				{
					iMeleeSlotSheenChosen[param1] = true;
					DrawKillstreakSheenMenu(param1);
				}
			}
		}
		
		case MenuAction_Cancel:
		{
			PrintToServer("Client %d's menu was cancelled for reason %d", param1, param2); // Logging once again.
		}
		
		case MenuAction_End:
		{
			delete menu;
		}
		
		case MenuAction_DrawItem:
		{
			int style;
			char info[32];
			menu.GetItem(param2, info, sizeof(info), style);
		}
		
		case MenuAction_DisplayItem:
		{
			char info[32];
			menu.GetItem(param2, info, sizeof(info));
		}
	}
}

public int TiersSelection_Handler(Menu menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_Start:
		{
			// It's important to log anything in any way, the best is printtoserver, but if you just want to log to client to make it easier to get progress done, feel free.
			PrintToServer("Displaying menu"); // Log it
		}
		
		case MenuAction_Display:
		{
			PrintToServer("Client %d was sent menu with panel %x", param1, param2); // Log so you can check if it gets sent.
		}
		
		case MenuAction_Select:
		{
			char sInfo[32];
			menu.GetItem(param2, sInfo, sizeof(sInfo));
			
			switch (param2)
			{
				case 0: // Primary
				{
					iPrimarySlotTiersChosen[param1] = true;
					DrawKillstreakTierMenu(param1);
				}
				case 1: // Secondary
				{
					iSecondarySlotTiersChosen[param1] = true;
					DrawKillstreakTierMenu(param1);
				}
				case 2: // Melee
				{
					iMeleeSlotTiersChosen[param1] = true;
					DrawKillstreakTierMenu(param1);
				}
			}
		}
		
		case MenuAction_Cancel:
		{
			PrintToServer("Client %d's menu was cancelled for reason %d", param1, param2); // Logging once again.
		}
		
		case MenuAction_End:
		{
			delete menu;
		}
		
		case MenuAction_DrawItem:
		{
			int style;
			char info[32];
			menu.GetItem(param2, info, sizeof(info), style);
		}
		
		case MenuAction_DisplayItem:
		{
			char info[32];
			menu.GetItem(param2, info, sizeof(info));
		}
	}
}

public int EffectsSelection_Handler(Menu menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_Start:
		{
			// It's important to log anything in any way, the best is printtoserver, but if you just want to log to client to make it easier to get progress done, feel free.
			PrintToServer("Displaying menu"); // Log it
		}
		
		case MenuAction_Display:
		{
			PrintToServer("Client %d was sent menu with panel %x", param1, param2); // Log so you can check if it gets sent.
		}
		
		case MenuAction_Select:
		{
			char sInfo[32];
			menu.GetItem(param2, sInfo, sizeof(sInfo));
			
			switch (param2)
			{
				case 0: // Primary
				{
					iPrimarySlotEffectsChosen[param1] = true;
					DrawKillstreakEffectMenu(param1);
				}
				case 1: // Secondary
				{
					iSecondarySlotEffectsChosen[param1] = true;
					DrawKillstreakEffectMenu(param1);
				}
				case 2: // Melee
				{
					iMeleeSlotEffectsChosen[param1] = true;
					DrawKillstreakEffectMenu(param1);
				}
			}
		}
		
		case MenuAction_Cancel:
		{
			PrintToServer("Client %d's menu was cancelled for reason %d", param1, param2); // Logging once again.
		}
		
		case MenuAction_End:
		{
			delete menu;
		}
		
		case MenuAction_DrawItem:
		{
			int style;
			char info[32];
			menu.GetItem(param2, info, sizeof(info), style);
		}
		
		case MenuAction_DisplayItem:
		{
			char info[32];
			menu.GetItem(param2, info, sizeof(info));
		}
	}
}

void DrawToggleWarPaint(int client)
{
	// Make the weapon paints menu.
	Menu menu = new Menu(DrawToggleWarPaint_Handler, MENU_ACTIONS_ALL);
	
	menu.SetTitle("Toggle War Paint"); // Self explanatory
	
	// Add the items
	menu.AddItem("0", "Toggle");
	
	menu.ExitButton = true; // Self explanatory
	menu.Display(client, MENU_TIME_FOREVER); // Draw the menu to the client.
}

// Stocks

void AttachParticle(int iEntity, char[] strParticleType)
{
	int iParticle = CreateEntityByName("info_particle_system");
	
	char strName[128];
	if (IsValidEdict(iParticle))
	{
		float fPos[3];
		GetEntPropVector(iEntity, Prop_Send, "m_vecOrigin", fPos);
		fPos[2] += 10;
		TeleportEntity(iParticle, fPos, NULL_VECTOR, NULL_VECTOR);
		
		Format(strName, sizeof(strName), "target%i", iEntity);
		DispatchKeyValue(iEntity, "targetname", strName);
		
		DispatchKeyValue(iParticle, "targetname", "tf2particle");
		DispatchKeyValue(iParticle, "parentname", strName);
		DispatchKeyValue(iParticle, "effect_name", strParticleType);
		DispatchSpawn(iParticle);
		SetVariantString(strName);
		AcceptEntityInput(iParticle, "SetParent", iParticle, iParticle, 0);
		SetVariantString("");
		AcceptEntityInput(iParticle, "SetParentAttachment", iParticle, iParticle, 0);
		ActivateEntity(iParticle);
		AcceptEntityInput(iParticle, "start");
		
		g_Ent[iEntity] = iParticle;
	}
}

void AttachParticleWeapon(int iEntity, char[] strParticleEffect, char[] strAttachPoint = "")
{
	int iParticle = CreateEntityByName("info_particle_system");
	
	if (IsValidEdict(iParticle))
	{
		float flPos[3];
		GetEntPropVector(iEntity, Prop_Send, "m_vecOrigin", flPos);
		flPos[2] += 10;
		
		TeleportEntity(iParticle, flPos, NULL_VECTOR, NULL_VECTOR);
		
		DispatchKeyValue(iParticle, "effect_name", strParticleEffect);
		DispatchSpawn(iParticle);
		
		SetVariantString("!activator");
		AcceptEntityInput(iParticle, "SetParent", iEntity);
		ActivateEntity(iParticle);
		
		if (strlen(strAttachPoint))
		{
			SetVariantString(strAttachPoint);
			AcceptEntityInput(iParticle, "SetParentAttachmentMaintainOffset");
		}
		
		AcceptEntityInput(iParticle, "start");
		
		g_WepEnt[iEntity] = iParticle;
	}
}

void DeleteParticle(int particle)
{
	if (IsValidEntity(particle))
	{
		char classname[64];
		GetEdictClassname(particle, classname, sizeof(classname));
		if (StrEqual(classname, "info_particle_system", false))
		{
			AcceptEntityInput(particle, "DestroyImmediately"); //some particles don't disappear without this
			RemoveEdict(particle);
		}
	}
}

// Making warpaints, australiums and festive weapons work properly

public Action TF2Items_OnGiveNamedItem(int client, char[] classname, int iItemDefinitionIndex, Handle &hItem)
{
	if (StrEqual(classname, "tf_weapon_scattergun") && bNeedsWarPaint[client])
		return Plugin_Handled;
	
	return Plugin_Continue;
}

void ApplyWarPaint(int client)
{
	if (IsClientInGame(client))
	{
		int weapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
		
		if (GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex") == 13)
		{
			Handle hItem = TF2Items_CreateItem(OVERRIDE_ALL);
			TF2Items_SetClassname(hItem, "tf_weapon_scattergun");
			TF2Items_SetItemIndex(hItem, 15015);
			TF2Items_SetQuality(hItem, 6);
			TF2Items_SetLevel(hItem, 1);
			
			TF2Items_SetNumAttributes(hItem, 1);
			TF2Items_SetAttribute(hItem, 0, 725, 1.0);
			
			int iWeapon = TF2Items_GiveNamedItem(client, hItem);
			EquipPlayerWeapon(client, iWeapon);
		}
	}
}

bool IsPaintKitable(int iItemId)
{
	for (int i = 0; i < sizeof(g_iPaintKitable); i++)
	{
		if (iItemId == g_iPaintKitable[i])
		{
			return true;
		}
	}
	return false;
} 
