#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <cstrike>
#include <basecomm>
#include <lvl_ranks>

#pragma newdecls optional
#include <clientmod>
#include <clientmod/multicolors>
#pragma newdecls required

public Plugin myinfo =
{
    name = "Levels Ranks Team Chat",
    author = "Woobbie",
    description = "",
    version = "3.5.1"
};

ConVar g_cvEnablePlugin;
ConVar g_cvEnableGeneral;
ConVar g_cvEnableTeamChat;
ConVar g_cvShowRankTag;
ConVar g_cvShowTeamTag;
ConVar g_cvShowTeamText;
ConVar g_cvSeparator;
ConVar g_cvShowRankTeamSeparator;
ConVar g_cvRankTeamSeparator;
ConVar g_cvShowNameTeamSeparator;
ConVar g_cvNameTeamSeparator;
ConVar g_cvTeamTagPosition;
ConVar g_cvColorRankTag;
ConVar g_cvColorTeamText;
ConVar g_cvColorTTag;
ConVar g_cvColorCTTag;
ConVar g_cvColorSpecTag;
ConVar g_cvColorTName;
ConVar g_cvColorCTName;
ConVar g_cvColorSpecName;
ConVar g_cvColorTMsg;
ConVar g_cvColorCTMsg;
ConVar g_cvColorSpecMsg;
ConVar g_cvColorDefaultMsg;

bool g_bProcessing[MAXPLAYERS + 1];

char g_sRankTags[128][64];
char g_sRankColors[128][16];
int g_iRankTagCount = 0;

char g_sColorRankTag[16];
char g_sColorTeamText[16];
char g_sColorTTag[16];
char g_sColorCTTag[16];
char g_sColorSpecTag[16];
char g_sColorTName[16];
char g_sColorCTName[16];
char g_sColorSpecName[16];
char g_sColorTMsg[16];
char g_sColorCTMsg[16];
char g_sColorSpecMsg[16];
char g_sColorDefaultMsg[16];

#define COLOR_WHITE "\x01"

// OnPluginStart

