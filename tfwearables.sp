#include <sourcemod>
#include <tf2_stocks>
#include <tf2items>
#include <tf2attributes>
#include <morecolors>
#include <clientprefs>
#include <sdktools>
#include <tf_econ_data>
#include <tf2utils>
#include <stocksoup/textparse>

#pragma newdecls required	 // Force Transitional Syntax
#pragma semicolon 1			 // Force semicolon mode

#define PLUGIN_VERSION	"1.3.2"

// REF: https://developer.valvesoftware.com/wiki/Entity_limit
#define MAX_ENTITY_SIZE 4096

// GLOBALS
// Unforuantely methodmaps do not have the ability to define variables inside them, they are used as wrappers to keep data organized instead.
// MAXPLAYERS is a definition from SourceMod which will store players from 0 to 65 (This should be changed to MaxClients if server is over 65 slots, but that is a NO GO because SRCDS is not multithreaded and runs more than 32 players VERY POORLY)
int		  killStreakTier[MAXPLAYERS + 1][MAX_ENTITY_SIZE];	  // When setting or printing this value through our methodmap, we should add +1 to ensure it lines up correctly with slot range (starts at 1 not 0, ends at 3)
int		  killStreakSheen[MAXPLAYERS + 1][MAX_ENTITY_SIZE];
int		  killStreakEffect[MAXPLAYERS + 1][MAX_ENTITY_SIZE];
char	  unusualTauntEffect[MAXPLAYERS + 1][64];	 // Store selected unusual taunt affect in string array, we will be creating the particle manually and attaching it to the player.
int		  particleEntity[MAXPLAYERS + 1];			 // Used to track current particles created by our plugin, when player no longer needs them, we call DeleteParticle to ensure entity limit is not reached, see above.
Handle	  refireTimer[MAXPLAYERS + 1];				 // Handle to track unusual taunts with an expiry time.
int		  unusualHatEffect[MAXPLAYERS + 1];
int		  unusualWeaponEffect[MAXPLAYERS + 1][MAX_ENTITY_SIZE];

ArrayList hatIDList;				// ArrayList to store all hat ids we can apply unusual effects too in-game
ArrayList unusualEffectNameList;	// Array list to store all unusual effect names for menu creation.
ArrayList unusualEffectIDList;		// Array list to store all unusual effect ids for menu creation.
ArrayList tauntEffectList;			// Arraylist to store all taunt unusual effects in the game.
ArrayList tauntEffectNameList;		// Arraylist to store taunt unusual effect names for menu creation.
ArrayList tauntRefireTimerList;		// Arraylist to store refire times of unusual taunts.

// temporary variables
// we are gonna use these to keep track of effect per slot in the menu handler
// once item is selected we can forget about these variables as they will be overwritten when player picks another option
// I don't know how else to implement slot selection via menu without creating two menu functions.
int		  tTier[MAXPLAYERS + 1];
int		  tSheen[MAXPLAYERS + 1];
int		  tEffect[MAXPLAYERS + 1];
int		  tWeaponEffect[MAXPLAYERS + 1];

Database  WearablesDB			= null;	   // Setup database handle we will be using in our plugin.

