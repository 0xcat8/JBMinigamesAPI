#include < amxmodx >
#include < minigames >

#define PLUGIN_NAME "Minigame: Test"
#define PLUGIN_VERSION "1.0"

enum _:eVoteCTGames ( += 1 )
{
	GAME_TEST_ONE = 0,
	GAME_TEST_TWO,
	GAME_TEST_THREE,
	GAME_TEST_FOUR,
};

new const g_szVoteCTGames[ eVoteCTGames ][ ] =
{
	"Test 1",
	"Test 2",
	"Test 3",
	"Test 4"
};

new g_iGameHandler[ eVoteCTGames ];

public plugin_init() 
{
	register_plugin( PLUGIN_NAME, PLUGIN_VERSION, PLUGIN_AUTHOR );
	
	for( new i = GAME_TEST_ONE; i < eVoteCTGames; i++ )
		g_iGameHandler[ i ] = register_votect_game( g_szVoteCTGames[ i ] );
}

public votect_game_activated( iGame )
{
	for( new i = GAME_TEST_ONE; i < eVoteCTGames; i++ )
	{
		if( iGame == g_iGameHandler[ i ] )
		{
			new szGame[ 21 ];

			get_votect_game( szGame, GetProp_Name );
			
			client_print( 0, print_chat, "Game %s should run now", szGame );
			
			deactivate_votect_game( .enable_forward = 0 );
		}
	}
}