public void OnPluginStart()
{
    g_cvEnablePlugin   = CreateConVar("sm_lr_tags_enable", "1", "Enable plugin", FCVAR_NOTIFY, true, 0.0, true, 1.0);
    g_cvEnableGeneral  = CreateConVar("sm_lr_tags_general", "1", "Enable normal chat formatting", FCVAR_NOTIFY, true, 0.0, true, 1.0);
    g_cvEnableTeamChat = CreateConVar("sm_lr_tags_teamchat", "1", "Enable team chat formatting", FCVAR_NOTIFY, true, 0.0, true, 1.0);

    g_cvShowRankTag    = CreateConVar("sm_lr_tags_show_rank", "1", "Show Levels Ranks tag", FCVAR_NOTIFY, true, 0.0, true, 1.0);
    g_cvShowTeamTag    = CreateConVar("sm_lr_tags_show_teamtag", "1", "Show team tag [T]/[CT]/[SPEC]", FCVAR_NOTIFY, true, 0.0, true, 1.0);
    g_cvShowTeamText   = CreateConVar("sm_lr_tags_show_teamtext", "0", "Show (TEAM) in team chat", FCVAR_NOTIFY, true, 0.0, true, 1.0);
    g_cvSeparator      = CreateConVar("sm_lr_tags_separator", ">", "Legacy separator between rank tag and team tag");

    g_cvShowRankTeamSeparator = CreateConVar("sm_lr_tags_show_rank_team_separator", "1", "Show separator between rank tag and team tag", FCVAR_NOTIFY, true, 0.0, true, 1.0);
    g_cvRankTeamSeparator     = CreateConVar("sm_lr_tags_rank_team_separator", ">", "Separator between rank tag and team tag");
    g_cvShowNameTeamSeparator = CreateConVar("sm_lr_tags_show_name_team_separator", "1", "Show separator between team tag and player name when team tag is before name, or between player name and team tag when team tag is after name", FCVAR_NOTIFY, true, 0.0, true, 1.0);
    g_cvNameTeamSeparator     = CreateConVar("sm_lr_tags_name_team_separator", ">", "Separator between team tag and player name (before_name) or player name and team tag (after_name)");
    g_cvTeamTagPosition       = CreateConVar("sm_lr_tags_teamtag_position", "before_name", "Team tag position: before_name or after_name");

    g_cvColorRankTag   = CreateConVar("sm_lr_tags_color_rank", "#CBB8D9", "Default rank tag color");
    g_cvColorTeamText  = CreateConVar("sm_lr_tags_color_teamtext", "#5C9E9A", "(TEAM) text color");
    g_cvColorTTag      = CreateConVar("sm_lr_tags_color_t_tag", "#C98B47", "T tag color");
    g_cvColorCTTag     = CreateConVar("sm_lr_tags_color_ct_tag", "#5E81AC", "CT tag color");
    g_cvColorSpecTag   = CreateConVar("sm_lr_tags_color_spec_tag", "#C97B63", "SPEC tag color");
    g_cvColorTName     = CreateConVar("sm_lr_tags_color_t_name", "#9DBA8A", "T player name color");
    g_cvColorCTName    = CreateConVar("sm_lr_tags_color_ct_name", "#7FA6C9", "CT player name color");
    g_cvColorSpecName  = CreateConVar("sm_lr_tags_color_spec_name", "#D9B86C", "SPEC player name color");
    g_cvColorTMsg      = CreateConVar("sm_lr_tags_color_t_msg", "default", "T message color");
    g_cvColorCTMsg     = CreateConVar("sm_lr_tags_color_ct_msg", "default", "CT message color");
    g_cvColorSpecMsg   = CreateConVar("sm_lr_tags_color_spec_msg", "default", "SPEC message color");
    g_cvColorDefaultMsg= CreateConVar("sm_lr_tags_color_default_msg", "default", "Default message color");

    AutoExecConfig(true, "lr_teamtags", "sourcemod");

    HookAllColorCvars();

    RegAdminCmd("sm_lr_reloadtags", Command_ReloadTags, ADMFLAG_ROOT, "Reload LR tags.ini");
    RegAdminCmd("sm_lr_reloadrankcolors", Command_ReloadRankColors, ADMFLAG_ROOT, "Reload rank_colors.ini");
    RegAdminCmd("sm_lr_reloadchatcfg", Command_ReloadChatCfg, ADMFLAG_ROOT, "Reload LR chat cfg cache");

    AddCommandListener(Command_Say, "say");
    AddCommandListener(Command_Say, "say_team");

    LoadRankTagsExact();
    LoadRankColors();
    RefreshColorCache();

    PrintToServer("[LR Team Chat Tags] Loaded successfully.");
}

// HookAllColorCvars

void HookAllColorCvars()
{
    HookConVarChange(g_cvColorRankTag, ConVarChanged_ReloadColors);
    HookConVarChange(g_cvColorTeamText, ConVarChanged_ReloadColors);
    HookConVarChange(g_cvColorTTag, ConVarChanged_ReloadColors);
    HookConVarChange(g_cvColorCTTag, ConVarChanged_ReloadColors);
    HookConVarChange(g_cvColorSpecTag, ConVarChanged_ReloadColors);
    HookConVarChange(g_cvColorTName, ConVarChanged_ReloadColors);
    HookConVarChange(g_cvColorCTName, ConVarChanged_ReloadColors);
    HookConVarChange(g_cvColorSpecName, ConVarChanged_ReloadColors);
    HookConVarChange(g_cvColorTMsg, ConVarChanged_ReloadColors);
    HookConVarChange(g_cvColorCTMsg, ConVarChanged_ReloadColors);
    HookConVarChange(g_cvColorSpecMsg, ConVarChanged_ReloadColors);
    HookConVarChange(g_cvColorDefaultMsg, ConVarChanged_ReloadColors);
}