// In an attempt to keep away from multiple implementations of practically the same code, store main menu options here.
char	  wearableMenuItems[][] = {
	 "Killstreak Menu",
	 "Unusual Taunts Menu",
	 "Unusual Hats Menu",
	 "Unusual Weapons Menu"
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

char unusualWeaponMenuItems[][] = {	   // Unusual weapon effects in menu, matches unusualWeaponSel int array
	"Hot",
	"Isotope",
	"Cool",
	"Energy Orb"
};

// All possible menus which can be created, I have given them an ID order of +1 to keep it simple.
enum wearablesOptions
{
	wearablesMenu		 = 0,
	killStreakMenu		 = 1,
	unusualTauntMenu	 = 2,
	killStreakTierMenu	 = 3,
	killStreakSheenMenu	 = 4,
	killStreakEffectMenu = 5,
	slotSelectMenu		 = 6,
	unusualMenu			 = 7,
	unusualWeaponMenu	 = 8
};

int unusualWeaponSel[] = {
	// Unusual weapon effects, matches unusualWeaponSel int array
	701,	// Hot
	702,	// Isotope
	703,	// Cool
	704		// Energy Orb
};

// These are the three different type of effects which can be applied to a single weapon slot. Matches killStreakTierMenuItems string array.
int killStreakTierSel[] = {
	0,	  // Basic
	1,	  // Specialized
	2	  // Professional
};

// These are all different types of Killstreak sheens which can be applied to a single weapon slot. Matches killStreakSheenMenuItems string array.
int killStreakSheenSel[] = {
	1,	  // Team Shine
	2,	  // Deadly Daffodil
	3,	  // Manndarin
	4,	  // Mean Green
	5,	  // Agonizing Emerald
	6,	  // Villainous Violet
	7	  // Hot Rod
};

// These are all different types of Killstreak effects which can be applied to a single weapon slot. Matches killStreakEffectMenuItems string array.
int killStreakEffectSel[] = {
	2002,	 // Fire Horns
	2003,	 // Cerebral Discharge
	2004,	 // Tornado
	2005,	 // Flames
	2006,	 // Singularity
	2007,	 // Incinerator
	2008	 // Hypno Beam
};

// ConVars
// These are server side settings which the server administrator can change to help tailor the plugin to their specific use case.
// Defined ConVars are just wrappers for handles which allow the plugin to manage the state of a ConVar
ConVar cEnabled;		 // Is the plugin enabled?
ConVar cDatabaseName;	 // Name of database to connect to inside of databases.cfg REF: https://wiki.alliedmods.net/SQL_(SourceMod_Scripting)#Connecting
ConVar cTableName;		 // Name of table created / read from inside the database.
public Plugin myinfo =
{
	name		= "[TF2] Wearables",
	author		= "keybangz",
	description = "Allows players to use a menu to pick custom attributes for there weapons or player.",
	version		= PLUGIN_VERSION,
	url			= "https://github.com/keybangz",
};

public void OnPluginStart()
{
	// Version ConVar, used on AlliedModders forum to check count of servers running this plugin.
	CreateConVar("tf_wearables_version", PLUGIN_VERSION, "Wearables Version (Do not touch).", FCVAR_NOTIFY | FCVAR_REPLICATED);
	cEnabled	  = CreateConVar("tf_wearables_enabled", "1", "Enable TF2 wearables plugin?", _, true, 0.0, true, 1.0);
	cDatabaseName = CreateConVar("tf_wearables_db", "wearables", "Name of the database connecting to store player data.", _, false, _, false, _);
	cTableName	  = CreateConVar("tf_wearables_table", "wearables", "Name of the table holding the player data in the database.", _, false, _, false, _);

	// In-game events the plugin should listen to.
	// If other plugins are manually invoking these events, THESE EVENTS WILL FIRE. (Bad practice to manually invoke events anyways)
	HookEvent("post_inventory_application", OnResupply);	// When player touches resupply locker, respawns or manually invokes a refresh of player items.

	// Admin Commands
	RegAdminCmd("sm_wearables", WearablesCommand, ADMFLAG_RESERVATION, "Shows the wearables menu.");	// Translates to /wearables in-game

	// Initialize new ArrayList to store all hat id's inside game, used in ReadItemSchema()
	hatIDList			  = new ArrayList(ByteCountToCells(512));
	unusualEffectNameList = new ArrayList(ByteCountToCells(512));
	unusualEffectIDList	  = new ArrayList(ByteCountToCells(512));
	tauntEffectList		  = new ArrayList(ByteCountToCells(512));
	tauntEffectNameList	  = new ArrayList(ByteCountToCells(512));
	tauntRefireTimerList  = new ArrayList(ByteCountToCells(512));

	ReadItemSchema();

	// Setup database connection.
	char dbname[64];
	cDatabaseName.GetString(dbname, sizeof(dbname));	// Grab database ConVar string value and store to buffer.

	TranslationFileParser tfp;
	tfp.Init();
	tfp.OnKeyValue = OnTranslationPair;

	// cheers nosoup for the stocksoup collection :)
	// the file must be opened in binary mode
	// it's also recommended to set use_valve_fs to ensure it can be read even if is mounted from a different directory
	File f		   = OpenFile("resource/tf_english.txt", "rb", .use_valve_fs = true);
	tfp.ParseOpenUTF16File(f);
	delete f;

	// Connect to database here.
	Database.Connect(DatabaseHandler, dbname);	  // Pass string buffer to connect method.
}

void OnTranslationPair(const char[] key, const char[] value)
{
	// Loop through taunt effect ID list and match them with the key.
	if (StrContains(key, "Attrib_Particle", true) != -1)
	{
		// unusual hat effects
		if (strlen(key) == 18 || strlen(key) == 17 || strlen(key) == 16)
		{
			unusualEffectNameList.PushString(value);
			// LogMessage("hatEffect added: key: %s, val: %s, size: %i", key, value, unusualEffectNameList.Length);
		}

		// unusual taunts
		if (strlen(key) == 19)
		{
			tauntEffectNameList.PushString(value);
			// LogMessage("tauntEffect added: key: %s, val: %s, size: %i", key, value, tauntEffectNameList.Length);
		}
	}
}

// Here we will setup the SQL table to store player preferences.
// GOAL: Support MySQL and SQLite(?)
public void DatabaseHandler(Database db, const char[] error, any data)
{
	if (!cEnabled.BoolValue)	// If plugin is not enabled, do nothing.
		return;

	if (db == null)									// Ensure databases.cfg settings are correct.
		LogError("Database failure: %s", error);	// If anything fails, report back to server.

	WearablesDB = db;	 // Set global database handle to newly connected to database set out in databases.cfg

	char query[512];	 // Buffer to store query in.
	char buffer[256];	 // Alternative buffer used to store desired ConVar values and use with query.

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
	FormatEx(query, sizeof(query), "CREATE TABLE IF NOT EXISTS %s (id int(11) NOT NULL AUTO_INCREMENT, steamid varchar(32) UNIQUE, primaryTier int(11), primarySheen int(11), primaryEffect int(11), secondaryTier int(11), secondarySheen int(11), secondaryEffect int(11), meleeTier int(11), meleeSheen int(11), meleeEffect int(11), unusualTauntId varchar(64), unusualHatId int(11), unusualPrimary int(11), unusualSecondary int(11), unusualMelee int(11), PRIMARY KEY (id))", buffer);
	WearablesDB.Query(SQLError, query);	   // Query to SQL error callback, since we do nothing with data when creating table.
}

// SQLError
// Standard SQL callback to process errors for any queries that are used throughout the plugin, any queries which take and redefine data will have their own callback.
public void SQLError(Database db, DBResultSet results, const char[] error, any data)
{
	if (!cEnabled.BoolValue)	// If plugin is not enabled, do nothing.
		return;

	if (results == null)
		LogError("Query failure: %s", error);
}

// Our main methodmap, this provides us with all functions required to assign desired effects to the desired player.
methodmap Player
{

public 	Player(int userid)
	{	 // Constructor of methodmap
		if (IsClientInGame(userid))
			return view_as<Player>(GetClientUserId(userid));	// Will return index of Player entry in methodmap, note this does not reflect the client unless we assign the client to the methodmap first.
		return view_as<Player>(-1);								// We want to ensure we hold no null / disconnected players even in our constructor.
	}
	// Apparently this gets overwritten when player entity list ticks over max count
	// First player on server -> Server gets full -> First player leaves -> New player joins -> New player takes index of first player
	// From my own testing with just a single person, this doesn't seem to be the case?
	// If run into issues, get index by userid and convert when needed.
	property int index
	{	 // Returns player index so we can apply effects when needed.
public 		get() { return view_as<int>(this); }
	}

	// Was previously using real methodmap setters and getters for this, however we want the ability to set effects to desired slot and we cannot pass more than 1 parameter to setters in SourceMod.
	// Update: .get methodmap function on property was not returning anything?, just use standard function for now.
	// Get players current killstreak tier on desired slot.
public 	int GetKillstreakTierId(int slot)
	{
		return killStreakTier[this.index][slot];
	}

	// Set players selected killstreak tier on desired slot.
public 	void SetKillstreakTierId(int val, int slot)
	{
		killStreakTier[this.index][slot] = val;
	}

	// Get players current killstreak sheen on desired slot.
public 	int GetKillstreakSheenId(int slot)
	{
		return killStreakSheen[this.index][slot];
	}

	// Set players selected killstreak sheen on desired slot.
public 	void SetKillstreakSheenId(int val, int slot)
	{
		killStreakSheen[this.index][slot] = val;
	}

	// Get players current killstreak effect on desired slot.
public 	int GetKillstreakEffectId(int slot)
	{
		return killStreakEffect[this.index][slot];
	}

	// Set players selected killstreak effect on desired slot.
public 	void SetKillstreakEffectId(int val, int slot)
	{
		killStreakEffect[this.index][slot] = val;
	}

	// Get players current unusual taunt effect and stores them into destination buffer.
public 	void GetUnusualTauntEffectId(char[] val, int length)
	{
		strcopy(val, length, unusualTauntEffect[this.index]);
	}

	// Set players selected unusual taunt effect.
public 	void SetUnusualTauntEffectId(char[] val)
	{
		strcopy(unusualTauntEffect[this.index], sizeof(unusualTauntEffect), val);
	}

	// Get players current unusual hat effect
public 	int GetUnusualHatEffectId()
	{
		return unusualHatEffect[this.index];
	}

	// Set players current unusual hat effect
public 	void SetUnusualHatEffectId(int val)
	{
		unusualHatEffect[this.index] = val;
	}

	// Get players current unusual weapon effect at desired slot
public 	int GetUnusualWeaponEffect(int slot)
	{
		return unusualWeaponEffect[this.index][slot];
	}

	// Set players current unusual weapon effect at desired slot
public 	void SetUnusualWeaponEffectId(int val, int slot)
	{
		unusualWeaponEffect[this.index][slot] = val;
	}
}

// Our goal here from version 1 is too minimize the amount of repitition the previous codebase had used.
// To do this we will strip a lot of logic into single functions and determine the use case based on the parameters passed.
// We want to organize our code into a methodmap or some sort of structured way to prevent recreation of variables that we don't need.
// Unlike the previous version, we will be using SQLite or MySQL to store player preferences, this will provide us with a cleaner codebase and remove the hassle of cookie caching and verification.

// Unusual effects cannot be fetched & applied fast enough to update before player spawns, here we'll grab Unusual Taunt + Unusual Hat Effect and set them since we can do that without any extra information. (such as weapon slots)
public void OnClientPutInServer(int client)
{
	if (IsFakeClient(client))
	{	 // Check if the client is a fake or not. If the client is fake, we stop the function so we don't send unnecessary queries to the database.
		return;
	}
	int	 userid = GetClientUserId(client);	  // Pass through client userid to validate & update player data in handler.
	char buffer[256];						  // Buffer used to store temporary values in FetchWearables
	char query[256];						  // Buffer used to store queries sent to database.

	// REF: https://sm.alliedmods.net/new-api/clients/AuthIdType
	char steamid[32];														  // Buffer to store SteamID32
	if (!GetClientAuthId(client, AuthId_Steam2, steamid, sizeof(steamid)))	  // Grab player SteamID32, if fails do nothing.
		return;

	cTableName.GetString(buffer, sizeof(buffer));																		  // Grab table name string value
	FormatEx(query, sizeof(query), "SELECT unusualTauntId, unusualHatId FROM %s WHERE steamid='%s'", buffer, steamid);	  // Setup query to select effects only if matching steamid.

	WearablesDB.Query(updateEffectsEarly, query, userid);
}

// I would totally prefer not to do an early fetch and fetch all information at once, but hey not everything can be perfect.
// (Suggestions open)
void updateEffectsEarly(Database db, DBResultSet results, const char[] error, any data)
{
	int client = 0;

	if (db == null || results == null || error[0] != '\0')
	{	 // If database handle or results are null, log error also check if error buffer has anything stored.
		LogError("Query failed! error: %s", error);
		return;
	}

	char buffer[64];	// Buffer to fetch unusualTauntId's

	// If userid passed to callback is invalid, do nothing.
	if ((client = GetClientOfUserId(data)) == 0)
		return;

	Player player = Player(client);

	// Early update both unusualTauntId and unusualHatId if player is found in database.
	while (results.FetchRow())
	{
		// unusualTauntId
		if (!SQL_IsFieldNull(results, 0))
		{
			results.FetchString(0, buffer, sizeof(buffer));
			player.SetUnusualTauntEffectId(buffer);
		}

		// unusualHatId
		if (!SQL_IsFieldNull(results, 1))
			player.SetUnusualHatEffectId(results.FetchInt(1));
	}
}

// FetchWearables - Used to fetch all data that might be already stored for the player inside the database.
void FetchWearables(int client, char[] steamid)
{
	if (IsFakeClient(client) || !IsClientInGame(client))
		return;

	int	 userid = GetClientUserId(client);	  // Pass through client userid to validate & update player data in handler.
	char buffer[256];						  // Buffer used to store temporary values in FetchWearables
	char query[512];						  // Buffer used to store queries sent to database.

	cTableName.GetString(buffer, sizeof(buffer));																																																														// Grab table name string value
	FormatEx(query, sizeof(query), "SELECT primaryTier, primarySheen, primaryEffect, secondaryTier, secondarySheen, secondaryEffect, meleeTier, meleeSheen, meleeEffect, unusualTauntId, unusualHatId, unusualPrimary, unusualSecondary, unusualMelee FROM %s WHERE steamid='%s'", buffer, steamid);	// Setup query to select effects only if matching steamid.
	WearablesDB.Query(FetchWearablesHandler, query, userid);

	// If player does not exist in table, add players steamid to table.
	FormatEx(query, sizeof(query), "INSERT IGNORE INTO %s(steamid) VALUES('%s')", buffer, steamid);
	WearablesDB.Query(SQLError, query);
}

// FetchWearablesHandler - Callback used to set wearable effects set by player.
void FetchWearablesHandler(Database db, DBResultSet results, const char[] error, any data)
{
	int client = 0;	   // We will need to pass through client with userid.

	if (db == null || results == null || error[0] != '\0')
	{	 // If database handle or results are null, log error also check if error buffer has anything stored.
		LogError("Query failed! error: %s", error);
		return;
	}

	char buffer[64];	// Buffer to fetch unusualTauntId's

	// If userid passed to callback is invalid, do nothing.
	if ((client = GetClientOfUserId(data)) == 0)
		return;

	int	   primary	 = ProcessLoadoutSlot(TF2Econ_TranslateLoadoutSlotNameToIndex("primary"), client);
	int	   secondary = ProcessLoadoutSlot(TF2Econ_TranslateLoadoutSlotNameToIndex("secondary"), client);
	int	   melee	 = ProcessLoadoutSlot(TF2Econ_TranslateLoadoutSlotNameToIndex("melee"), client);

	Player player	 = Player(client);

	// Grab row of data provided by SQL query.
	while (results.FetchRow())
	{
		// Here we've got to check each individual field and check if it's null before attempting to grab or update data.
		// Goes in order with query, meaning primaryTier = 0, primarySheen = 1, primaryEffect = 2, and so on.

		if (IsValidEntity(primary))
		{
			// primaryTier
			if (!SQL_IsFieldNull(results, 0))
				player.SetKillstreakTierId(results.FetchInt(0), primary);

			// primarySheen
			if (!SQL_IsFieldNull(results, 1))
				player.SetKillstreakSheenId(results.FetchInt(1), primary);

			// primaryEffect
			if (!SQL_IsFieldNull(results, 2))
				player.SetKillstreakEffectId(results.FetchInt(2), primary);

			// unusualPrimary
			if (!SQL_IsFieldNull(results, 11))
				player.SetUnusualWeaponEffectId(results.FetchInt(11), primary);
		}

		if (IsValidEntity(secondary))
		{
			// secondaryTier
			if (!SQL_IsFieldNull(results, 3))
				player.SetKillstreakTierId(results.FetchInt(3), secondary);

			// secondarySheen
			if (!SQL_IsFieldNull(results, 4))
				player.SetKillstreakSheenId(results.FetchInt(4), secondary);

			// secondaryEffect
			if (!SQL_IsFieldNull(results, 5))
				player.SetKillstreakEffectId(results.FetchInt(5), secondary);

			// unusualSecondary
			if (!SQL_IsFieldNull(results, 12))
				player.SetUnusualWeaponEffectId(results.FetchInt(12), secondary);
		}

		if (IsValidEntity(melee))
		{
			// meleeTier
			if (!SQL_IsFieldNull(results, 6))
				player.SetKillstreakTierId(results.FetchInt(6), melee);

			// meleeSheen
			if (!SQL_IsFieldNull(results, 7))
				player.SetKillstreakSheenId(results.FetchInt(7), melee);

			// meleeEffect
			if (!SQL_IsFieldNull(results, 8))
				player.SetKillstreakEffectId(results.FetchInt(8), melee);

			// unusualMelee
			if (!SQL_IsFieldNull(results, 13))
				player.SetUnusualWeaponEffectId(results.FetchInt(13), melee);
		}

		// unusualTauntId
		if (!SQL_IsFieldNull(results, 9))
		{
			results.FetchString(9, buffer, sizeof(buffer));
			player.SetUnusualTauntEffectId(buffer);
		}

		// unusualHatId
		if (!SQL_IsFieldNull(results, 10))
			player.SetUnusualHatEffectId(results.FetchInt(10));
	}
}

// UpdateWearables() - Responsible for updating effects per player to the database.
void UpdateWearables(int client, char[] steamid)
{
	char   query[512];
	char   buffer[256];

	Player player	 = Player(client);	  // Initalize player methodmap

	// Since we are working off of player slots, the player must be alive when we update the database.
	int	   primary	 = ProcessLoadoutSlot(TF2Econ_TranslateLoadoutSlotNameToIndex("primary"), client);
	int	   secondary = ProcessLoadoutSlot(TF2Econ_TranslateLoadoutSlotNameToIndex("secondary"), client);
	int	   melee	 = ProcessLoadoutSlot(TF2Econ_TranslateLoadoutSlotNameToIndex("melee"), client);

	char   effect[MAXPLAYERS + 1][64];								   // String to store current unusual taunt effect into
	player.GetUnusualTauntEffectId(effect[client], sizeof(effect));	   // Store unusual taunt effect to buffer to use below.

	cTableName.GetString(buffer, sizeof(buffer));

	if (IsValidEntity(primary))
	{
		FormatEx(query, sizeof(query), "UPDATE %s SET primaryTier='%i', primarySheen='%i', primaryEffect='%i', unusualPrimary='%i' WHERE steamid='%s'", buffer, player.GetKillstreakTierId(primary), player.GetKillstreakSheenId(primary), player.GetKillstreakEffectId(primary), player.GetUnusualWeaponEffect(primary), steamid);
		WearablesDB.Query(SQLError, query);
	}

	if (IsValidEntity(secondary))
	{
		FormatEx(query, sizeof(query), "UPDATE %s SET secondaryTier='%i', secondarySheen='%i', secondaryEffect='%i', unusualSecondary='%i' WHERE steamid='%s'", buffer, player.GetKillstreakTierId(secondary), player.GetKillstreakSheenId(secondary), player.GetKillstreakEffectId(secondary), player.GetUnusualWeaponEffect(secondary), steamid);
		WearablesDB.Query(SQLError, query);
	}

	if (IsValidEntity(melee))
	{
		FormatEx(query, sizeof(query), "UPDATE %s SET meleeTier='%i', meleeSheen='%i', meleeEffect='%i', unusualMelee='%i' WHERE steamid='%s'", buffer, player.GetKillstreakTierId(melee), player.GetKillstreakSheenId(melee), player.GetKillstreakEffectId(melee), player.GetUnusualWeaponEffect(melee), steamid);
		WearablesDB.Query(SQLError, query);
	}

	FormatEx(query, sizeof(query), "UPDATE %s SET unusualTauntId='%s', unusualHatId='%i' WHERE steamid='%s'", buffer, effect[client], player.GetUnusualHatEffectId(), steamid);
	WearablesDB.Query(SQLError, query);
}

// TF2_OnConditionAdded is an event which SourceMod listens to natively, here we can check different player conditions (ex: jumping, taunting, etc etc)
// Check if player is taunting, if so add desired effect to player.
public void TF2_OnConditionAdded(int client, TFCond condition)
{
	if (!cEnabled.BoolValue)	// If plugin is not enabled, do nothing.
		return;

	if (!IsClientInGame(client) || !IsPlayerAlive(client))	  // Self explanatory
		return;

	if (condition != TFCond_Taunting)
		return;

	Player player = Player(client);									   // Initalize player methodmap
	char   effect[MAXPLAYERS + 1][64];								   // String to store current unusual taunt effect into
	player.GetUnusualTauntEffectId(effect[client], sizeof(effect));	   // Grab player current unusual effect and store into destination buffer

	if(!strlen(effect[client]))
		return;

	// AttachParticle(client, effect[client]); // Create and attach desired particle effect to player.
	CreateTempParticle(effect[client], client);

	DataPack pack;	  // Create a datapack which we will use for refire timings below.

	char	 sRefire[512];
	int		 iRefireTime = tauntEffectList.FindString(effect[client]);
	float	 fRefireTime = 0.0;

	if (iRefireTime != -1)
	{
		GetArrayString(tauntRefireTimerList, iRefireTime, sRefire, sizeof(sRefire));
		fRefireTime = StringToFloat(sRefire);
		LogMessage("%f reFireTime, %d iRefireTime", fRefireTime, iRefireTime);

		if (fRefireTime >> 0.0)
		{
			refireTimer[client] = CreateDataTimer(fRefireTime, HandleRefire, pack, TIMER_REPEAT);
			pack.WriteCell(client);
			pack.WriteString(effect[client]);
		}
	}

	// Here we will re-attach any particles with an expiry time
	// I would much rather check the players taunt in the timer handler, however different taunts have different expiry times.
	// REF: https://wiki.teamfortress.com/wiki/Item_schema
	// if (StrEqual(effect[client], "utaunt_firework_teamcolor_red"))
	// {	 // Showstopper (RED) expires every 2.6 seconds according to latest items_game.txt
	// 	refireTimer[client] = CreateDataTimer(2.6, HandleRefire, pack, TIMER_REPEAT);
	// 	pack.WriteCell(client);
	// 	pack.WriteString(effect[client]);
	// }
	// else if (StrEqual(effect[client], "utaunt_firework_teamcolor_blue")) {	  // Showstopper (BLU) expires every 2.6 seconds according to latest items_game.txt
	// 	refireTimer[client] = CreateDataTimer(2.6, HandleRefire, pack, TIMER_REPEAT);
	// 	pack.WriteCell(client);
	// 	pack.WriteString(effect[client]);
	// }
	// else if (StrEqual(effect[client], "utaunt_lightning_parent")) {	   // Mega Strike expires every 0.9 seconds according to latest items_game.txt
	// 	refireTimer[client] = CreateDataTimer(0.9, HandleRefire, pack, TIMER_REPEAT);
	// 	pack.WriteCell(client);
	// 	pack.WriteString(effect[client]);
	// }
	// else if (StrEqual(effect[client], "utaunt_firework_dragon_parent")) {	 // Roaring Rockets expires every 5.25 seconds according to latest items_game.txt
	// 	refireTimer[client] = CreateDataTimer(5.25, HandleRefire, pack, TIMER_REPEAT);
	// 	pack.WriteCell(client);
	// 	pack.WriteString(effect[client]);
	// }
}

// HandleRefire
// Timer callback handled per client to reissue any unusual taunt effects which have an expiry time.
public Action HandleRefire(Handle timer, DataPack pack)
{
	char buffer[64];	// Unusual taunt effect passed through
	int	 client;		// Client passed through

	// Datapacks require the data that is written to them be read in the same order it was written to.
	pack.Reset();								// Reset datapack incase there is data left over.
	client = pack.ReadCell();					// Get client index passed through
	pack.ReadString(buffer, sizeof(buffer));	// Get unusual effect passed through.

	// AttachParticle(client, buffer); // Attach the particle to player.
	CreateTempParticle(buffer, client);

	return Plugin_Handled;
}

// TF2_OnConditionRemoved is an event which SourceMod listens to natively, here we can check if different player conditions are no longer active (ex: jumping, taunting, etc etc)
// Check if player is no longer taunting and delete desired particle.
public void TF2_OnConditionRemoved(int client, TFCond condition)
{
	if (!cEnabled.BoolValue)	// If plugin is not enabled, do nothing.
		return;

	if (!IsClientInGame(client))
		return;

	if (condition != TFCond_Taunting)
		return;

	ClearTempParticles(client);

	delete refireTimer[client];	   // Stop timer from refiring if player is no longer taunting.
}

// Hooked Events
public Action OnResupply(Event event, const char[] name, bool dontBroadcast)
{
	if (!cEnabled.BoolValue)	// If plugin is not enabled, do nothing.
		return Plugin_Handled;

	int client = GetClientOfUserId(GetEventInt(event, "userid"));

	if (!IsClientInGame(client))
		return Plugin_Handled;

	// REF: https://sm.alliedmods.net/new-api/clients/AuthIdType
	char steamid[32];														  // Buffer to store SteamID32
	if (!GetClientAuthId(client, AuthId_Steam2, steamid, sizeof(steamid)))	  // Grab player SteamID32, if fails do nothing.
		return Plugin_Continue;

	FetchWearables(client, steamid);	// Fetch the wearable set from the database.

	// Item attribute 2025 is a attribute definition for killstreak tiers
	// Item attribute 2014 is a attribute definition for killstreak sheens
	// Item attribute 2013 is a attribute definition for killstreak effects
	// REF: https://wiki.teamfortress.com/wiki/List_of_item_attributes

	// OnResupply, ensure to override default item attributes again with desired attributes.
	// Primary Weapons

	CreateTimer(0.1, ProcessWeaponsHandler, client);	// Process weapons after a slight delay to ensure player has spawned.

	return Plugin_Handled;
}

Action ProcessWeaponsHandler(Handle timer, int client)
{
	Player player	 = Player(client);

	// These will be valid entities on resupply due to player has be alive for resupply to take place.
	int	   primary	 = ProcessLoadoutSlot(TF2Econ_TranslateLoadoutSlotNameToIndex("primary"), client);
	int	   secondary = ProcessLoadoutSlot(TF2Econ_TranslateLoadoutSlotNameToIndex("secondary"), client);
	int	   melee	 = ProcessLoadoutSlot(TF2Econ_TranslateLoadoutSlotNameToIndex("melee"), client);

	if (IsValidEntity(primary))
	{
		if (player.GetKillstreakTierId(primary) > 0)											   // Only do if player has selected a killstreak tier
			TF2Attrib_SetByDefIndex(primary, 2025, float(player.GetKillstreakTierId(primary)));	   // Updates killstreak tier attribute to selected value
		if (player.GetKillstreakSheenId(primary) > 0)
			TF2Attrib_SetByDefIndex(primary, 2014, float(player.GetKillstreakSheenId(primary)));
		if (player.GetKillstreakEffectId(primary) > 0)
			TF2Attrib_SetByDefIndex(primary, 2013, float(player.GetKillstreakEffectId(primary)));
		if (player.GetUnusualWeaponEffect(primary) > 0)
			TF2Attrib_SetByDefIndex(primary, 134, float(player.GetUnusualWeaponEffect(primary)));
	}

	// Secondary Weapons
	if (IsValidEntity(secondary))
	{
		if (player.GetKillstreakTierId(secondary) > 0)												   // Only do if player has selected a killstreak tier
			TF2Attrib_SetByDefIndex(secondary, 2025, float(player.GetKillstreakTierId(secondary)));	   // Updates killstreak tier attribute to selected value
		if (player.GetKillstreakSheenId(secondary) > 0)
			TF2Attrib_SetByDefIndex(secondary, 2014, float(player.GetKillstreakSheenId(secondary)));
		if (player.GetKillstreakEffectId(secondary) > 0)
			TF2Attrib_SetByDefIndex(secondary, 2013, float(player.GetKillstreakEffectId(secondary)));
		if (player.GetUnusualWeaponEffect(secondary) > 0)
			TF2Attrib_SetByDefIndex(secondary, 134, float(player.GetUnusualWeaponEffect(secondary)));
	}

	// Melee Weapons
	if (IsValidEntity(melee))
	{
		if (player.GetKillstreakTierId(melee) > 0)											   // Only do if player has selected a killstreak tier
			TF2Attrib_SetByDefIndex(melee, 2025, float(player.GetKillstreakTierId(melee)));	   // Updates killstreak tier attribute to selected value
		if (player.GetKillstreakSheenId(melee) > 0)
			TF2Attrib_SetByDefIndex(melee, 2014, float(player.GetKillstreakSheenId(melee)));
		if (player.GetKillstreakEffectId(melee) > 0)
			TF2Attrib_SetByDefIndex(melee, 2013, float(player.GetKillstreakEffectId(melee)));
		if (player.GetUnusualWeaponEffect(melee) > 0)
			TF2Attrib_SetByDefIndex(melee, 134, float(player.GetUnusualWeaponEffect(melee)));
	}

	return Plugin_Stop;
}

// Command Handlers
public Action WearablesCommand(int client, int args)
{
	if (client <= 0)
	{
		PrintToServer("[TF2 Wearables] This command is not available to the server console");	 // Properly handle command for server console, instead of throwing an error.
		return Plugin_Handled;
	}

	if (!cEnabled.BoolValue)	// If plugin is not enabled, do nothing.
		return Plugin_Handled;

	// Validate client is actually in-game for menu to display
	if (!IsClientInGame(client))
		return Plugin_Handled;

	// Call our menu create function, on command /wearables run, we display the base menu.
	MenuCreate(client, wearablesMenu, "Wearables Menu");

	return Plugin_Handled;	  // Return Plugin_Handled to prevent "unknown command issues."
}

// Menu Constructors
// Switch cases are not fall-through in SourceMod, once a condition is met it will stop the switch at desired case and run block of code.
// FIXME: Use default: keyword for error handling(?) Not sure if required here, need to test.
public void MenuCreate(int client, wearablesOptions menuOptions, char[] menuTitle)
{
	if (!cEnabled.BoolValue)	// If plugin is not enabled, do nothing.
		return;

	if (!IsClientInGame(client))	// MenuCreate is called multiple times throughout this plugin, the client could potentionally disconnect after the initial menu creation.
		return;

	Menu menu = new Menu(Menu_Handler, MENU_ACTIONS_ALL);

	menu.SetTitle("%s", menuTitle);	   // Set menu title passed from function call

	switch (menuOptions)
	{	 // Which menu should be created?
		case wearablesMenu:
		{	 // Wearables Main Menu
			// Loop through wearableMenuItems string array to add correct options.
			for (int i = 0; i < sizeof(wearableMenuItems); i++)
			{
				menu.AddItem(wearableMenuItems[i], wearableMenuItems[i]);
			}
		}
		case killStreakMenu:
		{	 // Killstreaks Main Menu
			// Loop through killstreaksMenuItems string array to add correct options.
			for (int i = 0; i < sizeof(killStreakMenuItems); i++)
			{
				menu.AddItem(killStreakMenuItems[i], killStreakMenuItems[i]);
			}
		}
		case unusualTauntMenu:
		{	 // Unusual Taunts Main Menu
			char tauntName[512];
			char tauntEffect[512];

			char oldTauntName[512];
			char oldTauntEffect[512];

			int	 j = 0;

			for (int i = 0; i < tauntEffectNameList.Length; i++)
			{
				tauntEffectNameList.GetString(i, tauntName, sizeof(tauntName));
				tauntEffectList.GetString(i, tauntEffect, sizeof(tauntEffect));

				j = i - 1;

				if (StrEqual(oldTauntName, tauntName, true))
				{
					tauntEffectNameList.GetString(j, oldTauntName, sizeof(oldTauntName));
					tauntEffectList.GetString(j, oldTauntEffect, sizeof(oldTauntEffect));
					Format(oldTauntName, sizeof(oldTauntName), "%s (RED)", oldTauntName);
					menu.AddItem(oldTauntEffect, oldTauntName);
					menu.RemoveItem(j);
					// LogMessage("oldTauntName: %s, oldTauntEffect: %s", oldTauntName, oldTauntEffect);

					Format(tauntName, sizeof(tauntName), "%s (BLU)", tauntName);
					menu.AddItem(tauntEffect, tauntName);
					// LogMessage("tauntName: %s, tauntEffect: %s", tauntName, tauntEffect);
					continue;
				}

				oldTauntName = tauntName;
				// LogMessage("tauntEffect: %s, tauntName: %s", tauntEffect, tauntName);
				menu.AddItem(tauntEffect, tauntName);
			}
		}
		case killStreakTierMenu:
		{	 // Killstreaks Tier Menu
			// Loop through killstreaksTierMenuItems string array to add correct options.
			for (int i = 0; i < sizeof(killStreakTierMenuItems); i++)
			{
				menu.AddItem(killStreakTierMenuItems[i], killStreakTierMenuItems[i]);
			}
		}

		case killStreakSheenMenu:
		{	 // Killstreaks Sheen Menu
			// Loop through killstreaksSheenMenuItems string array to add correct options.
			for (int i = 0; i < sizeof(killStreakSheenMenuItems); i++)
			{
				menu.AddItem(killStreakSheenMenuItems[i], killStreakSheenMenuItems[i]);
			}
		}

		case killStreakEffectMenu:
		{	 // Killstreaks Effect Menu
			// Loop through killstreaksEffectMenuItems string array to add correct options.
			for (int i = 0; i < sizeof(killStreakEffectMenuItems); i++)
			{
				menu.AddItem(killStreakEffectMenuItems[i], killStreakEffectMenuItems[i]);
			}
		}

		case slotSelectMenu:
		{	 // Weapon Slot Selection Menu
			// Loop through killstreaksEffectMenuItems string array to add correct options.
			for (int i = 0; i < sizeof(weaponSlotMenuItems); i++)
			{
				menu.AddItem(weaponSlotMenuItems[i], weaponSlotMenuItems[i]);
			}
		}

		case unusualMenu:
		{	 // Unusual Hat Selection Menu

			char effectName[512];
			char effectID[512];

			for (int i = 0; i < unusualEffectIDList.Length; i++)
			{
				unusualEffectNameList.GetString(i+1, effectName, sizeof(effectName));
				unusualEffectIDList.GetString(i, effectID, sizeof(effectID));

				// LogMessage("effectName: %s, effectID: %s", effectName, effectID);

				menu.AddItem(effectID, effectName);
			}

			// Loop through unusualHatMenuItems string array to add correct options.
			// for (int i = 0; i < sizeof(unusualMenuItems); i++)
			// {
			// 	menu.AddItem(unusualMenuItems[i], unusualMenuItems[i]);
			// }
		}

		case unusualWeaponMenu:
		{
			// Loop through unusualWeaponMenuItems string array to add correct options.
			for (int i = 0; i < sizeof(unusualWeaponMenuItems); i++)
			{
				menu.AddItem(unusualWeaponMenuItems[i], unusualWeaponMenuItems[i]);
			}
		}
	}

	menu.ExitButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

// Menu Handlers
public int Menu_Handler(Menu menu, MenuAction menuAction, int client, int menuItem)
{
	// We will only be worrying about handling the display of menu & the selection of the menu's items, rest can be ignored unless debugging.
	switch (menuAction)
	{
		case MenuAction_Select:
		{
			Player player = Player(client);	   // Initialize our player method map to save, store and update wearable effects.

			// SourceMod uses strings as selectors for menus, we will grab our selected menu item string and compare with our available options to give the menu functionality.
			char   info[256];
			menu.GetItem(menuItem, info, sizeof(info));

			// REF: https://sm.alliedmods.net/new-api/clients/AuthIdType
			char steamid[32];														  // Buffer to store SteamID32
			if (!GetClientAuthId(client, AuthId_Steam2, steamid, sizeof(steamid)))	  // Grab player SteamID32, if fails do nothing.
				return -1;

			// Main Menu Handling
			// If item selected is killstreaks, show client killstreak menu.
			if (StrEqual(info, "Killstreak Menu"))
			{
				MenuCreate(client, killStreakMenu, "Killstreak Menu");
			}

			// Unusual Taunt Menu Handling
			// If selected, display available Unusual Taunts for player to choose from.
			if (StrEqual(info, "Unusual Taunts Menu"))
			{
				MenuCreate(client, unusualTauntMenu, "Unusual Taunts Menu");
			}

			// Unusual Hat Menu Handling
			// IF selected, display all available unusual effects for player to choose from.
			if (StrEqual(info, "Unusual Hats Menu"))
			{
				MenuCreate(client, unusualMenu, "Unusual Hats Menu");
			}

			// Killstreak Menu Handling
			// If selected, display available Killstreak Tiers for player to choose from.
			if (StrEqual(info, "Killstreak Tier"))
			{
				MenuCreate(client, killStreakTierMenu, "Killstreak Tier Menu");
			}

			// If selected, display available Killstreak Sheens for player to choose from.
			if (StrEqual(info, "Killstreak Sheen"))
			{
				MenuCreate(client, killStreakSheenMenu, "Killstreak Sheens Menu");
			}

			// If selected, display available Killstreak Effects for player to choose from.
			if (StrEqual(info, "Killstreak Effect"))
			{
				MenuCreate(client, killStreakEffectMenu, "Killstreak Effects Menu");
			}

			// If selected, display available Killstreak Effects for player to choose from.
			if (StrEqual(info, "Unusual Weapons Menu"))
			{
				MenuCreate(client, unusualWeaponMenu, "Unusual Weapons Menu");
			}

			// After selecting a killstreak attribute, player must select which weapon slot to apply the effect too.
			if (StrEqual(info, "Primary"))
			{
				int slot = ProcessLoadoutSlot(TF2Econ_TranslateLoadoutSlotNameToIndex("primary"), client);

				if (!IsValidEntity(slot))
					return -1;

				if (tTier[client] > 0)
				{																  // If temporary variable has been set, update values.
					TF2Attrib_SetByDefIndex(slot, 2025, float(tTier[client]));	  // Updates killstreak tier to temporary value, permanent value used in OnResupply
					player.SetKillstreakTierId(tTier[client], slot);			  // Update player killstreak tier to be used elsewhere.
					tTier[client] = 0;
				}

				if (tSheen[client] > 0)
				{
					TF2Attrib_SetByDefIndex(slot, 2014, float(tSheen[client]));	   // Updates killstreak sheen to temporary value, permanent value used in OnResupply
					player.SetKillstreakSheenId(tSheen[client], slot);			   // Update player killstreak sheen to be used elsewhere.
					tSheen[client] = 0;
				}

				if (tEffect[client] > 0)
				{
					TF2Attrib_SetByDefIndex(slot, 2013, float(tEffect[client]));	// Updates killstreak effect to temporary value, permanent value used in OnResupply
					player.SetKillstreakEffectId(tEffect[client], slot);			// Update player killstreak effect to be used elsewhere.
					tEffect[client] = 0;
				}

				if (tWeaponEffect[client] > 0)
				{
					TF2Attrib_SetByDefIndex(slot, 134, float(tWeaponEffect[client]));	 // Updates weapon unusual effect to temporary value, permanent value used in OnResupply
					player.SetUnusualWeaponEffectId(tWeaponEffect[client], slot);
					tWeaponEffect[client] = 0;
				}

				// Display the main wearables menu after player has selected killstreak option.
				MenuCreate(client, wearablesMenu, "Wearables Menu");
				UpdateWearables(client, steamid);	 // Update the wearable attributes set by player by writing changes to database.
			}

			// If player chose second weapon slot
			if (StrEqual(info, "Secondary"))
			{
				int slot = ProcessLoadoutSlot(TF2Econ_TranslateLoadoutSlotNameToIndex("secondary"), client);

				if (!IsValidEntity(slot))
					return -1;

				if (tTier[client] > 0)
				{
					TF2Attrib_SetByDefIndex(slot, 2025, float(tTier[client]));	  // Updates killstreak tier to temporary value, permanent value used in OnResupply
					player.SetKillstreakTierId(tTier[client], slot);			  // Update player killstreak tier effect to be used elsewhere.
				}

				if (tSheen[client] > 0)
				{
					TF2Attrib_SetByDefIndex(slot, 2014, float(tSheen[client]));	   // Updates killstreak sheen to temporary value, permanent value used in OnResupply
					player.SetKillstreakSheenId(tSheen[client], slot);			   // Update player killstreak sheen to be used elsewhere.
				}

				if (tEffect[client] > 0)
				{
					TF2Attrib_SetByDefIndex(slot, 2013, float(tEffect[client]));	// Updates killstreak effect to temporary value, permanent value used in OnResupply
					player.SetKillstreakEffectId(tEffect[client], slot);			// Update player killstreak effect to be used elsewhere.
				}

				if (tWeaponEffect[client] > 0)
				{
					player.SetUnusualWeaponEffectId(tWeaponEffect[client], slot);
					tWeaponEffect[client] = 0;
				}

				// Display the main wearables menu after player has selected killstreak option.
				MenuCreate(client, wearablesMenu, "Wearables Menu");
				UpdateWearables(client, steamid);	 // Update the wearable attributes set by player by writing changes to database.
			}

			// If player chose melee weapon slot
			if (StrEqual(info, "Melee"))
			{
				int slot = ProcessLoadoutSlot(TF2Econ_TranslateLoadoutSlotNameToIndex("melee"), client);

				if (!IsValidEntity(slot))
					return -1;

				if (tTier[client] > 0)
				{
					TF2Attrib_SetByDefIndex(slot, 2025, float(tTier[client]));	  // Updates killstreak tier to temporary value, permanent value used in OnResupply
					player.SetKillstreakTierId(tTier[client], slot);			  // Update player killstreak tier to be used elsewhere.
				}

				if (tSheen[client] > 0)
				{
					TF2Attrib_SetByDefIndex(slot, 2014, float(tSheen[client]));	   // Updates killstreak sheen to temporary value, permanent value used in OnResupply
					player.SetKillstreakSheenId(tSheen[client], slot);			   // Update player killstreak sheen to be used elsewhere.
				}

				if (tEffect[client] > 0)
				{
					TF2Attrib_SetByDefIndex(slot, 2013, float(tEffect[client]));	// Updates killstreak effect to temporary value, permanent value used in OnResupply
					player.SetKillstreakEffectId(tEffect[client], slot);			// Update player killstreak effect to be used elsewhere.
				}

				if (tWeaponEffect[client] > 0)
				{
					player.SetUnusualWeaponEffectId(tWeaponEffect[client], slot);
					tWeaponEffect[client] = 0;
				}

				// Display the main wearables menu after player has selected killstreak option.
				MenuCreate(client, wearablesMenu, "Wearables Menu");
				UpdateWearables(client, steamid);	 // Update the wearable attributes set by player by writing changes to database.
			}

			// Killstreak Tiers, Sheens, Effects Handlers (We give players the effects selected here!)

			// Let's handle killStreakTiers first.
			// Loop through killStreakTierMenuItems string array
			for (int i = 0; i < sizeof(killStreakTierMenuItems); i++)
			{
				// If value picked on the menu matches our string value, then set item attribute index to value matching at same index.
				// Item attribute 2025 is a attribute definition for killstreak tiers, reference link at OnResupply
				if (StrEqual(info, killStreakTierMenuItems[i]))
				{
					MenuCreate(client, slotSelectMenu, "Apply to slot: ");
					tTier[client] = killStreakTierSel[i] + 1;	 // Set our temporary variable to value of our selected killstreak tier.
					break;
				}
			}

			// Loop through killStreakSheenMenuItems string array
			for (int i = 0; i < sizeof(killStreakSheenMenuItems); i++)
			{
				// If value picked on the menu matches our string value, then set item attribute index to value matching at same index.
				// Item attribute 2014 is a attribute definition for killstreak sheens, reference link at OnResupply
				if (StrEqual(info, killStreakSheenMenuItems[i]))
				{
					MenuCreate(client, slotSelectMenu, "Apply to slot: ");
					tSheen[client] = killStreakSheenSel[i];	   // Set our temporary variable to value of our selected killstreak sheen.
					break;
				}
			}

			// Loop through killStreakEffectMenuItems string array
			for (int i = 0; i < sizeof(killStreakEffectMenuItems); i++)
			{
				// If value picked on the menu matches our string value, then set item attribute index to value matching at same index.
				// Item attribute 2013 is a attribute definition for killstreak effects, reference link at OnResupply
				if (StrEqual(info, killStreakEffectMenuItems[i]))
				{
					MenuCreate(client, slotSelectMenu, "Apply to slot: ");
					tEffect[client] = killStreakEffectSel[i];	 // Set our temporary variable to value of our selected killstreak effect.
					break;
				}
			}

			char tName[512];
			// Loop through unusualTauntMenuItems string array
			for (int i = 0; i < tauntEffectNameList.Length; i++)
			{
				// If value picked on menu matches our string value, then set item attribute index to value matching at same index.
				// Unusual taunt particles are extracted from TF2's packed in items_game.txt file (pak01.vpk), we will be using the string name of particle from the items_game.txt document to add our unusual taunt to the player.
				// REF: https://wiki.teamfortress.com/wiki/Item_schema

				// Here we've got to think a little differently than the others, since we cannot append a attribute index to each individual taunt, we must use the string name of unusual taunt found in items_game.txt and attach the particle to the player manually.
				// This also means for particles which require a refire timer (Showstopper for example) will need magic numbers in order to function properly. These will be defined at the top of the file for readability.
				// Loop through unusual taunt menu item id list and match display name with item id.
				// Check if unusualTauntMenu matches selected by player
				tauntEffectList.GetString(i, tName, sizeof(tName));
				if (StrEqual(info, tName))
				{
					// Set unusualTauntMenuId to desired effect by matching index of display name with id.
					player.SetUnusualTauntEffectId(tName);
					MenuCreate(client, wearablesMenu, "Wearables Menu");
					UpdateWearables(client, steamid);	 // Update the wearable attributes set by player by writing changes to database.
					break;
				}
			}

			// Loop through unusualMenuItems string array
			for (int i = 0; i+1 < unusualEffectIDList.Length; i++)
			{
				// If value picked on the menu matches our string value, then set item attribute index to value matching at same index.
				unusualEffectIDList.GetString(i, tName, sizeof(tName));
				if (StrEqual(info, tName))
				{
					LogMessage("tName: %s", tName);
					player.SetUnusualHatEffectId(StringToInt(tName));
					MenuCreate(client, wearablesMenu, "Wearables Menu");
					UpdateWearables(client, steamid);	 // Update the wearable attributes set by player by writing changes to database.
					break;
				}
			}

			// Loop through unusualMenuItems string array
			for (int i = 0; i < sizeof(unusualWeaponMenuItems); i++)
			{
				// If value picked on the menu matches our string value, then set item attribute index to value matching at same index.
				if (StrEqual(info, unusualWeaponMenuItems[i]))
				{
					MenuCreate(client, slotSelectMenu, "Apply to slot: ");
					tWeaponEffect[client] = unusualWeaponSel[i];
					UpdateWearables(client, steamid);	 // Update the wearable attributes set by player by writing changes to database.
					break;
				}
			}
		}
	}

	return 0;	 // 0 means our menu returned without any issues.
}

// AttachParticle - Used to manually create and attach particles to player.
// Labelled as stock as we are not currently using this in the plugin, but have plans to in the future. (Prevents compiler warnings.)
stock void AttachParticle(int client, char[] particle)
{
	// Here we will implement Temporary Entity system for particles which either 1. Don't disappear when the parent entity is killed or 2. Don't follow player model body pattern like they should in official taunts.
	// REF: https://wiki.alliedmods.net/Temp_Entity_Lists_(Source)

	// Create info_particle_system entity
	// REF: https://developer.valvesoftware.com/wiki/Info_particle_system
	int	 particleSystem = CreateEntityByName("info_particle_system");

	char name[128];
	if (IsValidEntity(particleSystem))
	{
		float pos[3];	 // Create position vector (x, y, z)
		float ang[3];	 // Angle vector

		GetEntPropVector(client, Prop_Send, "m_vecOrigin", pos);	// Update position vector with default position values
		GetEntPropVector(client, Prop_Data, "m_angRotation", ang);

		TeleportEntity(particleSystem, pos, ang, NULL_VECTOR);	  // Teleport entity to new position vectors (All setup to be attached to player)

		// Format(name, sizeof(name), "target%i", client); // Set target to client which is creating the particle
		// DispatchKeyValue(client, "targetname", name); // Dispatch KeyValue "targetname" into client.
		SetVariantString("!activator");
		AcceptEntityInput(particleSystem, "SetParent", client);

		DispatchKeyValue(particleSystem, "targetname", "tf2particle");	  // Dispatch KeyValue "targetname" with value "tf2particle" into partice entity, this tells the game we are trying to create a default in-game particle effect.
		DispatchKeyValue(particleSystem, "parentname", name);			  // Set / dispatch parent of particle system to target client.
		DispatchKeyValue(particleSystem, "effect_name", particle);		  // Set particle name, this is where we change the particle we want to spawn.
		DispatchSpawn(particleSystem);									  // Remove it from it's 0,0 world center position.
		SetVariantString("0");											  // Ensure no more variant strings are being sent to cause issues
		AcceptEntityInput(particleSystem, "SetParentAttachment", particleSystem, particleSystem, 0);

		ActivateEntity(particleSystem);				   // Make the particle start doing it's thing!
		AcceptEntityInput(particleSystem, "start");	   // Same thing as above essentially, some particles don't listen to ActivateEntity

		particleEntity[client] = particleSystem;	// Set particle entity client picked with newly created particle.
	}
}

// DeleteParticle - Deletes particle entity when called
// Labelled as stock as we are not currently using this in the plugin, but have plans to in the future. (Prevents compiler warnings.)
stock void DeleteParticle(int particle)
{
	if (IsValidEntity(particle))
	{	 // If particle exists as an entity.
		char classname[64];
		GetEdictClassname(particle, classname, sizeof(classname));	  // Store classname of particle entity grabbed, (this case: info_particle_system)
		if (StrEqual(classname, "info_particle_system", false))
		{														  // Check if entity classname matches info_particle_system
			AcceptEntityInput(particle, "Stop");				  // We're trying our best to get rid of stubborn particles.
			AcceptEntityInput(particle, "DestroyImmediately");	  // Some particles don't disappear without this
			AcceptEntityInput(particle, "Kill");				  // Hotfix to destroy some particles from server on next game frame.
			RemoveEdict(particle);								  // Remove it from the server to reduce entity count.
		}
	}
}

// This creates a temporary entity as a TFParticleEffect which allows the unusual taunts to be wrapped around the client model / take the client model sizing correctly.
// The downside to this is in ThirdPerson mode, killstreak effects are also wiped as they are also temporary entities
// Temporary entities do not have an index or ID, meaning we must clear all at once.
// REF: https://developer.valvesoftware.com/wiki/Temporary_Entity
//
// 08/12/24 - I wonder if a particle system with SetTransmit is a better idea?
// Especially for lingering taunt particles and weapon unusual effects, they could also probably just break.
void CreateTempParticle(char[] particle, int entity = -1, float origin[3] = NULL_VECTOR, float angles[3] = { 0.0, 0.0, 0.0 }, bool resetparticles = false)
{
	int	 tblidx = FindStringTable("ParticleEffectNames");	 // Grab particle effect string table

	char tmp[256];
	int	 stridx = INVALID_STRING_INDEX;

	for (int i = 0; i < GetStringTableNumStrings(tblidx); i++)
	{													 // Loop through particle effect string table
		ReadStringTable(tblidx, i, tmp, sizeof(tmp));	 // Store particle at index into temporary value
		if (StrEqual(tmp, particle, false))
		{	 // If the value matches our particle we wish to create, assign string index.
			stridx = i;
			break;
		}
	}

	TE_Start("TFParticleEffect");				   // Start temporary entity as TFParticleEffect
	TE_WriteFloat("m_vecOrigin[0]", origin[0]);	   // Set origin vector for TFParticleEffect
	TE_WriteFloat("m_vecOrigin[1]", origin[1]);
	TE_WriteFloat("m_vecOrigin[2]", origin[2]);
	TE_WriteFloat("m_vecStart[0]", origin[0]);	  // Set start vector for TFParticleEffect
	TE_WriteFloat("m_vecStart[1]", origin[1]);
	TE_WriteFloat("m_vecStart[2]", origin[2]);
	TE_WriteVector("m_vecAngles", angles);				 // Set angle vector for TFParticleEffect
	TE_WriteNum("m_iParticleSystemIndex", stridx);		 // Set temporary entity particle index in TempEnt to match the particle from our string table.
	TE_WriteNum("entindex", entity);					 // Assign the temporary entity to the entity passed in parameter 2.
	TE_WriteNum("m_iAttachType", 0);					 // AttachType 1 sets origin of temporary entity to the map world origin point (0, 0), we don't want that.
	TE_WriteNum("m_bResetParticles", resetparticles);	 // This is called to reset all particles attached to that entity, unfortunately there's no other to clear temporary entities.
	TE_SendToAll();										 // Send temporary entity to all players.
}

// ClearTempParticles()
// Dummy function used to easier remove all temporary entities from target entity.
void ClearTempParticles(int client)
{
	float empty[3];
	CreateTempParticle("sandwich_fx", client, empty, empty, true);	  // Creates a empty sandwich_fx particle and passes true on m_bResetParticles, deleting all particles attached to entity.
}

// TF2Items_OnGiveNamedItem - from <tf2items>, called whenever a player gets a fresh set of items (when changing class, respawning(?), etc)
public Action TF2Items_OnGiveNamedItem(int client, char[] className, int itemIndex, Handle &hItem)
{
	hItem = TF2Items_CreateItem(OVERRIDE_ATTRIBUTES | PRESERVE_ATTRIBUTES);	   // Assign our item to be changing, we want to be keeping the old attributes of the players item but also overriding any we wish.

	if (StrEqual(className, "tf_wearable"))
		ProcessHats(client, itemIndex, hItem);

	return Plugin_Changed;
}

public Action ProcessHats(int client, int itemIndex, Handle &hItem)
{
	Player player = Player(client);	   // Initialize our player method map to save, store and update wearable effects.

	if (hatIDList.FindValue(itemIndex) == -1)
		return Plugin_Continue;

	TF2Items_SetNumAttributes(hItem, 5);	// Set number of attributes to change

	TF2Items_SetQuality(hItem, 5);													// Set to unusual quality.
	TF2Items_SetAttribute(hItem, 0, 134, float(player.GetUnusualHatEffectId()));	// Set "attach particle (134) attribute to players desired unusual effect.
	TF2Items_SetAttribute(hItem, 1, 520, 1.0);

	return Plugin_Changed;
}

public int ProcessLoadoutSlot(int slotIndex, int client)
{
	int ret = 0;
	ret		= TF2Util_GetPlayerLoadoutEntity(client, slotIndex);

	return ret;
}

// ReadItemSchema
// Function made to traverse the items_game schema and grab all "hat" item indexes so we can only give unusual effects to hats.
public void ReadItemSchema()
{
	KeyValues kv = new KeyValues("items_game");
	kv.ImportFromFile("scripts/items/items_game.txt");

	kv.JumpToKey("items");
	kv.GotoFirstSubKey();

	char itemID[64];
	char itemSlot[64];

	do
	{
		kv.GetSectionName(itemID, sizeof(itemID));
		kv.GetString("item_slot", itemSlot, sizeof(itemSlot));

		// If wearable is on head, add to wearable array list.
		if (strcmp(itemSlot, "head") == 0)
		{
			hatIDList.Push(StringToInt(itemID));
		}
		else {	  // If that fails, check any other cosmetic we might be able to apply an unusual effect too.
			kv.GetString("prefab", itemSlot, sizeof(itemSlot));

			if (strcmp(itemSlot, "hat") == 0 || strcmp(itemSlot, "base_hat") == 0 || strcmp(itemSlot, "no_craft hat marketable") == 0 || strcmp(itemSlot, "valve base_hat") == 0)
			{	 // Check if "prefab" key has value of hat, base_hat, no_craft hat marketable or valve base_hat
				hatIDList.Push(StringToInt(itemID));
			}
			else {	  // If not, let's triple check the equip_region
				kv.GetString("equip_region", itemSlot, sizeof(itemSlot));

				if (strcmp(itemSlot, "hat") == 0)	 // If equip_region key has value of hat, push to hatID arrayList
					hatIDList.Push(StringToInt(itemID));
			}
		}
	}
	while (kv.GotoNextKey());

	kv.Rewind();
	kv.JumpToKey("attribute_controlled_attached_particles");
	LogMessage("Jumped to key attribute_controlled_attached_particles");
	kv.GotoFirstSubKey();

	char reFireTime[64];
	char tauntEffect[256];
	char tauntEffectID[512];
	char hatEffectID[512];
	char sectionName[256];

	do
	{
		kv.GetSectionName(sectionName, sizeof(sectionName));
		LogMessage("%s is the current section", sectionName);

		if (strcmp(sectionName, "taunt_unusual_effects") == 0)
		{
			do
			{
				kv.GotoFirstSubKey();
				kv.GetSectionName(tauntEffectID, sizeof(tauntEffectID));
				kv.GetString("system", tauntEffect, sizeof(tauntEffect));

				if (kv.GetFloat("refire_time") >> 0.0)
				{
					kv.GetString("refire_time", reFireTime, sizeof(reFireTime));
					// TODO: Track which taunts have refire times and make sure to apply them properly in the plugin, also add a blacklist function for broken effects.

					tauntRefireTimerList.PushString(reFireTime);
					LogMessage("%s has refire time of %s seconds.", tauntEffect, reFireTime);
				}
				else {	  // Best way to match taunt effects with refire times, 0.0 for ones without and an actual value for ones with, definitely makes sorting easier
					tauntRefireTimerList.PushString("0.0");
					LogMessage("%s has no refire timer.", tauntEffect, reFireTime);
				}

				tauntEffectList.PushString(tauntEffect);
			}
			while (kv.GotoNextKey());

			kv.GoBack();
		}

		if (strcmp(sectionName, "other_particles") == 0)
		{
			do
			{
				kv.GotoFirstSubKey();
				kv.GetSectionName(hatEffectID, sizeof(hatEffectID));

				LogMessage("hatEffectID: %s", hatEffectID);

				unusualEffectIDList.PushString(hatEffectID);
			}
			while (kv.GotoNextKey());

			kv.GoBack();
		}

		if (strcmp(sectionName, "cosmetic_unusual_effects") == 0)
		{
			do
			{
				kv.GotoFirstSubKey();
				kv.GetSectionName(hatEffectID, sizeof(hatEffectID));

				LogMessage("hatEffectID: %s", hatEffectID);

				unusualEffectIDList.PushString(hatEffectID);
			}
			while (kv.GotoNextKey());

			kv.GoBack();
		}
	}
	while (kv.GotoNextKey());

	delete kv;
}

// 09 J-Factor CreateParticle function
// Test SetTransmit on Taunt Effects and Weapon effects (maybe?)
stock int CreateParticle(int iClient, char[] strParticle, bool bAttach = false, char[] strAttachmentPoint = "", float fOffset[3] = { 0.0, 0.0, 0.0 })
{
	int iParticle = CreateEntityByName("info_particle_system");
	if (IsValidEdict(iParticle))
	{
		float fPosition[3];
		float fAngles[3];
		float fForward[3];
		float fRight[3];
		float fUp[3];

		// Retrieve entity's position and angles
		GetClientAbsOrigin(iClient, fPosition);
		GetClientAbsAngles(iClient, fAngles);

		// Determine vectors and apply offset
		GetAngleVectors(fAngles, fForward, fRight, fUp);
		fPosition[0] += fRight[0] * fOffset[0] + fForward[0] * fOffset[1] + fUp[0] * fOffset[2];
		fPosition[1] += fRight[1] * fOffset[0] + fForward[1] * fOffset[1] + fUp[1] * fOffset[2];
		fPosition[2] += fRight[2] * fOffset[0] + fForward[2] * fOffset[1] + fUp[2] * fOffset[2];

		// Teleport and attach to client
		TeleportEntity(iParticle, fPosition, fAngles, NULL_VECTOR);
		DispatchKeyValue(iParticle, "effect_name", strParticle);

		if (bAttach == true)
		{
			SetVariantString("!activator");
			AcceptEntityInput(iParticle, "SetParent", iClient, iParticle, 0);

			if (StrEqual(strAttachmentPoint, "") == false)
			{
				SetVariantString(strAttachmentPoint);
				AcceptEntityInput(iParticle, "SetParentAttachmentMaintainOffset", iParticle, iParticle, 0);
			}
		}

		// Spawn and start
		DispatchSpawn(iParticle);
		ActivateEntity(iParticle);
		AcceptEntityInput(iParticle, "Start");
	}

	return iParticle;
}
