// LR_PrintMessage
void LR_PrintMessage(int iClient, bool bPrefix, bool bNative, const char[] sFormat, any ...)
{
	#pragma unused iClient, bPrefix, bNative, sFormat
}

// LogWarning
void LogWarning(bool bNative, const char[] sFormat, any ...)
{
	static char sLogPath[PLATFORM_MAX_PATH];

	if(!sLogPath[0])
	{
		BuildPath(Path_SM, sLogPath, sizeof(sLogPath), "logs/lr_warnings.log");
	}

	decl char sLogContent[256];

	if(bNative)
	{
		FormatNativeString(0, 3, 4, sizeof(sLogContent), _, sLogContent);
	}
	else
	{
		VFormat(sLogContent, sizeof(sLogContent), sFormat, 5);
	}

	LogToFile(sLogPath, "%s", sLogContent);
}

// GetAccountIDFromSteamID2
int GetAccountIDFromSteamID2(const char[] sSteamID2)
{
	return StringToInt(sSteamID2[10]) << 1 | sSteamID2[8] - '0';
}

// GetMaxPlayers
int GetMaxPlayers()
{
	int iSlots = GetMaxHumanPlayers();

	return (iSlots < MaxClients + 1 ? iSlots : MaxClients) + 1;
}

// GetPlayerName
char[] GetPlayerName(int iClient)
{

	decl char sName[MAX_NAME_LENGTH * 2 + 1];

	GetClientName(iClient, sName, MAX_NAME_LENGTH);

	g_hDatabase.Escape(sName, sName, sizeof(sName));

	if(!g_Settings[LR_DB_Allow_UTF8MB4])
	{
		GetFixNamePlayer(sName);
	}

	return sName;
}

// GetFixNamePlayer
void GetFixNamePlayer(char[] sName)
{
	for(int i = 0, iLen = strlen(sName), iCharBytes; i < iLen;)
	{
		if((iCharBytes = GetCharBytes(sName[i])) == 4)
		{
			iLen -= iCharBytes;

			for(int j = i; j <= iLen; j++)
			{
				sName[j] = sName[j + iCharBytes];
			}
		}
		else
		{
			i += iCharBytes;
		}
	}
}

// GetSignValue
char[] GetSignValue(int iValue)
{
	bool bPlus = iValue > 0;

	decl char sValue[16];

	if(bPlus)
	{
		sValue[0] = '+';
	}

	IntToString(iValue, sValue[view_as<int>(bPlus)], sizeof(sValue) - view_as<int>(bPlus));

	return sValue;
}

// GetSteamID2
char[] GetSteamID2(int iAccountID)
{
	decl char sSteamID2[22] = "STEAM_";

	if(!sSteamID2[6])
	{
		sSteamID2[6] = '0';
		sSteamID2[7] = ':';
	}

	FormatEx(sSteamID2[8], 14, "%i:%i", iAccountID & 1, iAccountID >>> 1);

	return sSteamID2;
}

// NotifClient
bool NotifClient(int iClient, int iValue, const char[] sTitlePhrase, bool bAllow = false)
{
	if(CheckStatus(iClient) && (bAllow || g_bAllowStatistic))
	{
		if(iValue)
		{
			int iExpBuffer = 0,
			    iOldExp = g_iPlayerInfo[iClient].iStats[ST_EXP];

			if(g_Settings[LR_TypeStatistics])
			{
				iExpBuffer = 400;
			}

			if((g_iPlayerInfo[iClient].iStats[ST_EXP] += iValue) < iExpBuffer)
			{
				g_iPlayerInfo[iClient].iStats[ST_EXP] = iExpBuffer;
			}

			g_iPlayerInfo[iClient].iRoundExp += iExpBuffer = g_iPlayerInfo[iClient].iStats[ST_EXP] - iOldExp;
			g_iPlayerInfo[iClient].iSessionStats[ST_EXP] += iExpBuffer;

			CheckRank(iClient);
			CallForward_OnExpChanged(iClient, iExpBuffer, g_iPlayerInfo[iClient].iStats[ST_EXP]);

			if(g_Settings[LR_ShowUsualMessage] == 1)
			{
				LR_PrintMessage(iClient, true, false, "%T", sTitlePhrase, iClient, g_iPlayerInfo[iClient].iStats[ST_EXP], GetSignValue(iValue));
			}
		}

		return true;
	}

	return false;
}

