#include <sourcemod>
#include <store>

#pragma semicolon 1
#pragma newdecls required

public Plugin myinfo = 
{
	name = "Günlük Kredi Limiti", 
	author = "ByDexter", 
	description = "", 
	version = "1.0", 
	url = "https://steamcommunity.com/id/ByDexterTR - ByDexter#5494"
};

ConVar g_limit = null;

public void OnPluginStart()
{
	CreateDirectory("addons/sourcemod/logs/gunluk-kredi", 511);
	LoadTranslations("common.phrases");
	
	AddCommandListener(CommandListener_Gift, "sm_hediye");
	AddCommandListener(CommandListener_Gift, "sm_gift");
	
	RegConsoleCmd("sm_limit", Command_Limit, "");
	for (int i = 1; i <= MaxClients; i++)if (IsClientInGame(i) && !IsFakeClient(i))
		OnClientPostAdminCheck(i);
	
	g_limit = CreateConVar("sm_dailycredit_limit", "10000", "Günlük Kaç Kredi atılsın?", 0, true, 1.0, false);
	AutoExecConfig(true, "Gunluk-KrediLimit", "ByDexter");
}

public void OnClientPostAdminCheck(int client)
{
	if (!DirExists("addons/sourcemod/logs/gunluk-kredi/"))
	{
		CreateDirectory("addons/sourcemod/logs/gunluk-kredi", 511);
	}
	char steamid[32], name[128], dosyayolu[256];
	
	FormatTime(dosyayolu, 256, "%F", GetTime());
	BuildPath(Path_SM, dosyayolu, sizeof(dosyayolu), "logs/gunluk-kredi/%s.log", dosyayolu);
	
	GetClientAuthId(client, AuthId_Steam2, steamid, 32);
	GetClientName(client, name, 128);
	ReplaceString(name, 128, "/", "");
	
	int Par;
	
	KeyValues kv = new KeyValues("Kredi");
	kv.ImportFromFile(dosyayolu);
	if (kv.JumpToKey(steamid, true))
	{
		kv.SetString("sonisim", name);
		Par = kv.GetNum("atilankredi", -1);
		if (Par == -1)
			kv.SetNum("atilankredi", 0);
		Par = kv.GetNum("alinankredi", -1);
		if (Par == -1)
			kv.SetNum("alinankredi", 0);
	}
	kv.Rewind();
	kv.ExportToFile(dosyayolu);
	delete kv;
}

public Action Command_Limit(int client, int args)
{
	char steamid[32], name[128], dosyayolu[256];
	
	FormatTime(dosyayolu, 256, "%F", GetTime());
	BuildPath(Path_SM, dosyayolu, sizeof(dosyayolu), "logs/gunluk-kredi/%s.log", dosyayolu);
	
	GetClientAuthId(client, AuthId_Steam2, steamid, 32);
	GetClientName(client, name, 128);
	ReplaceString(name, 128, "/", "");
	
	KeyValues kv = new KeyValues("Kredi");
	kv.ImportFromFile(dosyayolu);
	if (kv.JumpToKey(steamid, true))
	{
		kv.SetString("sonisim", name);
		int Par = kv.GetNum("atilankredi", 0);
		PrintToChat(client, "[SM] Kalan Kredi Limitin: \x05%d", g_limit.IntValue - Par);
	}
	kv.Rewind();
	kv.ExportToFile(dosyayolu);
	delete kv;
	return Plugin_Handled;
}

public Action CommandListener_Gift(int client, const char[] command, int argc)
{
	char arg2[64];
	GetCmdArg(2, arg2, 64);
	int Kredi = StringToInt(arg2);
	if (Store_GetClientCredits(client) < Kredi || Kredi <= 0)
	{
		return Plugin_Stop;
	}
	
	if (Kredi > g_limit.IntValue)
	{
		PrintToChat(client, "[SM] Günlük kredi limitini aşamazsın. (!limit)");
		return Plugin_Stop;
	}
	
	char arg1[128];
	GetCmdArg(1, arg1, 128);
	
	int Hedef = FindTarget(client, arg1, true, false);
	
	if (Hedef <= 0)
	{
		return Plugin_Stop;
	}
	
	
	char steamid[32], name[128], dosyayolu[256];
	
	int Par;
	
	FormatTime(dosyayolu, 256, "%F", GetTime());
	BuildPath(Path_SM, dosyayolu, sizeof(dosyayolu), "logs/gunluk-kredi/%s.log", dosyayolu);
	
	GetClientAuthId(client, AuthId_Steam2, steamid, 32);
	GetClientName(client, name, 128);
	ReplaceString(name, 128, "/", "");
	
	KeyValues kv = new KeyValues("Kredi");
	kv.ImportFromFile(dosyayolu);
	if (kv.JumpToKey(steamid, true))
	{
		kv.SetString("sonisim", name);
		Par = kv.GetNum("atilankredi", 0);
		if (Par == 0)
		{
			kv.SetNum("atilankredi", 0);
		}
		else if (Par == g_limit.IntValue)
		{
			PrintToChat(client, "[SM] Günlük kredi limitini aşamazsın. (!limit)");
			delete kv;
			return Plugin_Stop;
		}
		if (Kredi + Par > g_limit.IntValue)
		{
			PrintToChat(client, "[SM] Günlük kredi limitini aşamazsın. (!limit)");
			delete kv;
			return Plugin_Stop;
		}
		else
		{
			kv.SetNum("atilankredi", Kredi + Par);
		}
	}
	kv.Rewind();
	
	int Par2;
	
	GetClientAuthId(Hedef, AuthId_Steam2, steamid, 32);
	GetClientName(Hedef, name, 128);
	ReplaceString(name, 128, "/", "");
	if (kv.JumpToKey(steamid, true))
	{
		kv.SetString("sonisim", name);
		Par2 = kv.GetNum("alinankredi", 0);
		kv.SetNum("alinankredi", Par2 + Kredi + Par);
	}
	kv.Rewind();
	kv.ExportToFile(dosyayolu);
	
	delete kv;
	return Plugin_Continue;
} 