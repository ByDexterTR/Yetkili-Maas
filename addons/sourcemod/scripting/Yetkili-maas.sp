#include <sourcemod>
#include <emitsoundany>
#include <store>

#pragma semicolon 1
#pragma newdecls required

public Plugin myinfo = 
{
	name = "Yetkili Maaş", 
	author = "ByDexter", 
	description = "", 
	version = "1.0", 
	url = "https://steamcommunity.com/id/ByDexterTR - ByDexter#5494"
};

ConVar Kredi = null;
static char Dosya[256];


public void OnPluginStart()
{
	Kredi = CreateConVar("sm_maas_odul", "5", "Oyuncular maaş yazınca kaç kredi alacak", 0, true, 1.0);
	RegConsoleCmd("sm_maas", Command_Maas);
	BuildPath(Path_SM, Dosya, sizeof(Dosya), "ByDexter/Yetkilimaas.txt");
	AutoExecConfig(true, "Yetkili-Maas", "ByDexter");
}

public void OnMapStart()
{
	PrecacheSoundAny("ByDexter/maas/nah.mp3");
	AddFileToDownloadsTable("sound/ByDexter/maas/nah.mp3");
	PrecacheSoundAny("ByDexter/maas/maas.mp3");
	AddFileToDownloadsTable("sound/ByDexter/maas/maas.mp3");
}

public void OnClientPostAdminCheck(int client)
{
	if (GetUserAdmin(client) != INVALID_ADMIN_ID)
	{
		KeyValues kv = new KeyValues("ByDexter");
		kv.ImportFromFile(Dosya);
		char steamid[128];
		GetClientAuthId(client, AuthId_Steam2, steamid, 128);
		if (kv.JumpToKey(steamid, true))
		{
			char Time[20];
			FormatTime(Time, 20, "%j", GetTime());
			char Sonalis[20];
			kv.GetString("last", Sonalis, 20, "none");
			if (strcmp(Sonalis, "none") == 0)
			{
				PrintToChat(client, "[SM] \x01İlk maaşın seni bekliyor \x04!maas");
			}
			else if (StringToInt(Sonalis) != StringToInt(Time))
			{
				PrintToChat(client, "[SM] \x01Maaşın hesabına yatırılmış \x04!maas");
			}
		}
		kv.Rewind();
		kv.ExportToFile(Dosya);
		delete kv;
	}
}

public Action Command_Maas(int client, int args)
{
	if (GetUserAdmin(client) != INVALID_ADMIN_ID)
	{
		KeyValues kv = new KeyValues("ByDexter");
		kv.ImportFromFile(Dosya);
		char steamid[128];
		GetClientAuthId(client, AuthId_Steam2, steamid, 128);
		if (kv.JumpToKey(steamid, true))
		{
			char Time[20];
			FormatTime(Time, 20, "%j", GetTime());
			char Sonalis[20];
			kv.GetString("last", Sonalis, 20, "none");
			if (strcmp(Sonalis, "none") == 0)
			{
				EmitSoundToClientAny(client, "ByDexter/maas/maas.mp3", SOUND_FROM_PLAYER, 1, 100);
				kv.SetString("last", Time);
				Store_SetClientCredits(client, Store_GetClientCredits(client) + Kredi.IntValue);
				PrintToChat(client, "[SM] \x01İlk maaşın hayırlı olsun, \x04%d Kredi", Kredi.IntValue);
			}
			else if (StringToInt(Sonalis) == StringToInt(Time))
			{
				EmitSoundToClientAny(client, "ByDexter/maas/nah.mp3", SOUND_FROM_PLAYER, 1, 100);
				ReplyToCommand(client, "[SM] Bugün zaten maaşını almışsın.");
			}
			else
			{
				EmitSoundToClientAny(client, "ByDexter/maas/maas.mp3", SOUND_FROM_PLAYER, 1, 100);
				kv.SetString("last", Time);
				Store_SetClientCredits(client, Store_GetClientCredits(client) + Kredi.IntValue);
				PrintToChat(client, "[SM] \x01Maaşını çektin, \x04%d Kredi", Kredi.IntValue);
			}
		}
		kv.Rewind();
		kv.ExportToFile(Dosya);
		delete kv;
		return Plugin_Handled;
	}
	else
	{
		EmitSoundToClientAny(client, "ByDexter/maas/nah.mp3", SOUND_FROM_PLAYER, 1, 100);
		ReplyToCommand(client, "[SM] Bu komutu kullanmak için yetkili olmalısın.");
		return Plugin_Handled;
	}
} 