// CheckStatus
bool CheckStatus(int iClient)
{
	return (iClient && IsClientAuthorized(iClient) && !IsFakeClient(iClient) && g_iPlayerInfo[iClient].bInitialized) || (g_iPlayerInfo[iClient].bInitialized = false);
}

// CheckRank
void CheckRank(int iClient, bool bActive = true)
{
	if(CheckStatus(iClient))
	{
		int iExp = g_iPlayerInfo[iClient].iStats[ST_EXP],
		    iMaxRanks = g_hRankExp.Length;

		if(iMaxRanks)
		{
			int iRank = iMaxRanks + 1,
			    iOldRank = g_iPlayerInfo[iClient].iStats[ST_RANK];

			decl char sRankName[192];

			while(--iRank && g_hRankExp.Get(iRank - 1) > iExp) {}

			if(iRank != iOldRank)
			{
				g_iPlayerInfo[iClient].iStats[ST_RANK] = iRank;

				if(g_hForward_Hook[LR_OnLevelChangedPre].FunctionCount)
				{
					int iNewRank = iRank;

					CallForward_OnLevelChanged(iClient, iNewRank, iOldRank);

					if(0 < iNewRank < iMaxRanks && iNewRank != iOldRank)
					{
						g_iPlayerInfo[iClient].iStats[ST_RANK] = iRank = iNewRank;
					}
					else
					{
						LogError("%i - invalid number rank.", iNewRank);
					}
				}

				if(bActive)
				{
					bool bIsUp = iRank > iOldRank;

					g_iPlayerInfo[iClient].iSessionStats[ST_RANK] += iRank - iOldRank;

					g_hRankNames.GetString(iRank ? iRank - 1 : iRank, sRankName, sizeof(sRankName));

					if(TranslationPhraseExists(sRankName))
					{
						FormatEx(sRankName, sizeof(sRankName), "%T", sRankName, iClient);
					}

					LR_PrintMessage(iClient, true, false, "%T", bIsUp ? "LevelUp" : "LevelDown", iClient, sRankName);

					if(IsClientInGame(iClient) && g_Settings[LR_IsLevelSound])
					{
						EmitSoundToClient(iClient, bIsUp ? g_sSoundUp : g_sSoundDown, SOUND_FROM_PLAYER, 80);
					}

					if(g_Settings[LR_ShowLevelUpMessage + view_as<int>(!bIsUp)])
					{
						for(int i = GetMaxPlayers(); --i;)
						{
							if(g_iPlayerInfo[i].bInitialized && i != iClient)
							{
								LR_PrintMessage(i, true, false, "%T", bIsUp ? "LevelUpAll" : "LevelDownAll", i, iClient, sRankName);
							}
						}
					}

					if(g_Settings[LR_DB_SaveDataPlayer_Mode])
					{
						SaveDataPlayer(iClient);
					}
				}

				CallForward_OnLevelChanged(iClient, iRank, iOldRank, false);
			}
		}
		else
		{
			LogWarning(false, "settings_ranks.ini: MaxRanks = %i", iMaxRanks);
		}

	}
}

// ResetPlayerData
void ResetPlayerData(int iClient)
{
	g_iPlayerInfo[iClient].iStats = g_iInfoNULL.iStats;
	g_iPlayerInfo[iClient].iSessionStats = g_iInfoNULL.iSessionStats;
	g_iPlayerInfo[iClient].iKillStreak = 0;

	g_iPlayerInfo[iClient].iStats[ST_PLAYTIME] = g_iPlayerInfo[iClient].iSessionStats[ST_PLAYTIME] -= GetTime();
	g_iPlayerInfo[iClient].iStats[ST_EXP] = g_Settings[LR_TypeStatistics] ? 1000 : 0;
}

// ResetPlayerStats
void ResetPlayerStats(int iClient)
{
	ResetPlayerData(iClient);
	CheckRank(iClient, false);
	CallForward_OnResetPlayerStats(iClient, g_iPlayerInfo[iClient].iAccountID);
}
