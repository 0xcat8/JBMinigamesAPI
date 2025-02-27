#include < amxmodx >
#include < minigames >
#include < amxmisc >

enum _:eTasks ( += 258 )
{
	TASK_STARTCOUNT = 258,
	TASK_GUESSCOUNT
}

#define PLUGIN_NAME "Guess The Number"
#define PLUGIN_VERSION "1.0"

#define MIN_GUESS 1
#define MAX_GUESS 100
#define ADMIN_GUESS ADMIN_CVAR

new g_iMaxPlayers;

new g_iGuessTheNumber, iMustGuess, iPlayerGuess[ 33 ], iGuessTimer;

public plugin_init() 
{
	register_plugin( PLUGIN_NAME, PLUGIN_VERSION, PLUGIN_AUTHOR );
	
	g_iGuessTheNumber = register_votect_game( PLUGIN_NAME );
	
	g_iMaxPlayers = get_maxplayers();
}

public client_command( client )
{
	new szCmd[ 8 ];
	
	read_argv( 0, szCmd, charsmax( szCmd ) );
	
	if( !strcmp( szCmd, "say" ) || !strcmp( szCmd, "say_team" ) )
	{
		new szCommand[ 16 ];
		
		read_argv( 1, szCommand, charsmax( szCommand ) );
		
		if( szCommand[ 0 ] == '/' || szCommand[ 0 ] == '!' )
		{
			if( equal( szCommand[ 1 ], "nc", 2 ) )
			{
				if( !access( client, ADMIN_GUESS ) )
					return 0;
				
				if( iGuessTimer > 0 )
				{
					client_print_color( client, "^x04 Guess the number^x01 minigame is already running!" );
					
					return 1;
				}
				
				startMinigame();
				
				return 1;
			}
			
			if( equal( szCommand[ 1 ], "guess", 1 ) )
			{
				if( !task_exists( TASK_GUESSCOUNT ) ) 
					return 1;
					
				if( fm_get_user_team( client ) != FM_TEAM_T )
				{
					client_print_color( client, "^x01 Only^x03 terrorists^x01 can^x04 participate" );
					
					return 1;
				}
				
				if( iPlayerGuess[ client ] != INVALID_HANDLE )
				{
					client_print_color( client, "^x01 You can only guess once, your guess was^x03 %d", iPlayerGuess[ client ] );
					
					return 1;
				}
				
				parse( szCommand, szCommand, charsmax( szCommand ), szCommand, charsmax( szCommand ) );
				
				if( !is_str_num( szCommand ) ) return 1;
				
				static iGuess;
				
				iGuess = str_to_num( szCommand );
				
				if( !(MIN_GUESS <= iGuess <= MAX_GUESS) )
				{
					client_print_color( client, "^x01 Please specify only numbers between^x03 %d^x01 and^x03 %d^x01", MIN_GUESS, MAX_GUESS );
					
					return 1;
				}
				
				if( is_number_taken( iGuess ) )
				{
					client_print_color( client, "^x01 The guess^x03 %d^x01 is already taken", iGuess );
					
					return 1;
				}
				
				iPlayerGuess[ client ] = iGuess;
				
				client_print_color( client, "^x01 Your guess is^x03 %d", iPlayerGuess[ client ] );
				
				return 1;
			}
			
			return 0;
		}
	}
	
	return 0;
}

public votect_game_activated( GameID )
{
	if( GameID == g_iGuessTheNumber )
	{
		startMinigame();
	}
}

public votect_game_deactivated( GameID )
{
	if( GameID == g_iGuessTheNumber )
	{
		remove_task( TASK_STARTCOUNT );
		remove_task( TASK_GUESSCOUNT );
		
		resetMinigame();
	}
}

