#include <sourcemod>
#include <tf2_stocks>
#include <tf2items>
#include <tf2attributes>
#include <morecolors>
#include <clientprefs>

#pragma newdecls required // Force Transitional Syntax
#pragma semicolon 1 // Force Semicolon, should use in every plugin.

#define PLUGIN_VERSION "1.0.0"

int g_Ent[MAXPLAYERS + 1];
int g_WepEnt[MAXPLAYERS + 1];

// Wearables menu

#define KILLSTREAKS "0"
#define UNUSUALS "1"
#define UNUSUALTAUNTS "2"
#define AUSTRALIUMS "3"

#define iKILLSTREAKS 0
#define iUNUSUALS 1
#define iUNUSUALTAUNTS 2
#define iAUSTRALIUMS 3

// Killstreaks Menu

#define KILLSTREAKSHEEN "0"
#define KILLSTREAKTIERS "1"
#define KILLSTREAKEFFECT "2"

#define iKILLSTREAKSHEEN 0
#define iKILLSTREAKTIERS 1
#define iKILLSTREAKEFFECT 2

float KillstreakTierID[MAXPLAYERS + 1];
float KillstreakEffectID[MAXPLAYERS + 1];
float KillstreakSheenID[MAXPLAYERS + 1];

// Unusual Taunts Menu
char UnusualTauntID[MAXPLAYERS + 1][64];
float WeaponUnusualID[MAXPLAYERS + 1];
char strWeaponUnusual[MAXPLAYERS + 1][64];
bool HasPickedUnusualTaunt[MAXPLAYERS + 1];
bool HasPickedWeaponUnusual[MAXPLAYERS + 1];
Handle CheckTaunt[MAXPLAYERS + 1];

// COOOKIESS!!!!

Handle UnusualTauntCookie = null;
Handle UnusualWeaponCookie = null;
Handle UnusualWeaponFloatCookie = null;
Handle UnusualWeaponBoolCookie = null;
Handle KillstreakTierCookie = null;
Handle KillstreakSheenCookie = null;
Handle KillstreakEffectCookie = null;

// ConVars

ConVar RegeneratePlayer;

// This is pretty self explanatory.
public Plugin myinfo = 
{
	name = "[TF2] Wearables", 
	author = "blood", 
	description = "Allows players to use a menu to pick custom attributes for there weapons or player.", 
	version = PLUGIN_VERSION, 
	url = "https://savita-gaming.com", 
};

public void OnPluginStart()
{
	// ConVars
	CreateConVar("tf_wearables_version", PLUGIN_VERSION, "Wearables Version (Do not touch).", FCVAR_NOTIFY | FCVAR_REPLICATED);
	RegeneratePlayer = CreateConVar("sm_wearables_rg", "1", "Regenerate player on wearable update?", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	
	// These cookies are stale, gross.
	UnusualTauntCookie = RegClientCookie("UnusualTauntID", "A cookie for reading the saved Unusual Taunt ID", CookieAccess_Private); // Make a client cookie, make sure cookie cannot be written over by client, by making it private.
	UnusualWeaponCookie = RegClientCookie("WeaponUnusualID", "A cookie for reading the saved Unusual Weapon ID", CookieAccess_Private);
	UnusualWeaponFloatCookie = RegClientCookie("WeaponUnusualIDFloat", "A cookie for reading the saved Unusual Weapon ID Float", CookieAccess_Private);
	UnusualWeaponBoolCookie = RegClientCookie("WeaponUnusualIDBool", "A cookie for reading the saved Unusual Weapon ID Bool", CookieAccess_Private);
	KillstreakTierCookie = RegClientCookie("KillstreakTier", "A cookie for reading the saved Killstreak Cookie", CookieAccess_Private);
	KillstreakSheenCookie = RegClientCookie("KillstreakSheen", "A cookie for reading the saved Killstreak Sheen", CookieAccess_Private);
	KillstreakEffectCookie = RegClientCookie("KillstreakEffect", "A cookie for reading the saved Killstreak Effect", CookieAccess_Private);
	
	// Hooks
	HookEvent("player_spawn", PlayerSpawn, EventHookMode_Post);
	HookEvent("player_death", PlayerDeath, EventHookMode_Pre);
	
	// Admin Commands
	RegAdminCmd("sm_wearables", WearablesMenu, ADMFLAG_RESERVATION, "Shows the wearables menu.");
	
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
	
	menu.ExitButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
	
	return Plugin_Handled; // Return Plugin_Handled to prevent "unknown command issues."
}

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
	
	CheckTaunt[client] = CreateTimer(3.0, Timer_CheckTaunt, GetClientSerial(client), TIMER_REPEAT);
	
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
		
		// Killstreak Tier Cookie
		char sCookieTierValue[64];
		GetClientCookie(client, KillstreakTierCookie, sCookieTierValue, sizeof(sCookieTierValue));
		
		float fCookieTierValue = StringToFloat(sCookieTierValue);
		
		if (fCookieTierValue > 0.0) // If tier cookie is higher than 0.0
		{
			TF2Attrib_SetByDefIndex(weapon, 2025, fCookieTierValue); // Set it to choice picked in menu.
		}
		
		// Killstreak Effect Cookie
		char sCookieEffectValue[64];
		GetClientCookie(client, KillstreakEffectCookie, sCookieEffectValue, sizeof(sCookieEffectValue));
		
		float fCookieEffectValue = StringToFloat(sCookieEffectValue);
		
		if (fCookieEffectValue > 0.0)
		{
			TF2Attrib_SetByDefIndex(weapon, 2013, fCookieEffectValue); // Set it to choice picked in menu.
		}
		
		// Killstreak Sheen Cookie
		char sCookieSheenValue[64];
		GetClientCookie(client, KillstreakSheenCookie, sCookieSheenValue, sizeof(sCookieSheenValue));
		
		float fCookieSheenValue = StringToFloat(sCookieSheenValue);
		
		if (fCookieSheenValue > 0.0)
		{
			TF2Attrib_SetByDefIndex(weapon, 2014, fCookieSheenValue); // Set it to choice picked in menu.
		}
	}
}

