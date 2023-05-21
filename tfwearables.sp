#include <sourcemod>
#include <tf2_stocks>
#include <tf2items>
#include <tf2attributes>
#include <morecolors>
#include <clientprefs>
#include <tf_econ_data>

#pragma newdecls required // Force Transitional Syntax
#pragma semicolon 1 // Force Semicolon, should use in every plugin.

#define PLUGIN_VERSION "2.0.0"

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

int iPrimarySlotUnusualWeaponChosen[MAXPLAYERS+1];
int iSecondarySlotUnusualWeaponChosen[MAXPLAYERS+1];
int iMeleeSlotUnusualWeaponChosen[MAXPLAYERS+1];

bool bNeedsWarPaint[MAXPLAYERS + 1];

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
Handle PrimaryUnusualWeaponCookie = null;
Handle SecondaryUnusualWeaponCookie = null;
Handle MeleeUnusualWeaponCookie = null;
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
ConVar g_cServerLogging;
// ConVar g_cJailbreakCompat;

// Thanks 404
public const int g_iPaintKitable[45] =  {
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
	1178  // Dragon's Fury
};

// This is pretty self explanatory.
public Plugin myinfo = 
{
	name = "[TF2] Wearables", 
	author = "cigzag", 
	description = "Allows players to use a menu to pick custom attributes for there weapons or player.", 
	version = PLUGIN_VERSION, 
	url = "", 
};