public startCountdown( taskid )
{
	if( iGuessTimer <= 0 )
	{
		iGuessTimer = 30;

		set_task( 1.0, "guessCountdown", TASK_GUESSCOUNT, _, _, "a", ( iGuessTimer + 1 ) );
		
		client_print_color( 0, "^x01 You have^x03 %d seconds^x01 to guess a number between^x03 %d^x01 and^x03 %d^x01", iGuessTimer, MIN_GUESS, MAX_GUESS );
		client_print_color( 0, "^x01 To guess a number type^x04 /guess^x01 ^x03<num>^x01" );
	}
	
	else
	{
		secondsToVoice( iGuessTimer );
		
		set_hudmessage( 34,255,34, -1.0, 0.53, 0, 0.0, 1.0, 0.0, 0.0, -1 );
		
		show_hudmessage( 0, "[%s Minigame]^nThe game will start within %d seconds", PLUGIN_NAME, iGuessTimer-- );
	}
}

public guessCountdown( taskid )
{
	if( iGuessTimer <= 0 )
	{
		getMinigameWinner();
	}
	
	else
	{
		if( iGuessTimer == 5 ) client_print_color( 0, "^x01 Only^x03 5 seconds^x01 remaining to guess the number!^x04 HURRY UP!!^x01" );
		
		//secondsToVoice( iGuessTimer );
		
		set_hudmessage( 34,255,34, -1.0, 0.53, 0, 0.0, 1.0, 0.0, 0.0, -1 );
		
		show_hudmessage( 0, "Random number between %d and %d has set!^nYou have %d seconds to guess that number", MIN_GUESS, MAX_GUESS, iGuessTimer--  );
	}
}

public getMinigameWinner()
{
	new iGuess, iClosest = iMustGuess, iPlayer = 0;
	
	for( new i = 1; i <= g_iMaxPlayers; i++ )
	{
		if( !( 1 <= iPlayerGuess[ i ] <= 100 ) )
			continue;
		
		iGuess = abs( iMustGuess - iPlayerGuess[ i ] );
		
		if( iGuess < iClosest )
		{
			iPlayer = i;
			
			iClosest = iGuess;
		}
	}
	
	set_hudmessage( 34,255,34, -1.0, 0.53, 0, 0.0, 5.0, 0.1, 0.1, -1 );

	if( !iPlayer )
	{
		show_hudmessage( 0, "[%s Minigame]^nTime is Over!^nNo one was able to guess the correct number", PLUGIN_NAME );
	}
	
	else
	{
		new szName[ 32 ];
		
		get_user_name( iPlayer, szName, charsmax( szName ) );
		
		if( iClosest == 0 )
		{
			show_hudmessage( 0, "[%s Minigame]^nCongrats! %s was able to guess the currect number", PLUGIN_NAME, szName );
		}
		
		else
		{
			show_hudmessage( 0, "[%s Minigame]^n%s is the player with the closest guess, his guess was %d", PLUGIN_NAME, szName, iPlayerGuess[ iPlayer ] );
		}
		
		client_print_color( 0, "^x01 The^x04 correct^x01 guess was:^x04 %d", iMustGuess );
		
		setGuard( iPlayer );
	}
	
	deactivate_votect_game( 1 );
}

startMinigame( )
{
	resetMinigame();
	
	iMustGuess = random_num( MIN_GUESS, MAX_GUESS );
	
	for( new i = 1; i <= g_iMaxPlayers; i++ )
	{
		if( !access( i, ADMIN_GUESS ) ) 
			continue;
		
		client_print_color( i, "^x01 The number^x03 %d^x01 has set as the^x04 correct^x01 guess", iMustGuess );
	}
	
	iGuessTimer = 3;
	
	set_task( 1.0, "startCountdown", TASK_STARTCOUNT, _, _, "a", ( iGuessTimer + 1 ) );
}

bool:is_number_taken( num )
{
	for( new i = 1; i <= g_iMaxPlayers; i++ )
	{
		if( !( MIN_GUESS <= iPlayerGuess[ i ] <= MAX_GUESS ) )
			continue;
		
		if( iPlayerGuess[ i ] == num )
			return true;
	}
	
	return false;
}

resetMinigame()
{
	iMustGuess = INVALID_HANDLE;
	iGuessTimer = INVALID_HANDLE;
	
	arrayset( iPlayerGuess, INVALID_HANDLE, charsmax( iPlayerGuess ) );
}