public Action PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	DeleteParticle(g_Ent[client]);
	DeleteParticle(g_WepEnt[client]);
	
	if (CheckTaunt[client] != null)
		KillTimer(CheckTaunt[client]);
}

public Action Timer_CheckTaunt(Handle timer, any serial)
{
	int client = GetClientFromSerial(serial); // Validate the client serial
	
	if (client != 0)
	{
		if (IsClientInGame(client) && IsPlayerAlive(client))
		{
			if (TF2_IsPlayerInCondition(client, TFCond_Taunting))
			{
				if (AreClientCookiesCached(client))
				{
					char sCookieValue[64];
					GetClientCookie(client, UnusualTauntCookie, sCookieValue, sizeof(sCookieValue));
					
					DeleteParticle(g_Ent[client]);
					AttachParticle(client, sCookieValue);
				}
			}
			else
				DeleteParticle(g_Ent[client]);
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
			
			switch (param2)
			{
				case 0:
				{
					HasPickedUnusualTaunt[param1] = false;
					DeleteParticle(g_Ent[param1]);
					CPrintToChat(param1, "{yellow}Savita Gaming {white}| You have reset your effect.");
				}
				case 1:
				{
					HasPickedUnusualTaunt[param1] = true;
					//Format(UnusualTauntID[param1], sizeof(UnusualTauntID[]), "%s", "utaunt_firework_teamcolor_red"); // Thank you Techno
					UnusualTauntID[param1] = "utaunt_firework_teamcolor_red";
					CPrintToChat(param1, "{yellow}Savita Gaming {white}| You have picked effect Showstopper (RED)");
				}
				case 2:
				{
					HasPickedUnusualTaunt[param1] = true;
					UnusualTauntID[param1] = "utaunt_firework_teamcolor_blue";
					//Format(UnusualTauntID[param1], sizeof(UnusualTauntID[]), "%s", "utaunt_firework_teamcolor_blue");
					CPrintToChat(param1, "{yellow}Savita Gaming {white}| You have picked effect Showstopper (BLU)");
				}
				case 3:
				{
					HasPickedUnusualTaunt[param1] = true;
					UnusualTauntID[param1] = "utaunt_beams_yellow";
					CPrintToChat(param1, "{yellow}Savita Gaming {white}| You have picked effect Holy Grail");
				}
				case 4:
				{
					HasPickedUnusualTaunt[param1] = true;
					UnusualTauntID[param1] = "utaunt_disco_party";
					CPrintToChat(param1, "{yellow}Savita Gaming {white}| You have picked effect '72");
				}
				case 5:
				{
					HasPickedUnusualTaunt[param1] = true;
					UnusualTauntID[param1] = "utaunt_hearts_glow_parent";
					CPrintToChat(param1, "{yellow}Savita Gaming {white}| You have picked effect Fountain Of Delight");
				}
				case 6:
				{
					HasPickedUnusualTaunt[param1] = true;
					UnusualTauntID[param1] = "utaunt_meteor_parent";
					CPrintToChat(param1, "{yellow}Savita Gaming {white}| You have picked effect Screaming Tiger", info);
				}
				case 7:
				{
					HasPickedUnusualTaunt[param1] = true;
					UnusualTauntID[param1] = "utaunt_cash_confetti";
					CPrintToChat(param1, "{yellow}Savita Gaming {white}| You have picked effect Skill Gotten Gains", info);
				}
				case 8:
				{
					HasPickedUnusualTaunt[param1] = true;
					UnusualTauntID[param1] = "utaunt_tornado_parent_black";
					CPrintToChat(param1, "{yellow}Savita Gaming {white}| You have picked effect Midnight Whirlwind", info);
				}
				case 9:
				{
					HasPickedUnusualTaunt[param1] = true;
					UnusualTauntID[param1] = "utaunt_tornado_parent_white";
					CPrintToChat(param1, "{yellow}Savita Gaming {white}| You have picked effect Silver Cyclone", info);
				}
				case 10:
				{
					HasPickedUnusualTaunt[param1] = true;
					UnusualTauntID[param1] = "utaunt_lightning_parent";
					CPrintToChat(param1, "{yellow}Savita Gaming {white}| You have picked effect Mega Strike", info);
				}
				case 11:
				{
					HasPickedUnusualTaunt[param1] = true;
					UnusualTauntID[param1] = "utaunt_souls_green_parent";
					CPrintToChat(param1, "{yellow}Savita Gaming {white}| You have picked effect Haunted Phantasm", info);
				}
				case 12:
				{
					HasPickedUnusualTaunt[param1] = true;
					UnusualTauntID[param1] = "utaunt_souls_purple_parent";
					CPrintToChat(param1, "{yellow}Savita Gaming {white}| You have picked effect Ghastly Ghosts", info);
				}
				case 13:
				{
					HasPickedUnusualTaunt[param1] = true;
					UnusualTauntID[param1] = "utaunt_hellpit_parent";
					CPrintToChat(param1, "{yellow}Savita Gaming {white}| You have picked effect Hellish Inferno", info);
				}
				case 14:
				{
					HasPickedUnusualTaunt[param1] = true;
					UnusualTauntID[param1] = "utaunt_firework_dragon_parent";
					CPrintToChat(param1, "{yellow}Savita Gaming {white}| You have picked effect Roaring Rockets", info);
				}
				case 15:
				{
					HasPickedUnusualTaunt[param1] = true;
					UnusualTauntID[param1] = "utaunt_bubbles_glow_green_parent";
					CPrintToChat(param1, "{yellow}Savita Gaming {white}| You have picked effect Acid Bubbles of Envy", info);
				}
				case 16:
				{
					HasPickedUnusualTaunt[param1] = true;
					UnusualTauntID[param1] = "utaunt_bubbles_glow_orange_parent";
					CPrintToChat(param1, "{yellow}Savita Gaming {white}| You have picked effect Flammable Bubbles of Attraction", info);
				}
				case 17:
				{
					HasPickedUnusualTaunt[param1] = true;
					UnusualTauntID[param1] = "utaunt_bubbles_glow_purple_parent";
					CPrintToChat(param1, "{yellow}Savita Gaming {white}| You have picked effect Poisonous Bubbles of Regret", info);
				}
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
						TF2Attrib_SetByDefIndex(weapon, 134, effect);
						AttachParticleWeapon(weapon, "", _);
					}
					HasPickedWeaponUnusual[param1] = false;
					CPrintToChat(param1, "{yellow}Savita Gaming {white}| You have reset your weapon effect.");
				}
				case 1:
				{
					if (IsValidEntity(weapon))
					{
						TF2Attrib_SetByDefIndex(weapon, 134, effect);
						AttachParticleWeapon(weapon, "weapon_unusual_hot", _);
						strWeaponUnusual[param1] = "weapon_unusual_hot";
					}
					HasPickedWeaponUnusual[param1] = true;
					CPrintToChat(param1, "{yellow}Savita Gaming {white}| You have chosen weapon effect Hot");
				}
				case 2:
				{
					if (IsValidEntity(weapon))
					{
						TF2Attrib_SetByDefIndex(weapon, 134, effect);
						AttachParticleWeapon(weapon, "weapon_unusual_isotope", _);
						strWeaponUnusual[param1] = "weapon_unusual_isotope";
					}
					HasPickedWeaponUnusual[param1] = true;
					CPrintToChat(param1, "{yellow}Savita Gaming {white}| You have chosen weapon effect Isotope");
				}
				case 3:
				{
					if (IsValidEntity(weapon))
					{
						HasPickedWeaponUnusual[param1] = true;
						TF2Attrib_SetByDefIndex(weapon, 134, effect);
						AttachParticleWeapon(weapon, "weapon_unusual_cool", _);
						strWeaponUnusual[param1] = "weapon_unusual_cool";
					}
					HasPickedWeaponUnusual[param1] = true;
					CPrintToChat(param1, "{yellow}Savita Gaming {white}| You have chosen weapon effect Cool");
				}
				case 4:
				{
					if (IsValidEntity(weapon))
					{
						TF2Attrib_SetByDefIndex(weapon, 134, effect);
						AttachParticleWeapon(weapon, "weapon_unusual_energyorb", _);
						strWeaponUnusual[param1] = "weapon_unusual_energyorb";
					}
					HasPickedWeaponUnusual[param1] = true;
					CPrintToChat(param1, "{yellow}Savita Gaming {white}| You have chosen weapon effect Energy Orb");
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
					DrawKillstreakSheenMenu(param1);
				}
				case iKILLSTREAKTIERS:
				{
					DrawKillstreakTierMenu(param1);
				}
				case iKILLSTREAKEFFECT:
				{
					DrawKillstreakEffectMenu(param1);
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
			int weapon = GetEntPropEnt(param1, Prop_Send, "m_hActiveWeapon");
			char sInfo[32];
			menu.GetItem(param2, sInfo, sizeof(sInfo));
			float tier = StringToFloat(sInfo);
			KillstreakTierID[param1] = tier;
			
			if (IsValidEntity(weapon))
			{
				TF2Attrib_SetByDefIndex(weapon, 2025, tier);
			}
			
			CPrintToChat(param1, "{yellow}Savita Gaming {white}| You have selected killstreak tier %f", tier);
			if (GetConVarBool(RegeneratePlayer))
				TF2_RegeneratePlayer(param1);
			
			if (AreClientCookiesCached(param1))
			{
				char sCookieValue[64];
				GetClientCookie(param1, KillstreakTierCookie, sCookieValue, sizeof(sCookieValue));
				
				float fCookieValue = StringToFloat(sCookieValue);
				
				fCookieValue = tier;
				
				FloatToString(fCookieValue, sCookieValue, sizeof(sCookieValue));
				
				SetClientCookie(param1, KillstreakTierCookie, sCookieValue);
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
			int weapon = GetEntPropEnt(param1, Prop_Send, "m_hActiveWeapon");
			char sInfo[32];
			menu.GetItem(param2, sInfo, sizeof(sInfo));
			float effect = StringToFloat(sInfo);
			KillstreakEffectID[param1] = effect;
			
			if (IsValidEntity(weapon))
			{
				TF2Attrib_SetByDefIndex(weapon, 2013, effect);
			}
			
			CPrintToChat(param1, "{yellow}Savita Gaming {white}| You have selected killstreak effect %f", effect);
			if (GetConVarBool(RegeneratePlayer))
				TF2_RegeneratePlayer(param1);
			
			if (AreClientCookiesCached(param1))
			{
				char sCookieValue[64];
				GetClientCookie(param1, KillstreakEffectCookie, sCookieValue, sizeof(sCookieValue));
				
				float fCookieValue = StringToFloat(sCookieValue);
				
				fCookieValue = effect;
				
				FloatToString(fCookieValue, sCookieValue, sizeof(sCookieValue));
				
				SetClientCookie(param1, KillstreakEffectCookie, sCookieValue);
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
			int weapon = GetEntPropEnt(param1, Prop_Send, "m_hActiveWeapon");
			char sInfo[32];
			menu.GetItem(param2, sInfo, sizeof(sInfo));
			float sheen = StringToFloat(sInfo);
			KillstreakSheenID[param1] = sheen;
			
			if (IsValidEntity(weapon))
			{
				TF2Attrib_SetByDefIndex(weapon, 2014, sheen);
			}
			
			CPrintToChat(param1, "{yellow}Savita Gaming {white}| You have selected killstreak effect %f", sheen);
			if (GetConVarBool(RegeneratePlayer))
				TF2_RegeneratePlayer(param1);
			
			if (AreClientCookiesCached(param1))
			{
				char sCookieValue[64];
				GetClientCookie(param1, KillstreakSheenCookie, sCookieValue, sizeof(sCookieValue));
				
				float fCookieValue = StringToFloat(sCookieValue);
				
				fCookieValue = sheen;
				
				FloatToString(fCookieValue, sCookieValue, sizeof(sCookieValue));
				
				SetClientCookie(param1, KillstreakSheenCookie, sCookieValue);
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
			
			CPrintToChat(param1, "{yellow}Savita Gaming {white}| You have selected item attribute %f", choice);
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