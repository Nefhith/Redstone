#if defined _nd_stocks_included_
  #endinput
#endif
#define _nd_stocks_included_

/* The team name constants */
#define TEAM_UNASSIGNED		0
#define TEAM_SPEC		1
#define TEAM_CONSORT		2
#define TEAM_EMPIRE		3

stock String:NumberInEnglish(num)
{
	decl String:englishNumber[16];
	switch (num)
	{
		case 1: Format(englishNumber, sizeof(englishNumber), "one");
		case 2: Format(englishNumber, sizeof(englishNumber), "two");
		case 3: Format(englishNumber, sizeof(englishNumber), "three");
		case 4: Format(englishNumber, sizeof(englishNumber), "four");
		case 5: Format(englishNumber, sizeof(englishNumber), "five");
		case 6: Format(englishNumber, sizeof(englishNumber), "six");
		case 7: Format(englishNumber, sizeof(englishNumber), "seven");
		case 8: Format(englishNumber, sizeof(englishNumber), "eight");
		case 9: Format(englishNumber, sizeof(englishNumber), "nine");
		case 10: Format(englishNumber, sizeof(englishNumber), "ten");
	}	
	return englishNumber;
}

/**
 * Gets the name of a given team index
 *
 * @param team			Team index.
 * @return			The name of the team or "Unknown" on invalid team index
 * @error			Invalid team index.
 */

stock String:ND_GetTeamName(team)
{
	new String:TeamName[12];
	
	switch(team)
	{
		case TEAM_EMPIRE: 	TeamName = "Empire";
		case TEAM_CONSORT: 	TeamName = "Consortium";
		case TEAM_SPEC:		TeamName = "Spectate";
		case TEAM_UNASSIGNED:	TeamName = "Unassigned";
		default: 		TeamName = "Unknown";
	}
	
	return TeamName;
}

stock String:GetTransNumber(value)
{
	new String:number[32];
	
	switch (value)
	{
		case 1: Format(number, sizeof(number), "%t", "one");
		case 2: Format(number, sizeof(number), "%t", "two");
		case 3: Format(number, sizeof(number), "%t", "three");
		case 4: Format(number, sizeof(number), "%t", "four");
		case 5: Format(number, sizeof(number), "%t", "five");
		case 6: Format(number, sizeof(number), "%t", "six");
		case 7: Format(number, sizeof(number), "%t", "seven");
		case 8: Format(number, sizeof(number), "%t", "eight");
		case 9: Format(number, sizeof(number), "%t", "nine");
		case 10: Format(number, sizeof(number), "%t", "ten");
		case 11: Format(number, sizeof(number), "%t", "eleven");
		case 12: Format(number, sizeof(number), "%t", "twelve");	
	}
	
	return number;
}

stock bool:IsValidClient(client, bool:nobots = true)
{ 
    if (client <= 0 || client > MaxClients || !IsClientConnected(client) || (nobots && IsFakeClient(client)))
        return false;

    return IsClientInGame(client); 
} 

stock bool:IsValidAdmin(client, const String:flags[]) 
{ 
	new ibFlags = ReadFlagString(flags); 
	return ((GetUserFlagBits(client) & ibFlags) == ibFlags || GetUserFlagBits(client) & ADMFLAG_ROOT);
}  

stock PrintToAdmins(const String:message[], const String:flags[]) 
{ 
    for (new x = 1; x <= MaxClients; x++) 
    { 
        if (IsValidClient(x) && IsValidAdmin(x, flags)) 
        { 
            PrintToChat(x, message); 
        } 
    } 
}

/** 
 * Retreives the level of a given client index
 *
 * @param client		Client index.
 * @return			The level of the client or some value less than 2
 * @error			Unloaded level or level less than 2.
 */
 
stock ND_RetreiveLevel(client)
{
	return GetEntProp(GetPlayerResourceEntity(), Prop_Send, "m_iPlayerRank", 1, client);
}

/** 
 * Retreives the current score of a given client index
 *
 * @param client		Client index.
 * @return			The current score of the client
 */

stock ND_RetrieveScore(client)
{
	return GetEntProp(GetPlayerResourceEntity(), Prop_Send, "m_iScore", 1, client);
}

/* Count Constants */

stock ValidClientCount(bool:PlaceHolder = false)
{
	new clientCount;
	
	for (new idx = 1; idx <= MaxClients; idx++) 
		if (IsValidClient(idx))
			clientCount++;
	
	return clientCount;
}

stock ReadyToBalanceCount()
{
	new clientCount;
	for (new idx = 1; idx <= MaxClients; idx++) 
		if (IsValidClient(idx) && GetClientTeam(idx) > 0)
			clientCount++;
			
	return clientCount;
}

stock OnTeamCount()
{
	new clientCount;
	for (new idx = 1; idx <= MaxClients; idx++) 
		if (IsValidClient(idx) && GetClientTeam(idx) > 1)
			clientCount++;
			
	return clientCount;
}

stock OnTeamCountEx()
{
	return GetTeamClientCount(3) + GetTeamClientCount(2);
}

stock ValidTeamCount(teamName)
{
	new clientCount;
	for (new idx = 1; idx <= MaxClients; idx++) 
		if (IsValidClient(idx) && GetClientTeam(idx) == teamName)
			clientCount++;
	
	return clientCount;
}

stock getOverBalance()
{
	new clientCount[2], team;
	
	for (new idx = 1; idx <= MaxClients; idx++) 
		if (IsValidClient(idx))
		{
			team = GetClientTeam(idx);
			if (team > 1)
				clientCount[team -2]++;
		}

	return clientCount[1] - clientCount[0];
}

stock getPositiveOverBalance()
{
	new overBalance = getOverBalance();
	
	if (overBalance < 0)
		overBalance *= -1;
		
	return overBalance;
}

/* Team Constants */

stock getOtherTeam(team)
{
	//consort = 2, empire = 3	
	return team == 2 ? 3 : 2;
}

stock bool:isOnTeam(client)
{	
	return IsClientInGame(client) && GetClientTeam(client) > 1;
}

stock getLeastStackedTeam(Float:teamdiff)
{
	return teamdiff > 0 ? 3 : 2;
}

stock getStackedTeam(Float:teamdiff)
{
	return teamdiff > 0 ? 2 : 3;
}

stock getRandomTeam() {
	return GetRandomInt(2, 3);
}
