#include < amxmodx >
#include < minigames >

#define PLUGIN_NAME "Random Player"
#define PLUGIN_VERSION "1.0"

#define TASK_COUNT_RANDOM 179

new g_iRandomPlayer, g_iRandomCount;

public plugin_init() 
{
	register_plugin( PLUGIN_NAME, PLUGIN_VERSION, PLUGIN_AUTHOR );
	
	g_iRandomPlayer = register_votect_game( PLUGIN_NAME );
}

public votect_game_activated( GameID )
{
	if( GameID == g_iRandomPlayer )
	{
		g_iRandomCount = 3;
		
		set_task( 1.0, "startCount", TASK_COUNT_RANDOM, _, _, "a", (g_iRandomCount + 1) );
	}
}

public startCount( TaskID )
{
	if( g_iRandomCount <= 0 )
	{
		randomPlayer();
		
		deactivate_votect_game();
	}
	
	else
	{
		secondsToVoice( g_iRandomCount );
		
		set_hudmessage( 238, 64, 0, -1.0, 0.53, 0, 0.0, 1.0, 0.0, 0.0, -1 );
		
		show_hudmessage( 0, "[%s Minigame]^nThe game will start within %d seconds", PLUGIN_NAME, g_iRandomCount-- );
	}
}

randomPlayer( )
{
	static iPlayers[ 32 ], iCount;
	
	get_players( iPlayers, iCount, "ech", "TERRORIST" );

	set_hudmessage( 238, 64, 0, -1.0, 0.53, 0, 0.0, 5.0, 0.0, 0.0, -1 );
	
	if( iCount <= 1 )
	{
		show_hudmessage( 0, "[%s Minigame]^nNo enough players! game is deactivated", PLUGIN_NAME );
		
		return;
	}
	
	static iRandomPlayer;
	
	while( !is_user_connected( (iRandomPlayer = iPlayers[ random( iCount ) ]) ) ) { }
	
	static szName[ 32 ];
	
	get_user_name( iRandomPlayer, szName, charsmax( szName ) );
	
	show_hudmessage( 0, "[%s Minigame]^nPlayer %s is randomly chosen to be a guard", PLUGIN_NAME, szName );
	
	setGuard( iRandomPlayer );
}