public void OnPluginStart()
{
	// ConVars
	CreateConVar("tf_wearables_version", PLUGIN_VERSION, "Wearables Version (Do not touch).", FCVAR_NOTIFY | FCVAR_REPLICATED);
	RegeneratePlayer = CreateConVar("sm_wearables_rg", "0", "Regenerate player on wearable update?", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_cServerLogging = CreateConVar("sm_wearables_logging", "0", "Log debug outputs to server console?", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	// g_cJailbreakCompat = CreateConVar("sm_wearables_jb", "0", "Add specific checks to ensure no interference with Scag's TF2 Jailbreak plugin.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	
	// These cookies are stale, gross.
	UnusualTauntCookie = RegClientCookie("UnusualTauntID", "A cookie for reading the saved Unusual Taunt ID", CookieAccess_Private); // Make a client cookie, make sure cookie cannot be written over by client, by making it private.
	PrimaryUnusualWeaponCookie = RegClientCookie("PrimaryWeaponUnusualID", "A cookie for reading the saved Unusual Weapon ID", CookieAccess_Private);
	SecondaryUnusualWeaponCookie = RegClientCookie("SecondaryWeaponUnusualID", "A cookie for reading the saved Unusual Weapon ID", CookieAccess_Private);
	MeleeUnusualWeaponCookie = RegClientCookie("MeleeWeaponUnusualID", "A cookie for reading the saved Unusual Weapon ID", CookieAccess_Private);
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
	HookEvent("player_death", PlayerDeath, EventHookMode_Pre);
	HookEvent("post_inventory_application", OnResupply);
	
	// Admin Commands
	RegAdminCmd("sm_wearables", WearablesMenu, ADMFLAG_RESERVATION, "Shows the wearables menu.");
	RegAdminCmd("sm_warpaint", WarPaintTest, ADMFLAG_RESERVATION, "Tests warpaints");
	
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
	menu.AddItem(WARPAINTS, "War Paints");
	
	menu.ExitButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
	
	return Plugin_Handled; // Return Plugin_Handled to prevent "unknown command issues."
}

public Action WarPaintTest(int client, int args)
{
	//static const float WEAR_LEVELS[] = {
//		0.200, 0.400, 0.600, 0.800, 1.00
//	};

	if(!IsClientInGame(client) || !IsPlayerAlive(client))
		return Plugin_Handled;

	if(args < 2)
	{
		ReplyToCommand(client, "[SM] Usage: sm_warpaint <warpaint> <unusual id>");
		return Plugin_Handled;
	}

	char arg1[32];
	GetCmdArg(1, arg1, sizeof(arg1));

	char arg2[32];
	GetCmdArg(2, arg2, sizeof(arg2));

	int weapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");

	if (IsValidEntity(weapon) && GetEntPropEnt(weapon, Prop_Send, "m_hOwnerEntity") == client)
	{
		int itemindex = GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex");

		TFClassType class = TF2_GetPlayerClass(client);
		char sClassName[32];

		TF2Econ_GetItemClassName(itemindex, sClassName, sizeof(sClassName));
		int slot = TF2Econ_GetItemLoadoutSlot(itemindex, class);

		PrintToChat(client, "[SM] Item Index: %i, Classname: %s, Slot: %i", itemindex, sClassName, slot);

		PrintToChat(client, "[SM] IsPaintKitable returns %i", IsPaintKitable(itemindex));

		if(IsPaintKitable(itemindex))
		{
			PrintToChat(client, "[SM] Item %s at %i is warpaintable.", sClassName, itemindex);
			AcceptEntityInput(weapon, "kill");

			int iArg1 = StringToInt(arg1);
			int iArg2 = StringToInt(arg2);

			CreateWeapon(client, itemindex, sClassName, 99, 6, slot, iArg1, iArg2);
		}
	}
	
	return Plugin_Handled;
}

// Next, make the handler.
public int WearablesMenu_Handler(Menu menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_Start:
		{
			// It's important to log anything in any way, the best is printtoserver, but if you just want to log to client to make it easier to get progress done, feel free.
			if(g_cServerLogging.BoolValue)
				PrintToServer("Displaying menu"); // Log it
		}
		
		case MenuAction_Display:
		{
			if(g_cServerLogging.BoolValue)
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
					DrawUnusualSlotSelectionMenu(param1);
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
			if(g_cServerLogging.BoolValue)
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

	return 0;
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
		if (IsValidEntity(slot1))
		{
			int itemindex = GetEntProp(slot1, Prop_Send, "m_iItemDefinitionIndex");

			char sClassName[32];

			TF2Econ_GetItemClassName(itemindex, sClassName, sizeof(sClassName));

			if(IsPaintKitable(itemindex))
			{
				PrintToChat(client, "[SM] Item %s at %i is warpaintable.", sClassName, itemindex);

				PrintToChat(client, "[SM] kseffect: %f, kssheen: %f, kstier: %f", KillstreakEffectID[client], KillstreakSheenID[client], KillstreakTierID[client]);

				// UNUSUAL WEAPON SLOTS

				// Primary

				char sPrimaryUnusualWeaponValue[64];
				GetClientCookie(client, PrimaryUnusualWeaponCookie, sPrimaryUnusualWeaponValue, sizeof(sPrimaryUnusualWeaponValue));
				float fPrimaryUnusualWeaponValue = StringToFloat(sPrimaryUnusualWeaponValue);

				if(fPrimaryUnusualWeaponValue > 0.0)
				{
					AcceptEntityInput(slot1, "kill");
					CreateWeapon(client, itemindex, sClassName, 99, 6, slot1, 0, RoundToNearest(fPrimaryUnusualWeaponValue));
				}
			}
		}

		if(IsValidEntity(slot2))
		{
			int itemindex = GetEntProp(slot2, Prop_Send, "m_iItemDefinitionIndex");

			char sClassName[32];

			TF2Econ_GetItemClassName(itemindex, sClassName, sizeof(sClassName));

			if(IsPaintKitable(itemindex))
			{
				// Secondary

				char sSecondaryUnusualWeaponValue[64];
				GetClientCookie(client, SecondaryUnusualWeaponCookie, sSecondaryUnusualWeaponValue, sizeof(sSecondaryUnusualWeaponValue));
				float fSecondaryUnusualWeaponValue = StringToFloat(sSecondaryUnusualWeaponValue);

				if(fSecondaryUnusualWeaponValue > 0.0)
				{
					AcceptEntityInput(slot2, "kill");
					CreateWeapon(client, itemindex, sClassName, 99, 6, slot2, 0, RoundToNearest(fSecondaryUnusualWeaponValue));
				}
			}
		}

		if(IsValidEntity(slot3))
		{
			int itemindex = GetEntProp(slot3, Prop_Send, "m_iItemDefinitionIndex");

			char sClassName[32];

			TF2Econ_GetItemClassName(itemindex, sClassName, sizeof(sClassName));

			if(IsPaintKitable(itemindex))
			{
				// Melee

				char sMeleeUnusualWeaponValue[64];
				GetClientCookie(client, MeleeUnusualWeaponCookie, sMeleeUnusualWeaponValue, sizeof(sMeleeUnusualWeaponValue));
				float fMeleeUnusualWeaponValue = StringToFloat(sMeleeUnusualWeaponValue);

				if(fMeleeUnusualWeaponValue > 0.0)
				{
					AcceptEntityInput(slot3, "kill");
					CreateWeapon(client, itemindex, sClassName, 99, 6, slot3, 0, RoundToNearest(fMeleeUnusualWeaponValue));
				}
			}
		}
		
		// KS Tiers
		
		// Primary	
		char sPrimaryCookieTierValue[64];
		GetClientCookie(client, PrimaryKillstreakTierCookie, sPrimaryCookieTierValue, sizeof(sPrimaryCookieTierValue));
		
		float fPrimaryCookieTierValue = StringToFloat(sPrimaryCookieTierValue);
		
		if (fPrimaryCookieTierValue > 0.0) // If tier cookie is higher than 0.0
		{
			if(IsValidEntity(slot1))
			{
				DataPack pack;
				CreateDataTimer(2.0, FixKSTierPrimary, pack);
				pack.WriteCell(client);
				pack.WriteFloat(fPrimaryCookieTierValue);
			}
		}
		
		if(g_cServerLogging.BoolValue)
			PrintToServer("Retrieved %N's PrimaryKillstreakTierCookie with %s", client, sPrimaryCookieTierValue);
		
		// Secondary
		char sSecondaryCookieTierValue[64];
		GetClientCookie(client, SecondaryKillstreakTierCookie, sSecondaryCookieTierValue, sizeof(sSecondaryCookieTierValue));
		
		float fSecondaryCookieTierValue = StringToFloat(sSecondaryCookieTierValue);
		
		if (fSecondaryCookieTierValue > 0.0) // If tier cookie is higher than 0.0
		{
			if(IsValidEntity(slot2))
			{
				DataPack pack;
				CreateDataTimer(2.0, FixKSTierSecondary, pack);
				pack.WriteCell(client);
				pack.WriteFloat(fSecondaryCookieTierValue);
			}
		}
		
		if(g_cServerLogging.BoolValue)
			PrintToServer("Retrieved %N's SecondaryKillstreakTierCookie with %s", client, sSecondaryCookieTierValue);
		
		// Melee
		char sMeleeCookieTierValue[64];
		GetClientCookie(client, MeleeKillstreakTierCookie, sMeleeCookieTierValue, sizeof(sMeleeCookieTierValue));
		
		float fMeleeCookieTierValue = StringToFloat(sMeleeCookieTierValue);
		
		if (fMeleeCookieTierValue > 0.0) // If tier cookie is higher than 0.0
		{
			if(IsValidEntity(slot3))
			{
				DataPack pack;
				CreateDataTimer(2.0, FixKSTierMelee, pack);
				pack.WriteCell(client);
				pack.WriteFloat(fMeleeCookieTierValue);
			}
		}
		
		if(g_cServerLogging.BoolValue)
			PrintToServer("Retrieved %N's MeleeKillstreakTierCookie with %s", client, sPrimaryCookieTierValue);
		
		// KS Effects
		
		// Primary	
		char sPrimaryCookieEffectValue[64];
		GetClientCookie(client, PrimaryKillstreakEffectCookie, sPrimaryCookieEffectValue, sizeof(sPrimaryCookieEffectValue));
		
		float fPrimaryCookieEffectValue = StringToFloat(sPrimaryCookieEffectValue);
		
		if (fPrimaryCookieEffectValue > 0.0) // If tier cookie is higher than 0.0
		{
			if(IsValidEntity(slot1))
			{
				DataPack pack;
				CreateDataTimer(2.0, FixKSEffectPrimary, pack);
				pack.WriteCell(client);
				pack.WriteFloat(fPrimaryCookieEffectValue);
			}
		}
		
		if(g_cServerLogging.BoolValue)
			PrintToServer("Retrieved %N's PrimaryKillstreakEffectCookie with %s", client, sPrimaryCookieEffectValue);
		
		// Secondary
		char sSecondaryCookieEffectValue[64];
		GetClientCookie(client, SecondaryKillstreakEffectCookie, sSecondaryCookieEffectValue, sizeof(sSecondaryCookieEffectValue));
		
		float fSecondaryCookieEffectValue = StringToFloat(sSecondaryCookieEffectValue);
		
		if (fSecondaryCookieEffectValue > 0.0) // If tier cookie is higher than 0.0
		{
			if(IsValidEntity(slot2))
			{
				DataPack pack;
				CreateDataTimer(2.0, FixKSEffectSecondary, pack);
				pack.WriteCell(client);
				pack.WriteFloat(fSecondaryCookieEffectValue);
			}
		}
		
		if(g_cServerLogging.BoolValue)
			PrintToServer("Retrieved %N's SecondaryKillstreakEffectCookie with %s", client, sPrimaryCookieEffectValue);
		
		// Melee
		char sMeleeCookieEffectValue[64];
		GetClientCookie(client, MeleeKillstreakEffectCookie, sMeleeCookieEffectValue, sizeof(sMeleeCookieEffectValue));
		
		float fMeleeCookieEffectValue = StringToFloat(sMeleeCookieEffectValue);
		
		if (fMeleeCookieEffectValue > 0.0) // If tier cookie is higher than 0.0
		{
			if(IsValidEntity(slot3))
			{
				DataPack pack;
				CreateDataTimer(2.0, FixKSEffectMelee, pack);
				pack.WriteCell(client);
				pack.WriteFloat(fMeleeCookieEffectValue);
			}
		}
		
		if(g_cServerLogging.BoolValue)
			PrintToServer("Retrieved %N's MeleeKillstreakEffectCookie with %s", client, sMeleeCookieEffectValue);
		
		// KS Sheen
		
		// Primary	
		char sPrimaryCookieSheenValue[64];
		GetClientCookie(client, PrimaryKillstreakSheenCookie, sPrimaryCookieSheenValue, sizeof(sPrimaryCookieSheenValue));
		
		float fPrimaryCookieSheenValue = StringToFloat(sPrimaryCookieSheenValue);
		
		if (fPrimaryCookieSheenValue > 0.0) // If tier cookie is higher than 0.0
		{
			if(IsValidEntity(slot1))
			{
				DataPack pack;
				CreateDataTimer(2.0, FixKSSheenPrimary, pack);
				pack.WriteCell(client);
				pack.WriteFloat(fPrimaryCookieSheenValue);
			}
		}
		
		if(g_cServerLogging.BoolValue)
			PrintToServer("Retrieved %N's PrimaryKillstreakSheenCookie with %s", client, sPrimaryCookieSheenValue);
		
		// Secondary
		char sSecondaryCookieSheenValue[64];
		GetClientCookie(client, SecondaryKillstreakSheenCookie, sSecondaryCookieSheenValue, sizeof(sSecondaryCookieSheenValue));
		
		float fSecondaryCookieSheenValue = StringToFloat(sSecondaryCookieSheenValue);
		
		if (fSecondaryCookieSheenValue > 0.0) // If tier cookie is higher than 0.0
		{
			if(IsValidEntity(slot2))
			{
				DataPack pack;
				CreateDataTimer(2.0, FixKSSheenSecondary, pack);
				pack.WriteCell(client);
				pack.WriteFloat(fSecondaryCookieSheenValue);
			}
		}
		
		if(g_cServerLogging.BoolValue)
			PrintToServer("Retrieved %N's SecondaryKillstreakSheenCookie with %s", client, sSecondaryCookieSheenValue);
		
		// Melee
		char sMeleeCookieSheenValue[64];
		GetClientCookie(client, MeleeKillstreakSheenCookie, sMeleeCookieSheenValue, sizeof(sMeleeCookieSheenValue));
		
		float fMeleeCookieSheenValue = StringToFloat(sMeleeCookieSheenValue);
		
		if (fMeleeCookieSheenValue > 0.0) // If tier cookie is higher than 0.0
		{
			if(IsValidEntity(slot3))
			{
				DataPack pack;
				CreateDataTimer(2.0, FixKSSheenMelee, pack);
				pack.WriteCell(client);
				pack.WriteFloat(fMeleeCookieSheenValue);
			}
		}
		
		if(g_cServerLogging.BoolValue)
			PrintToServer("Retrieved %N's MeleeKillstreakSheenCookie with %s", client, sMeleeCookieSheenValue);
	}

	return Plugin_Continue;
}

// Killstreak Tiers Fix (Thought it was better than looping through all players on RoundActive)
public Action FixKSTierPrimary(Handle timer, DataPack pack)
{
	int client;
	int slot; 
	float cookie;

	pack.Reset();
	client = pack.ReadCell();
	cookie = pack.ReadFloat();

	slot = GetPlayerWeaponSlot(client, TFWeaponSlot_Primary);

	if(IsValidEntity(slot))
		TF2Attrib_SetByDefIndex(slot, 2025, cookie); // Set it to choice picked in menu.

	return Plugin_Stop;
}

public Action FixKSTierSecondary(Handle timer, DataPack pack)
{
	int client;
	int slot; 
	float cookie;

	pack.Reset();
	client = pack.ReadCell();
	cookie = pack.ReadFloat();

	slot = GetPlayerWeaponSlot(client, TFWeaponSlot_Secondary);

	if(IsValidEntity(slot))
		TF2Attrib_SetByDefIndex(slot, 2025, cookie); // Set it to choice picked in menu.

	return Plugin_Stop;
}

public Action FixKSTierMelee(Handle timer, DataPack pack)
{
	int client;
	int slot; 
	float cookie;

	pack.Reset();
	client = pack.ReadCell();
	cookie = pack.ReadFloat();

	slot = GetPlayerWeaponSlot(client, TFWeaponSlot_Melee);

	if(IsValidEntity(slot))
		TF2Attrib_SetByDefIndex(slot, 2025, cookie); // Set it to choice picked in menu.

	return Plugin_Stop;
}
// Killstreak Effects Fix

public Action FixKSEffectPrimary(Handle timer, DataPack pack)
{
	int client;
	int slot; 
	float cookie;

	pack.Reset();
	client = pack.ReadCell();
	cookie = pack.ReadFloat();

	slot = GetPlayerWeaponSlot(client, TFWeaponSlot_Primary);

	if(IsValidEntity(slot))
		TF2Attrib_SetByDefIndex(slot, 2013, cookie); // Set it to choice picked in menu.

	return Plugin_Stop;
}

public Action FixKSEffectSecondary(Handle timer, DataPack pack)
{
	int client;
	int slot; 
	float cookie;

	pack.Reset();
	client = pack.ReadCell();
	cookie = pack.ReadFloat();

	slot = GetPlayerWeaponSlot(client, TFWeaponSlot_Secondary);

	if(IsValidEntity(slot))
		TF2Attrib_SetByDefIndex(slot, 2013, cookie); // Set it to choice picked in menu.

	return Plugin_Stop;
}

public Action FixKSEffectMelee(Handle timer, DataPack pack)
{
	int client;
	int slot; 
	float cookie;

	pack.Reset();
	client = pack.ReadCell();
	cookie = pack.ReadFloat();

	slot = GetPlayerWeaponSlot(client, TFWeaponSlot_Melee);

	if(IsValidEntity(slot))
		TF2Attrib_SetByDefIndex(slot, 2013, cookie); // Set it to choice picked in menu.

	return Plugin_Stop;
}

// Killstreak Sheens

public Action FixKSSheenPrimary(Handle timer, DataPack pack)
{
	int client;
	int slot; 
	float cookie;

	pack.Reset();
	client = pack.ReadCell();
	cookie = pack.ReadFloat();

	slot = GetPlayerWeaponSlot(client, TFWeaponSlot_Primary);

	if(IsValidEntity(slot))
		TF2Attrib_SetByDefIndex(slot, 2014, cookie); // Set it to choice picked in menu.

	return Plugin_Stop;
}

public Action FixKSSheenSecondary(Handle timer, DataPack pack)
{
	int client;
	int slot; 
	float cookie;

	pack.Reset();
	client = pack.ReadCell();
	cookie = pack.ReadFloat();

	slot = GetPlayerWeaponSlot(client, TFWeaponSlot_Secondary);

	if(IsValidEntity(slot))
		TF2Attrib_SetByDefIndex(slot, 2014, cookie); // Set it to choice picked in menu.

	return Plugin_Stop;
}

public Action FixKSSheenMelee(Handle timer, DataPack pack)
{
	int client;
	int slot; 
	float cookie;

	pack.Reset();
	client = pack.ReadCell();
	cookie = pack.ReadFloat();

	slot = GetPlayerWeaponSlot(client, TFWeaponSlot_Melee);

	if(IsValidEntity(slot))
		TF2Attrib_SetByDefIndex(slot, 2014, cookie); // Set it to choice picked in menu.

	return Plugin_Stop;
}

public Action PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	DeleteParticle(g_Ent[client]);
	DeleteParticle(g_WepEnt[client]);
	
	g_bIsTaunting[client] = false;

	return Plugin_Continue;
	
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

	return Plugin_Handled;
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

	return Plugin_Handled;
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

	return Plugin_Handled;
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

	return Plugin_Handled;
}

public int UnusualTauntMenu_Handler(Menu menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_Start:
		{
			if(g_cServerLogging.BoolValue)
				PrintToServer("Displaying menu"); // Log it
		}
		
		case MenuAction_Display:
		{
			if(g_cServerLogging.BoolValue)
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
						CPrintToChat(param1, "{orange}Hellhound {white}| You have reset your effect.");
					}
					case 1:
					{
						HasPickedUnusualTaunt[param1] = true;
						//Format(UnusualTauntID[param1], sizeof(UnusualTauntID[]), "%s", "utaunt_firework_teamcolor_red"); // Thank you Techno
						UnusualTauntID[param1] = "utaunt_firework_teamcolor_red";
						CPrintToChat(param1, "{orange}Hellhound {white}| You have picked effect Showstopper (RED)");
					}
					case 2:
					{
						HasPickedUnusualTaunt[param1] = true;
						UnusualTauntID[param1] = "utaunt_firework_teamcolor_blue";
						//Format(UnusualTauntID[param1], sizeof(UnusualTauntID[]), "%s", "utaunt_firework_teamcolor_blue");
						CPrintToChat(param1, "{orange}Hellhound {white}| You have picked effect Showstopper (BLU)");
					}
					case 3:
					{
						HasPickedUnusualTaunt[param1] = true;
						UnusualTauntID[param1] = "utaunt_beams_yellow";
						CPrintToChat(param1, "{orange}Hellhound {white}| You have picked effect Holy Grail");
					}
					case 4:
					{
						HasPickedUnusualTaunt[param1] = true;
						UnusualTauntID[param1] = "utaunt_disco_party";
						CPrintToChat(param1, "{orange}Hellhound {white}| You have picked effect '72");
					}
					case 5:
					{
						HasPickedUnusualTaunt[param1] = true;
						UnusualTauntID[param1] = "utaunt_hearts_glow_parent";
						CPrintToChat(param1, "{orange}Hellhound {white}| You have picked effect Fountain Of Delight");
					}
					case 6:
					{
						HasPickedUnusualTaunt[param1] = true;
						UnusualTauntID[param1] = "utaunt_meteor_parent";
						CPrintToChat(param1, "{orange}Hellhound {white}| You have picked effect Screaming Tiger", info);
					}
					case 7:
					{
						HasPickedUnusualTaunt[param1] = true;
						UnusualTauntID[param1] = "utaunt_cash_confetti";
						CPrintToChat(param1, "{orange}Hellhound {white}| You have picked effect Skill Gotten Gains", info);
					}
					case 8:
					{
						HasPickedUnusualTaunt[param1] = true;
						UnusualTauntID[param1] = "utaunt_tornado_parent_black";
						CPrintToChat(param1, "{orange}Hellhound {white}| You have picked effect Midnight Whirlwind", info);
					}
					case 9:
					{
						HasPickedUnusualTaunt[param1] = true;
						UnusualTauntID[param1] = "utaunt_tornado_parent_white";
						CPrintToChat(param1, "{orange}Hellhound {white}| You have picked effect Silver Cyclone", info);
					}
					case 10:
					{
						HasPickedUnusualTaunt[param1] = true;
						UnusualTauntID[param1] = "utaunt_lightning_parent";
						CPrintToChat(param1, "{orange}Hellhound {white}| You have picked effect Mega Strike", info);
					}
					case 11:
					{
						HasPickedUnusualTaunt[param1] = true;
						UnusualTauntID[param1] = "utaunt_souls_green_parent";
						CPrintToChat(param1, "{orange}Hellhound {white}| You have picked effect Haunted Phantasm", info);
					}
					case 12:
					{
						HasPickedUnusualTaunt[param1] = true;
						UnusualTauntID[param1] = "utaunt_souls_purple_parent";
						CPrintToChat(param1, "{orange}Hellhound {white}| You have picked effect Ghastly Ghosts", info);
					}
					case 13:
					{
						HasPickedUnusualTaunt[param1] = true;
						UnusualTauntID[param1] = "utaunt_hellpit_parent";
						CPrintToChat(param1, "{orange}Hellhound {white}| You have picked effect Hellish Inferno", info);
					}
					case 14:
					{
						HasPickedUnusualTaunt[param1] = true;
						UnusualTauntID[param1] = "utaunt_firework_dragon_parent";
						CPrintToChat(param1, "{orange}Hellhound {white}| You have picked effect Roaring Rockets", info);
					}
					case 15:
					{
						HasPickedUnusualTaunt[param1] = true;
						UnusualTauntID[param1] = "utaunt_bubbles_glow_green_parent";
						CPrintToChat(param1, "{orange}Hellhound {white}| You have picked effect Acid Bubbles of Envy", info);
					}
					case 16:
					{
						HasPickedUnusualTaunt[param1] = true;
						UnusualTauntID[param1] = "utaunt_bubbles_glow_orange_parent";
						CPrintToChat(param1, "{orange}Hellhound {white}| You have picked effect Flammable Bubbles of Attraction", info);
					}
					case 17:
					{
						HasPickedUnusualTaunt[param1] = true;
						UnusualTauntID[param1] = "utaunt_bubbles_glow_purple_parent";
						CPrintToChat(param1, "{orange}Hellhound {white}| You have picked effect Poisonous Bubbles of Regret", info);
					}
				}
			}
			else
			{
				CPrintToChat(param1, "{orange}Hellhound {white}| You may not change effect when taunting.");
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
			if(g_cServerLogging.BoolValue)
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

	return 0;
}