// ConVarChanged_ReloadColors

public void ConVarChanged_ReloadColors(ConVar convar, const char[] oldValue, const char[] newValue)
{
    RefreshColorCache();
}

// OnClientDisconnect

public void OnClientDisconnect(int client)
{
    g_bProcessing[client] = false;
}

// Command_ReloadTags

public Action Command_ReloadTags(int client, int args)
{
    LoadRankTagsExact();
    ReplyToCommand(client, "[LR Tags] tags.ini reloaded.");
    return Plugin_Handled;
}

// Command_ReloadRankColors

public Action Command_ReloadRankColors(int client, int args)
{
    LoadRankColors();
    ReplyToCommand(client, "[LR Tags] rank_colors.ini reloaded.");
    return Plugin_Handled;
}

// Command_ReloadChatCfg

public Action Command_ReloadChatCfg(int client, int args)
{
    RefreshColorCache();
    ReplyToCommand(client, "[LR Tags] chat cfg cache reloaded.");
    return Plugin_Handled;
}

// IsHexChar

bool IsHexChar(char c)
{
    return ((c >= '0' && c <= '9') ||
            (c >= 'A' && c <= 'F') ||
            (c >= 'a' && c <= 'f'));
}

// NormalizeColorString

void NormalizeColorString(const char[] input, char[] output, int maxlen)
{
    output[0] = '\0';

    char value[32];
    strcopy(value, sizeof(value), input);
    TrimString(value);

    static const char sColorNames[][] = {
        "default", "darkred", "green", "lightgreen", "red", "blue", "white", "olive"
    };

    if (!value[0])
    {
        strcopy(output, maxlen, "{default}");
        return;
    }

    if (value[0] == '{')
    {
        strcopy(output, maxlen, value);
        return;
    }

    for (int i = 0; i < sizeof(sColorNames); i++)
    {
        if (StrEqual(value, sColorNames[i], false))
        {
            Format(output, maxlen, "{%s}", sColorNames[i]);
            return;
        }
    }

    if (StrEqual(value, "\\x01", false) || StrEqual(value, "\x01", false))
    {
        strcopy(output, maxlen, "{default}");
        return;
    }

    if (StrContains(value, "\\x07", false) == 0 && strlen(value) == 10)
    {
        char hexPart[7];
        strcopy(hexPart, sizeof(hexPart), value[4]);

        for (int i = 0; i < 6; i++)
        {
            if (!IsHexChar(hexPart[i]))
            {
                strcopy(output, maxlen, "{default}");
                return;
            }
            hexPart[i] = CharToUpper(hexPart[i]);
        }

        Format(output, maxlen, "\x07%s", hexPart);
        return;
    }

    char hex[7];

    if (value[0] == '#')
    {
        if (strlen(value) != 7)
        {
            strcopy(output, maxlen, "{default}");
            return;
        }

        for (int i = 0; i < 6; i++)
        {
            hex[i] = value[i + 1];
            if (!IsHexChar(hex[i]))
            {
                strcopy(output, maxlen, "{default}");
                return;
            }
            hex[i] = CharToUpper(hex[i]);
        }
        hex[6] = '\0';

        Format(output, maxlen, "\x07%s", hex);
        return;
    }

    if (strlen(value) == 6)
    {
        for (int i = 0; i < 6; i++)
        {
            hex[i] = value[i];
            if (!IsHexChar(hex[i]))
            {
                strcopy(output, maxlen, "{default}");
                return;
            }
            hex[i] = CharToUpper(hex[i]);
        }
        hex[6] = '\0';

        Format(output, maxlen, "\x07%s", hex);
        return;
    }

    strcopy(output, maxlen, "{default}");
}

// GetConVarEasyColor

