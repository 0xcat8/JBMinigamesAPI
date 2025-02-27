#include < amxmodx >
#include < minigames >

#pragma semicolon 1

new const PLUGIN_NAME[] = "Jailbreak MinigamesAPI";

#define PLUGIN_VERSION "1.0"

new Array:g_aGames, g_iGamesCount, g_iCurrentGame;

new g_iThinkEntity, g_iMaxPlayers, g_iForward[ MINIGAME_FORWARDS ], g_iForwardReturn;

new g_iMenuGames[ MINIGAME_MAX_ITEMS ], g_iVotes[ MINIGAME_MAX_ITEMS ], g_iMenuCount, g_iVoted[ 33 ];

public plugin_natives( ) 
{ 
	register_library( PLUGIN_NAME[ 10 ] );
	
	g_iCurrentGame = MINIGAME_INVALID_HANDLE;
	g_aGames = ArrayCreate( MINIGAME_MAX_LENGTH );
	
	arrayset( g_iMenuGames, MINIGAME_INVALID_HANDLE, sizeof( g_iMenuGames ) );
	
	register_native( "register_votect_game", "_native_RegisterVoteCTGame" );
	register_native( "get_votect_game", "_native_GetVoteCTGame" );
	register_native( "is_votect_running", "_native_VoteCTRunning" );
	register_native( "deactivate_votect_game", "_native_DeactivateVoteCTGame" );
}

public _native_RegisterVoteCTGame( plugin, params )
{
	if( !(1 <= params <= 1) )
	{
		log_native_error( "ERROR: Invalid number of parameters, must be 1" );
		
		return MINIGAME_INVALID_HANDLE;
	}
	
	static szMinigame[ MINIGAME_MAX_LENGTH ]; 
	
	get_string( 1, szMinigame, charsmax( szMinigame ) );
	
	if( strlen( szMinigame ) < 1 )
	{
		log_native_error( "ERROR: You can't register a minigame with an empty name" );
		
		return MINIGAME_INVALID_HANDLE;
	}
	
	if( g_iGamesCount )
	{
		static szName[ MINIGAME_MAX_LENGTH ], item;
		
		for( item = 0; item < g_iGamesCount; item++ )
		{
			ArrayGetString( g_aGames, item, szName, charsmax( szName ) );
			
			if( !strcmp( szMinigame, szName, 1 ) )
			{
				log_native_error( "ERROR: a minigame with the name ^"%s^" is already registred", szMinigame );
				
				return MINIGAME_INVALID_HANDLE;
			}
		}
		
		if( g_iGamesCount >= MINIGAME_MAX_GAMES )
		{
			log_native_error( "ERROR: Plugin reached to the maximum amount of registrations" );
			
			return MINIGAME_INVALID_HANDLE;
		}
	}
	
	ArrayPushString( g_aGames, szMinigame );
	
	server_print( "[%s] VoteCT Game Registered - <ID:%d> <Name:%s>", PLUGIN_NAME[ 10 ], ++g_iGamesCount, szMinigame );
	
	return g_iGamesCount;
}

public _native_GetVoteCTGame( plugin, params )
{
	if( !(2 <= params <= 2) )
	{
		log_native_error( "ERROR: Invalid number of parameters, must be 2" );
		
		return MINIGAME_INVALID_HANDLE;
	}
	
	if( GetProp:get_param( 2 ) == GetProp_Name )
	{
		static szGame[ MINIGAME_MAX_LENGTH ];
		
		ArrayGetString( g_aGames, (g_iCurrentGame - 1), szGame, charsmax( szGame ) );
		
		set_string( 1, szGame, (MINIGAME_MAX_LENGTH - 1) );
	}
	
	return g_iCurrentGame;
}

public _native_VoteCTRunning( plugin, params )
{
	if( params )
	{
		log_native_error( "ERROR: Invalid number of parameters, must be 0" );
		
		return MINIGAME_INVALID_HANDLE;
	}
	
	return bool:( task_exists(TASK_DISPLAY_MENU) );
}

