#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <multicolors>
#include <store>

#pragma semicolon 1
#pragma newdecls required

public Plugin myinfo = 
{
	name = "ZephStore - FNEmotes", 
	author = "ByDexter", 
	description = "", 
	version = "1.1", 
	url = "https://steamcommunity.com/id/ByDexterTR - ByDexter#5494"
};

ArrayList Emotes;

ConVar g_cvThirdperson;
ConVar g_cvTeleportBack;
ConVar g_cvHidePlayers;
ConVar g_cvHideWeapons;
ConVar g_cvCooldown;
ConVar g_cvSoundVolume;
ConVar g_cvEmotesSounds;

int g_iEmoteEnt[65];
int g_iEmoteSoundEnt[65];

char g_sEmoteSound[65][256];

bool g_bClientDancing[65];

Handle CooldownTimers[65];
bool g_bEmoteCooldown[65];

int g_iWeaponHandEnt[65];

bool g_bHooked[65];

int itemids[85];

float g_fLastAngles[65][3];
float g_fLastPosition[65][3];

public void OnPluginStart()
{
	LoadTranslations("fnemotes.phrases");
	LoadTranslations("common.phrases");
	
	g_cvTeleportBack = CreateConVar("sm_emotes_teleportonend", "0", "Teleport back to the exact position when he started to dance. (Some maps need this for teleport triggers)", _, true, 0.0, true, 1.0);
	g_cvHidePlayers = CreateConVar("sm_emotes_hide_enemies", "0", "Hide enemy players when dancing", _, true, 0.0, true, 1.0);
	g_cvHideWeapons = CreateConVar("sm_emotes_hide_weapons", "1", "Hide weapons when dancing", _, true, 0.0, true, 1.0);
	g_cvCooldown = CreateConVar("sm_emotes_cooldown", "4.0", "Cooldown for emotes in seconds. -1 or 0 = no cooldown.");
	g_cvSoundVolume = CreateConVar("sm_emotes_soundvolume", "0.4", "Sound volume for the emotes.");
	g_cvEmotesSounds = CreateConVar("sm_emotes_sounds", "1", "Enable/Disable sounds for emotes.", _, true, 0.0, true, 1.0);
	
	AutoExecConfig(true, "store_fnemotes", "ByDexter");
	
	HookEvent("player_death", Event_PlayerDeath, EventHookMode_Pre);
	HookEvent("player_hurt", Event_PlayerHurt, EventHookMode_Pre);
	HookEvent("round_prestart", Event_Start);
	
	Emotes = new ArrayList(85);
	
	Store_RegisterHandler("fnemote", "emoteid", EmoteOnMapStart, EmoteReset, EmoteConfig, EmoteEquip, EmoteRemove, false);
	
	RegConsoleCmd("sm_emotes", Command_Menu);
	RegConsoleCmd("sm_emote", Command_Menu);
	RegConsoleCmd("sm_dances", Command_Menu);
	RegConsoleCmd("sm_dance", Command_Menu);
	
	g_cvThirdperson = FindConVar("sv_allow_thirdperson");
	if (!g_cvThirdperson)SetFailState("sv_allow_thirdperson not found!");
	
	g_cvThirdperson.AddChangeHook(OnConVarChanged);
	g_cvThirdperson.BoolValue = true;
}

void OnConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	if (convar == g_cvThirdperson)
	{
		if (newValue[0] != '1')convar.BoolValue = true;
	}
}

public void OnMapStart()
{
	EmoteOnMapStart();
}

public void OnClientPostAdminCheck(int client)
{
	if (IsValidClient(client))
	{
		ResetCam(client);
		TerminateEmote(client);
		g_iWeaponHandEnt[client] = INVALID_ENT_REFERENCE;
		
		if (CooldownTimers[client] != null)
		{
			KillTimer(CooldownTimers[client]);
		}
	}
}

public void OnClientDisconnect(int client)
{
	if (IsValidClient(client))
	{
		ResetCam(client);
		TerminateEmote(client);
		
		if (CooldownTimers[client] != null)
		{
			KillTimer(CooldownTimers[client]);
			CooldownTimers[client] = null;
			g_bEmoteCooldown[client] = false;
		}
	}
	g_bHooked[client] = false;
}

public Action BlockCommand(int client, const char[] command, int argc)
{
	return Plugin_Stop;
}

