// Includes
#pragma tabsize 0
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <tf2>
#include <tf2_stocks>
#include <tf2attributes>

// Plugin Info
public Plugin:myinfo =
{
	name = "UberUpgrades Custom Attribues",
	author = "Razor",
	description = "Plugin for handling custom attributes.",
	version = "2.0",
	url = "n/a",
}
//Variables
new bool:b_Hooked[MAXPLAYERS+1];



stock bool:IsValidClient( client, bool:replaycheck = true )
{
    if ( client <= 0 || client > MaxClients ) return false; 
    if ( !IsClientInGame( client ) ) return false; 
    if ( !IsClientConnected( client ) ) return false; 
    if ( GetEntProp( client, Prop_Send, "m_bIsCoaching" ) ) return false; 
    if ( replaycheck )
    {
        if ( IsClientSourceTV( client ) || IsClientReplay( client ) ) return false; 
    }
    return true; 
}
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////Actual Hooks & Functions////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

// On Plugin Start
public OnPluginStart()
{
	for(new i=1; i<=MAXPLAYERS; i++)
	{
		if(IsValidClient(i))
		{
			if(b_Hooked[i] == false)
			{
				b_Hooked[i] = true;
				SDKHook(i, SDKHook_OnTakeDamage, OnTakeDamage);
				SDKHook(i, SDKHook_TraceAttack, TraceAttack);
			}
		}
	}
}
public OnPluginEnd()
{
	for(new i=1; i<=MAXPLAYERS; i++)
	{
		if(IsValidClient(i))
		{
			if(b_Hooked[i] == true)
			{
				b_Hooked[i] = false;
				SDKUnhook(i, SDKHook_OnTakeDamage, OnTakeDamage);
				SDKUnhook(i, SDKHook_TraceAttack, TraceAttack);
			}
		}
	}
}
public OnMapStart()
{
	for(new i=1; i<=MAXPLAYERS; i++)
	{
		if(IsValidClient(i))
		{
			if(b_Hooked[i] == false)
			{
				b_Hooked[i] = true;
				SDKHook(i, SDKHook_OnTakeDamage, OnTakeDamage);
				SDKHook(i, SDKHook_TraceAttack, TraceAttack);
			}
		}
	}
}

// On Client Put In Server
public OnClientPutInServer(client)
{
	if(b_Hooked[client] == false)
	{
		b_Hooked[client] = true;
		SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
		SDKHook(client, SDKHook_TraceAttack, TraceAttack);
	}
}

