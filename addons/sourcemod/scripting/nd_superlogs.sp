/**
 * HLstatsX Community Edition - SourceMod plugin to generate advanced weapon logging
 * http://www.hlxcommunity.com
 * Copyright (C) 2009 Nicholas Hastings (psychonic)
 * Copyright (C) 2007-2008 TTS Oetzel & Goerz GmbH
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
 */

#pragma semicolon 1
 
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <nd_stocks>

#define MAX_LOG_WEAPONS 28
#define IGNORE_SHOTS_START 16
#define MAX_WEAPON_LEN 20

#define BUNKER_DAMAGE_TIMES 10

new g_weapon_stats[MAXPLAYERS+1][MAX_LOG_WEAPONS][15];
new const String:g_weapon_list[MAX_LOG_WEAPONS][MAX_WEAPON_LEN] = {
									"avenger", 
									"bag90",
									"chaingun", 
									"daisy cutter",
									"f2000",
									"grenade launcher",
									"m95",
									"mp500",
									"mp7",
									"nx300",
									"p900",
									"paladin",
									"pp22",
									"psg",
									"shotgun",
									"sp5",
									"x01",
									"medpack",
									"armblade", 
									"mine",
									"emp grenade",
									"p12 grenade",
									"remote grenade",
									"repair tool",
									"svr grenade",
									"u23 grenade",
									"armknives",
									"frag grenade"
								};

#include <loghelper>
#include <wstatshelper>

new g_bReadyToShoot[MAXPLAYERS+1] = {false,...};
new g_iBunkerAttacked[2] = {0,...};

public Plugin:myinfo = 
{
	name 		= "[ND] Superlogs",
	author 		= "Peace-Maker, stickz",
	description 	= "Advanced Nuclear Dawn logging designed for various statistical plugins",
	version 	= "dummy",
	url 		= "http://www.hlxcommunity.com"
};

/* Updater Support */
#define UPDATE_URL  "https://github.com/stickz/Redstone/raw/build/updater/nd_superlogs/nd_superlogs.txt"
#include "updater/standard.sp"

public OnPluginStart()
{
	CreatePopulateWeaponTrie();

	HookEvents(); //Hook events
	
	CreateTimer(1.0, LogMap);
	
	SetupTeams();
	
	AccountForLateLoading();
	
	AddUpdaterLibrary(); //Add updater support if included
}

public OnMapStart()
{
	SetupTeams();
	
	g_iBunkerAttacked[0] = 0;
	g_iBunkerAttacked[1] = 0;
}

public OnClientPutInServer(client)
{
	g_bReadyToShoot[client] = false;
	if (!IsFakeClient(client))
	{
		SDKHook(client, SDKHook_TraceAttackPost, Hook_TraceAttackPost);
		SDKHook(client, SDKHook_PostThink, Hook_PostThink);
		SDKHook(client, SDKHook_PostThinkPost, Hook_PostThinkPost);
	}
	reset_player_stats(client);
}

public Action:Event_PlayerDeathPre(Handle:event, const String:name[], bool:dontBroadcast)
{
	new victim   = GetClientOfUserId(GetEventInt(event, "userid"));
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	
	decl String:weapon[MAX_WEAPON_LEN];
	GetEventString(event, "weapon", weapon, sizeof(weapon));
	
	if (attacker <= 0 || victim <= 0)
		return Plugin_Continue;

	// Which commander ablilty?!
	if(StrEqual(weapon, "commander ability"))
	{
		new damagebits = GetEventInt(event, "damagebits");
		if(damagebits & DMG_ENERGYBEAM)
		{
			Format(weapon, sizeof(weapon), "commander poison");
			SetEventString(event, "weapon", weapon);
		}
		else if(damagebits & DMG_BLAST)
		{
			Format(weapon, sizeof(weapon), "commander damage");
			SetEventString(event, "weapon", weapon);
		}
	}
	
	new victim_team = GetClientTeam(victim);
	
	if(attacker != victim)
	{
		// Check if victim was commander?
		if(GameRules_GetPropEnt("m_hCommanders", victim_team-2) == victim)
			LogPlayerEvent(attacker, "triggered", "killed_commander");
	}
	
	new weapon_index = get_weapon_index(weapon);
	if (weapon_index > -1)
	{
		g_weapon_stats[attacker][weapon_index][LOG_HIT_KILLS]++;
		g_weapon_stats[victim][weapon_index][LOG_HIT_DEATHS]++;
		
		if (GetClientTeam(attacker) == victim_team)
			g_weapon_stats[attacker][weapon_index][LOG_HIT_TEAMKILLS]++;

		dump_player_stats(victim);
	}
	
	return Plugin_Continue;
}