public void EmoteOnMapStart()
{
	AddFileToDownloadsTable("models/player/custom_player/kodua/fortnite_emotes_v2.mdl");
	AddFileToDownloadsTable("models/player/custom_player/kodua/fortnite_emotes_v2.vvd");
	AddFileToDownloadsTable("models/player/custom_player/kodua/fortnite_emotes_v2.dx90.vtx");
	
	// Edit
	// Add the sound file routes here
	AddFileToDownloadsTable("sound/kodua/fortnite_emotes/ninja_dance_01.mp3");
	AddFileToDownloadsTable("sound/kodua/fortnite_emotes/dance_soldier_03.mp3");
	AddFileToDownloadsTable("sound/kodua/fortnite_emotes/hip_hop_good_vibes_mix_01_loop.wav");
	AddFileToDownloadsTable("sound/kodua/fortnite_emotes/emote_zippy_a.wav");
	AddFileToDownloadsTable("sound/kodua/fortnite_emotes/athena_emote_electroshuffle_music.wav");
	AddFileToDownloadsTable("sound/kodua/fortnite_emotes/emote_aerobics_01.wav");
	AddFileToDownloadsTable("sound/kodua/fortnite_emotes/athena_music_emotes_bendy.wav");
	AddFileToDownloadsTable("sound/kodua/fortnite_emotes/athena_emote_bandofthefort_music.wav");
	AddFileToDownloadsTable("sound/kodua/fortnite_emotes/emote_boogiedown.wav");
	AddFileToDownloadsTable("sound/kodua/fortnite_emotes/emote_capoeira.mp3");
	AddFileToDownloadsTable("sound/kodua/fortnite_emotes/athena_emote_flapper_music.wav");
	AddFileToDownloadsTable("sound/kodua/fortnite_emotes/athena_emote_chicken_foley_01.wav");
	AddFileToDownloadsTable("sound/kodua/fortnite_emotes/emote_cry.mp3");
	AddFileToDownloadsTable("sound/kodua/fortnite_emotes/athena_emote_music_boneless.wav");
	AddFileToDownloadsTable("sound/kodua/fortnite_emotes/athena_emotes_music_shoot_v7.wav");
	AddFileToDownloadsTable("sound/kodua/fortnite_emotes/Athena_Emotes_Music_SwipeIt.wav");
	AddFileToDownloadsTable("sound/kodua/fortnite_emotes/athena_emote_disco.wav");
	AddFileToDownloadsTable("sound/kodua/fortnite_emotes/athena_emote_worm_music.mp3");
	AddFileToDownloadsTable("sound/kodua/fortnite_emotes/athena_music_emotes_takethel.wav");
	AddFileToDownloadsTable("sound/kodua/fortnite_emotes/athena_emote_breakdance_music.mp3");
	AddFileToDownloadsTable("sound/kodua/fortnite_emotes/Emote_Dance_Pump.wav");
	AddFileToDownloadsTable("sound/kodua/fortnite_emotes/athena_emote_ridethepony_music_01.mp3");
	AddFileToDownloadsTable("sound/kodua/fortnite_emotes/athena_emote_facepalm_foley_01.mp3");
	AddFileToDownloadsTable("sound/kodua/fortnite_emotes/Athena_Emotes_OnTheHook_02.mp3");
	AddFileToDownloadsTable("sound/kodua/fortnite_emotes/athena_emote_floss_music.wav");
	AddFileToDownloadsTable("sound/kodua/fortnite_emotes/Emote_FlippnSexy.mp3");
	AddFileToDownloadsTable("sound/kodua/fortnite_emotes/athena_emote_fresh_music.wav");
	AddFileToDownloadsTable("sound/kodua/fortnite_emotes/emote_groove_jam_a.wav");
	AddFileToDownloadsTable("sound/kodua/fortnite_emotes/br_emote_shred_guitar_mix_03_loop.wav");
	AddFileToDownloadsTable("sound/kodua/fortnite_emotes/Emote_HeelClick.mp3");
	AddFileToDownloadsTable("sound/kodua/fortnite_emotes/s5_hiphop_breakin_132bmp_loop.wav");
	AddFileToDownloadsTable("sound/kodua/fortnite_emotes/Emote_Hotstuff.mp3");
	AddFileToDownloadsTable("sound/kodua/fortnite_emotes/emote_hula_01.wav");
	AddFileToDownloadsTable("sound/kodua/fortnite_emotes/athena_emote_infinidab.wav");
	AddFileToDownloadsTable("sound/kodua/fortnite_emotes/emote_Intensity.wav");
	AddFileToDownloadsTable("sound/kodua/fortnite_emotes/emote_irish_jig_foley_music_loop.wav");
	AddFileToDownloadsTable("sound/kodua/fortnite_emotes/Athena_Music_Emotes_KoreanEagle.wav");
	AddFileToDownloadsTable("sound/kodua/fortnite_emotes/emote_kpop_01.wav");
	AddFileToDownloadsTable("sound/kodua/fortnite_emotes/emote_laugh_01.mp3");
	AddFileToDownloadsTable("sound/kodua/fortnite_emotes/emote_LivingLarge_A.wav");
	AddFileToDownloadsTable("sound/kodua/fortnite_emotes/Emote_Luchador.mp3");
	AddFileToDownloadsTable("sound/kodua/fortnite_emotes/Emote_Hillbilly_Shuffle.wav");
	AddFileToDownloadsTable("sound/kodua/fortnite_emotes/emote_samba_new_B.wav");
	AddFileToDownloadsTable("sound/kodua/fortnite_emotes/athena_emote_makeitrain_music.mp3");
	AddFileToDownloadsTable("sound/kodua/fortnite_emotes/Athena_Emote_PopLock.wav");
	AddFileToDownloadsTable("sound/kodua/fortnite_emotes/Emote_PopRock_01.wav");
	AddFileToDownloadsTable("sound/kodua/fortnite_emotes/athena_emote_robot_music.wav");
	AddFileToDownloadsTable("sound/kodua/fortnite_emotes/athena_emote_salute_foley_01.mp3");
	AddFileToDownloadsTable("sound/kodua/fortnite_emotes/Emote_Snap1.mp3");
	AddFileToDownloadsTable("sound/kodua/fortnite_emotes/emote_stagebow.mp3");
	AddFileToDownloadsTable("sound/kodua/fortnite_emotes/Emote_Dino_Complete.mp3");
	AddFileToDownloadsTable("sound/kodua/fortnite_emotes/athena_emote_founders_music.wav");
	AddFileToDownloadsTable("sound/kodua/fortnite_emotes/athena_emotes_music_twist.wav");
	AddFileToDownloadsTable("sound/kodua/fortnite_emotes/Emote_Warehouse.wav");
	AddFileToDownloadsTable("sound/kodua/fortnite_emotes/Wiggle_Music_Loop.wav");
	AddFileToDownloadsTable("sound/kodua/fortnite_emotes/Emote_Yeet.mp3");
	AddFileToDownloadsTable("sound/kodua/fortnite_emotes/youre_awesome_emote_music.mp3");
	AddFileToDownloadsTable("sound/kodua/fortnite_emotes/athena_emotes_lankylegs_loop_02.wav");
	AddFileToDownloadsTable("sound/kodua/fortnite_emotes/eastern_bloc_musc_setup_d.wav");
	AddFileToDownloadsTable("sound/kodua/fortnite_emotes/athena_emote_hot_music.wav");
	PrecacheModel("models/player/custom_player/kodua/fortnite_emotes_v2.mdl", true);
	PrecacheSound("kodua/fortnite_emotes/ninja_dance_01.mp3");
	PrecacheSound("kodua/fortnite_emotes/dance_soldier_03.mp3");
	PrecacheSound("*/kodua/fortnite_emotes/hip_hop_good_vibes_mix_01_loop.wav");
	PrecacheSound("*/kodua/fortnite_emotes/emote_zippy_a.wav");
	PrecacheSound("*/kodua/fortnite_emotes/athena_emote_electroshuffle_music.wav");
	PrecacheSound("*/kodua/fortnite_emotes/emote_aerobics_01.wav");
	PrecacheSound("*/kodua/fortnite_emotes/athena_music_emotes_bendy.wav");
	PrecacheSound("*/kodua/fortnite_emotes/athena_emote_bandofthefort_music.wav");
	PrecacheSound("*/kodua/fortnite_emotes/emote_boogiedown.wav");
	PrecacheSound("kodua/fortnite_emotes/emote_capoeira.mp3");
	PrecacheSound("*/kodua/fortnite_emotes/athena_emote_flapper_music.wav");
	PrecacheSound("*/kodua/fortnite_emotes/athena_emote_chicken_foley_01.wav");
	PrecacheSound("kodua/fortnite_emotes/emote_cry.mp3");
	PrecacheSound("*/kodua/fortnite_emotes/athena_emote_music_boneless.wav");
	PrecacheSound("*/kodua/fortnite_emotes/athena_emotes_music_shoot_v7.wav");
	PrecacheSound("*/kodua/fortnite_emotes/Athena_Emotes_Music_SwipeIt.wav");
	PrecacheSound("*/kodua/fortnite_emotes/athena_emote_disco.wav");
	PrecacheSound("kodua/fortnite_emotes/athena_emote_worm_music.mp3");
	PrecacheSound("*/kodua/fortnite_emotes/athena_music_emotes_takethel.wav");
	PrecacheSound("kodua/fortnite_emotes/athena_emote_breakdance_music.mp3");
	PrecacheSound("*/kodua/fortnite_emotes/Emote_Dance_Pump.wav");
	PrecacheSound("kodua/fortnite_emotes/athena_emote_ridethepony_music_01.mp3");
	PrecacheSound("kodua/fortnite_emotes/athena_emote_facepalm_foley_01.mp3");
	PrecacheSound("kodua/fortnite_emotes/Athena_Emotes_OnTheHook_02.mp3");
	PrecacheSound("*/kodua/fortnite_emotes/athena_emote_floss_music.wav");
	PrecacheSound("kodua/fortnite_emotes/Emote_FlippnSexy.mp3");
	PrecacheSound("*/kodua/fortnite_emotes/athena_emote_fresh_music.wav");
	PrecacheSound("*/kodua/fortnite_emotes/emote_groove_jam_a.wav");
	PrecacheSound("*/kodua/fortnite_emotes/br_emote_shred_guitar_mix_03_loop.wav");
	PrecacheSound("kodua/fortnite_emotes/Emote_HeelClick.mp3");
	PrecacheSound("*/kodua/fortnite_emotes/s5_hiphop_breakin_132bmp_loop.wav");
	PrecacheSound("kodua/fortnite_emotes/Emote_Hotstuff.mp3");
	PrecacheSound("*/kodua/fortnite_emotes/emote_hula_01.wav");
	PrecacheSound("*/kodua/fortnite_emotes/athena_emote_infinidab.wav");
	PrecacheSound("*/kodua/fortnite_emotes/emote_Intensity.wav");
	PrecacheSound("*/kodua/fortnite_emotes/emote_irish_jig_foley_music_loop.wav");
	PrecacheSound("*/kodua/fortnite_emotes/Athena_Music_Emotes_KoreanEagle.wav");
	PrecacheSound("*/kodua/fortnite_emotes/emote_kpop_01.wav");
	PrecacheSound("kodua/fortnite_emotes/emote_laugh_01.mp3");
	PrecacheSound("*/kodua/fortnite_emotes/emote_LivingLarge_A.wav");
	PrecacheSound("kodua/fortnite_emotes/Emote_Luchador.mp3");
	PrecacheSound("*/kodua/fortnite_emotes/Emote_Hillbilly_Shuffle.wav");
	PrecacheSound("*/kodua/fortnite_emotes/emote_samba_new_B.wav");
	PrecacheSound("kodua/fortnite_emotes/athena_emote_makeitrain_music.mp3");
	PrecacheSound("*/kodua/fortnite_emotes/Athena_Emote_PopLock.wav");
	PrecacheSound("*/kodua/fortnite_emotes/Emote_PopRock_01.wav");
	PrecacheSound("*/kodua/fortnite_emotes/athena_emote_robot_music.wav");
	PrecacheSound("kodua/fortnite_emotes/athena_emote_salute_foley_01.mp3");
	PrecacheSound("kodua/fortnite_emotes/Emote_Snap1.mp3");
	PrecacheSound("kodua/fortnite_emotes/emote_stagebow.mp3");
	PrecacheSound("kodua/fortnite_emotes/Emote_Dino_Complete.mp3");
	PrecacheSound("*/kodua/fortnite_emotes/athena_emote_founders_music.wav");
	PrecacheSound("*/kodua/fortnite_emotes/athena_emotes_music_twist.wav");
	PrecacheSound("*/kodua/fortnite_emotes/Emote_Warehouse.wav");
	PrecacheSound("*/kodua/fortnite_emotes/Wiggle_Music_Loop.wav");
	PrecacheSound("kodua/fortnite_emotes/Emote_Yeet.mp3");
	PrecacheSound("kodua/fortnite_emotes/youre_awesome_emote_music.mp3");
	PrecacheSound("*/kodua/fortnite_emotes/athena_emotes_lankylegs_loop_02.wav");
	PrecacheSound("*/kodua/fortnite_emotes/eastern_bloc_musc_setup_d.wav");
	PrecacheSound("*/kodua/fortnite_emotes/athena_emote_hot_music.wav");
}