public int UnusualWeaponMenu_Handler(Menu menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_Start:
		{
			if(g_cServerLogging.BoolValue)
				PrintToServer("Displaying menu"); // Log it
		}
		
		case MenuAction_Display:
		{
			if(g_cServerLogging.BoolValue)
				PrintToServer("Client %d was sent menu with panel %x", param1, param2);
		}
		
		case MenuAction_Select:
		{
			char info[24];
			GetMenuItem(menu, param2, info, sizeof(info));
			int weapon;
			float effect = StringToFloat(info);
			WeaponUnusualID[param1] = effect;

			if(iPrimarySlotUnusualWeaponChosen[param1] == 1)
			{
				weapon = GetPlayerWeaponSlot(param1, TFWeaponSlot_Primary);
			}
			else if(iSecondarySlotUnusualWeaponChosen[param1] == 1)
			{
				weapon = GetPlayerWeaponSlot(param1, TFWeaponSlot_Secondary);
			}
			else if(iMeleeSlotUnusualWeaponChosen[param1] == 1)
			{
				weapon = GetPlayerWeaponSlot(param1, TFWeaponSlot_Melee);
			}
			
			switch (param2)
			{
				case 0:
				{
					if (IsValidEntity(weapon) && GetEntPropEnt(weapon, Prop_Send, "m_hOwnerEntity") == param1)
					{
						int itemindex = GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex");

						TFClassType class = TF2_GetPlayerClass(param1);
						char sClassName[32];

						TF2Econ_GetItemClassName(itemindex, sClassName, sizeof(sClassName));
						int slot = TF2Econ_GetItemLoadoutSlot(itemindex, class);

						if(IsPaintKitable(itemindex))
						{
							PrintToChat(param1, "[SM] Item %s at %i is warpaintable.", sClassName, itemindex);
							AcceptEntityInput(weapon, "kill");

							PrintToChat(param1, "[SM] kseffect: %f, kssheen: %f, kstier: %f", KillstreakEffectID[param1], KillstreakSheenID[param1], KillstreakTierID[param1]);

							CreateWeapon(param1, itemindex, sClassName, 99, 6, slot, 0, RoundToNearest(effect));
						}
					}
					HasPickedWeaponUnusual[param1] = false;
					CPrintToChat(param1, "{orange}Hellhound {white}| You have reset your weapon effect.");
				}
				case 1:
				{
					if (IsValidEntity(weapon) && GetEntPropEnt(weapon, Prop_Send, "m_hOwnerEntity") == param1)
					{
						int itemindex = GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex");

						TFClassType class = TF2_GetPlayerClass(param1);
						char sClassName[32];

						TF2Econ_GetItemClassName(itemindex, sClassName, sizeof(sClassName));
						int slot = TF2Econ_GetItemLoadoutSlot(itemindex, class);

						if(IsPaintKitable(itemindex))
						{
							PrintToChat(param1, "[SM] Item %s at %i is warpaintable.", sClassName, itemindex);
							AcceptEntityInput(weapon, "kill");

							CreateWeapon(param1, itemindex, sClassName, 99, 6, slot, 0, RoundToNearest(effect));
						}
					}
					HasPickedWeaponUnusual[param1] = true;
					CPrintToChat(param1, "{orange}Hellhound {white}| You have chosen weapon effect Hot");
				}
				case 2:
				{
					if (IsValidEntity(weapon) && GetEntPropEnt(weapon, Prop_Send, "m_hOwnerEntity") == param1)
					{
						int itemindex = GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex");

						TFClassType class = TF2_GetPlayerClass(param1);
						char sClassName[32];

						TF2Econ_GetItemClassName(itemindex, sClassName, sizeof(sClassName));
						int slot = TF2Econ_GetItemLoadoutSlot(itemindex, class);

						if(IsPaintKitable(itemindex))
						{
							PrintToChat(param1, "[SM] Item %s at %i is warpaintable.", sClassName, itemindex);
							AcceptEntityInput(weapon, "kill");

							CreateWeapon(param1, itemindex, sClassName, 99, 6, slot, 0, RoundToNearest(effect));
						}
					}
					HasPickedWeaponUnusual[param1] = true;
					CPrintToChat(param1, "{orange}Hellhound {white}| You have chosen weapon effect Isotope");
				}
				case 3:
				{
					if (IsValidEntity(weapon) && GetEntPropEnt(weapon, Prop_Send, "m_hOwnerEntity") == param1)
					{
						int itemindex = GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex");

						TFClassType class = TF2_GetPlayerClass(param1);
						char sClassName[32];

						TF2Econ_GetItemClassName(itemindex, sClassName, sizeof(sClassName));
						int slot = TF2Econ_GetItemLoadoutSlot(itemindex, class);

						if(IsPaintKitable(itemindex))
						{
							PrintToChat(param1, "[SM] Item %s at %i is warpaintable.", sClassName, itemindex);
							AcceptEntityInput(weapon, "kill");

							CreateWeapon(param1, itemindex, sClassName, 99, 6, slot, 0, RoundToNearest(effect));
						}
					}
					HasPickedWeaponUnusual[param1] = true;
					CPrintToChat(param1, "{orange}Hellhound {white}| You have chosen weapon effect Cool");
				}
				case 4:
				{
					if (IsValidEntity(weapon) && GetEntPropEnt(weapon, Prop_Send, "m_hOwnerEntity") == param1)
					{
						int itemindex = GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex");

						TFClassType class = TF2_GetPlayerClass(param1);
						char sClassName[32];

						TF2Econ_GetItemClassName(itemindex, sClassName, sizeof(sClassName));
						int slot = TF2Econ_GetItemLoadoutSlot(itemindex, class);

						if(IsPaintKitable(itemindex))
						{
							PrintToChat(param1, "[SM] Item %s at %i is warpaintable.", sClassName, itemindex);
							AcceptEntityInput(weapon, "kill");

							CreateWeapon(param1, itemindex, sClassName, 99, 6, slot, 0, RoundToNearest(effect));
						}
					}
					HasPickedWeaponUnusual[param1] = true;
					CPrintToChat(param1, "{orange}Hellhound {white}| You have chosen weapon effect Energy Orb");
				}
			}
			
			if (AreClientCookiesCached(param1))
			{
				if(iPrimarySlotUnusualWeaponChosen[param1])
				{
					char sPrimaryCookieValue[64];
					GetClientCookie(param1, PrimaryUnusualWeaponCookie, sPrimaryCookieValue, sizeof(sPrimaryCookieValue));
					
					float fPrimaryCookieValue = StringToFloat(sPrimaryCookieValue);
					
					fPrimaryCookieValue = effect;
					
					FloatToString(fPrimaryCookieValue, sPrimaryCookieValue, sizeof(sPrimaryCookieValue));
					
					SetClientCookie(param1, PrimaryKillstreakTierCookie, sPrimaryCookieValue);
				}
				else if(iSecondarySlotUnusualWeaponChosen[param1])
				{
					char sSecondaryCookieValue[64];
					GetClientCookie(param1, SecondaryUnusualWeaponCookie, sSecondaryCookieValue, sizeof(sSecondaryCookieValue));
					
					float fSecondaryCookieValue = StringToFloat(sSecondaryCookieValue);
					
					fSecondaryCookieValue = effect;
					
					FloatToString(fSecondaryCookieValue, sSecondaryCookieValue, sizeof(sSecondaryCookieValue));
					
					SetClientCookie(param1, SecondaryUnusualWeaponCookie, sSecondaryCookieValue);
				}
				else if(iMeleeSlotUnusualWeaponChosen[param1])
				{
					char sMeleeCookieValue[64];
					GetClientCookie(param1, MeleeUnusualWeaponCookie, sMeleeCookieValue, sizeof(sMeleeCookieValue));
					
					float fMeleeCookieValue = StringToFloat(sMeleeCookieValue);
					
					fMeleeCookieValue = effect;
					
					FloatToString(fMeleeCookieValue, sMeleeCookieValue, sizeof(sMeleeCookieValue));
					
					SetClientCookie(param1, MeleeUnusualWeaponCookie, sMeleeCookieValue);
				}
			}
		}
		
		case MenuAction_Cancel:
		{
			if(g_cServerLogging.BoolValue)
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

	return 0;
}


public int KillstreaksMenu_Handler(Menu menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_Start:
		{
			if(g_cServerLogging.BoolValue)
				PrintToServer("Displaying menu"); // Log it
		}
		
		case MenuAction_Display:
		{
			if(g_cServerLogging.BoolValue)
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
			if(g_cServerLogging.BoolValue)
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

	return 0;
}

public int KillstreakTiersMenu_Handler(Menu menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_Start:
		{
			if(g_cServerLogging.BoolValue)
				PrintToServer("Displaying menu"); // Log it
		}
		
		case MenuAction_Display:
		{
			if(g_cServerLogging.BoolValue)
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
			
			CPrintToChat(param1, "{orange}Hellhound {white}| You have selected killstreak tier %f, on slot %s", tier, sSlot);
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
					
					if(g_cServerLogging.BoolValue)
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
					
					if(g_cServerLogging.BoolValue)
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
					
					if(g_cServerLogging.BoolValue)
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
			if(g_cServerLogging.BoolValue)
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

	return 0;
}

public int KillstreakEffectMenu_Handler(Menu menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_Start:
		{
			if(g_cServerLogging.BoolValue)
				PrintToServer("Displaying menu"); // Log it
		}
		
		case MenuAction_Display:
		{
			if(g_cServerLogging.BoolValue)
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
			
			CPrintToChat(param1, "{orange}Hellhound {white}| You have selected killstreak effect %f, on slot %s", effect, sSlot);
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
					
					if(g_cServerLogging.BoolValue)
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
					
					if(g_cServerLogging.BoolValue)
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
					
					if(g_cServerLogging.BoolValue)
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
			if(g_cServerLogging.BoolValue)
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

	return 0;
}

public int KillstreakSheenMenu_Handler(Menu menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_Start:
		{
			if(g_cServerLogging.BoolValue)
				PrintToServer("Displaying menu"); // Log it
		}
		
		case MenuAction_Display:
		{
			if(g_cServerLogging.BoolValue)
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
			
			CPrintToChat(param1, "{orange}Hellhound {white}| You have selected killstreak effect %f, on slot %s", sheen, sSlot);
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
					
					if(g_cServerLogging.BoolValue)
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
					
					if(g_cServerLogging.BoolValue)
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
					
					if(g_cServerLogging.BoolValue)
						PrintToServer("Updated %N's MeleeKillstreakSheenCookie with %s", param1, sMeleeCookieValue);
				}
			}
			
			iPrimarySlotSheenChosen[param1] = false;
			iSecondarySlotSheenChosen[param1] = false;
			iMeleeSlotSheenChosen[param1] = false;
		}
		
		case MenuAction_Cancel:
		{
			if(g_cServerLogging.BoolValue)
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

	return 0;
}

public int ItemAttributes_Handler(Menu menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_Start:
		{
			if(g_cServerLogging.BoolValue)
				PrintToServer("Displaying menu"); // Log it
		}
		
		case MenuAction_Display:
		{
			if(g_cServerLogging.BoolValue)
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
				{
					TF2Attrib_SetByDefIndex(weapon, 2027, 1.0);
					TF2Attrib_SetByDefIndex(weapon, 2022, 1.0);
					TF2Attrib_SetByDefIndex(weapon, 542, 1.0);
				}
				else if (choice == 2053)
				{
					TF2Attrib_SetByDefIndex(weapon, 2053, 1.0);
					TF2Attrib_SetByDefIndex(weapon, 542, 1.0);
				}
			}
			
			CPrintToChat(param1, "{orange}Hellhound {white}| You have selected item attribute %f", choice);
			if (GetConVarBool(RegeneratePlayer))
				TF2_RegeneratePlayer(param1);
		}
		
		case MenuAction_Cancel:
		{
			if(g_cServerLogging.BoolValue)
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

	return 0;
}

public int DrawToggleWarPaint_Handler(Menu menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_Start:
		{
			if(g_cServerLogging.BoolValue)
				PrintToServer("Displaying menu"); // Log it
		}
		
		case MenuAction_Display:
		{
			if(g_cServerLogging.BoolValue)
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
			
			CPrintToChat(param1, "{orange}Hellhound {white}| You have toggled war paint.");
		}
		
		case MenuAction_Cancel:
		{
			if(g_cServerLogging.BoolValue)
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

	return 0;
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

void DrawUnusualSlotSelectionMenu(int client)
{
	Menu menu = new Menu(UnusualSlotSelectionSlot_Handler, MENU_ACTIONS_ALL);

	menu.SetTitle("Choose a slot");

	// Add the items
	menu.AddItem("0", "Primary");
	menu.AddItem("1", "Secondary");
	menu.AddItem("2", "Melee");

	menu.ExitButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

public int SheenSelection_Handler(Menu menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_Start:
		{
			// It's important to log anything in any way, the best is printtoserver, but if you just want to log to client to make it easier to get progress done, feel free.

			if(g_cServerLogging.BoolValue)
				PrintToServer("Displaying menu"); // Log it
		}
		
		case MenuAction_Display:
		{
			if(g_cServerLogging.BoolValue)
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
			if(g_cServerLogging.BoolValue)
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

	return 0;
}

public int TiersSelection_Handler(Menu menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_Start:
		{
			// It's important to log anything in any way, the best is printtoserver, but if you just want to log to client to make it easier to get progress done, feel free.

			if(g_cServerLogging.BoolValue)
				PrintToServer("Displaying menu"); // Log it
		}
		
		case MenuAction_Display:
		{
			if(g_cServerLogging.BoolValue)
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
			if(g_cServerLogging.BoolValue)
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

	return 0;
}

public int EffectsSelection_Handler(Menu menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_Start:
		{
			// It's important to log anything in any way, the best is printtoserver, but if you just want to log to client to make it easier to get progress done, feel free.

			if(g_cServerLogging.BoolValue)
				PrintToServer("Displaying menu"); // Log it
		}
		
		case MenuAction_Display:
		{
			if(g_cServerLogging.BoolValue)
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
			if(g_cServerLogging.BoolValue)
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

	return 0;
}

public int UnusualSlotSelectionSlot_Handler(Menu menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_Start:
		{
			// It's important to log anything in any way, the best is printtoserver, but if you just want to log to client to make it easier to get progress done, feel free.

			if(g_cServerLogging.BoolValue)
				PrintToServer("Displaying menu"); // Log it
		}
		
		case MenuAction_Display:
		{
			if(g_cServerLogging.BoolValue)
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
					iPrimarySlotUnusualWeaponChosen[param1] = 1;
					DrawWeaponUnusualMenu(param1);
				}
				case 1: // Secondary
				{
					iSecondarySlotUnusualWeaponChosen[param1] = 1;
					DrawWeaponUnusualMenu(param1);
				}
				case 2: // Melee
				{
					iMeleeSlotUnusualWeaponChosen[param1] = 1;
					DrawWeaponUnusualMenu(param1);
				}
			}
		}
		
		case MenuAction_Cancel:
		{
			if(g_cServerLogging.BoolValue)
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

	return 0;
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
		//AcceptEntityInput(iParticle, "SetParentAttachment", iParticle, iParticle, 0);
		ActivateEntity(iParticle);
		AcceptEntityInput(iParticle, "start");
		
		g_Ent[iEntity] = iParticle;
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
		
	hItem = TF2Items_CreateItem(OVERRIDE_ATTRIBUTES | PRESERVE_ATTRIBUTES);
	
	TF2Items_SetNumAttributes(hItem, 1); // 1 Attribute is unusual.
	
	return Plugin_Continue;
}

/*void ApplyWarPaint(int client)
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
}*/

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

// modified functions from PC Gamer's Gimme Plugin below this line.

int CreateWeapon(int client, int itemindex, const char[] classname, int level, int quality, int weaponSlot, int warpaint, int effect)
{
	int newitem = CreateEntityByName(classname);
	
	if (!IsValidEntity(newitem))
	{
		PrintToChat(client, "Item %i : %s is invalid for current class", itemindex, classname);
		return false;
	}

	if (StrEqual(classname, "tf_weapon_invis"))
	{
		weaponSlot = 4;
	}
	
	if (itemindex == 735 || itemindex == 736 || StrEqual(classname, "tf_weapon_sapper"))
	{
		weaponSlot = 1;
	}
	
	if (StrEqual(classname, "tf_weapon_revolver"))
	{
		weaponSlot = 0;
	}	

	if (TF2_GetPlayerClass(client) == TFClass_Engineer && weaponSlot > 2 && weaponSlot < 8)
	{
		return newitem;
	}
	
	if(weaponSlot < 6)
	{
		TF2_RemoveWeaponSlot(client, weaponSlot);		
	}
	
	char entclass[64];

	GetEntityNetClass(newitem, entclass, sizeof(entclass));	
	SetEntData(newitem, FindSendPropInfo(entclass, "m_iItemDefinitionIndex"), itemindex);
	SetEntData(newitem, FindSendPropInfo(entclass, "m_bInitialized"), 1);
	SetEntData(newitem, FindSendPropInfo(entclass, "m_iEntityLevel"), level);
	SetEntData(newitem, FindSendPropInfo(entclass, "m_iEntityQuality"), quality);
	SetEntProp(newitem, Prop_Send, "m_bValidatedAttachedEntity", 1);
	
	SetEntProp(newitem, Prop_Send, "m_iAccountID", GetSteamAccountID(client));
	SetEntPropEnt(newitem, Prop_Send, "m_hOwnerEntity", client);
	
	if (level > 0)
	{
		SetEntData(newitem, FindSendPropInfo(entclass, "m_iEntityLevel"), level);
	}
	else
	{
		SetEntData(newitem, FindSendPropInfo(entclass, "m_iEntityLevel"), GetRandomUInt(1,99));
	}

	switch (itemindex)
	{
	case 735, 736, 810, 831, 933, 1080, 1102:
		{
			SetEntProp(newitem, Prop_Send, "m_iObjectType", 3);
			SetEntProp(newitem, Prop_Data, "m_iSubType", 3);
			SetEntProp(newitem, Prop_Send, "m_aBuildableObjectTypes", 0, _, 0);
			SetEntProp(newitem, Prop_Send, "m_aBuildableObjectTypes", 0, _, 1);
			SetEntProp(newitem, Prop_Send, "m_aBuildableObjectTypes", 0, _, 2);
			SetEntProp(newitem, Prop_Send, "m_aBuildableObjectTypes", 1, _, 3);
		}
	case 998:
		{
			SetEntData(newitem, FindSendPropInfo(entclass, "m_nChargeResistType"), GetRandomInt(0,2));
		}
	case 1071:
		{
			TF2Attrib_SetByName(newitem, "item style override", 0.0);
			TF2Attrib_SetByName(newitem, "loot rarity", 1.0);		
			TF2Attrib_SetByName(newitem, "turn to gold", 1.0);

			DispatchSpawn(newitem);
			EquipPlayerWeapon(client, newitem);

			char itemname[64];
			TF2Econ_GetItemName(itemindex, itemname, sizeof(itemname));
			PrintToChat(client, "%N received item %d (%s)", client, itemindex, itemname);
			
			return newitem; 
		}
	}

	if(quality == 9 || warpaint == 1) //self made quality, internally used for australium items
	{
		TF2Attrib_SetByName(newitem, "is australium item", 1.0);
		TF2Attrib_SetByName(newitem, "item style override", 1.0);
		SetEntData(newitem, FindSendPropInfo(entclass, "m_iEntityQuality"), 11);		
	}

	if (warpaint > 1)
	{
		TF2Attrib_SetByDefIndex(newitem, 834, view_as<float>(warpaint));
		SetEntData(newitem, FindSendPropInfo(entclass, "m_iEntityQuality"), 15);		
	}

	if(quality == 11) //strange quality
	{
		/*if (GetRandomInt(1,15) == 1)
		{
			TF2Attrib_SetByDefIndex(newitem, 2025, 1.0);
		}
		else if (GetRandomInt(1,15) == 2)
		{
			TF2Attrib_SetByDefIndex(newitem, 2025, 2.0);
			TF2Attrib_SetByDefIndex(newitem, 2014, GetRandomInt(1,7) + 0.0);
		}
		else if (GetRandomInt(1,15) == 3)
		{
			TF2Attrib_SetByDefIndex(newitem, 2025, 3.0);
			TF2Attrib_SetByDefIndex(newitem, 2014, GetRandomInt(1,7) + 0.0);
			TF2Attrib_SetByDefIndex(newitem, 2013, GetRandomInt(2002,2008) + 0.0);
		}*/
		TF2Attrib_SetByDefIndex(newitem, 214, view_as<float>(GetRandomInt(0, 9000)));
	}
	
	if (quality == 15)
	{
		switch(itemindex)
		{
		case 30665, 30666, 30667, 30668:
			{
				TF2Attrib_RemoveByDefIndex(newitem, 725);
			}
		default:
			{
				TF2Attrib_SetByDefIndex(newitem, 725, GetRandomFloat(0.0,1.0));
			}
		}
	}

	if (effect > 0 && warpaint == 0)
	{
		SetEntData(newitem, FindSendPropInfo(entclass, "m_iEntityQuality"), 5);	
		if (effect == 999)
		{
			TF2Attrib_SetByDefIndex(newitem, 134, GetRandomInt(1,223) + 0.0);
		}
		else
		{
			TF2Attrib_SetByDefIndex(newitem, 134, effect + 0.0);
		}
	}
	
	if(weaponSlot < 2)
	{
		TF2Attrib_SetByDefIndex(newitem, 725, 0.0);
	}

	// Applying killstreak attributes to spawned weapon does not work, must re-apply after weapon is created.
	//DataPack entinfo;
	//CreateDataTimer(5.0, FixKillstreak, entinfo);
	//entinfo.WriteCell(client);
	//entinfo.WriteCell(weaponSlot);
	//entinfo.WriteCell(kstier);
	//entinfo.WriteCell(kssheen);
	//entinfo.WriteCell(kseffect);

	/*// not working properly?
	if(kstier > 0)
		TF2Attrib_SetByDefIndex(newitem, 2025, kstier + 0.0);

	// not working properly?
	if(kssheen > 0)
		TF2Attrib_SetByDefIndex(newitem, 2014, kssheen + 0.0);

	// not working properly?
	if(kseffect > 0)
		TF2Attrib_SetByDefIndex(newitem, 2013, kseffect + 0.0);*/
	
	DispatchSpawn(newitem);

	EquipPlayerWeapon(client, newitem);
	
	if (IsPaintKitable(itemindex))
	{
		if (weaponSlot < 2 || StrEqual(classname, "tf_weapon_knife"))
		{
			if (warpaint < 2 || effect < 1)
			{
				SetEntData(newitem, FindSendPropInfo(entclass, "m_iEntityQuality"), 5);
				TF2_SwitchtoSlot(client, weaponSlot);
				int iRand = GetRandomUInt(1,4);
				if (iRand == 1)
				{
					TF2Attrib_SetByDefIndex(newitem, 134, 701.0);	
				}
				else if (iRand == 2)
				{
					TF2Attrib_SetByDefIndex(newitem, 134, 702.0);	
				}	
				else if (iRand == 3)
				{
					TF2Attrib_SetByDefIndex(newitem, 134, 703.0);	
				}
				else if (iRand == 4)
				{
					TF2Attrib_SetByDefIndex(newitem, 134, 704.0);	
				}
			}
		}
		if (effect > 0)
		{
			switch(effect)
			{
			case 701:
				{
					SetEntData(newitem, FindSendPropInfo(entclass, "m_iEntityQuality"), 5);
					TF2_SwitchtoSlot(client, weaponSlot);
					TF2Attrib_SetByDefIndex(newitem, 134, 701.0);	
				}
			case 702:
				{
					SetEntData(newitem, FindSendPropInfo(entclass, "m_iEntityQuality"), 5);
					TF2_SwitchtoSlot(client, weaponSlot);
					TF2Attrib_SetByDefIndex(newitem, 134, 702.0);	
				}
			case 703:
				{
					SetEntData(newitem, FindSendPropInfo(entclass, "m_iEntityQuality"), 5);
					TF2_SwitchtoSlot(client, weaponSlot);
					TF2Attrib_SetByDefIndex(newitem, 134, 703.0);	
				}
			case 704:
				{
					SetEntData(newitem, FindSendPropInfo(entclass, "m_iEntityQuality"), 5);
					TF2_SwitchtoSlot(client, weaponSlot);
					TF2Attrib_SetByDefIndex(newitem, 134, 704.0);	
				}				
			default:
				{
					PrintToChat(client, "Invalid weapon effect. Valid effects are: 701, 702, 703, or 704");
				}
			}
		}
	}

	if (StrEqual(classname, "tf_weapon_scattergun"))
	{
		SetEntProp(newitem, Prop_Data, "m_iClip1", 6);
		SetNewAmmo(client, weaponSlot, 32);
	}
	if (StrEqual(classname, "tf_weapon_shortstop") || StrEqual(classname, "tf_weapon_pep_brawler_blaster"))
	{
		SetEntProp(newitem, Prop_Data, "m_iClip1", 4);
		SetNewAmmo(client, weaponSlot, 32);
	}
	if (StrEqual(classname, "tf_weapon_pistol"))
	{
		SetEntProp(newitem, Prop_Data, "m_iClip1", 12);
		SetNewAmmo(client, weaponSlot, 36);
	}
	if (StrContains(classname, "tf_weapon_shotgun") != -1)
	{
		SetEntProp(newitem, Prop_Data, "m_iClip1", 6);
		SetNewAmmo(client, weaponSlot, 32);
	}	
	if (StrEqual(classname, "tf_weapon_handgun_scout_secondary"))
	{
		SetEntProp(newitem, Prop_Data, "m_iClip1", 12);
		SetNewAmmo(client, weaponSlot, 36);
	}		
	if (StrEqual(classname, "tf_weapon_rocketlauncher") || StrEqual(classname, "tf_weapon_rocketlauncher_directhit") || StrEqual(classname, "tf_weapon_rocketlauncher_airstrike"))
	{
		if (itemindex == 228)
		{
			SetEntProp(newitem, Prop_Data, "m_iClip1", 3);
			SetNewAmmo(client, weaponSlot, 20);		
		}
		else
		{
			SetEntProp(newitem, Prop_Data, "m_iClip1", 4);
			SetNewAmmo(client, weaponSlot, 20);
		}
	}
	if (StrEqual(classname, "tf_weapon_minigun") || StrEqual(classname, "tf_weapon_flamethrower"))
	{
		SetEntProp(newitem, Prop_Data, "m_iClip1", 200);
	}
	if (StrEqual(classname, "tf_weapon_rocketlauncher_fireball"))
	{
		SetEntProp(newitem, Prop_Data, "m_iClip1", 40);
	}
	if (StrEqual(classname, "tf_weapon_grenadelauncher"))
	{
		SetEntProp(newitem, Prop_Data, "m_iClip1", 4);
		SetNewAmmo(client, weaponSlot, 16);
	}
	if (StrEqual(classname, "tf_weapon_pipebomblauncher"))
	{
		SetEntProp(newitem, Prop_Data, "m_iClip1", 8);
		SetNewAmmo(client, weaponSlot, 24);
	}
	if (StrEqual(classname, "tf_weapon_syringegun_medic"))
	{
		SetEntProp(newitem, Prop_Data, "m_iClip1", 40);
		SetNewAmmo(client, weaponSlot, 150);
	}
	if (StrEqual(classname, "tf_weapon_syringegun_medic"))
	{
		SetEntProp(newitem, Prop_Data, "m_iClip1", 40);
		SetNewAmmo(client, weaponSlot, 150);
	}
	if (StrEqual(classname, "tf_weapon_crossbow"))
	{
		SetEntProp(newitem, Prop_Data, "m_iClip1", 1);
		SetNewAmmo(client, weaponSlot, 38);
	}
	if (StrEqual(classname, "tf_weapon_sniperrifle") || StrEqual(classname, "tf_weapon_sniperrifle_decap") || StrEqual(classname, "tf_weapon_sniperrifle_classic"))
	{
		SetEntProp(newitem, Prop_Data, "m_iClip1", 25);
	}	
	if (StrEqual(classname, "tf_weapon_compound_bow"))
	{
		SetEntProp(newitem, Prop_Data, "m_iClip1", 1);
		SetNewAmmo(client, weaponSlot, 25);
	}
	if (StrEqual(classname, "tf_weapon_smg"))
	{
		SetEntProp(newitem, Prop_Data, "m_iClip1", 25);
		SetNewAmmo(client, weaponSlot, 75);
	}
	if (StrEqual(classname, "tf_weapon_charged_smg"))
	{
		SetEntProp(newitem, Prop_Data, "m_iClip1", 20);
		SetNewAmmo(client, weaponSlot, 75);
	}
	if (StrEqual(classname, "tf_weapon_revolver"))
	{
		SetEntProp(newitem, Prop_Data, "m_iClip1", 6);
		SetNewAmmo(client, weaponSlot, 24);
	}
	
	TF2_SwitchtoSlot(client, 2);
	TF2_SwitchtoSlot(client, 0);	

	char itemname[64];
	TF2Econ_GetItemName(itemindex, itemname, sizeof(itemname));
	PrintToChat(client, "%N received item %d, %s, warpaint: %i, effect: %i", client, itemindex, itemname, warpaint, effect);
	
	return newitem;
} 

int GetRandomUInt(int min, int max)
{
	return RoundToFloor(GetURandomFloat() * (max - min + 1)) + min;
}

void TF2_SwitchtoSlot(int client, int slot)
{
	if (slot >= 0 && slot <= 5 && IsClientInGame(client) && IsPlayerAlive(client))
	{
		char wepclassname[64];
		int wep = GetPlayerWeaponSlot(client, slot);
		if (wep > MaxClients && IsValidEdict(wep) && GetEdictClassname(wep, wepclassname, sizeof(wepclassname)))
		{
			FakeClientCommandEx(client, "use %s", wepclassname);
			SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", wep);
		}
	}
}

void SetNewAmmo(int client, int wepslot, int newAmmo)
{
	int weapon = GetPlayerWeaponSlot(client, wepslot);
	if (!IsValidEntity(weapon)) return;
	int type = GetEntProp(weapon, Prop_Send, "m_iPrimaryAmmoType");
	if (type < 0 || type > 31) return;
	SetEntProp(client, Prop_Send, "m_iAmmo", newAmmo, _, type);	
}