void GetConVarEasyColor(ConVar cvar, char[] output, int maxlen)
{
    char value[32];
    GetConVarString(cvar, value, sizeof(value));
    NormalizeColorString(value, output, maxlen);
}

// RefreshColorCache

void RefreshColorCache()
{
    GetConVarEasyColor(g_cvColorRankTag, g_sColorRankTag, sizeof(g_sColorRankTag));
    GetConVarEasyColor(g_cvColorTeamText, g_sColorTeamText, sizeof(g_sColorTeamText));
    GetConVarEasyColor(g_cvColorTTag, g_sColorTTag, sizeof(g_sColorTTag));
    GetConVarEasyColor(g_cvColorCTTag, g_sColorCTTag, sizeof(g_sColorCTTag));
    GetConVarEasyColor(g_cvColorSpecTag, g_sColorSpecTag, sizeof(g_sColorSpecTag));
    GetConVarEasyColor(g_cvColorTName, g_sColorTName, sizeof(g_sColorTName));
    GetConVarEasyColor(g_cvColorCTName, g_sColorCTName, sizeof(g_sColorCTName));
    GetConVarEasyColor(g_cvColorSpecName, g_sColorSpecName, sizeof(g_sColorSpecName));
    GetConVarEasyColor(g_cvColorTMsg, g_sColorTMsg, sizeof(g_sColorTMsg));
    GetConVarEasyColor(g_cvColorCTMsg, g_sColorCTMsg, sizeof(g_sColorCTMsg));
    GetConVarEasyColor(g_cvColorSpecMsg, g_sColorSpecMsg, sizeof(g_sColorSpecMsg));
    GetConVarEasyColor(g_cvColorDefaultMsg, g_sColorDefaultMsg, sizeof(g_sColorDefaultMsg));
}

// LoadRankTagsExact

void LoadRankTagsExact()
{
    g_iRankTagCount = 0;

    for (int i = 0; i < sizeof(g_sRankTags); i++)
    {
        g_sRankTags[i][0] = '\0';
    }

    char sPath[PLATFORM_MAX_PATH];
    BuildPath(Path_SM, sPath, sizeof(sPath), "configs/levels_ranks/tags.ini");

    KeyValues kv = new KeyValues("LR_Tags");

    if (!kv.ImportFromFile(sPath))
    {
        SetFailState("[LR Tags] Could not read file: %s", sPath);
        return;
    }

    if (!kv.JumpToKey("Tags"))
    {
        delete kv;
        SetFailState("[LR Tags] Section 'Tags' not found in %s", sPath);
        return;
    }

    char sKey[16];
    for (int rank = 1; rank <= sizeof(g_sRankTags); rank++)
    {
        IntToString(rank, sKey, sizeof(sKey));

        if (kv.JumpToKey(sKey, false))
        {
            kv.GetString("tag", g_sRankTags[rank - 1], sizeof(g_sRankTags[]), "");
            if (g_sRankTags[rank - 1][0] != '\0')
            {
                g_iRankTagCount = rank;
            }
            kv.GoBack();
        }
    }

    delete kv;
    PrintToServer("[LR Tags] Loaded %d rank tags from tags.ini", g_iRankTagCount);
}

// LoadRankColors

void LoadRankColors()
{
    for (int i = 0; i < sizeof(g_sRankColors); i++)
    {
        g_sRankColors[i][0] = '\0';
    }

    char sPath[PLATFORM_MAX_PATH];
    BuildPath(Path_SM, sPath, sizeof(sPath), "configs/levels_ranks/rank_colors.ini");

    KeyValues kv = new KeyValues("RankColors");

    if (!kv.ImportFromFile(sPath))
    {
        PrintToServer("[LR Tags] rank_colors.ini not found, using default rank color.");
        delete kv;
        return;
    }

    char sKey[16];
    char rawColor[32];

    for (int rank = 1; rank <= sizeof(g_sRankColors); rank++)
    {
        IntToString(rank, sKey, sizeof(sKey));

        if (kv.JumpToKey(sKey, false))
        {
            kv.GetString("color", rawColor, sizeof(rawColor), "");
            NormalizeColorString(rawColor, g_sRankColors[rank - 1], sizeof(g_sRankColors[]));
            kv.GoBack();
        }
    }

    delete kv;
    PrintToServer("[LR Tags] Rank colors loaded successfully.");
}