void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	
	if (IsValidClient(client))
	{
		ResetCam(client);
		StopEmote(client);
	}
}

void Event_PlayerHurt(Event event, const char[] name, bool dontBroadcast)
{
	int attacker = GetClientOfUserId(event.GetInt("attacker"));
	
	char sAttacker[16];
	GetEntityClassname(attacker, sAttacker, sizeof(sAttacker));
	if (StrEqual(sAttacker, "worldspawn")) //If player was killed by bomb
	{
		int client = GetClientOfUserId(event.GetInt("userid"));
		StopEmote(client);
	}
}

void Event_Start(Event event, const char[] name, bool dontBroadcast)
{
	for (int i = 1; i <= MaxClients; i++)
	if (IsValidClient(i, false) && g_bClientDancing[i]) {
		ResetCam(i);
		//StopEmote(client);
		WeaponUnblock(i);
		
		g_bClientDancing[i] = false;
	}
}

Action CreateEmote(int client, const char[] anim1, const char[] anim2, const char[] soundName, bool isLooped)
{
	if (!IsValidClient(client))
		return Plugin_Handled;
	
	if (!IsPlayerAlive(client))
	{
		CReplyToCommand(client, "%t", "MUST_BE_ALIVE");
		return Plugin_Handled;
	}
	
	if (!(GetEntityFlags(client) & FL_ONGROUND))
	{
		CReplyToCommand(client, "%t", "STAY_ON_GROUND");
		return Plugin_Handled;
	}
	
	if (GetEntProp(client, Prop_Send, "m_bIsScoped"))
	{
		CReplyToCommand(client, "%t", "SCOPE_DETECTED");
		return Plugin_Handled;
	}
	
	if (CooldownTimers[client])
	{
		CReplyToCommand(client, "%t", "COOLDOWN_EMOTES");
		return Plugin_Handled;
	}
	
	if (StrEqual(anim1, ""))
	{
		CReplyToCommand(client, "%t", "AMIN_1_INVALID");
		return Plugin_Handled;
	}
	
	if (g_iEmoteEnt[client])
		StopEmote(client);
	
	if (GetEntityMoveType(client) == MOVETYPE_NONE)
	{
		CReplyToCommand(client, "%t", "CANNOT_USE_NOW");
		return Plugin_Handled;
	}
	
	int EmoteEnt = CreateEntityByName("prop_dynamic");
	if (IsValidEntity(EmoteEnt))
	{
		SetEntityMoveType(client, MOVETYPE_NONE);
		WeaponBlock(client);
		
		float vec[3], ang[3];
		GetClientAbsOrigin(client, vec);
		GetClientAbsAngles(client, ang);
		
		g_fLastPosition[client] = vec;
		g_fLastAngles[client] = ang;
		
		char emoteEntName[16];
		FormatEx(emoteEntName, sizeof(emoteEntName), "emoteEnt%i", GetRandomInt(1000000, 9999999));
		
		DispatchKeyValue(EmoteEnt, "targetname", emoteEntName);
		DispatchKeyValue(EmoteEnt, "model", "models/player/custom_player/kodua/fortnite_emotes_v2.mdl");
		DispatchKeyValue(EmoteEnt, "solid", "0");
		DispatchKeyValue(EmoteEnt, "rendermode", "10");
		
		ActivateEntity(EmoteEnt);
		DispatchSpawn(EmoteEnt);
		
		TeleportEntity(EmoteEnt, vec, ang, NULL_VECTOR);
		
		SetVariantString(emoteEntName);
		AcceptEntityInput(client, "SetParent", client, client, 0);
		
		g_iEmoteEnt[client] = EntIndexToEntRef(EmoteEnt);
		
		int enteffects = GetEntProp(client, Prop_Send, "m_fEffects");
		enteffects |= 1; /* This is EF_BONEMERGE */
		enteffects |= 16; /* This is EF_NOSHADOW */
		enteffects |= 64; /* This is EF_NORECEIVESHADOW */
		enteffects |= 128; /* This is EF_BONEMERGE_FASTCULL */
		enteffects |= 512; /* This is EF_PARENT_ANIMATES */
		SetEntProp(client, Prop_Send, "m_fEffects", enteffects);
		
		//Sound
		
		if (g_cvEmotesSounds.BoolValue && !StrEqual(soundName, ""))
		{
			int EmoteSoundEnt = CreateEntityByName("info_target");
			if (IsValidEntity(EmoteSoundEnt))
			{
				char soundEntName[16];
				FormatEx(soundEntName, sizeof(soundEntName), "soundEnt%i", GetRandomInt(1000000, 9999999));
				
				DispatchKeyValue(EmoteSoundEnt, "targetname", soundEntName);
				
				DispatchSpawn(EmoteSoundEnt);
				
				vec[2] += 72.0;
				TeleportEntity(EmoteSoundEnt, vec, NULL_VECTOR, NULL_VECTOR);
				
				SetVariantString(emoteEntName);
				AcceptEntityInput(EmoteSoundEnt, "SetParent");
				
				g_iEmoteSoundEnt[client] = EntIndexToEntRef(EmoteSoundEnt);
				
				//Formatting sound path
				
				char soundNameBuffer[64];
				
				if (StrEqual(soundName, "ninja_dance_01") || StrEqual(soundName, "dance_soldier_03"))
				{
					int randomSound = GetRandomInt(0, 1);
					if (randomSound)
					{
						soundNameBuffer = "ninja_dance_01";
					} else
					{
						soundNameBuffer = "dance_soldier_03";
					}
				} else
				{
					FormatEx(soundNameBuffer, sizeof(soundNameBuffer), "%s", soundName);
				}
				
				if (isLooped)
				{
					FormatEx(g_sEmoteSound[client], PLATFORM_MAX_PATH, "*/kodua/fortnite_emotes/%s.wav", soundNameBuffer);
				} else
				{
					FormatEx(g_sEmoteSound[client], PLATFORM_MAX_PATH, "kodua/fortnite_emotes/%s.mp3", soundNameBuffer);
				}
				
				EmitSoundToAll(g_sEmoteSound[client], EmoteSoundEnt, SNDCHAN_AUTO, SNDLEVEL_CONVO, _, g_cvSoundVolume.FloatValue, _, _, vec, _, _, _);
			}
		}
		else
		{
			g_sEmoteSound[client] = "";
		}
		
		if (StrEqual(anim2, "none", false))
		{
			HookSingleEntityOutput(EmoteEnt, "OnAnimationDone", EndAnimation, true);
		} else
		{
			SetVariantString(anim2);
			AcceptEntityInput(EmoteEnt, "SetDefaultAnimation", -1, -1, 0);
		}
		
		SetVariantString(anim1);
		AcceptEntityInput(EmoteEnt, "SetAnimation", -1, -1, 0);
		
		SetCam(client);
		
		g_bClientDancing[client] = true;
		
		if (g_cvHidePlayers.BoolValue)
		{
			for (int i = 1; i <= MaxClients; i++)
			if (IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i) != GetClientTeam(client) && !g_bHooked[i])
			{
				SDKHook(i, SDKHook_SetTransmit, SetTransmit);
				g_bHooked[i] = true;
			}
		}
		
		
		if (g_cvCooldown.FloatValue > 0.0)
		{
			CooldownTimers[client] = CreateTimer(g_cvCooldown.FloatValue, ResetCooldown, client);
		}
	}
	
	return Plugin_Handled;
}