public _native_DeactivateVoteCTGame( plugin, params )
{
	if( !(1 <= params <= 1) )
	{
		log_native_error( "ERROR: Invalid number of parameters, must be 1" );
		
		return MINIGAME_INVALID_HANDLE;
	}
	
	/*
	if( g_iCurrentGame == MINIGAME_INVALID_HANDLE )
	{
		log_native_error( "ERROR: No running minigames detected, can't deactivate" );
		
		return MINIGAME_INVALID_HANDLE;
	}
	*/
	
	if( get_param( 1 ) )
		ExecuteForward( g_iForward[ FORWARD_GAME_DEACTIVATED ], g_iForwardReturn, g_iCurrentGame );
	
	g_iCurrentGame = MINIGAME_INVALID_HANDLE;
	
	return 1;
}

public plugin_init() 
{
	register_plugin( PLUGIN_NAME, PLUGIN_VERSION, PLUGIN_AUTHOR );
	
	set_task( 5.0, "countGames", TASK_COUNT_MINIGAMES );
	
	g_iMaxPlayers = get_maxplayers();
	
	g_iForward[ FORWARD_GAME_ACTIVATED ] = CreateMultiForward( "votect_game_activated", ET_IGNORE, FP_CELL );
	g_iForward[ FORWARD_GAME_DEACTIVATED ] = CreateMultiForward( "votect_game_deactivated", ET_IGNORE, FP_CELL );
	
	register_menucmd( register_menuid( PLUGIN_NAME ), 1023, "menuKeys" );
	
	g_iThinkEntity = engfunc( EngFunc_CreateNamedEntity, engfunc( EngFunc_AllocString, "info_target" ) );
	set_pev( g_iThinkEntity, pev_classname, "MinigamesAPI_Think" );
	set_pev( g_iThinkEntity, pev_nextthink, get_gametime() + 5.0 );
	
	register_forward( FM_Think, "Forward_API_Think" );
}

public plugin_end( ) 
{ 
	ArrayDestroy( g_aGames ); 
}

public countGames( TaskID )
{
	if( !g_iGamesCount )
	{
		fail_state( "No registered votect games found" );
	}
	
	if( g_iGamesCount < MINIGAME_MAX_ITEMS )
	{
		fail_state( "No enough registered votect games found (%d/%d)", g_iGamesCount, MINIGAME_MAX_ITEMS );
	}
	
	server_print( "[%s] Found %d Registered VoteCT Games", PLUGIN_NAME[ 10 ], g_iGamesCount );
}

public client_disconnect( client )
{
	g_iVoted[ client ] = 0;
	
	if( is_votect_running() )
	{
		static iPlayers[ 32 ], iCount;
		
		get_players( iPlayers, iCount, "ch" );
		
		if( iCount <= 1 ) 
		{
			turnOffVote();
			
			if( is_player_index( iPlayers[ 0 ] ) )
				closeMenu( iPlayers[ 0 ] );
		}
	}
}

public Forward_API_Think( iEntity )
{
	static Float:fGametime;
	
	fGametime = get_gametime();
	
	if( iEntity == g_iThinkEntity )
	{
		enum _:ePlayersCount ( += 1 ) { eTotalPlayers, eTerrorists, eGuards };
		
		static iPlayers[ ePlayersCount ], i;
		
		arrayset( iPlayers, 0, sizeof( iPlayers ) );
		
		for( i = 1; i <= g_iMaxPlayers; i++ )
		{
			if( !is_player_index( i ) )
				continue;
			
			switch( fm_get_user_team( i ) )
			{
				case FM_TEAM_T: 
					iPlayers[ eTerrorists ]++;
				
				case FM_TEAM_CT: 
					iPlayers[ eGuards ]++;
			}
			
			iPlayers[ eTotalPlayers ]++;
		}
		
		if( iPlayers[ eTotalPlayers ] <= 1 )
		{
			set_pev( iEntity, pev_nextthink, (fGametime + 5.0) );
			
			if( is_votect_running() )
				turnOffVote( );
			
			return 1;
		}
		
		else
		{
			if( iPlayers[ eTerrorists ] >= 2 )
			{
				if( g_iCurrentGame != MINIGAME_INVALID_HANDLE )
				{
					set_pev( iEntity, pev_nextthink, (fGametime + 5.0) );
					
					return 1;
				}
				
				if( is_votect_running() )
				{
					set_pev( iEntity, pev_nextthink, (fGametime + 5.0) );
					
					return 1;
				}
				
				if( teamRatio( iPlayers[ eTerrorists ], iPlayers[ eGuards ] ) )
				{
					set_pev( iEntity, pev_nextthink, (fGametime + 5.0) );
					
					return 1;
				}
				
				sortMinigames( g_iMenuGames, sizeof( g_iMenuGames ) );
				
				arrayset( g_iVotes, 0, sizeof( g_iMenuGames ) );
				
				g_iMenuCount = 15;
				
				for( i = 1; i <= g_iMaxPlayers; i++ )
				{
					if( !is_player_index( i ) )
						continue;
					
					g_iVoted[ i ] = 0;
				}
				
				set_task( 1.0, "Task_DisplayMenu", TASK_DISPLAY_MENU, _, _, "a", (g_iMenuCount + 1) );
			}
		}
		
		set_pev( iEntity, pev_nextthink, (fGametime + 5.0) );
	}
	
	return 1;
}

