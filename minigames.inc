#if defined _minigame_api_included
	#endinput
#endif

#define _minigame_api_included

#if AMXX_VERSION_NUM >= 175
	#pragma reqlib MinigamesAPI

	#if !defined AMXMODX_NOAUTOLOAD
		#pragma loadlib MinigamesAPI
	#endif
#else
	#pragma library MinigamesAPI
#endif

#include < amxmodx >
#include < fakemeta >

#include < minigames_const >

#pragma semicolon 1

#define PLUGIN_AUTHOR "0xcat8"

/**
* Registers new votect game
*
* @param name     Votect game name
*
* @return       Returns current votect games count.
* @error        Name is already registered, Name is empty, or Invalid number of parameters.
*/

native register_votect_game( const name[] );

/**
* Gets current votect game and index
*
* @param name	output for the game name
* @param len	output length size
*
* @return       Returns current game index if set, -1 if not.
* @error        Invalid number of parameters.
*/

native get_votect_game( output[] = 0, GetProp:type );

/**
* Checks if vote ct is running
*
* @return       Returns true if running, false if not.
* @error        Invalid number of parameters.
*/

native is_votect_running();

/**
* Deactivates current minigame
*
* @param enable_forward	if set it will also execute forward
*
* @return       Returns 1 on success, -1 on failure.
* @error        Invalid number of parameters.
*/

native deactivate_votect_game( enable_forward = 0 );

/**
* Called after game voting is over, activating the most voted game
*/
forward votect_game_activated( GameID );

/**
* Called before deactivating current game
*/
forward votect_game_deactivated( GameID );


/**
* Useful Functions
*/
/*

stock client_print_color( const index, const message[], any:... ) 
{
	new szMessage[ 192 ], iLength;
	
	iLength = formatex( szMessage, charsmax( szMessage ), "^x04[ %s ]^x01 ", PLUGIN_PREFIX );
	
	vformat( szMessage[ iLength ], charsmax( szMessage ) - iLength, message, 3 );
	
	szMessage[ 191 ] = '^0';
	
	new iMsgType, iPlayer;
	
	if( index )
	{
		iMsgType = MSG_ONE_UNRELIABLE;
		iPlayer = index;
	}
	
	else
	{
		static iMaxPlayers;
		iMaxPlayers = get_maxplayers();
		
		iMsgType = MSG_BROADCAST;
		
		for( new i = 1; i <= iMaxPlayers; i++ )
		{
			if( is_user_connected( i ) )
			{
				iPlayer = i;
				
				break;
			}
		}
	}
	
	message_begin( iMsgType, get_user_msgid( "SayText" ), _, iPlayer );
	write_byte( iPlayer );
	write_string( szMessage );
	message_end();
}
*/

stock printColor( index, sender, const message[], any:... ) 
{
	new szMessage[ 192 ], iLength;
	
	iLength = formatex( szMessage, charsmax( szMessage ), "^x04[ %s ]^x01 ", PLUGIN_PREFIX );
	
	vformat( szMessage[ iLength ], charsmax( szMessage ) - iLength, message, 4 );
	
	szMessage[ 191 ] = '^0';
	
	client_print_color( index, sender, message );
}

stock fm_get_user_team( const index ) 
{ 
	return get_pdata_int( index, 114 ); 
}

stock fm_set_user_team( const index, team ) 
{
	set_pdata_int( index, 114, team );
	
	static const szTeamInfo[ ][ ] = { "UNASSIGNED", "TERRORIST", "CT", "SPECTATOR" };
	
	message_begin( MSG_ONE_UNRELIABLE, get_user_msgid("TeamInfo"), _, index );
	write_byte( index );
	write_string( szTeamInfo[ team ] );
	message_end( );
}

stock setGuard( const index )
{
	if( is_user_alive( index ) )
	{
		engfunc( EngFunc_SetOrigin, index ,Float:{ -4800.0, -4800.0, -4800.0 } );
		
		user_kill( index, 1 );
		
		set_pdata_int( index, 444, 0 );
	}
	
	fm_set_user_team( index, FM_TEAM_CT );
	
	set_pev( index, pev_deadflag, DEAD_RESPAWNABLE );
	//set_pev( index, pev_iuser1, 0 );
	//dllfunc( DLLFunc_Think, index );
	
	set_task( 0.25, "spawnPlayer", index );
}

public spawnPlayer( index )
{
	if( !is_user_connected( index ) )
		return;
	
	dllfunc( DLLFunc_Spawn, index );
}

stock secondsToVoice( seconds ) 
{
	static szVoice[ 128 ];
	
	num_to_word( seconds, szVoice, charsmax( szVoice  ) );
	
	client_cmd( 0, "spk ^"vox/%s^"", szVoice );
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ fbidis\\ ansi\\ ansicpg1252\\ deff0{\\ fonttbl{\\ f0\\ fnil\\ fcharset0 Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ ltrpar\\ lang1037\\ f0\\ fs16 \n\\ par }
*/