public Action OnPlayerRunCmd(int client, int &iButtons, int &iImpulse, float fVelocity[3], float fAngles[3], int &iWeapon)
{
	if (g_bClientDancing[client] && !(GetEntityFlags(client) & FL_ONGROUND))
		StopEmote(client);
	
	static int iAllowedButtons = IN_BACK | IN_FORWARD | IN_MOVELEFT | IN_MOVERIGHT | IN_WALK | IN_SPEED | IN_SCORE;
	
	if (iButtons == 0)
		return Plugin_Continue;
	
	if (g_iEmoteEnt[client] == 0)
		return Plugin_Continue;
	
	if ((iButtons & iAllowedButtons) && !(iButtons & ~iAllowedButtons))
		return Plugin_Continue;
	
	StopEmote(client);
	
	return Plugin_Continue;
}

void EndAnimation(const char[] output, int caller, int activator, float delay)
{
	if (caller > 0)
	{
		activator = GetEmoteActivator(EntIndexToEntRef(caller));
		StopEmote(activator);
	}
}

int GetEmoteActivator(int iEntRefDancer)
{
	if (iEntRefDancer == INVALID_ENT_REFERENCE)
		return 0;
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (g_iEmoteEnt[i] == iEntRefDancer)
		{
			return i;
		}
	}
	return 0;
}

void StopEmote(int client)
{
	if (!g_iEmoteEnt[client])
		return;
	
	int iEmoteEnt = EntRefToEntIndex(g_iEmoteEnt[client]);
	if (iEmoteEnt && iEmoteEnt != INVALID_ENT_REFERENCE && IsValidEntity(iEmoteEnt))
	{
		char emoteEntName[50];
		GetEntPropString(iEmoteEnt, Prop_Data, "m_iName", emoteEntName, sizeof(emoteEntName));
		SetVariantString(emoteEntName);
		AcceptEntityInput(client, "ClearParent", iEmoteEnt, iEmoteEnt, 0);
		DispatchKeyValue(iEmoteEnt, "OnUser1", "!self,Kill,,1.0,-1");
		AcceptEntityInput(iEmoteEnt, "FireUser1");
		
		if (g_cvTeleportBack.BoolValue)
			TeleportEntity(client, g_fLastPosition[client], g_fLastAngles[client], NULL_VECTOR);
		
		ResetCam(client);
		WeaponUnblock(client);
		SetEntityMoveType(client, MOVETYPE_WALK);
		
		g_iEmoteEnt[client] = 0;
		g_bClientDancing[client] = false;
	} else
	{
		g_iEmoteEnt[client] = 0;
		g_bClientDancing[client] = false;
	}
	
	if (g_iEmoteSoundEnt[client])
	{
		int iEmoteSoundEnt = EntRefToEntIndex(g_iEmoteSoundEnt[client]);
		
		if (!StrEqual(g_sEmoteSound[client], "") && iEmoteSoundEnt && iEmoteSoundEnt != INVALID_ENT_REFERENCE && IsValidEntity(iEmoteSoundEnt))
		{
			StopSound(iEmoteSoundEnt, SNDCHAN_AUTO, g_sEmoteSound[client]);
			AcceptEntityInput(iEmoteSoundEnt, "Kill");
			g_iEmoteSoundEnt[client] = 0;
		} else
		{
			g_iEmoteSoundEnt[client] = 0;
		}
	}
}