public Task_DisplayMenu( const TaskID )
{
	static i;
	
	if( g_iMenuCount > 0 )
	{
		for( i = 1; i <= g_iMaxPlayers; i++ )
		{
			if( !is_player_index( i ) )
				continue;
			
			if( !(FM_TEAM_T <= fm_get_user_team( i ) <= FM_TEAM_CT) )
				continue;
			
			displayMenu( i );
		}
		
		g_iMenuCount--;
	}
	
	else
	{
		static iReturn[ 2 ];
		
		iReturn = sortVotes( g_iVotes, MINIGAME_MAX_ITEMS );
		
		g_iCurrentGame = ( g_iMenuGames[ iReturn[ 1 ] ] + 1 );
		
		static szMinigame[ MINIGAME_MAX_LENGTH ];
		
		ArrayGetString( g_aGames, ( g_iCurrentGame - 1 ), szMinigame, charsmax( szMinigame ) );
		
		for( i = 1; i <= g_iMaxPlayers; i++ )
		{
			if( !is_player_index( i ) )
				continue;
			
			show_menu( i, 0, "^n", 1, PLUGIN_NAME );
			
			if( iReturn[ 0 ] )
				client_print_color( i, "^x01 Game^x03 %s^x01 is^x04 randomly^x01 chosen^x03 (VOTE TIED)", szMinigame );
			else
				client_print_color( i, "^x01 Game^x03 %s^x04 won^x01 with^x03 %d^x01 votes", szMinigame, g_iVotes[ iReturn[ 1 ] ] );
		}
		
		ExecuteForward( g_iForward[ FORWARD_GAME_ACTIVATED ], g_iForwardReturn, g_iCurrentGame );
	}
}

displayMenu( const index ) 
{
	static szMenu[ 320 ], iLength;
	
	iLength = formatex( szMenu, charsmax( szMenu ), "\r[ \y%s \r] \wJailbreak Vote^nWhat \rVOTE CT \wgame would you like to play?^n^n", PLUGIN_PREFIX );
	
	iLength += formatex( szMenu[ iLength ], charsmax( szMenu ) - iLength, "\wVote ends within \y%d \wseconds^n\wYou have \r%s^n^n", g_iMenuCount, g_iVoted[ index ] ? "already voted" : "not yet voted" );
	
	static szMinigame[ MINIGAME_MAX_LENGTH ], bitKeys, item;
	
	for( item = 0; item < MINIGAME_MAX_ITEMS; item++ )
	{
		bitKeys |= (1<<item);
		
		ArrayGetString( g_aGames, g_iMenuGames[ item ], szMinigame, charsmax( szMinigame ) );
		
		iLength += formatex( szMenu[ iLength ], charsmax( szMenu ) - iLength, "\r%d. \w%s \y(%d Votes)%s", (item + 1), szMinigame, g_iVotes[ item ], ( item == (MINIGAME_MAX_ITEMS - 1) ) ? "^n^n" : "^n" );
	}
	
	menu_cancel( index );
	set_pdata_int( index, 205, 0 ); 
	
	show_menu( index, bitKeys, szMenu, _, PLUGIN_NAME );
}