// GetRankTag

void GetRankTag(int client, char[] buffer, int maxlen)
{
    buffer[0] = '\0';

    if (!GetConVarBool(g_cvShowRankTag))
        return;

    if (client < 1 || client > MaxClients || !IsClientInGame(client))
        return;

    if (!LibraryExists("levelsranks"))
        return;

    int rank = LR_GetClientInfo(client, ST_RANK);
    if (rank <= 0)
        return;

    int index = rank - 1;
    if (index < 0 || index >= sizeof(g_sRankTags))
        return;

    if (!g_sRankTags[index][0])
        return;

    char rankColor[16];
    if (g_sRankColors[index][0] != '\0')
    {
        strcopy(rankColor, sizeof(rankColor), g_sRankColors[index]);
    }
    else
    {
        strcopy(rankColor, sizeof(rankColor), g_sColorRankTag);
    }

    Format(buffer, maxlen, "%s%s%s", rankColor, g_sRankTags[index], COLOR_WHITE);
}

// GetTeamPrefix

void GetTeamPrefix(int client, char[] buffer, int maxlen)
{
    buffer[0] = '\0';

    if (!GetConVarBool(g_cvShowTeamTag))
        return;

    switch (GetClientTeam(client))
    {
        case CS_TEAM_T:
        {
            Format(buffer, maxlen, "%s[T]%s", g_sColorTTag, COLOR_WHITE);
        }
        case CS_TEAM_CT:
        {
            Format(buffer, maxlen, "%s[CT]%s", g_sColorCTTag, COLOR_WHITE);
        }
        case CS_TEAM_SPECTATOR:
        {
            Format(buffer, maxlen, "%s[SPEC]%s", g_sColorSpecTag, COLOR_WHITE);
        }
        default:
        {
            buffer[0] = '\0';
        }
    }
}

// GetNameColor

void GetNameColor(int client, char[] buffer, int maxlen)
{
    switch (GetClientTeam(client))
    {
        case CS_TEAM_T:
        {
            strcopy(buffer, maxlen, g_sColorTName);
        }
        case CS_TEAM_CT:
        {
            strcopy(buffer, maxlen, g_sColorCTName);
        }
        case CS_TEAM_SPECTATOR:
        {
            strcopy(buffer, maxlen, g_sColorSpecName);
        }
        default:
        {
            strcopy(buffer, maxlen, COLOR_WHITE);
        }
    }
}

// GetMessageColor

void GetMessageColor(int client, char[] buffer, int maxlen)
{
    switch (GetClientTeam(client))
    {
        case CS_TEAM_T:
        {
            strcopy(buffer, maxlen, g_sColorTMsg);
        }
        case CS_TEAM_CT:
        {
            strcopy(buffer, maxlen, g_sColorCTMsg);
        }
        case CS_TEAM_SPECTATOR:
        {
            strcopy(buffer, maxlen, g_sColorSpecMsg);
        }
        default:
        {
            strcopy(buffer, maxlen, g_sColorDefaultMsg);
        }
    }
}

// IsFormattedMessage

bool IsFormattedMessage(const char[] text)
{
    if (StrContains(text, "[CT]", false) != -1)   return true;
    if (StrContains(text, "[T]", false) != -1)    return true;
    if (StrContains(text, "[SPEC]", false) != -1) return true;
    if (StrContains(text, "(TEAM)", false) != -1) return true;
    return false;
}

// Command_Say

