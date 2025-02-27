#include < amxmodx >
#include < minigames >
#include < amxmisc >

enum _:eTasks ( += 358 )
{
	TASK_STARTCOUNT = 358,
	TASK_ENDCOUNT
}

#define PLUGIN_NAME "First Writes"
#define PLUGIN_VERSION "1.0"

new g_iFirstWrites, iGameTimer, szPhrase[ 7 ];

public plugin_init() 
{
	register_plugin( PLUGIN_NAME, PLUGIN_VERSION, PLUGIN_AUTHOR );
	
	g_iFirstWrites = register_votect_game( PLUGIN_NAME );
}

public client_command( client )
{
	if( get_votect_game( _, GetProp_Id ) != g_iFirstWrites )
		return 0;
	
	new szCmd[ 9 ];
	
	read_argv( 0, szCmd, charsmax( szCmd ) );
	
	if( !strcmp( szCmd, "say" ) || !strcmp( szCmd, "say_team" ) )
	{
		new szCommand[ 16 ];
		
		read_argv( 1, szCommand, charsmax( szCommand ) );
		
		if( szCommand[ 0 ] == '/' || szCommand[ 0 ] == '!' )
		{
			if( equal( szCommand[ 1 ], "first", 5 ) || equal( szCommand[ 1 ], "fw", 2 ) )
			{
				if( !access( client, ADMIN_CVAR ) )
					return 1;
				
				if( task_exists( TASK_STARTCOUNT ) || task_exists( TASK_ENDCOUNT ) )
				{
					client_print_color( client, "^x01 There is a running^x04 first writes^x01 minigame" );
					
					return 1;
				}
				
				parse( szCommand, szCommand, charsmax( szCommand ), szCommand, charsmax( szCommand ) );
				
				new iDifficulty = str_to_num( szCommand ) ? str_to_num( szCommand ) : 0;
				
				if( !(0 <= iDifficulty <= 4) ) iDifficulty = 0;
				
				new szParam[ 1 ];
				szParam[ 0 ] = iDifficulty;
				
				resetMinigame();
				
				iGameTimer = 3;
				
				set_task( 1.0, "startCount", TASK_STARTCOUNT, szParam, sizeof( szParam ), "a", ( iGameTimer + 1 ) );
				
				new szName[ 32 ];
				get_user_name( client, szName, charsmax( szName ) );
				
				client_print_color( client, "^x01 Admin^x03 %s^x01 started^x04 first writes^x01 minigame", szName );
			}
			
			if( equal( szCommand[ 1 ], "stopfw", 6 ) )
			{
				if( !access( client, ADMIN_CVAR ) )
					return 1;
				
				if( !task_exists( TASK_STARTCOUNT ) && !task_exists( TASK_ENDCOUNT ) )
				{
					client_print_color( client, "^x01 There is no^x04 first writes^x01 minigame running" );
					
					return 1;
				}
				
				deactivate_votect_game( 1 );
				
				new szName[ 32 ];
				get_user_name( client, szName, charsmax( szName ) );
				
				client_print_color( client, "^x01 Admin^x03 %s^x01 stopped the^x04 first writes^x01 minigame", szName );
			}
			
			return 1;
		}
		
		if( task_exists( TASK_ENDCOUNT ) )
		{
			if( !strcmp( szCommand, szPhrase ) )
			{
				remove_task( TASK_STARTCOUNT );
				remove_task( TASK_ENDCOUNT );
				
				new szName[ 32 ];
				get_user_name( client, szName, charsmax( szName ) );
				
				set_hudmessage( 0, 145, 255, -1.0, 0.53, 0, 0.0, 5.0, 0.1, 0.1, -1 );
				show_hudmessage( 0, "[%s Minigame]^nCongrats! %s is the first who was able to write %s", PLUGIN_NAME, szName, szPhrase );
				
				setGuard( client );
				
				deactivate_votect_game( 1 );
			}
			
			else
			{
				client_print_color( 0, "^x01 You wrote the^x04 wrong^x01 phrase, try again" ); 
				client_print_color( 0, "^x01 The^x04 correct^x01 phrase is^x03 %s", szPhrase ); 
			}
			
			return 1;
		}
	}
	
	return 0;
}