public menuKeys( client, key )
{
	if( !g_iVoted[ client ] )
	{
		g_iVotes[ key ]++;
		
		g_iVoted[ client ] = 1;
	}
	
	displayMenu( client );
}

log_native_error( const error[], any:... ) 
{
	static szError[ 128 ], iLength;
	
	iLength = formatex( szError, charsmax( szError ), "[%s] ", PLUGIN_NAME );
	
	vformat( szError[ iLength ], charsmax( szError ) - iLength, error, 2 );
	
	log_error( AMX_ERR_NATIVE, szError );
}

sortMinigames( param[], len ) 
{
	static bool:bAdded[ MINIGAME_MAX_GAMES ], item;
	
	arrayset( bAdded, false, sizeof( bAdded ) );
	
	for( item = 0; item < len; item++ )
	{
		while( ( bAdded[ param[ item ] = random( g_iGamesCount ) ] ) ) { }
		
		bAdded[ param[ item ] ] = true;
	}
}

sortVotes( const param[], const len ) 
{
	static iVotes[ MINIGAME_MAX_ITEMS ], iParam[ 2 ], item;
	
	for( item = 0; item < len; item++ )
		iVotes[ item ] = param[ item ];
	
	iParam[ 0 ] = 0;
	
	SortCustom1D( iVotes, len, "cmpVotes", iParam, charsmax( iParam ) );
	
	if( iVotes[ 0 ] > iVotes[ 1 ] )
	{
		for( item = 0; item < len; item++ )
		{
			if( g_iVotes[ item ] == iVotes[ 0 ] )
			{
				iParam[ 1 ] = item;
				
				break;
			}	
		}
	}
	
	else
	{
		static g_iGameIndex[ MINIGAME_MAX_ITEMS ], iCount; iCount = 0;
		
		iParam[ 0 ] = 1;
		
		for( item = 0; item < len; item++ )
		{
			g_iGameIndex[ item ] = item;
			
			if( iVotes[ item ] == iVotes[ 0 ] )
				iCount++;	
		}
		
		SortCustom1D( g_iGameIndex, len, "cmpVotes", iParam, charsmax( iParam ) );
		
		iParam[ 1 ] = g_iGameIndex[ random( iCount ) ];
	}
	
	return iParam;
}

public cmpVotes( elem1, elem2, const array[], const data[], len )
{
	if( !data[ 0 ] )
	{
		if( elem1 > elem2 )
			return -1;
		
		else if( elem1 < elem2 )
			return 1;
	}
	
	else
	{
		if( g_iVotes[ elem1 ] > g_iVotes[ elem2 ] )
			return -1;
		
		else if( g_iVotes[ elem1 ] < g_iVotes[ elem2 ] )
			return 1;
	}
	
	return 0;
}

turnOffVote( ) 
{
	if( task_exists( TASK_DISPLAY_MENU ) ) 
		remove_task( TASK_DISPLAY_MENU );
	
	arrayset( g_iMenuGames, MINIGAME_INVALID_HANDLE, sizeof( g_iMenuGames ) );
	
	g_iMenuCount = 0;
}

closeMenu( const index ) 
{
	menu_cancel( index );
	
	set_pdata_int( index, 205, 0 ); 
	
	show_menu( index, 0, "^n", 1, PLUGIN_NAME );
}

fail_state( const message[], any:... ) 
{
	static szError[ 128 ], iLength;
	
	iLength = formatex( szError, charsmax( szError ), "[%s] ", PLUGIN_NAME );
	
	vformat( szError[ iLength ], charsmax( szError ) - iLength, message, 2 );
	
	set_fail_state( szError );
}

bool:teamRatio( const terrorists, const guards ) 
{
	
	static const g_iRequiredPlayers[ ] = { 2, 7, 14, 21, 25 }; 
	
	static i; 
	
	for( i = 0; i < sizeof( g_iRequiredPlayers ); i++ )
	{
		if( terrorists >= g_iRequiredPlayers[ i ] && guards < (i + 1) )
			return false;
	}
	
	return true;
}

is_player_index( const index ) { return ( is_user_connected( index ) && !is_user_bot( index ) && !is_user_hltv( index ) && (1 <= index <= g_iMaxPlayers) ); }