// On Client Disconnect
public OnClientDisconnect(client)
{
	if(IsClientInGame(client))
	{
		if(b_Hooked[client] == true)
		{
			b_Hooked[client] = false;
			SDKUnhook(client, SDKHook_OnTakeDamage, OnTakeDamage);
			SDKUnhook(client, SDKHook_TraceAttack, TraceAttack);
		}
	}
}
public OnGameFrame()
{
	for(new i=1; i<=MaxClients; i++)
	{
		if(IsValidClient(i) && IsClientInGame(i) && IsPlayerAlive(i))
		{
			//Firerate for Secondaries
			new CWeapon = GetEntPropEnt(i, Prop_Send, "m_hActiveWeapon");
			new melee = GetPlayerWeaponSlot(i,2)
			new primary = GetPlayerWeaponSlot(i,0)
			if(IsValidEntity(CWeapon))
			{
				if(IsValidEntity(melee) && CWeapon == melee){
					continue;
				}
				if(IsValidEntity(primary) && CWeapon == primary && TF2_GetPlayerClass(i) == TFClass_Sniper){
					continue;
				}
				if(IsValidEntity(primary) && CWeapon == primary && TF2_GetPlayerClass(i) == TFClass_Heavy){
					continue;
				}
				new Float:SecondaryROF = 1.0;
				new Address:Firerate1 = TF2Attrib_GetByName(CWeapon, "fire rate penalty");
				new Address:Firerate2 = TF2Attrib_GetByName(CWeapon, "fire rate bonus HIDDEN");
				new Address:Firerate3 = TF2Attrib_GetByName(CWeapon, "fire rate penalty HIDDEN");
				new Address:Firerate4 = TF2Attrib_GetByName(CWeapon, "fire rate bonus");
				if(Firerate1 != Address_Null)
				{
					new Float:Firerate1Amount = TF2Attrib_GetValue(Firerate1);
					SecondaryROF =  SecondaryROF/Firerate1Amount;
				}
				if(Firerate2 != Address_Null)
				{
					new Float:Firerate2Amount = TF2Attrib_GetValue(Firerate2);
					SecondaryROF =  SecondaryROF/Firerate2Amount;
				}
				if(Firerate3 != Address_Null)
				{
					new Float:Firerate3Amount = TF2Attrib_GetValue(Firerate3);
					SecondaryROF =  SecondaryROF/Firerate3Amount;
				}
				if(Firerate4 != Address_Null)
				{
					new Float:Firerate4Amount = TF2Attrib_GetValue(Firerate4);
					SecondaryROF =  SecondaryROF/Firerate4Amount;
				}
				SecondaryROF = Pow(SecondaryROF, 0.4);
				new Float:m_flNextSecondaryAttack = GetEntPropFloat(CWeapon, Prop_Send, "m_flNextSecondaryAttack");
				new Float:SeTime = (m_flNextSecondaryAttack - GetGameTime()) - ((SecondaryROF - 1.0) / (1/GetTickInterval()));
				new Float:FinalS = SeTime+GetGameTime();
				SetEntPropFloat(CWeapon, Prop_Send, "m_flNextSecondaryAttack", FinalS);
			}
		}
	}
}
//		Expect this to be changed in the future.
//
//public Action OnPlayerRunCmd(int client, int& buttons, int& impulse, float vel[3], float angles[3], int& weapon, int& subtype, int& cmdnum, int& tickcount, int& seed, int mouse[2])
//
//	if (IsValidClient(client))
//	{
//	}
//}
public Action TraceAttack(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &ammotype, int hitbox, int hitgroup)
{
	if (hitgroup == 1)
	{
		new CWeapon = GetEntPropEnt(attacker, Prop_Send, "m_hActiveWeapon");
		if(IsValidEntity(CWeapon))
		{
			new Address:HeadshotsActive = TF2Attrib_GetByName(CWeapon, "charge time decreased");
			if(HeadshotsActive != Address_Null && !TF2_IsPlayerInCondition(victim, TFCond_DefenseBuffNoCritBlock))// Batallions 
			{
				damagetype |= DMG_CRIT;
				new Float:HeadshotDMG = TF2Attrib_GetValue(HeadshotsActive);
				damage *= HeadshotDMG;
				return Plugin_Changed;
			}
		}
	}
    return Plugin_Continue;
}
public Action:OnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype, &weapon, Float:damageForce[3], Float:damagePosition[3], damagecustom)
{
	if(IsValidClient(attacker) && IsValidEntity(weapon))
	{
		new Address:overrideProj = TF2Attrib_GetByName(weapon, "override projectile type");//Adding support for damage increase on the lightning orb override.
		if(overrideProj != Address_Null && TF2Attrib_GetValue(overrideProj) == 31)
		{
			new Address:DMGVSPlayer = TF2Attrib_GetByName(weapon, "dmg penalty vs players");
			new Address:DamageBonusHidden = TF2Attrib_GetByName(weapon, "damage bonus HIDDEN");
			new Address:DamagePenalty = TF2Attrib_GetByName(weapon, "damage penalty");
			new Address:DamageBonus = TF2Attrib_GetByName(weapon, "damage bonus");
			new Address:bulletspershot = TF2Attrib_GetByName(weapon, "bullets per shot bonus");
			
			if(DMGVSPlayer != Address_Null)
			{
				damage *= TF2Attrib_GetValue(DMGVSPlayer);
			}
			if(DamageBonusHidden != Address_Null)
			{
				damage *= TF2Attrib_GetValue(DamageBonusHidden);
			}
			if(DamagePenalty != Address_Null)
			{
				damage *= TF2Attrib_GetValue(DamagePenalty);
			}
			if(DamageBonus != Address_Null)
			{
				damage *= TF2Attrib_GetValue(DamageBonus);
			}
			if(bulletspershot != Address_Null)
			{
				damage *= TF2Attrib_GetValue(bulletspershot);
			}
		}
	}
	if(damage < 0.0)// Make sure you can't deal negative damage....
	{
		damage = 0.0;
	}
	return Plugin_Changed;
}
public Action:TF2_CalcIsAttackCritical(client, weapon, String:weaponname[], &bool:result)
{
	new hClientWeapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
	if(IsValidEntity(hClientWeapon))
	{
		new Address:override = TF2Attrib_GetByName(hClientWeapon, "override projectile type");
		decl Float:fAngles[3], Float:fVelocity[3], Float:fOrigin[3], Float:vBuffer[3];
		if(override != Address_Null)
		{
			new Float:projnum = TF2Attrib_GetValue(override);
			if(projnum == 27)
			{
				new iEntity = CreateEntityByName("tf_projectile_sentryrocket");
				if (IsValidEdict(iEntity)) 
				{
					new iTeam = GetClientTeam(client);
					SetEntPropEnt(iEntity, Prop_Send, "m_hOwnerEntity", client);

					SetEntProp(iEntity, Prop_Send, "m_iTeamNum", iTeam, 1);
					SetEntProp(iEntity, Prop_Send, "m_nSkin", (iTeam-2));
					
					
					SetEntPropEnt(iEntity, Prop_Data, "m_hOwnerEntity", client);
					SetEntPropEnt(iEntity, Prop_Send, "m_hLauncher", client);
								
					GetClientEyePosition(client, fOrigin);
					GetClientEyeAngles(client, fAngles);
					
					GetAngleVectors(fAngles, vBuffer, NULL_VECTOR, NULL_VECTOR);
					new Float:Speed = 2000.0;
					new Address:projspeed = TF2Attrib_GetByName(hClientWeapon, "Projectile speed increased");
					if(projspeed != Address_Null)
					{
						Speed *= TF2Attrib_GetValue(projspeed);
					}
					fVelocity[0] = vBuffer[0]*Speed;
					fVelocity[1] = vBuffer[1]*Speed;
					fVelocity[2] = vBuffer[2]*Speed;
					
					new Float:ProjectileDamage = 90.0;
					
					new Address:DMGVSPlayer = TF2Attrib_GetByName(hClientWeapon, "dmg penalty vs players");
					new Address:DamagePenalty = TF2Attrib_GetByName(hClientWeapon, "damage penalty");
					new Address:DamageBonus = TF2Attrib_GetByName(hClientWeapon, "damage bonus");
					new Address:DamageBonusHidden = TF2Attrib_GetByName(hClientWeapon, "damage bonus HIDDEN");
					
					if(DMGVSPlayer != Address_Null)
					{
						new Float:dmgmult1 = TF2Attrib_GetValue(DMGVSPlayer);
						ProjectileDamage *= dmgmult1;
					}
					if(DamagePenalty != Address_Null)
					{
						new Float:dmgmult2 = TF2Attrib_GetValue(DamagePenalty);
						ProjectileDamage *= dmgmult2;
					}
					if(DamageBonus != Address_Null)
					{
						new Float:dmgmult3 = TF2Attrib_GetValue(DamageBonus);
						ProjectileDamage *= dmgmult3;
					}
					if(DamageBonusHidden != Address_Null)
					{
						new Float:dmgmult4 = TF2Attrib_GetValue(DamageBonusHidden);
						ProjectileDamage *= dmgmult4;
					}
					
					SetEntDataFloat(iEntity, FindSendPropInfo("CTFProjectile_Rocket", "m_iDeflected") + 4, ProjectileDamage, true);  
					
					TeleportEntity(iEntity, fOrigin, fAngles, fVelocity);
					DispatchSpawn(iEntity);
				}
			}
			if(projnum == 31)
			{
				new iEntity = CreateEntityByName("tf_projectile_lightningorb");
				if (IsValidEdict(iEntity)) 
				{
					new iTeam = GetClientTeam(client);
					SetEntPropEnt(iEntity, Prop_Send, "m_hOwnerEntity", client);

					SetEntProp(iEntity, Prop_Send, "m_iTeamNum", iTeam, 1);
					SetEntProp(iEntity, Prop_Send, "m_nSkin", (iTeam-2));
					
					
					SetEntPropEnt(iEntity, Prop_Data, "m_hOwnerEntity", client);
					SetEntPropEnt(iEntity, Prop_Send, "m_hLauncher", client);
								
					GetClientEyePosition(client, fOrigin);
					GetClientEyeAngles(client, fAngles);
					
					GetAngleVectors(fAngles, vBuffer, NULL_VECTOR, NULL_VECTOR);
					new Float:Speed = 700.0;
					
					new Address:projspeed = TF2Attrib_GetByName(hClientWeapon, "Projectile speed increased");
					if(projspeed != Address_Null)
					{
						Speed *= TF2Attrib_GetValue(projspeed);
					}
					fVelocity[0] = vBuffer[0]*Speed;
					fVelocity[1] = vBuffer[1]*Speed;
					fVelocity[2] = vBuffer[2]*Speed;
					DispatchSpawn(iEntity);
					TeleportEntity(iEntity, fOrigin, fAngles, fVelocity);
				}
			}
		}
	}
	return Plugin_Handled;
}
public OnEntityCreated(entity, const char[] classname)
{
	if(StrEqual(classname, "tf_projectile_energy_ball"))
	{
		CreateTimer(0.0, delay, EntIndexToEntRef(entity));
	}
	else if(StrEqual(classname, "tf_projectile_mechanicalarmorb"))
	{
		CreateTimer(0.0, delay, EntIndexToEntRef(entity));
	}
	else if(StrEqual(classname, "tf_projectile_energy_ring"))
	{
		CreateTimer(0.0, delay, EntIndexToEntRef(entity));
	}
	else if(StrEqual(classname, "tf_projectile_arrow") || StrEqual(classname, "tf_projectile_healing_bolt"))
    {
		CreateTimer(0.0, delay, EntIndexToEntRef(entity));
	}
}
public Action:delay(Handle:timer, any:ref) 
{ 
    new entity = EntRefToEntIndex(ref); 

    if(IsValidEdict(entity)) 
    { 
		int client;
		client = GetEntPropEnt(entity, Prop_Data, "m_hOwnerEntity");
		if(IsValidClient(client))
		{
			new ClientWeapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
			if(IsValidEntity(ClientWeapon))
			{
				new Address:projspeed = TF2Attrib_GetByName(ClientWeapon, "Projectile speed increased");
				if(projspeed != Address_Null){
					new Float:vAngles[3];
					new Float:vPosition[3];
					GetEntPropVector(entity, Prop_Data, "m_vecOrigin", vPosition);
					GetEntPropVector(entity, Prop_Data, "m_angRotation", vAngles);
					decl Float:vBuffer[3];
					GetAngleVectors(vAngles, vBuffer, NULL_VECTOR, NULL_VECTOR);
					decl Float:vVelocity[3];
					new Float:projspd = TF2Attrib_GetValue(projspeed);
					new Float:vel[3];
					GetEntPropVector(entity, Prop_Data, "m_vecAbsVelocity", vel);
					vVelocity[0] = vBuffer[0]*projspd*GetVectorLength(vel);
					vVelocity[1] = vBuffer[1]*projspd*GetVectorLength(vel);
					vVelocity[2] = vBuffer[2]*projspd*GetVectorLength(vel);
					TeleportEntity(entity, NULL_VECTOR, NULL_VECTOR, vVelocity);
					SetEntPropVector(entity, Prop_Send, "m_vInitialVelocity", vVelocity);
				}
			}
		}
    } 
}