public Hook_PostThink(client)
{
	if(!IsPlayerAlive(client))
		return;
	
	new iWeapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
	if(IsInvalid(iWeapon))
	{
		g_bReadyToShoot[client] = false;
		return;
	}
	
	decl String:sWeapon[32];
	GetEdictClassname(iWeapon, sWeapon, sizeof(sWeapon));
	if(StrContains(sWeapon, "weapon_", false) != 0)
		return;
	
	g_bReadyToShoot[client] = GetEntPropFloat(iWeapon, Prop_Send, "m_flNextPrimaryAttack") <= GetGameTime() 
				&& GetEntProp(iWeapon, Prop_Send, "m_iClip1") > 0;
}

public Hook_PostThinkPost(client)
{
	if(!IsPlayerAlive(client))
		return;
	
	new iWeapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
	if(IsInvalid(iWeapon))
		return;
	
	decl String:sWeapon[30];
	GetEdictClassname(iWeapon, sWeapon, sizeof(sWeapon));
	if(StrContains(sWeapon, "weapon_", false) != 0)
		return;
	
	ReplaceString(sWeapon, sizeof(sWeapon), "weapon_", "", false);
	FixWeaponLoggingName(sWeapon, sizeof(sWeapon));
	
	if(g_bReadyToShoot[client] && GetEntPropFloat(iWeapon, Prop_Send, "m_flNextPrimaryAttack") > GetGameTime())
	{
		new weapon_index = get_weapon_index(sWeapon);
		if (weapon_index > -1 && weapon_index < IGNORE_SHOTS_START)
			g_weapon_stats[client][weapon_index][LOG_HIT_SHOTS]++;
			
		g_bReadyToShoot[client] = false;
	}
}

public Hook_TraceAttackPost(victim, attacker, inflictor, Float:damage, damagetype, ammotype, hitbox, hitgroup)
{
	if(IsClientInGame(victim))
	{
		if(1 <= attacker <= MaxClients && IsClientInGame(attacker))
		{
			new iWeapon = GetEntPropEnt(attacker, Prop_Send, "m_hActiveWeapon");
			new String:sWeapon[64];
			if(iWeapon > 0)
				GetEdictClassname(iWeapon, sWeapon, sizeof(sWeapon));
			
			ReplaceString(sWeapon, sizeof(sWeapon), "weapon_", "", false);
			FixWeaponLoggingName(sWeapon, sizeof(sWeapon));
			
			new weapon_index = get_weapon_index(sWeapon);
			
			// player_death
			if((GetClientHealth(victim) - RoundToCeil(damage)) < 0)
			{
				if (hitgroup == HITGROUP_HEAD)
				{
					LogPlayerEvent(attacker, "triggered", "headshot");
					if (weapon_index > -1)
						g_weapon_stats[attacker][weapon_index][LOG_HIT_HEADSHOTS]++;
				}
			}
			// player_hurt
			else
			{
				if (weapon_index > -1)
				{
					g_weapon_stats[attacker][weapon_index][LOG_HIT_HITS]++;
					g_weapon_stats[attacker][weapon_index][LOG_HIT_DAMAGE] += RoundToCeil(damage);
					if (hitgroup < 8)
					{
						g_weapon_stats[attacker][weapon_index][hitgroup + LOG_HIT_OFFSET]++;
					}
				}
			}
		}
	}
}

public Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	// "userid"        "short"         // user ID on server          

	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (client > 0)
		reset_player_stats(client);
}

public Action:Event_PlayerDisconnect(Handle:event, const String:name[], bool:dontBroadcast)
{
	//This calls OnPlayerDisconnect(client) forward
	OnPlayerDisconnect(GetClientOfUserId(GetEventInt(event, "userid")));
	return Plugin_Continue;
}

public Event_RoundWin(Handle:event, const String:name[], bool:dontBroadcast)
{
	new team = GetEventInt(event, "team");
	if(team >= 2)
	{
		LogTeamEvent(team, "triggered", "round_win");
		LogTeamEvent(getOtherTeam(team), "triggered", "round_lose");
	}
	
	g_iBunkerAttacked[0] = 0;
	g_iBunkerAttacked[1] = 0;
	WstatsDumpAll();
}

public Event_PromotedToCommander(Handle:event, const String:name[], bool:dontBroadcast)
{
	LogPlayerEvent(GetClientOfUserId(GetEventInt(event, "userid")), "triggered", "promoted_to_commander");
}

public Event_ResourceCaptured(Handle:event, const String:name[], bool:dontBroadcast)
{
	new team = GetEventInt(event, "team");
	if(team >= 2)
		LogTeamEvent(team, "triggered", "resource_captured");
}

public Event_StructureDamageSparse(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(!GetEventBool(event, "bunker"))
		return;
		
	new team = GetEventInt(event, "ownerteam");
	if(team >= 2)
	{
		g_iBunkerAttacked[team-2]++;
		
		if(g_iBunkerAttacked[team-2] == BUNKER_DAMAGE_TIMES)
		{
			LogTeamEvent(getOtherTeam(team), "triggered", "damaged_opposite_bunker");
			g_iBunkerAttacked[team-2] = 0;
		}
	}
}

