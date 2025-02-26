#define PLUGIN_PREFIX "FxP-CS"

#define MINIGAME_INVALID_HANDLE INVALID_HANDLE
#define MINIGAME_MAX_LENGTH 32
#define MINIGAME_MAX_GAMES 10
#define MINIGAME_MAX_ITEMS 4

enum ( += 1 ) 
{
	FM_TEAM_UNASSIGNED = 0,
	FM_TEAM_T = 1,
	FM_TEAM_CT = 2,
	FM_TEAM_SPECTATOR = 3
};

enum ( += 349 ) 
{
	TASK_COUNT_MINIGAMES = 349,
	TASK_DISPLAY_MENU
};

enum _:MINIGAME_FORWARDS ( += 1 ) 
{
	FORWARD_GAME_ACTIVATED,
	FORWARD_GAME_DEACTIVATED
};

enum GetProp ( += 1 ) 
{
	GetProp_Id,
	GetProp_Name
};
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ fbidis\\ ansi\\ ansicpg1252\\ deff0{\\ fonttbl{\\ f0\\ fnil\\ fcharset0 Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ ltrpar\\ lang1037\\ f0\\ fs16 \n\\ par }
*/