public startCount( param[], taskid )
{
	if( iGameTimer <= 0 )
	{
		startMinigame( param[ 0 ] );
	}
	
	else
	{
		secondsToVoice( iGameTimer );
		
		set_hudmessage( 0, 145, 255, -1.0, 0.53, 0, 0.0, 1.0, 0.0, 0.0, -1 );
		show_hudmessage( 0, "[%s Minigame]^nThe game will start within %d seconds", PLUGIN_NAME, iGameTimer-- );
	}
}

public endCount( taskid )
{
	if( iGameTimer <= 0 )
	{
		deactivate_votect_game( 1 );
		
		set_hudmessage( 0, 145, 255, -1.0, 0.53, 0, 0.0, 5.0, 0.1, 0.1, -1 );
		show_hudmessage( 0, "[%s Minigame]^nTime is Over!^nNo one wrote the correct phrase", PLUGIN_NAME );
	}
	
	else
	{
		set_hudmessage( 0, 145, 255, -1.0, 0.53, 1, 0.0, 1.0, 0.0, 0.0, -1 );
		show_hudmessage( 0, "[%s Minigame]^n%s", PLUGIN_NAME, szPhrase );
		
		iGameTimer--;
	}
}

public votect_game_activated( GameID )
{
	if( GameID == g_iFirstWrites )
	{
		new szParam[ 1 ];
		szParam[ 0 ] = random( 5 );
		
		resetMinigame();
		
		iGameTimer = 3;
		
		set_task( 1.0, "startCount", TASK_STARTCOUNT, szParam, sizeof( szParam ), "a", ( iGameTimer + 1 ) );
	}
}

public votect_game_deactivated( GameID )
{
	if( GameID == g_iFirstWrites )
	{
		remove_task( TASK_STARTCOUNT );
		remove_task( TASK_ENDCOUNT );
		
		resetMinigame();
	}
}

startMinigame( difficulty = 0 ) 
{
	new iReturn[ 2 ];
	
	iReturn = getPhrase( szPhrase, charsmax( szPhrase ), 6, difficulty );
	
	new szDifficulty[ 63 ];
	
	formatex( szDifficulty, charsmax( szDifficulty ), "%s",  
	( !iReturn[ 1 ] ) ? "Digits Only" : ( iReturn[ 1 ] == 1 ) ? "Lowercase Only" : 
	( iReturn[ 1 ] == 2 ) ? "Uppercase Only" : ( iReturn[ 1 ] == 3 ) ? "Lowercase & Uppercase" : "Digits & Lowercase & Uppercase" );
	
	client_print_color( 0, "^x01 Game difficulty:^x03 %s^x01 | Correct phrase:^x03 %s^x01", szDifficulty, szPhrase );
	
	iGameTimer = 15;
	
	client_print_color( 0, "^x01 You have^x03 %i^x01 seconds to write the^x04 correct^x01 phrase", iGameTimer );
	
	endCount( TASK_ENDCOUNT );
	
	set_task( 1.0, "endCount", TASK_ENDCOUNT, _, _, "a", ( iGameTimer + 1 ) );
}

resetMinigame() 
{
	iGameTimer = INVALID_HANDLE;
	
	arrayset( szPhrase, EOS, sizeof( szPhrase ) );
}

getPhrase( string[], len, c, difficulty = 0 ) 
{
	
	static const szPhraseChars[ ] = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXWZabcdefghijklmnopqrstuvwxyz";
	static const iCharsLength = sizeof( szPhraseChars );
	
	for( new i = 0; i < c; i++ )
	{
		switch( difficulty )
		{
			case 1: add( string, len, szPhraseChars[ random_num(36,iCharsLength - 1) ], 1 ); // only lowercase
				case 2: add( string, len, szPhraseChars[ random_num(10,iCharsLength - 27) ], 1 ); // only uppercase
				case 3: add( string, len, szPhraseChars[ random_num(10,iCharsLength - 1) ], 1 ); // lowercase & uppercase	
				case 4: add( string, len, szPhraseChars[ random( iCharsLength ) ], 1 ); // digits & lowercase & uppercase
				
			default: add( string, len, szPhraseChars[ random( 10 ) ], 1 ); // ez pz lemon squeezy
		}
	}
	
	new returnValue[ 2 ];
	returnValue[ 0 ] = c;
	returnValue[ 1 ] = difficulty;
	
	return returnValue;
}