public Event_StructureDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	new iEnt = GetEventInt(event, "entindex");
	new iAttacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	if(iAttacker > 0 && iAttacker <= MaxClients && iEnt != -1 && IsValidEntity(iEnt))
	{
		new type = GetEventInt(event, "type");
		
		switch (type) // get building name
		{
			//case 0: Command Bunker
			case 1:	LogPlayerEvent(iAttacker, "triggered", "machineguneturret_destroyed");
			case 2:	LogPlayerEvent(iAttacker, "triggered", "transportgate_destroyed");
			case 3:	LogPlayerEvent(iAttacker, "triggered", "powerstation_destroyed");
			case 4:	LogPlayerEvent(iAttacker, "triggered", "wirelessrepeater_destroyed");
			case 5:	LogPlayerEvent(iAttacker, "triggered", "powerrelay_destroyed");
			case 6:	LogPlayerEvent(iAttacker, "triggered", "supply_destroyed");
			case 7:	LogPlayerEvent(iAttacker, "triggered", "assembler_destroyed");
			case 8:	LogPlayerEvent(iAttacker, "triggered", "armoury_destroyed");
			case 9:	LogPlayerEvent(iAttacker, "triggered", "artillery_destroyed");
			case 10: LogPlayerEvent(iAttacker, "triggered", "radar_destroyed");
			case 11: LogPlayerEvent(iAttacker, "triggered", "flamethrowerturret_destroyed");
			case 12: LogPlayerEvent(iAttacker, "triggered", "sonicturret_destroyed");
			case 13: LogPlayerEvent(iAttacker, "triggered", "rocketturret_destroyed");
			case 14: LogPlayerEvent(iAttacker, "triggered", "wall_destroyed"); //not sure if this is correct
			case 15: LogPlayerEvent(iAttacker, "triggered", "barrier_destroyed"); //not sure if this is correct
			//default: Format(buildingname, sizeof(buildingname), "a %d (?)", type);
		}		
		
		/*decl String:sBuffer[32];
		GetEdictClassname(iEnt, sBuffer, sizeof(sBuffer));
		PrintToChatAll("%N destroyed %s", iAttacker, sBuffer);*/
	}
}

public Action:LogMap(Handle:timer)
{
	// Called 1 second after OnPluginStart since srcds does not log the first map loaded. Idea from Stormtrooper's "mapfix.sp" for psychostats
	LogMapLoad();
}

bool:IsInvalid(iWeapon)
{
	return iWeapon == -1 || !IsValidEdict(iWeapon);
}

stock FixWeaponLoggingName(String:sWeapon[], maxlength)
{
	if(StrEqual(sWeapon, "daisycutter"))
		strcopy(sWeapon, maxlength, "daisy cutter");
	else if(StrEqual(sWeapon, "emp_grenade"))
		strcopy(sWeapon, maxlength, "emp grenade");
	else if(StrEqual(sWeapon, "frag_grenade"))
		strcopy(sWeapon, maxlength, "frag grenade");
	else if(StrEqual(sWeapon, "grenade_launcher"))
		strcopy(sWeapon, maxlength, "grenade launcher");
	else if(StrEqual(sWeapon, "p12_grenade"))
		strcopy(sWeapon, maxlength, "p12 grenade");
	else if(StrEqual(sWeapon, "remote_grenade"))
		strcopy(sWeapon, maxlength, "remote grenade");
	//else if(StrEqual(sWeapon, "repair_tool"))
	//	strcopy(sWeapon, maxlength, "repair tool");
	else if(StrEqual(sWeapon, "u23_grenade"))
		strcopy(sWeapon, maxlength, "u23 grenade");
}

HookEvents()
{
	HookEvent("player_death", Event_PlayerDeathPre, EventHookMode_Pre);
	HookEvent("promoted_to_commander", Event_PromotedToCommander);
	HookEvent("resource_captured", Event_ResourceCaptured);
	HookEvent("structure_damage_sparse", Event_StructureDamageSparse);
	HookEvent("structure_death", Event_StructureDeath);
	
	// wstats
	HookEvent("player_spawn", Event_PlayerSpawn);
	HookEvent("round_win", Event_RoundWin);
	HookEvent("player_disconnect", Event_PlayerDisconnect, EventHookMode_Pre);
}

SetupTeams()
{
	GetTeams();
	
	// GetTeamName gets #ND_Consortium and #ND_Empire in release version -.-. Game logs with CONSORTIUM and EMPIRE translated
	strcopy(g_team_list[TEAM_CONSORT], sizeof(g_team_list[]), "CONSORTIUM");
	strcopy(g_team_list[TEAM_EMPIRE], sizeof(g_team_list[]), "EMPIRE");
}

AccountForLateLoading()
{
	for(new i=1;i<=MaxClients;i++)
	{
		if(IsClientInGame(i))
			OnClientPutInServer(i);
	}
}
