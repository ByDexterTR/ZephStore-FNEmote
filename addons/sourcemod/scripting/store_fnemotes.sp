#include <sourcemod>
#include <store>

#pragma semicolon 1
#pragma newdecls required

public Plugin myinfo = 
{
	name = "ZephStore - FNEmotes", 
	author = "ByDexter", 
	description = "", 
	version = "1.0", 
	url = "https://steamcommunity.com/id/ByDexterTR - ByDexter#5494"
};

ArrayList Emotes;

public void OnPluginStart()
{
	Emotes = new ArrayList(85);
	
	Store_RegisterHandler("fnemote", "emoteid", EmoteOnMapStart, EmoteReset, EmoteConfig, EmoteEquip, EmoteRemove, false);
	
	AddCommandListener(BlockCommand, "sm_emotes");
	AddCommandListener(BlockCommand, "sm_emote");
	AddCommandListener(BlockCommand, "sm_dances");
	AddCommandListener(BlockCommand, "sm_dance");
}

public Action BlockCommand(int client, const char[] command, int argc)
{
	return Plugin_Stop;
}

public void EmoteOnMapStart()
{
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
	return true;
}

public int EmoteEquip(int client, int itemid)
{
	int index = Store_GetDataIndex(itemid);
	char id[4];
	Emotes.GetString(index, id, 4);
	ServerCommand("sm_setemote #%d %d", GetClientUserId(client), StringToInt(id));
	return 0;
}

public int EmoteRemove(int client, int itemid)
{
} 