void TerminateEmote(int client)
{
	if (!g_iEmoteEnt[client])
		return;
	
	int iEmoteEnt = EntRefToEntIndex(g_iEmoteEnt[client]);
	if (iEmoteEnt && iEmoteEnt != INVALID_ENT_REFERENCE && IsValidEntity(iEmoteEnt))
	{
		char emoteEntName[50];
		GetEntPropString(iEmoteEnt, Prop_Data, "m_iName", emoteEntName, sizeof(emoteEntName));
		SetVariantString(emoteEntName);
		AcceptEntityInput(client, "ClearParent", iEmoteEnt, iEmoteEnt, 0);
		DispatchKeyValue(iEmoteEnt, "OnUser1", "!self,Kill,,1.0,-1");
		AcceptEntityInput(iEmoteEnt, "FireUser1");
		
		g_iEmoteEnt[client] = 0;
		g_bClientDancing[client] = false;
	} else
	{
		g_iEmoteEnt[client] = 0;
		g_bClientDancing[client] = false;
	}
	
	if (g_iEmoteSoundEnt[client])
	{
		int iEmoteSoundEnt = EntRefToEntIndex(g_iEmoteSoundEnt[client]);
		
		if (!StrEqual(g_sEmoteSound[client], "") && iEmoteSoundEnt && iEmoteSoundEnt != INVALID_ENT_REFERENCE && IsValidEntity(iEmoteSoundEnt))
		{
			StopSound(iEmoteSoundEnt, SNDCHAN_AUTO, g_sEmoteSound[client]);
			AcceptEntityInput(iEmoteSoundEnt, "Kill");
			g_iEmoteSoundEnt[client] = 0;
		} else
		{
			g_iEmoteSoundEnt[client] = 0;
		}
	}
}

void WeaponBlock(int client)
{
	SDKHook(client, SDKHook_WeaponCanUse, WeaponCanUseSwitch);
	SDKHook(client, SDKHook_WeaponSwitch, WeaponCanUseSwitch);
	
	if (g_cvHideWeapons.BoolValue)
		SDKHook(client, SDKHook_PostThinkPost, OnPostThinkPost);
	
	int iEnt = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
	if (iEnt != -1)
	{
		g_iWeaponHandEnt[client] = EntIndexToEntRef(iEnt);
		
		SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", -1);
	}
}

void WeaponUnblock(int client)
{
	SDKUnhook(client, SDKHook_WeaponCanUse, WeaponCanUseSwitch);
	SDKUnhook(client, SDKHook_WeaponSwitch, WeaponCanUseSwitch);
	
	//Even if are not activated, there will be no errors
	SDKUnhook(client, SDKHook_PostThinkPost, OnPostThinkPost);
	
	if (GetEmotePeople() == 0)
	{
		for (int i = 1; i <= MaxClients; i++)
		if (IsClientInGame(i) && g_bHooked[i])
		{
			SDKUnhook(i, SDKHook_SetTransmit, SetTransmit);
			g_bHooked[i] = false;
		}
	}
	
	if (IsPlayerAlive(client) && g_iWeaponHandEnt[client] != INVALID_ENT_REFERENCE)
	{
		int iEnt = EntRefToEntIndex(g_iWeaponHandEnt[client]);
		if (iEnt != INVALID_ENT_REFERENCE)
		{
			SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", iEnt);
		}
	}
	
	g_iWeaponHandEnt[client] = INVALID_ENT_REFERENCE;
}

Action WeaponCanUseSwitch(int client, int weapon)
{
	return Plugin_Stop;
}

void OnPostThinkPost(int client)
{
	SetEntProp(client, Prop_Send, "m_iAddonBits", 0);
}

public Action SetTransmit(int entity, int client)
{
	if (g_bClientDancing[client] && IsPlayerAlive(client) && GetClientTeam(client) != GetClientTeam(entity))return Plugin_Handled;
	
	return Plugin_Continue;
}

void SetCam(int client)
{
	ClientCommand(client, "cam_collision 0");
	ClientCommand(client, "cam_idealdist 100");
	ClientCommand(client, "cam_idealpitch 0");
	ClientCommand(client, "cam_idealyaw 0");
	ClientCommand(client, "thirdperson");
}

void ResetCam(int client)
{
	ClientCommand(client, "firstperson");
	ClientCommand(client, "cam_collision 1");
	ClientCommand(client, "cam_idealdist 150");
}

public Action Command_Menu(int client, int args)
{
	if (!IsValidClient(client))
		return Plugin_Handled;
	
	EmotesMenu(client);
	return Plugin_Handled;
}

