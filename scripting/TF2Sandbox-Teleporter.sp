#pragma semicolon 1

#define DEBUG

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <build>
#include <smlib>

#pragma newdecls required

public Plugin myinfo = 
{
	name = "TF2 Sandbox - Teleporter", 
	author = "LeadKiller, BattlefieldDuck", 
	description = "Ladder on Sandbox", 
	version = "1.0", 
	url = "http://steamcommunity.com/id/battlefieldduck/"
};

public void OnPluginStart()
{
	CreateConVar("sm_tf2sb_teleporter_version", "1.0", "", FCVAR_SPONLY | FCVAR_NOTIFY);
	RegAdminCmd("sm_teleporter", Command_Teleporter, 0, "TF2SB Portable Teleporter");

	PrecacheSound("weapons/teleporter_send.wav");
}

public Action Command_Teleporter(int client, int args)
{
	if (!Build_IsClientValid(client, client))
		return Plugin_Handled;

	Menu menu = CreateMenu(TeleportMenu);
	menu.SetTitle("TF2SB - Teleporters");
	
	char szClass[64];
	bool withinRange = false;

	for (int i = MaxClients; i < MAX_HOOK_ENTITIES; i++) if (IsValidEdict(i)) // taken from https://github.com/tf2-sandbox-studio/Module-Ladder
	{
		GetEdictClassname(i, szClass, sizeof(szClass));
		if (StrContains(szClass, "prop_dynamic") >= 0)
		{
			char szModel[100];
			char szIndex[2064];
			char szPropName[256];
			int builderIndex = -1;
			char buffer[512];
			
			GetEntPropString(i, Prop_Data, "m_ModelName", szModel, sizeof(szModel));
			GetEntPropString(i, Prop_Data, "m_iName", szPropName, sizeof(szPropName));
			builderIndex = Build_ReturnEntityOwner(i);
			IntToString(EntIndexToEntRef(i), szIndex, sizeof(szIndex));
			if (builderIndex > 0 && builderIndex <= MaxClients && IsClientInGame(builderIndex))
			{
				Format(buffer, sizeof(buffer), "%N's %s", builderIndex, szPropName);
				if (StrEqual(szModel, "models/props_lab/teleplatform.mdl"))
				{
					menu.AddItem(szIndex, buffer);

					if (Entity_InRange(client, i, 60.0))
					{
						withinRange = true;
					}
				}
			}
		}
	}
    
	menu.ExitButton = true;

	if (withinRange)
		menu.Display(client, MENU_TIME_FOREVER);
	else
		Build_PrintToChat(client, "Not inside of any teleporter!");

	return Plugin_Handled;
}

public int TeleportMenu(Handle menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_Select && param1 > 0 && param1 <= MaxClients && IsClientInGame(param1))
	{
		char item[2064];
		int builderIndex = -1;
		GetMenuItem(menu, param2, item, sizeof(item));
		
		int entity = EntRefToEntIndex(StringToInt(item));
		if (entity != INVALID_ENT_REFERENCE)
		{
			builderIndex = Build_ReturnEntityOwner(entity);
	
			Build_PrintToChat(param1, "Teleported to %N's teleporter!", builderIndex);
	
			float TeleporterPos[3];
			GetEntPropVector(entity, Prop_Send, "m_vecOrigin", TeleporterPos);
			
			TeleportEntity(param1, TeleporterPos, NULL_VECTOR, NULL_VECTOR);
			EmitSoundToClient(param1, "weapons/teleporter_send.wav");
		}
		
		// Command_Teleporter(param1, 0);
	}
	else if ((action == MenuAction_Cancel && param2 == MenuCancel_ExitBack && param1 > 0 && param1 <= MaxClients && IsClientInGame(param1)) || action == MenuAction_End)
	{
		CloseHandle(menu);
	}
	return 0;
}