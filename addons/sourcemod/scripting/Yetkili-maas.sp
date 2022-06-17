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

ConVar Kredi = null, Flag = null;

char _flag[8];
char Dosya[256];

public void OnPluginStart()
{
	CreateDirectory("addons/sourcemod/ByDexter", 3);
	BuildPath(Path_SM, Dosya, sizeof(Dosya), "ByDexter/Yetkilimaas.txt");
	Kredi = CreateConVar("sm_maas_odul", "200", "Oyuncular maaş yazınca kaç kredi alacak", 0, true, 1.0);
	Flag = CreateConVar("sm_maas_harf", "a", "Hangi yetki harfi alsın"); Flag.GetString(_flag, 8); Flag.AddChangeHook(Flagget);
	RegConsoleCmd("sm_maas", Command_Maas);
	AutoExecConfig(true, "Yetkili-Maas", "ByDexter");
}

public void Flagget(ConVar convar, const char[] oldValue, const char[] newValue) { Flag.GetString(_flag, 8); }

public void OnMapStart()
{
	PrecacheSoundAny("ByDexter/maas/maas.mp3");
	AddFileToDownloadsTable("sound/ByDexter/maas/maas.mp3");
	PrecacheSoundAny("ByDexter/maas/nah.mp3");
	AddFileToDownloadsTable("sound/ByDexter/maas/nah.mp3");
}

public void OnClientPostAdminCheck(int client)
{
	if (CheckAdminFlag(client, _flag))
	{
		KeyValues kv = new KeyValues("ByDexter");
		kv.ImportFromFile(Dosya);
		char steamid[32];
		GetClientAuthId(client, AuthId_Steam2, steamid, 32);
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
	if (CheckAdminFlag(client, _flag))
	{
		KeyValues kv = new KeyValues("ByDexter");
		kv.ImportFromFile(Dosya);
		char steamid[32];
		GetClientAuthId(client, AuthId_Steam2, steamid, 32);
		if (kv.JumpToKey(steamid, true))
		{
			char Time[16];
			FormatTime(Time, 16, "%F", GetTime());
			char Sonalis[16];
			kv.GetString("last", Sonalis, 16, "none");
			if (strcmp(Sonalis, "none") == 0)
			{
				EmitSoundToClientAny(client, "ByDexter/maas/maas.mp3", SOUND_FROM_PLAYER, 1, 150);
				kv.SetString("last", Time);
				Store_SetClientCredits(client, Store_GetClientCredits(client) + Kredi.IntValue);
				PrintToChat(client, "[SM] \x01İlk maaşın hayırlı olsun, \x04%d Kredi", Kredi.IntValue);
			}
			else if (strcmp(Sonalis, Time) == 0)
			{
				EmitSoundToClientAny(client, "ByDexter/maas/nah.mp3", SOUND_FROM_PLAYER, 1, 150);
				ReplyToCommand(client, "[SM] Bugün zaten maaşını almışsın.");
			}
			else
			{
				EmitSoundToClientAny(client, "ByDexter/maas/maas.mp3", SOUND_FROM_PLAYER, 1, 150);
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
		EmitSoundToClientAny(client, "ByDexter/maas/nah.mp3", SOUND_FROM_PLAYER, 1, 150);
		ReplyToCommand(client, "[SM] Bu komutu kullanmak için yetkili olmalısın.");
		return Plugin_Handled;
	}
}

bool CheckAdminFlag(int client, const char[] flags)
{
	int iCount = 0;
	char sflagNeed[22][8], sflagFormat[64];
	bool bEntitled = false;
	Format(sflagFormat, sizeof(sflagFormat), flags);
	ReplaceString(sflagFormat, sizeof(sflagFormat), " ", "");
	iCount = ExplodeString(sflagFormat, ",", sflagNeed, sizeof(sflagNeed), sizeof(sflagNeed[]));
	for (int i = 0; i < iCount; i++)
	{
		if ((GetUserFlagBits(client) & ReadFlagString(sflagNeed[i])) || (GetUserFlagBits(client) & ADMFLAG_ROOT))
		{
			bEntitled = true;
			break;
		}
	}
	return bEntitled;
} 