Action EmotesMenu(int client)
{
	Menu menu = new Menu(MenuHandlerEmotes);
	
	char title[65];
	Format(title, sizeof(title), "%T:\n ", "TITLE_EMOTES_MENU", client);
	menu.SetTitle(title);
	
	if (Store_HasClientItem(client, itemids[1]))
		AddTranslatedMenuItem(menu, "1", "Emote_Fonzie_Pistol", client);
	if (Store_HasClientItem(client, itemids[2]))
		AddTranslatedMenuItem(menu, "2", "Emote_Bring_It_On", client);
	if (Store_HasClientItem(client, itemids[3]))
		AddTranslatedMenuItem(menu, "3", "Emote_ThumbsDown", client);
	if (Store_HasClientItem(client, itemids[4]))
		AddTranslatedMenuItem(menu, "4", "Emote_ThumbsUp", client);
	if (Store_HasClientItem(client, itemids[5]))
		AddTranslatedMenuItem(menu, "5", "Emote_Celebration_Loop", client);
	if (Store_HasClientItem(client, itemids[6]))
		AddTranslatedMenuItem(menu, "6", "Emote_BlowKiss", client);
	if (Store_HasClientItem(client, itemids[7]))
		AddTranslatedMenuItem(menu, "7", "Emote_Calculated", client);
	if (Store_HasClientItem(client, itemids[8]))
		AddTranslatedMenuItem(menu, "8", "Emote_Confused", client);
	if (Store_HasClientItem(client, itemids[9]))
		AddTranslatedMenuItem(menu, "9", "Emote_Chug", client);
	if (Store_HasClientItem(client, itemids[10]))
		AddTranslatedMenuItem(menu, "10", "Emote_Cry", client);
	if (Store_HasClientItem(client, itemids[11]))
		AddTranslatedMenuItem(menu, "11", "Emote_DustingOffHands", client);
	if (Store_HasClientItem(client, itemids[12]))
		AddTranslatedMenuItem(menu, "12", "Emote_DustOffShoulders", client);
	if (Store_HasClientItem(client, itemids[13]))
		AddTranslatedMenuItem(menu, "13", "Emote_Facepalm", client);
	if (Store_HasClientItem(client, itemids[14]))
		AddTranslatedMenuItem(menu, "14", "Emote_Fishing", client);
	if (Store_HasClientItem(client, itemids[15]))
		AddTranslatedMenuItem(menu, "15", "Emote_Flex", client);
	if (Store_HasClientItem(client, itemids[16]))
		AddTranslatedMenuItem(menu, "16", "Emote_golfclap", client);
	if (Store_HasClientItem(client, itemids[17]))
		AddTranslatedMenuItem(menu, "17", "Emote_HandSignals", client);
	if (Store_HasClientItem(client, itemids[18]))
		AddTranslatedMenuItem(menu, "18", "Emote_HeelClick", client);
	if (Store_HasClientItem(client, itemids[19]))
		AddTranslatedMenuItem(menu, "19", "Emote_Hotstuff", client);
	if (Store_HasClientItem(client, itemids[20]))
		AddTranslatedMenuItem(menu, "20", "Emote_IBreakYou", client);
	if (Store_HasClientItem(client, itemids[21]))
		AddTranslatedMenuItem(menu, "21", "Emote_IHeartYou", client);
	if (Store_HasClientItem(client, itemids[22]))
		AddTranslatedMenuItem(menu, "22", "Emote_Kung-Fu_Salute", client);
	if (Store_HasClientItem(client, itemids[23]))
		AddTranslatedMenuItem(menu, "23", "Emote_Laugh", client);
	if (Store_HasClientItem(client, itemids[24]))
		AddTranslatedMenuItem(menu, "24", "Emote_Luchador", client);
	if (Store_HasClientItem(client, itemids[25]))
		AddTranslatedMenuItem(menu, "25", "Emote_Make_It_Rain", client);
	if (Store_HasClientItem(client, itemids[26]))
		AddTranslatedMenuItem(menu, "26", "Emote_NotToday", client);
	if (Store_HasClientItem(client, itemids[27]))
		AddTranslatedMenuItem(menu, "27", "Emote_RockPaperScissor_Paper", client);
	if (Store_HasClientItem(client, itemids[28]))
		AddTranslatedMenuItem(menu, "28", "Emote_RockPaperScissor_Rock", client);
	if (Store_HasClientItem(client, itemids[29]))
		AddTranslatedMenuItem(menu, "29", "Emote_RockPaperScissor_Scissor", client);
	if (Store_HasClientItem(client, itemids[30]))
		AddTranslatedMenuItem(menu, "30", "Emote_Salt", client);
	if (Store_HasClientItem(client, itemids[31]))
		AddTranslatedMenuItem(menu, "31", "Emote_Salute", client);
	if (Store_HasClientItem(client, itemids[32]))
		AddTranslatedMenuItem(menu, "32", "Emote_SmoothDrive", client);
	if (Store_HasClientItem(client, itemids[33]))
		AddTranslatedMenuItem(menu, "33", "Emote_Snap", client);
	if (Store_HasClientItem(client, itemids[34]))
		AddTranslatedMenuItem(menu, "34", "Emote_StageBow", client);
	if (Store_HasClientItem(client, itemids[35]))
		AddTranslatedMenuItem(menu, "35", "Emote_Wave2", client);
	if (Store_HasClientItem(client, itemids[36]))
		AddTranslatedMenuItem(menu, "36", "Emote_Yeet", client);
	if (Store_HasClientItem(client, itemids[37]))
		AddTranslatedMenuItem(menu, "37", "DanceMoves", client);
	if (Store_HasClientItem(client, itemids[38]))
		AddTranslatedMenuItem(menu, "38", "Emote_Mask_Off_Intro", client);
	if (Store_HasClientItem(client, itemids[39]))
		AddTranslatedMenuItem(menu, "39", "Emote_Zippy_Dance", client);
	if (Store_HasClientItem(client, itemids[40]))
		AddTranslatedMenuItem(menu, "40", "ElectroShuffle", client);
	if (Store_HasClientItem(client, itemids[41]))
		AddTranslatedMenuItem(menu, "41", "Emote_AerobicChamp", client);
	if (Store_HasClientItem(client, itemids[42]))
		AddTranslatedMenuItem(menu, "42", "Emote_Bendy", client);
	if (Store_HasClientItem(client, itemids[43]))
		AddTranslatedMenuItem(menu, "43", "Emote_BandOfTheFort", client);
	if (Store_HasClientItem(client, itemids[44]))
		AddTranslatedMenuItem(menu, "44", "Emote_Boogie_Down_Intro", client);
	if (Store_HasClientItem(client, itemids[45]))
		AddTranslatedMenuItem(menu, "45", "Emote_Capoeira", client);
	if (Store_HasClientItem(client, itemids[46]))
		AddTranslatedMenuItem(menu, "46", "Emote_Charleston", client);
	if (Store_HasClientItem(client, itemids[47]))
		AddTranslatedMenuItem(menu, "47", "Emote_Chicken", client);
	if (Store_HasClientItem(client, itemids[48]))
		AddTranslatedMenuItem(menu, "48", "Emote_Dance_NoBones", client);
	if (Store_HasClientItem(client, itemids[49]))
		AddTranslatedMenuItem(menu, "49", "Emote_Dance_Shoot", client);
	if (Store_HasClientItem(client, itemids[50]))
		AddTranslatedMenuItem(menu, "50", "Emote_Dance_SwipeIt", client);
	if (Store_HasClientItem(client, itemids[51]))
		AddTranslatedMenuItem(menu, "51", "Emote_Dance_Disco_T3", client);
	if (Store_HasClientItem(client, itemids[52]))
		AddTranslatedMenuItem(menu, "52", "Emote_DG_Disco", client);
	if (Store_HasClientItem(client, itemids[53]))
		AddTranslatedMenuItem(menu, "53", "Emote_Dance_Worm", client);
	if (Store_HasClientItem(client, itemids[54]))
		AddTranslatedMenuItem(menu, "54", "Emote_Dance_Loser", client);
	if (Store_HasClientItem(client, itemids[55]))
		AddTranslatedMenuItem(menu, "55", "Emote_Dance_Breakdance", client);
	if (Store_HasClientItem(client, itemids[56]))
		AddTranslatedMenuItem(menu, "56", "Emote_Dance_Pump", client);
	if (Store_HasClientItem(client, itemids[57]))
		AddTranslatedMenuItem(menu, "57", "Emote_Dance_RideThePony", client);
	if (Store_HasClientItem(client, itemids[58]))
		AddTranslatedMenuItem(menu, "58", "Emote_Dab", client);
	if (Store_HasClientItem(client, itemids[59]))
		AddTranslatedMenuItem(menu, "59", "Emote_EasternBloc_Start", client);
	if (Store_HasClientItem(client, itemids[60]))
		AddTranslatedMenuItem(menu, "60", "Emote_FancyFeet", client);
	if (Store_HasClientItem(client, itemids[61]))
		AddTranslatedMenuItem(menu, "61", "Emote_FlossDance", client);
	if (Store_HasClientItem(client, itemids[62]))
		AddTranslatedMenuItem(menu, "62", "Emote_FlippnSexy", client);
	if (Store_HasClientItem(client, itemids[63]))
		AddTranslatedMenuItem(menu, "63", "Emote_Fresh", client);
	if (Store_HasClientItem(client, itemids[64]))
		AddTranslatedMenuItem(menu, "64", "Emote_GrooveJam", client);
	if (Store_HasClientItem(client, itemids[65]))
		AddTranslatedMenuItem(menu, "65", "Emote_guitar", client);
	if (Store_HasClientItem(client, itemids[66]))
		AddTranslatedMenuItem(menu, "66", "Emote_Hillbilly_Shuffle_Intro", client);
	if (Store_HasClientItem(client, itemids[67]))
		AddTranslatedMenuItem(menu, "67", "Emote_Hiphop_01", client);
	if (Store_HasClientItem(client, itemids[68]))
		AddTranslatedMenuItem(menu, "68", "Emote_Hula_Start", client);
	if (Store_HasClientItem(client, itemids[69]))
		AddTranslatedMenuItem(menu, "69", "Emote_InfiniDab_Intro", client);
	if (Store_HasClientItem(client, itemids[70]))
		AddTranslatedMenuItem(menu, "70", "Emote_Intensity_Start", client);
	if (Store_HasClientItem(client, itemids[71]))
		AddTranslatedMenuItem(menu, "71", "Emote_IrishJig_Start", client);
	if (Store_HasClientItem(client, itemids[72]))
		AddTranslatedMenuItem(menu, "72", "Emote_KoreanEagle", client);
	if (Store_HasClientItem(client, itemids[73]))
		AddTranslatedMenuItem(menu, "73", "Emote_Kpop_02", client);
	if (Store_HasClientItem(client, itemids[74]))
		AddTranslatedMenuItem(menu, "74", "Emote_LivingLarge", client);
	if (Store_HasClientItem(client, itemids[75]))
		AddTranslatedMenuItem(menu, "75", "Emote_Maracas", client);
	if (Store_HasClientItem(client, itemids[76]))
		AddTranslatedMenuItem(menu, "76", "Emote_PopLock", client);
	if (Store_HasClientItem(client, itemids[77]))
		AddTranslatedMenuItem(menu, "77", "Emote_PopRock", client);
	if (Store_HasClientItem(client, itemids[78]))
		AddTranslatedMenuItem(menu, "78", "Emote_RobotDance", client);
	if (Store_HasClientItem(client, itemids[79]))
		AddTranslatedMenuItem(menu, "79", "Emote_T-Rex", client);
	if (Store_HasClientItem(client, itemids[80]))
		AddTranslatedMenuItem(menu, "80", "Emote_TechnoZombie", client);
	if (Store_HasClientItem(client, itemids[81]))
		AddTranslatedMenuItem(menu, "81", "Emote_Twist", client);
	if (Store_HasClientItem(client, itemids[82]))
		AddTranslatedMenuItem(menu, "82", "Emote_WarehouseDance_Start", client);
	if (Store_HasClientItem(client, itemids[83]))
		AddTranslatedMenuItem(menu, "83", "Emote_Wiggle", client);
	if (Store_HasClientItem(client, itemids[84]))
		AddTranslatedMenuItem(menu, "84", "Emote_Youre_Awesome", client);
	
	menu.AddItem("X", "X", ITEMDRAW_NOTEXT);
	
	menu.ExitButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
	
	return Plugin_Handled;
}

