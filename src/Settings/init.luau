                                                                                                        --[[
Welcome to Sword Admin. 

RANK TITLE  | PERMISSIONS                            | RANK NUMBER
------------|----------------------------------------|-------------
Head Admins | Full command permission                | 3
Admins      | A set command permssion of your choice | 2
Temp Admins | A set command permssion of your choice | 1                                                ]]

return{
	------[ADMINS]-------
	
	Head_Admins = {
		"aisleofplenty";  --lowercase
		"player1"; -- Username
		1;         -- User id
	};
	DevelopersAdmin = true; -- Group owner, developers, etc
	DeveloperGroupRanks = {
		255, -- owner
		254, -- example: studio lead
		253, -- example: dev
	}; -- these are the group ranks that are automatically given head admin
	-- only used if the experience is group-owned
	--
	-- Head Admins have access to all commands, you can only adjust the commands in PowerUserSettings
	
	Admins = {
		"player1"; 
		"player2";
		1;
	}; 
	Admin_Commands = {"spectate"; "unspectate"; "mute";"unmute";"commands"; "message";" kill"; "kick"; "ff"; "unff"; "explode"; "fly"; "noclip"; "ban"; "leaderstat"; "speed"; "clone"; "tempadmin"; "freeze"; "cmds";};
	-- this is the main rank for true administrators in your game
	
	Temp_Admins = {
		"player1"; 
		"player2";
		1;
	}; 
	Temp_AdminCommands = {"commands"; "kill"; "ff"; "unff"; "speed"; "freeze"; "cmds";};
	-- temp admin is just rank, they do not hold admin 
	-- for a set amout of time
	-- it is recommended to use this for gamepass/premium administrators 
	
	------[BANNING]-------
	
	BanLand = {
		"player1";
		"player2";
		1;
	};
	-- does not involve BanAsync
	-- just kicks the player as soon as they join
	
	------[PERKS_GIVEN]-------
	--! Gamepasses take higher priority over premium.
	GamePassId = 0;
	GamePassRank = 1;
	-- gives users who own the select gamepass the rank of your choice
	
	PremiumAdmin = false; 
	PremiumRank = 1;
	-- gives users who own premium the rank of your choice 

	------[MISC]-------

	prefix = ";"; -- the prefix for the commands e.g. [;]help [:]help [!]help
				  -- you can change this to any character or string
	adminJoinMessage = true; -- does sword admin display a message when the player joins?
	advertising = true; -- advertisement GUI for sword admin 
	freeAdmin = false; -- automatically give all players rank 1 (temp admin)
}