public Action Command_Say(int client, const char[] command, int argc)
{
    if (!GetConVarBool(g_cvEnablePlugin))
        return Plugin_Continue;

    if (client < 1 || client > MaxClients || !IsClientInGame(client))
        return Plugin_Continue;

    if (IsFakeClient(client))
        return Plugin_Continue;

    if (BaseComm_IsClientGagged(client))
        return Plugin_Handled;

    if (g_bProcessing[client])
        return Plugin_Handled;

    char message[256];
    GetCmdArgString(message, sizeof(message));
    StripQuotes(message);
    TrimString(message);

    if (!message[0])
        return Plugin_Handled;

    if (IsFormattedMessage(message))
        return Plugin_Continue;

    bool teamChat = StrEqual(command, "say_team", false);

    if (teamChat && !GetConVarBool(g_cvEnableTeamChat))
        return Plugin_Continue;

    if (!teamChat && !GetConVarBool(g_cvEnableGeneral))
        return Plugin_Continue;

    char rankTag[96], teamTag[32], teamText[32], nameColor[16], msgColor[16];
    char playerName[MAX_NAME_LENGTH], out[768];
    char rankTeamSeparator[32], nameTeamSeparator[32], teamTagPosition[32], legacySeparator[32];

    GetRankTag(client, rankTag, sizeof(rankTag));
    GetTeamPrefix(client, teamTag, sizeof(teamTag));
    GetNameColor(client, nameColor, sizeof(nameColor));
    GetMessageColor(client, msgColor, sizeof(msgColor));
    GetClientName(client, playerName, sizeof(playerName));

    GetConVarString(g_cvRankTeamSeparator, rankTeamSeparator, sizeof(rankTeamSeparator));
    GetConVarString(g_cvNameTeamSeparator, nameTeamSeparator, sizeof(nameTeamSeparator));
    GetConVarString(g_cvTeamTagPosition, teamTagPosition, sizeof(teamTagPosition));
    GetConVarString(g_cvSeparator, legacySeparator, sizeof(legacySeparator));

    if (!rankTeamSeparator[0])
    {
        strcopy(rankTeamSeparator, sizeof(rankTeamSeparator), legacySeparator);
    }

    if (teamChat && GetConVarBool(g_cvShowTeamText))
    {
        Format(teamText, sizeof(teamText), "%s(TEAM)%s ", g_sColorTeamText, COLOR_WHITE);
    }
    else
    {
        teamText[0] = '\0';
    }

    bool hasRank = (rankTag[0] != '\0');
    bool hasTeam = (teamTag[0] != '\0');
    bool showRankSep = GetConVarBool(g_cvShowRankTeamSeparator) && hasRank && hasTeam;
    bool showNameSep = GetConVarBool(g_cvShowNameTeamSeparator) && hasTeam;
    bool tagAfterName = StrEqual(teamTagPosition, "after_name", false);

    if (!tagAfterName)
    {
        if (hasRank && hasTeam)
        {
            if (showRankSep && showNameSep)
            {
                Format(out, sizeof(out), "%s %s %s%s %s %s%s%s : %s%s",
                    rankTag,
                    rankTeamSeparator,
                    teamText, teamTag,
                    nameTeamSeparator,
                    nameColor, playerName, COLOR_WHITE,
                    msgColor, message);
            }
            else if (showRankSep)
            {
                Format(out, sizeof(out), "%s %s %s%s %s%s%s : %s%s",
                    rankTag,
                    rankTeamSeparator,
                    teamText, teamTag,
                    nameColor, playerName, COLOR_WHITE,
                    msgColor, message);
            }
            else if (showNameSep)
            {
                Format(out, sizeof(out), "%s %s%s %s %s%s%s : %s%s",
                    rankTag,
                    teamText, teamTag,
                    nameTeamSeparator,
                    nameColor, playerName, COLOR_WHITE,
                    msgColor, message);
            }
            else
            {
                Format(out, sizeof(out), "%s %s%s %s%s%s : %s%s",
                    rankTag,
                    teamText, teamTag,
                    nameColor, playerName, COLOR_WHITE,
                    msgColor, message);
            }
        }
        else if (hasRank)
        {
            Format(out, sizeof(out), "%s %s%s%s : %s%s",
                rankTag,
                nameColor, playerName, COLOR_WHITE,
                msgColor, message);
        }
        else if (hasTeam)
        {
            if (showNameSep)
            {
                Format(out, sizeof(out), "%s%s %s %s%s%s : %s%s",
                    teamText, teamTag,
                    nameTeamSeparator,
                    nameColor, playerName, COLOR_WHITE,
                    msgColor, message);
            }
            else
            {
                Format(out, sizeof(out), "%s%s %s%s%s : %s%s",
                    teamText, teamTag,
                    nameColor, playerName, COLOR_WHITE,
                    msgColor, message);
            }
        }
        else
        {
            Format(out, sizeof(out), "%s%s%s : %s%s",
                nameColor, playerName, COLOR_WHITE,
                msgColor, message);
        }
    }
    else
    {
        if (hasRank && hasTeam)
        {
            if (showRankSep && showNameSep)
            {
                Format(out, sizeof(out), "%s %s%s%s %s %s%s %s%s",
                    rankTag,
                    nameColor, playerName, COLOR_WHITE,
                    rankTeamSeparator,
                    nameTeamSeparator,
                    teamText, teamTag,
                    msgColor, message);
            }
            else if (showRankSep)
            {
                Format(out, sizeof(out), "%s %s%s%s %s %s%s : %s%s",
                    rankTag,
                    nameColor, playerName, COLOR_WHITE,
                    rankTeamSeparator,
                    teamText, teamTag,
                    msgColor, message);
            }
            else if (showNameSep)
            {
                Format(out, sizeof(out), "%s %s%s%s %s %s%s : %s%s",
                    rankTag,
                    nameColor, playerName, COLOR_WHITE,
                    nameTeamSeparator,
                    teamText, teamTag,
                    msgColor, message);
            }
            else
            {
                Format(out, sizeof(out), "%s %s%s%s %s%s : %s%s",
                    rankTag,
                    nameColor, playerName, COLOR_WHITE,
                    teamText, teamTag,
                    msgColor, message);
            }
        }
        else if (hasRank)
        {
            Format(out, sizeof(out), "%s %s%s%s : %s%s",
                rankTag,
                nameColor, playerName, COLOR_WHITE,
                msgColor, message);
        }
        else if (hasTeam)
        {
            if (showNameSep)
            {
                Format(out, sizeof(out), "%s%s%s %s %s%s : %s%s",
                    nameColor, playerName, COLOR_WHITE,
                    nameTeamSeparator,
                    teamText, teamTag,
                    msgColor, message);
            }
            else
            {
                Format(out, sizeof(out), "%s%s%s %s%s : %s%s",
                    nameColor, playerName, COLOR_WHITE,
                    teamText, teamTag,
                    msgColor, message);
            }
        }
        else
        {
            Format(out, sizeof(out), "%s%s%s : %s%s",
                nameColor, playerName, COLOR_WHITE,
                msgColor, message);
        }
    }

    g_bProcessing[client] = true;

    if (teamChat)
    {
        int senderTeam = GetClientTeam(client);

        for (int i = 1; i <= MaxClients; i++)
        {
            if (!IsClientInGame(i) || IsFakeClient(i))
                continue;

            int targetTeam = GetClientTeam(i);
            if (targetTeam == senderTeam || targetTeam == CS_TEAM_SPECTATOR)
            {
                CPrintToChat(i, "%s", out);
            }
        }
    }
    else
    {
        for (int i = 1; i <= MaxClients; i++)
        {
            if (IsClientInGame(i) && !IsFakeClient(i))
            {
                CPrintToChat(i, "%s", out);
            }
        }
    }

    g_bProcessing[client] = false;
    return Plugin_Handled;
}