int MenuHandlerEmotes(Menu menu, MenuAction action, int client, int param2)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			char info[16];
			if (menu.GetItem(param2, info, sizeof(info)))
			{
				if (Store_HasClientItem(client, itemids[StringToInt(info)]))
					PerformEmote(client, StringToInt(info));
			}
		}
		case MenuAction_End:
		{
			delete menu;
		}
	}
}

Action ResetCooldown(Handle timer, any client)
{
	CooldownTimers[client] = null;
}

public void EmoteReset()
{
	Emotes.Clear();
}

public bool EmoteConfig(Handle &kv, int itemid)
{
	char id[4];
	KvGetString(kv, "emoteid", id, 4);
	Store_SetDataIndex(itemid, Emotes.PushString(id));
	itemids[StringToInt(id)] = itemid;
	return true;
}

public int EmoteEquip(int client, int itemid)
{
	int index = Store_GetDataIndex(itemid);
	char id[4];
	Emotes.GetString(index, id, 4);
	PerformEmote(client, StringToInt(id));
	return 0;
}

public int EmoteRemove(int client, int itemid)
{
}

public void OnEntityCreated(int entity, const char[] classname)
{
	if (StrEqual(classname, "trigger_multiple"))
	{
		SDKHook(entity, SDKHook_StartTouch, OnTrigger);
		SDKHook(entity, SDKHook_EndTouch, OnTrigger);
		SDKHook(entity, SDKHook_Touch, OnTrigger);
	}
	else if (StrEqual(classname, "trigger_hurt"))
	{
		SDKHook(entity, SDKHook_StartTouch, OnTrigger);
		SDKHook(entity, SDKHook_EndTouch, OnTrigger);
		SDKHook(entity, SDKHook_Touch, OnTrigger);
	}
	else if (StrEqual(classname, "trigger_push"))
	{
		SDKHook(entity, SDKHook_StartTouch, OnTrigger);
		SDKHook(entity, SDKHook_EndTouch, OnTrigger);
		SDKHook(entity, SDKHook_Touch, OnTrigger);
	}
}

public Action OnTrigger(int entity, int other)
{
	if (0 < other <= MaxClients)
	{
		StopEmote(other);
	}
	return Plugin_Continue;
}

void AddTranslatedMenuItem(Menu menu, const char[] opt, const char[] phrase, int client)
{
	char buffer[128];
	Format(buffer, sizeof(buffer), "%T", phrase, client);
	menu.AddItem(opt, buffer);
}

stock bool IsValidClient(int client, bool nobots = true)
{
	if (client <= 0 || client > MaxClients || !IsClientConnected(client) || (nobots && IsFakeClient(client)))
	{
		return false;
	}
	return IsClientInGame(client);
}

int GetEmotePeople()
{
	int count;
	for (int i = 1; i <= MaxClients; i++)
	if (IsClientInGame(i) && g_bClientDancing[i])
		count++;
	
	return count;
}

void PerformEmote(int target, int amount)
{
	switch (amount)
	{
		case 1:
		CreateEmote(target, "Emote_Fonzie_Pistol", "none", "", false);
		case 2:
		CreateEmote(target, "Emote_Bring_It_On", "none", "", false);
		case 3:
		CreateEmote(target, "Emote_ThumbsDown", "none", "", false);
		case 4:
		CreateEmote(target, "Emote_ThumbsUp", "none", "", false);
		case 5:
		CreateEmote(target, "Emote_Celebration_Loop", "", "", false);
		case 6:
		CreateEmote(target, "Emote_BlowKiss", "none", "", false);
		case 7:
		CreateEmote(target, "Emote_Calculated", "none", "", false);
		case 8:
		CreateEmote(target, "Emote_Confused", "none", "", false);
		case 9:
		CreateEmote(target, "Emote_Chug", "none", "", false);
		case 10:
		CreateEmote(target, "Emote_Cry", "none", "emote_cry", false);
		case 11:
		CreateEmote(target, "Emote_DustingOffHands", "none", "athena_emote_bandofthefort_music", true);
		case 12:
		CreateEmote(target, "Emote_DustOffShoulders", "none", "athena_emote_hot_music", true);
		case 13:
		CreateEmote(target, "Emote_Facepalm", "none", "athena_emote_facepalm_foley_01", false);
		case 14:
		CreateEmote(target, "Emote_Fishing", "none", "Athena_Emotes_OnTheHook_02", false);
		case 15:
		CreateEmote(target, "Emote_Flex", "none", "", false);
		case 16:
		CreateEmote(target, "Emote_golfclap", "none", "", false);
		case 17:
		CreateEmote(target, "Emote_HandSignals", "none", "", false);
		case 18:
		CreateEmote(target, "Emote_HeelClick", "none", "Emote_HeelClick", false);
		case 19:
		CreateEmote(target, "Emote_Hotstuff", "none", "Emote_Hotstuff", false);
		case 20:
		CreateEmote(target, "Emote_IBreakYou", "none", "", false);
		case 21:
		CreateEmote(target, "Emote_IHeartYou", "none", "", false);
		case 22:
		CreateEmote(target, "Emote_Kung-Fu_Salute", "none", "", false);
		case 23:
		CreateEmote(target, "Emote_Laugh", "Emote_Laugh_CT", "emote_laugh_01.mp3", false);
		case 24:
		CreateEmote(target, "Emote_Luchador", "none", "Emote_Luchador", false);
		case 25:
		CreateEmote(target, "Emote_Make_It_Rain", "none", "athena_emote_makeitrain_music", false);
		case 26:
		CreateEmote(target, "Emote_NotToday", "none", "", false);
		case 27:
		CreateEmote(target, "Emote_RockPaperScissor_Paper", "none", "", false);
		case 28:
		CreateEmote(target, "Emote_RockPaperScissor_Rock", "none", "", false);
		case 29:
		CreateEmote(target, "Emote_RockPaperScissor_Scissor", "none", "", false);
		case 30:
		CreateEmote(target, "Emote_Salt", "none", "", false);
		case 31:
		CreateEmote(target, "Emote_Salute", "none", "athena_emote_salute_foley_01", false);
		case 32:
		CreateEmote(target, "Emote_SmoothDrive", "none", "", false);
		case 33:
		CreateEmote(target, "Emote_Snap", "none", "Emote_Snap1", false);
		case 34:
		CreateEmote(target, "Emote_StageBow", "none", "emote_stagebow", false);
		case 35:
		CreateEmote(target, "Emote_Wave2", "none", "", false);
		case 36:
		CreateEmote(target, "Emote_Yeet", "none", "Emote_Yeet", false);
		case 37:
		CreateEmote(target, "DanceMoves", "none", "ninja_dance_01", false);
		case 38:
		CreateEmote(target, "Emote_Mask_Off_Intro", "Emote_Mask_Off_Loop", "Hip_Hop_Good_Vibes_Mix_01_Loop", true);
		case 39:
		CreateEmote(target, "Emote_Zippy_Dance", "none", "emote_zippy_A", true);
		case 40:
		CreateEmote(target, "ElectroShuffle", "none", "athena_emote_electroshuffle_music", true);
		case 41:
		CreateEmote(target, "Emote_AerobicChamp", "none", "emote_aerobics_01", true);
		case 42:
		CreateEmote(target, "Emote_Bendy", "none", "athena_music_emotes_bendy", true);
		case 43:
		CreateEmote(target, "Emote_BandOfTheFort", "none", "athena_emote_bandofthefort_music", true);
		case 44:
		CreateEmote(target, "Emote_Boogie_Down_Intro", "Emote_Boogie_Down", "emote_boogiedown", true);
		case 45:
		CreateEmote(target, "Emote_Capoeira", "none", "emote_capoeira", false);
		case 46:
		CreateEmote(target, "Emote_Charleston", "none", "athena_emote_flapper_music", true);
		case 47:
		CreateEmote(target, "Emote_Chicken", "none", "athena_emote_chicken_foley_01", true);
		case 48:
		CreateEmote(target, "Emote_Dance_NoBones", "none", "athena_emote_music_boneless", true);
		case 49:
		CreateEmote(target, "Emote_Dance_Shoot", "none", "athena_emotes_music_shoot_v7", true);
		case 50:
		CreateEmote(target, "Emote_Dance_SwipeIt", "none", "Athena_Emotes_Music_SwipeIt", true);
		case 51:
		CreateEmote(target, "Emote_Dance_Disco_T3", "none", "athena_emote_disco", true);
		case 52:
		CreateEmote(target, "Emote_DG_Disco", "none", "athena_emote_disco", true);
		case 53:
		CreateEmote(target, "Emote_Dance_Worm", "none", "athena_emote_worm_music", false);
		case 54:
		CreateEmote(target, "Emote_Dance_Loser", "Emote_Dance_Loser_CT", "athena_music_emotes_takethel", true);
		case 55:
		CreateEmote(target, "Emote_Dance_Breakdance", "none", "athena_emote_breakdance_music", false);
		case 56:
		CreateEmote(target, "Emote_Dance_Pump", "none", "Emote_Dance_Pump", true);
		case 57:
		CreateEmote(target, "Emote_Dance_RideThePony", "none", "athena_emote_ridethepony_music_01", false);
		case 58:
		CreateEmote(target, "Emote_Dab", "none", "", false);
		case 59:
		CreateEmote(target, "Emote_EasternBloc_Start", "Emote_EasternBloc", "eastern_bloc_musc_setup_d", true);
		case 60:
		CreateEmote(target, "Emote_FancyFeet", "Emote_FancyFeet_CT", "athena_emotes_lankylegs_loop_02", true);
		case 61:
		CreateEmote(target, "Emote_FlossDance", "none", "athena_emote_floss_music", true);
		case 62:
		CreateEmote(target, "Emote_FlippnSexy", "none", "Emote_FlippnSexy", false);
		case 63:
		CreateEmote(target, "Emote_Fresh", "none", "athena_emote_fresh_music", true);
		case 64:
		CreateEmote(target, "Emote_GrooveJam", "none", "emote_groove_jam_a", true);
		case 65:
		CreateEmote(target, "Emote_guitar", "none", "br_emote_shred_guitar_mix_03_loop", true);
		case 66:
		CreateEmote(target, "Emote_Hillbilly_Shuffle_Intro", "Emote_Hillbilly_Shuffle", "Emote_Hillbilly_Shuffle", true);
		case 67:
		CreateEmote(target, "Emote_Hiphop_01", "Emote_Hip_Hop", "s5_hiphop_breakin_132bmp_loop", true);
		case 68:
		CreateEmote(target, "Emote_Hula_Start", "Emote_Hula", "emote_hula_01", true);
		case 69:
		CreateEmote(target, "Emote_InfiniDab_Intro", "Emote_InfiniDab_Loop", "athena_emote_infinidab", true);
		case 70:
		CreateEmote(target, "Emote_Intensity_Start", "Emote_Intensity_Loop", "emote_Intensity", true);
		case 71:
		CreateEmote(target, "Emote_IrishJig_Start", "Emote_IrishJig", "emote_irish_jig_foley_music_loop", true);
		case 72:
		CreateEmote(target, "Emote_KoreanEagle", "none", "Athena_Music_Emotes_KoreanEagle", true);
		case 73:
		CreateEmote(target, "Emote_Kpop_02", "none", "emote_kpop_01", true);
		case 74:
		CreateEmote(target, "Emote_LivingLarge", "none", "emote_LivingLarge_A", true);
		case 75:
		CreateEmote(target, "Emote_Maracas", "none", "emote_samba_new_B", true);
		case 76:
		CreateEmote(target, "Emote_PopLock", "none", "Athena_Emote_PopLock", true);
		case 77:
		CreateEmote(target, "Emote_PopRock", "none", "Emote_PopRock_01", true);
		case 78:
		CreateEmote(target, "Emote_RobotDance", "none", "athena_emote_robot_music", true);
		case 79:
		CreateEmote(target, "Emote_T-Rex", "none", "Emote_Dino_Complete", false);
		case 80:
		CreateEmote(target, "Emote_TechnoZombie", "none", "athena_emote_founders_music", true);
		case 81:
		CreateEmote(target, "Emote_Twist", "none", "athena_emotes_music_twist", true);
		case 82:
		CreateEmote(target, "Emote_WarehouseDance_Start", "Emote_WarehouseDance_Loop", "Emote_Warehouse", true);
		case 83:
		CreateEmote(target, "Emote_Wiggle", "none", "Wiggle_Music_Loop", true);
		case 84:
		CreateEmote(target, "Emote_Youre_Awesome", "none", "youre_awesome_emote_music", false);
	}
} 