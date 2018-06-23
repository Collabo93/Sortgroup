SortGroupInformation = {};
local L = LibStub("AceLocale-3.0"):GetLocale("SortGroup")
local UpdateTable = {}

local Main_Frame = CreateFrame("Frame", "MainPanel", InterfaceOptionsFramePanelContainer);
local Option_Frame = CreateFrame("Frame", "OptionPanel", Main_Frame);
-- Main Frame

local defaultValues_DB = {
	Top = true,
	TopDescending = true,
	TopAscending = false,
	Bottom = false,
	BottomDescending = false,
	BottomAscending = false,
	AlwaysActive = false,
	AutoActivate = true,
	Profile = nil,
	RaidProfileBlockInCombat = true,
	ChatMessagesOn = true,
	NewDB = true
}

local changeableValues_DB = {
	EscIntepretAsOK = false, 
	--Personal recommendation to activate this. Pressing Cancel/Esc will be interpretet as OK - less taint and issues overall. However, someone might don't want this
	RaidProfilesUpdateInCombatVisibility = false, 
	--Since the friendly nameplate changes this can cause issues in a raid environment. Other then that, it doesn't seem to cause any issue. 
	ChangesInCombat = false;
	--You can change options in combat. Not really recommended
	CatchProfileSwitchEvent = false,
	--Experimental. If activated, every manual switch will automatically activate the sort function - to apply it to the new profile. This will cause issues !
	DebugModeActive = false,
	DebugModeLevel = 2
	-- debugging, false = deactivated
	-- 1 Options
	-- 2 Events+Method Names
	-- 4 Methods content
	-- combinable, so 7 = everything
}
-- Options, which are only changeable here atm. These can cause taint and errors, but can also be useful. Activate on own "risk"  

local internValues_DB = {
	showChatMessages = false, -- true when "PLAYER_ENTERING_WORLD" fired or cb Event gets triggered
	inCombat = false, -- true when "PLAYER_REGEN_DISABLED" fired	
	ddmItems = {}, -- ddm content
	GroupMembersOfC = 0
}


local Main_Title = Main_Frame:CreateFontString("MainTitle", "OVERLAY", "GameFontHighlight");
local Option_Title = Option_Frame:CreateFontString("OptionTitle", "OVERLAY", "GameFontHighlight");

local Main_Text_Version = CreateFrame("SimpleHTML", "MainTextVersion", Main_Frame);
local Main_Text_Author = CreateFrame("SimpleHTML", "MainTextAuthor", Main_Frame); 
local intern_version = "4.1.12";
local intern_versionOutput = "|cFF00FF00Version|r  " .. intern_version
local intern_author = "Collabo93"
local intern_authorOutput = "|cFF00FF00Author|r   " .. intern_author

local Option_Text_General = CreateFrame("SimpleHTML", "OptionTextGeneral", Option_Frame);
local Option_Text_Combat = CreateFrame("SimpleHTML", "OptionTextCombat", Option_Frame);
-- Text

local Main_cb_Top = CreateFrame("CheckButton", "MainCbTop", Main_Frame, "UICheckButtonTemplate");
local Main_cb_Bottom = CreateFrame("CheckButton", "MainCbBottom", Main_Frame, "UICheckButtonTemplate");
local Main_cb_TopDescending = CreateFrame("CheckButton", "MainCbTopDescending", Main_cb_Top, "UICheckButtonTemplate");
local Main_cb_TopAscending = CreateFrame("CheckButton", "MainCbTopAscending", Main_cb_Top, "UICheckButtonTemplate");
local Main_cb_BottomDescending = CreateFrame("CheckButton", "MainCbBottomDescending", Main_cb_Bottom, "UICheckButtonTemplate");
local Main_cb_BottomAscending = CreateFrame("CheckButton", "MainCbBottomAscending", Main_cb_Bottom, "UICheckButtonTemplate");
local Main_cb_AlwaysActive = CreateFrame("CheckButton", "MainCbAlwaysActive", Main_Frame, "UICheckButtonTemplate");
local Main_cb_AutoActivate = CreateFrame("CheckButton", "MainCbAutoActivate", Main_cb_AlwaysActive, "UICheckButtonTemplate");

local Option_cb_ChatMessagesOn = CreateFrame("CheckButton", "OptionCbChatMessagesOn", Option_Text_General, "UICheckButtonTemplate");
local Option_cb_RaidProfilesUpdateInCombat = CreateFrame("CheckButton", "OptionCbRaidProfilesUpdateInCombatn", Option_Text_Combat, "UICheckButtonTemplate");
-- Combo-box Options

local Main_btn_Reload = CreateFrame("Button", "MainBtnReload", Option_Frame, "UIPanelButtonTemplate");
-- Button

local Main_ddm_Profiles = CreateFrame("Button", "MainDdmProfiles", Main_cb_AutoActivate, "UIDropDownMenuTemplate");
-- DropDownMenu
---End Variables

local function ColorText(text, operation)
	local defaultColor = "#FFFFFF";
	if ( operation == "option" ) then
		local cacheText = text:gsub("SortGroup:" , function(cap)
			cap = cap:sub(1, -1);
			local color = "|cff00FF7F" or defaultColor;
			return color..cap.."|r";
		end)
		return cacheText;
	elseif ( operation == "disable" ) then
		local color = "|cff888888" or defaultColor;
		return color..text;
	elseif ( operation == "green" ) then
		local color = "|cff00ff00" or defaultColor;
		return color..text;
	elseif ( operation == "red" ) then
		local color = "|cffff0000" or defaultColor;
		return color..text;
	elseif ( operation == "white" ) then
		local color = "|cffffffff" or defaultColor;
		return color..text;
	end
end

local function Debug(methodName, methodContent, methodLevel)
	if ( changeableValues_DB.DebugModeActive == true ) then
		local debugMethodNameCache = nil;
		local debugMethodContentCache = nil;
		local debugMethodNamePrint = true;
		local debugLevelCache = changeableValues_DB.DebugModeLevel;
		if ( debugLevelCache % 2 == 1 and methodLevel >= 1 ) then
			debugLevelCache = debugLevelCache - 1;
			if ( methodLevel == 1 ) then
				debugMethodNamePrint = true;
				print(ColorText("SortGroup: Debuging - Options", "option"));
				print("'defaultValues_DB.Top' " .. tostring(defaultValues_DB.Top));
				print("'defaultValues_DB.TopDescending' " .. tostring(defaultValues_DB.TopDescending));
				print("'defaultValues_DB.TopAscending' " .. tostring(defaultValues_DB.TopAscending));
				print("'defaultValues_DB.Bottom' " .. tostring(defaultValues_DB.Bottom));
				print("'defaultValues_DB.BottomDescending' " .. tostring(defaultValues_DB.BottomDescending));
				print("'defaultValues_DB.Profile' " .. tostring(defaultValues_DB.Profile));
				print("'AutoActivate' " .. tostring(defaultValues_DB.AutoActivate));
				print("'defaultValues_DB.AlwaysActive' " .. tostring(defaultValues_DB.AlwaysActive));
				print("'defaultValues_DB.ChatMessagesOn' " .. tostring(defaultValues_DB.ChatMessagesOn));
				print("'defaultValues_DB.RaidProfileBlockInCombat' " .. tostring(defaultValues_DB.RaidProfileBlockInCombat));
			end
		end
		if ( ( debugLevelCache == 2 or debugLevelCache == 6 ) and methodLevel >= 2 ) then
			if ( debugMethodNameCache ~= methodName ) then
				if ( debugMethodNamePrint == true ) then
					print(ColorText("SortGroup: Debuging - Method Names", "option"));
					debugMethodNamePrint = false;
				end
				print("'" ..  methodName .. "()'");
				debugMethodNameCache = methodName;
			end
		end
		if ( debugLevelCache >= 4 and methodLevel == 3 ) then
			debugMethodNamePrint = true;
			if ( debugMethodContentCache ~= methodName ) then
				print(ColorText("SortGroup: Debuging - Method content", "option"));	
			end
			debugMethodContentCache = methodName;
			print( "'" .. methodName .. "()' " .. tostring(methodContent));
		end		
	end
end
-- Debug, goes through everything

local function ProfileExists(raidProfile)
	Debug("ProfileExists", "", 2);
	local raidprofilexists = false;
	for i=1, GetNumRaidProfiles(), 1 do
		internValues_DB.ddmItems[i] = GetRaidProfileName(i);
		if ( internValues_DB.ddmItems[i] == raidProfile ) then
			raidprofilexists = true;
		end
	end
	Debug("ProfileExists", tostring(raidprofilexists), 3);
	return raidprofilexists;
end
--Fills internValues_DB.ddmItems with raidprofiles and checks if raidprofil exists

local function ExecuteSwitchRaidProfiles(profile)
	Debug("ExecuteSwitchRaidProfiles", "", 2);
	Debug("ExecuteSwitchRaidProfiles", "to profile: " .. profile, 3);
	
	CompactUnitFrameProfiles.selectedProfile = profile;
	SaveRaidProfileCopy(profile);
	SetCVar("activeCUFProfile", profile);
	UIDropDownMenu_SetSelectedValue(CompactUnitFrameProfilesProfileSelector, profile);
	UIDropDownMenu_SetText(CompactUnitFrameProfilesProfileSelector, profile);	
	UIDropDownMenu_SetSelectedValue(CompactRaidFrameManagerDisplayFrameProfileSelector, profile);
	UIDropDownMenu_SetText(CompactRaidFrameManagerDisplayFrameProfileSelector, profile);		
	CompactUnitFrameProfiles_ApplyCurrentSettings();
	--CompactUnitFrameProfiles_UpdateCurrentPanel();
	--Taint - Disabled
	CompactUnitFrameProfiles_HidePopups();
	
	--CompactUnitFrameProfiles_ActivateRaidProfile(profile);
end

local function SwitchRaidProfiles()
	Debug("SwitchRaidProfiles", "", 2);
	if ( internValues_DB.inCombat == false or changeableValues_DB.ChangesInCombat == true ) then
		member = tonumber(GetNumGroupMembers());
		if ( HasLoadedCUFProfiles() == true ) then
			if ( internValues_DB.inCombat == false and defaultValues_DB.Profile ~= nil ) then
				if ( member <= 5 and ProfileExists(defaultValues_DB.Profile) ) then
					if ( GetActiveRaidProfile() ~= defaultValues_DB.Profile ) then
						ExecuteSwitchRaidProfiles(defaultValues_DB.Profile);
						if ( defaultValues_DB.ChatMessagesOn == true ) then
							print( ColorText(L["SortGroup_RaidProfil_changed_output"]:gsub("'replacement'", defaultValues_DB.Profile), "option") );
						end
					end
				end
			end
		end
	end
end
-- Possible switch by Group_Roster, OK button, COMPACT_UNIT_FRAME_PROFILES_LOADED, PLAYER_REGEN_ENABLED, Main_cb_AutoActivate or Main_ddm_Profiles

local function SortTopDescending()
	Debug("SortTopDescending", "", 2);
	LoadAddOn("CompactRaidFrameContainer");
	local CRFSort_TopDownwards = function(t1, t2)
		if UnitIsUnit(t1, "player") then 
			return true;
		elseif UnitIsUnit(t2, "player") then 
			return false;
		else 
			return t1 < t2;
		end 
	end
	CompactRaidFrameContainer_SetFlowSortFunction(CompactRaidFrameContainer, CRFSort_TopDownwards)
end

local function SortTopAscending()
	Debug("SortTopAscending", "", 2);
	LoadAddOn("CompactRaidFrameContainer");
	local CRFSort_TopUpwards = function(t1, t2)
		if UnitIsUnit(t1, "player") then 
			return true;
		elseif UnitIsUnit(t2, "player") then 
			return false;
		else 
			return t1 > t2;
		end 
	end
	CompactRaidFrameContainer_SetFlowSortFunction(CompactRaidFrameContainer, CRFSort_TopUpwards)
end
	
local function SortBottomDescending()
	Debug("SortBottomDescending", "", 2);
	LoadAddOn("CompactRaidFrameContainer");
	local CRFSort_BottomUpwards = function(t1, t2)
		if UnitIsUnit(t1, "player") then 
			return false;
		elseif UnitIsUnit(t2, "player") then 
			return true; 
		else 
			return t1 > t2;
		end 
	end
	CompactRaidFrameContainer_SetFlowSortFunction(CompactRaidFrameContainer, CRFSort_BottomUpwards)
end

local function SortBottomAscending()
	Debug("SortBottomAscending", "", 2);
	LoadAddOn("CompactRaidFrameContainer");
	local CRFSort_BottomDownwards = function(t1, t2)
		if UnitIsUnit(t1, "player") then 
			return false;
		elseif UnitIsUnit(t2, "player") then 
			return true; 
		else 
			return t1 < t2;
		end 
	end
	CompactRaidFrameContainer_SetFlowSortFunction(CompactRaidFrameContainer, CRFSort_BottomDownwards)
end

local function CheckProfileOptions()
	Debug("CheckProfileOptions", "", 2);
	if ( GetNumGroupMembers() <= 5 and GetActiveRaidProfile() == defaultValues_DB.Profile ) then
		if ( CompactUnitFrameProfilesRaidStylePartyFrames:GetChecked() == false ) then
			CompactUnitFrameProfilesRaidStylePartyFrames:Click("LeftButton",true);
			Debug("CheckProfileOptions", "RaidStylePartyFrames clicked", 3);
		end
		if ( CompactUnitFrameProfilesGeneralOptionsFrameKeepGroupsTogether:GetChecked() == true ) then
			--CompactUnitFrameProfilesGeneralOptionsFrameKeepGroupsTogether:Click();
			--taints if activated - need to make a work around
			if ( defaultValues_DB.ChatMessagesOn == true and internValues_DB.showChatMessages == true ) then	
				print(ColorText(L["SortGroup_Keep_Group_Together_Active_output"], "option"));
				internValues_DB.showChatMessages = false;
			end
			Debug("CheckProfileOptions", "KeepGroupsTogether checked", 3);
		end
	end
end
--necessary changes, otherwise there is no sort
--CompactUnitFrameProfilesGeneralOptionsFrameKeepGroupsTogether taints, so User needs to do this

local function ChoseSort(SortOption, RaidProfileName, ExternSwitch)	
	Debug("ChoseSort", "", 2);
	if ( ExternSwitch == true ) then 
		SwitchRaidProfiles();
	elseif ( internValues_DB.inCombat == false ) then
		if ( RaidProfileName ~= nil and GetNumGroupMembers() <= 5 and HasLoadedCUFProfiles() == true ) then
			if ( GetActiveRaidProfile() ~= RaidProfileName and AutoActivate == false and defaultValues_DB.AlwaysActive == false ) then
				if ( internValues_DB.showChatMessages == true ) then
					if ( defaultValues_DB.ChatMessagesOn == true ) then
						print(ColorText(L["SortGroup_RaidProfil_Doesnt_match_output_output"], "option"));
					end
				end
			elseif ( GetActiveRaidProfile() == RaidProfileName or defaultValues_DB.AlwaysActive == true ) then
				if ( SortOption == 'Down') then
					if ( defaultValues_DB.TopDescending == true ) then
						if ( internValues_DB.showChatMessages == true ) then
							if ( defaultValues_DB.AlwaysActive == true ) then
								if ( defaultValues_DB.ChatMessagesOn == true ) then
									print(ColorText(L["SortGroup_sort_top_descending_AlwaysActive_output"], "option"));
								end
							else
								if ( defaultValues_DB.ChatMessagesOn == true ) then
									print(ColorText(L["SortGroup_sort_top_descending_output"]:gsub("'replacement'", RaidProfileName), "option"));
								end
							end
						end
						CheckProfileOptions();
						SortTopDescending();
					end
					if ( defaultValues_DB.TopAscending == true ) then
						if ( internValues_DB.showChatMessages == true ) then
							if ( defaultValues_DB.AlwaysActive == true ) then
								if ( defaultValues_DB.ChatMessagesOn == true ) then
									print(ColorText(L["SortGroup_sort_top_ascending_AlwaysActive_output"], "option"));
								end
							else
								if ( defaultValues_DB.ChatMessagesOn == true ) then
									print(ColorText(L["SortGroup_sort_top_ascending_output"]:gsub("'replacement'", RaidProfileName), "option"));
								end
							end
						end
						CheckProfileOptions();
						SortTopAscending();
					end
				elseif ( SortOption == 'Up') then
					if ( defaultValues_DB.BottomDescending == true ) then
						if ( internValues_DB.showChatMessages == true ) then
							if ( defaultValues_DB.AlwaysActive == true ) then
								if ( defaultValues_DB.ChatMessagesOn == true ) then
									print(ColorText(L["SortGroup_sort_bottom_descending_AlwaysActive_output"], "option"));
								end
							else
								if ( defaultValues_DB.ChatMessagesOn == true ) then
									print(ColorText(L["SortGroup_sort_bottom_descending_output"]:gsub("'replacement'", RaidProfileName), "option"));
								end
							end
						end
						CheckProfileOptions();
						SortBottomAscending();
					end
					if ( defaultValues_DB.BottomAscending == true ) then
						if ( internValues_DB.showChatMessages == true ) then
							if ( defaultValues_DB.AlwaysActive == true ) then
								if ( defaultValues_DB.ChatMessagesOn == true ) then
									print(ColorText(L["SortGroup_sort_bottom_ascending_AlwaysActive_output"], "option"));
								end
							else
								if ( defaultValues_DB.ChatMessagesOn == true ) then
									print(ColorText(L["SortGroup_sort_bottom_ascending_output"]:gsub("'replacement'", RaidProfileName), "option"));
								end
							end
						end
						CheckProfileOptions();
						SortBottomDescending();
					end
				end
			end	
		end
	end
end
-- Final decision, which Raid defaultValues_DB.Profile gets loaded and which Sort Method will be used

local function SortInterstation(ExternSwitch)
	Debug("SortInterstation", "", 2);
	if ( defaultValues_DB.AlwaysActive == false ) then
		if ( defaultValues_DB.Top == true or defaultValues_DB.Bottom == true ) then
			if ( ProfileExists(defaultValues_DB.Profile) == false ) then
				defaultValues_DB.Profile = GetRaidProfileName(1);
				if ( defaultValues_DB.ChatMessagesOn == true ) then
					local cachePrintSendSortOptionToSortBy = L["SortGroup_RaidProfil_dont_exists_output"]:gsub("'replacement'", defaultValues_DB.Profile);
					print(ColorText(cachePrintSendSortOptionToSortBy:gsub("'replacement2'", defaultValues_DB.Profile), "option"));
				end
				UIDropDownMenu_SetText(Main_ddm_Profiles, defaultValues_DB.Profile);
			end
		end
	end
	if ( ExternSwitch == true ) then
		ChoseSort("","", true);
	end
	if ( defaultValues_DB.Top == true ) then
		ChoseSort('Down', defaultValues_DB.Profile, false);
	elseif ( defaultValues_DB.Bottom == true ) then
		ChoseSort('Up', defaultValues_DB.Profile, false);
	else
		if ( internValues_DB.showChatMessages == true ) then
			if ( defaultValues_DB.ChatMessagesOn == true ) then
				print (ColorText(L["SortGroup_sort_no_output"], "option"));
			end	
		end
	end
	internValues_DB.showChatMessages = false;
end
-- Breakpoint between Methods and ChoseSort

local function UpdateComboBoxes()
	Debug("UpdateComboBoxes", "", 2);
	
	if ( defaultValues_DB.AutoActivate == true ) then
		Main_cb_AutoActivate:SetChecked(true);
		getglobal(Main_cb_AutoActivate:GetName() .. 'Text'):SetText(ColorText(L["SortGroup_Main_cb_AutoActivate_Text"],"white"));
	else
		Main_cb_AutoActivate:SetChecked(false);
	end
	
	if ( defaultValues_DB.AlwaysActive == true ) then
		UIDropDownMenu_DisableDropDown(Main_ddm_Profiles);
		Main_cb_AutoActivate:Disable();
		getglobal(Main_cb_AutoActivate:GetName() .. 'Text'):SetText(ColorText(L["SortGroup_Main_cb_AutoActivate_Text"],"disable"));
		Main_cb_AlwaysActive:SetChecked(true);
	else
		defaultValues_DB.AlwaysActive = false;
		Main_cb_AutoActivate:Enable();
		getglobal(Main_cb_AutoActivate:GetName() .. 'Text'):SetText(ColorText(L["SortGroup_Main_cb_AutoActivate_Text"], "white"));
		if ( Main_cb_AutoActivate:GetChecked() == true ) then
			UIDropDownMenu_EnableDropDown(Main_ddm_Profiles);
		end
		Main_cb_AlwaysActive:SetChecked(false);
	end
	
	if ( defaultValues_DB.Top == true ) then
		Main_cb_Top:SetChecked(true);
		Main_cb_Bottom:SetChecked(false);
		Main_cb_TopDescending:Enable();
		Main_cb_TopAscending:Enable();
		Main_cb_BottomDescending:Disable();
		Main_cb_BottomAscending:Disable();
		getglobal(Main_cb_TopDescending:GetName() .. 'Text'):SetText(ColorText(L["SortGroup_Main_cb_Descending_Text"], "white"));
		getglobal(Main_cb_TopAscending:GetName() .. 'Text'):SetText(ColorText(L["SortGroup_Main_cb_Ascending_Text"], "white"));
		getglobal(Main_cb_BottomDescending:GetName() .. 'Text'):SetText(ColorText(L["SortGroup_Main_cb_Descending_Text"],"disable"));
		getglobal(Main_cb_BottomAscending:GetName() .. 'Text'):SetText(ColorText(L["SortGroup_Main_cb_Ascending_Text"],"disable"));
	elseif ( defaultValues_DB.Bottom == true ) then
		Main_cb_Top:SetChecked(false);
		Main_cb_Bottom:SetChecked(true);
		Main_cb_TopDescending:Disable();
		Main_cb_TopAscending:Disable();
		Main_cb_BottomDescending:Enable();
		Main_cb_BottomAscending:Enable();
		getglobal(Main_cb_TopDescending:GetName() .. 'Text'):SetText(ColorText(L["SortGroup_Main_cb_Descending_Text"],"disable"));
		getglobal(Main_cb_TopAscending:GetName() .. 'Text'):SetText(ColorText(L["SortGroup_Main_cb_Ascending_Text"],"disable"));
		getglobal(Main_cb_BottomDescending:GetName() .. 'Text'):SetText(ColorText(L["SortGroup_Main_cb_Descending_Text"], "white"));
		getglobal(Main_cb_BottomAscending:GetName() .. 'Text'):SetText(ColorText(L["SortGroup_Main_cb_Ascending_Text"], "white"));
	else
		Main_cb_Top:SetChecked(false);
		Main_cb_Bottom:SetChecked(false);
		Main_cb_TopDescending:Disable();
		Main_cb_TopAscending:Disable();
		Main_cb_BottomDescending:Disable();
		Main_cb_BottomAscending:Disable();
		getglobal(Main_cb_TopDescending:GetName() .. 'Text'):SetText(ColorText(L["SortGroup_Main_cb_Descending_Text"],"disable"));
		getglobal(Main_cb_TopAscending:GetName() .. 'Text'):SetText(ColorText(L["SortGroup_Main_cb_Ascending_Text"],"disable"));
		getglobal(Main_cb_BottomDescending:GetName() .. 'Text'):SetText(ColorText(L["SortGroup_Main_cb_Descending_Text"],"disable"));
		getglobal(Main_cb_BottomAscending:GetName() .. 'Text'):SetText(ColorText(L["SortGroup_Main_cb_Ascending_Text"],"disable"));
	end
	
	if ( defaultValues_DB.TopDescending == true ) then
		Main_cb_TopDescending:SetChecked(true);
		Main_cb_TopAscending:SetChecked(false);
	elseif ( defaultValues_DB.TopAscending == true ) then
			Main_cb_TopDescending:SetChecked(false);
			Main_cb_TopAscending:SetChecked(true);
	else 	
		Main_cb_TopDescending:SetChecked(false);
		Main_cb_TopAscending:SetChecked(false);
	end
	if ( defaultValues_DB.BottomDescending == true ) then
		Main_cb_BottomDescending:SetChecked(true);
		Main_cb_BottomAscending:SetChecked(false);
	elseif ( defaultValues_DB.BottomAscending == true ) then
		Main_cb_BottomDescending:SetChecked(false);
		Main_cb_BottomAscending:SetChecked(true);
	else
		Main_cb_BottomDescending:SetChecked(false);
		Main_cb_BottomAscending:SetChecked(false);
	end
	
	if ( defaultValues_DB.ChatMessagesOn == true ) then
		Option_cb_ChatMessagesOn:SetChecked(true);
	else 
		Option_cb_ChatMessagesOn:SetChecked(false);
	end
	if ( defaultValues_DB.RaidProfileBlockInCombat == true ) then
		Option_cb_RaidProfilesUpdateInCombat:SetChecked(true);
	else
		Option_cb_RaidProfilesUpdateInCombat:SetChecked(false);
	end
end
-- Updating all displayed elements
	
local function resetRaidContainer()	
	if ( defaultValues_DB.RaidProfileBlockInCombat == true ) then
		Debug("resetRaidContainer", "", 2);
		local old_CompactRaidFrameContainer_TryUpdate = CompactRaidFrameContainer_TryUpdate
		CompactRaidFrameContainer_TryUpdate = function(self)	
			if ( internValues_DB.inCombat == true ) then
				UpdateTable[self:GetName()] = "CompactRaidFrameContainer_TryUpdate"
			else
				old_CompactRaidFrameContainer_TryUpdate(self)
			end
		end
		
		local old_CompactRaidGroup_UpdateUnits = CompactRaidGroup_UpdateUnits
		CompactRaidGroup_UpdateUnits = function(self)
			if ( internValues_DB.inCombat == true ) then
				UpdateTable[self:GetName()] = "CompactRaidGroup_UpdateUnits"
			else
				old_CompactRaidGroup_UpdateUnits(self)
			end
		end
		
		if ( changeableValues_DB.RaidProfilesUpdateInCombatVisibility == true ) then
			local old_CompactUnitFrame_UpdateInRange = CompactUnitFrame_UpdateInRange
			hooksecurefunc("CompactUnitFrame_UpdateInRange", function(self)
				if not UnitExists(self.displayedUnit) then
					self:SetAlpha(0.1);
				else
					old_CompactUnitFrame_UpdateInRange(self);
				end
			end)
		end	
	end
end

local function ProfileChangedEvent()
	if ( changeableValues_DB.CatchProfileSwitchEvent == true ) then
		old_CompactUnitFrameProfiles_ActivateRaidProfile = CompactUnitFrameProfiles_ActivateRaidProfile;
		hooksecurefunc("CompactUnitFrameProfiles_ActivateRaidProfile", function(profile)
			Debug("ProfileChanged", "", 2);
			if ( (internValues_DB.inCombat == false or changeableValues_DB.ChangesInCombat == true) and defaultValues_DB.AlwaysActive == true) then
				SortInterstation(false);
				Debug("ProfileChanged", "true", 3);
			else
				old_CompactUnitFrameProfiles_ActivateRaidProfile(profile);
			end
		end)
	end
end
-- Event to catch Raid Profile changes

local function SaveOptions()
	Debug("SaveOptions", "", 2);
	SortGroupInformation = defaultValues_DB;
end

local function CountTable(t)
	Debug("CountTable", "", 2);
	local count = 0
	for _ in pairs(t) do 
		count = count + 1 
	end
	return count;
end

function SortGroup_Method_GetAutoActivate()
	if ( defaultValues_DB.AlwaysActive == false ) then
		return defaultValues_DB.AutoActivate;
	else
		return false;
	end
end

function SortGroup_Method_GetProfile()
	if ( defaultValues_DB.Profile == nil ) then
		return SortGroupInformation.Profile;
	end
	return defaultValues_DB.Profile;
end
--Global functions to get informations to ProfileSwitcher - if active


local function createFrame()	
	Debug("createFrame", "", 2);
	Main_Frame.name = "SortGroup";
	Main_Title:SetFont("Fonts\\FRIZQT__.TTF", 18);
	Main_Title:SetTextColor(1, 0.8, 0);
    Main_Title:SetPoint("TOPLEFT", 12, -18);
    Main_Title:SetText("SortGroup");
	
	if ( EscIntepretAsOK == true ) then
		InterfaceOptionsFrameCancel:SetScript("OnClick", function()
			Debug("InterfaceOptionsFrameIntepretetAsOk", "", 2);
			InterfaceOptionsFrameOkay:Click();
		end)
	else
		Main_Frame.cancel = function(Main_Frame)
			Debug("InterfaceOptionsFrameCancel", "", 2);
			SortInterstation(false);
		end
	end
	
	Main_Frame.okay = function(Main_Frame)
		Debug("InterfaceOptionsFrameOkay", "", 2);
		SortInterstation(true);
	end
	InterfaceOptions_AddCategory(Main_Frame);
	
	Option_Frame.name = L["SortGroup_Option_Frame_Text"];
	Option_Title:SetFont("Fonts\\FRIZQT__.TTF", 18);
	Option_Title:SetTextColor(1, 0.8, 0);
    Option_Title:SetPoint("TOPLEFT", 12, -18);
    Option_Title:SetText(L["SortGroup_Option_Frame_Text"].."|r");
	Option_Frame.parent = Main_Frame.name;
	InterfaceOptions_AddCategory(Option_Frame);
end

local function createText()
	Debug("createText", "", 2);
	
	Main_Text_Version:SetPoint("TOPLEFT", 20, -45);
	Main_Text_Version:SetFontObject(GameFontHighlightSmall);
	Main_Text_Version:SetText(intern_versionOutput);
	Main_Text_Version:SetSize(string.len(intern_versionOutput), 10);
	
	Main_Text_Author:SetPoint("TOPLEFT", 20 ,-55);
	Main_Text_Author:SetFontObject(GameFontHighlightSmall);
	Main_Text_Author:SetText(intern_authorOutput);
	Main_Text_Author:SetSize(string.len(intern_authorOutput), 10);
	
	Option_Text_General:SetPoint("TOPLEFT", 40, -80);
	Option_Text_General:SetFontObject(GameFontHighlightMedium);
	Option_Text_General:SetText(L["SortGroup_Option_Text_General_Text"]);
	Option_Text_General:SetSize(string.len(L["SortGroup_Option_Text_General_Text"]), 10);
	
	Option_Text_Combat:SetPoint("TOPLEFT", 40, -170);
	Option_Text_Combat:SetFontObject(GameFontHighlightMedium);
	Option_Text_Combat:SetText(L["SortGroup_Option_Text_Combat_Text"]);
	Option_Text_Combat:SetSize(string.len(L["SortGroup_Option_Text_Combat_Text"]), 10);
end

local function createCheckbox()	
	Debug("createCheckbox", "", 2);
	Main_cb_Top:SetPoint("TOPLEFT", Main_Title, 10, -100);
	Main_cb_Bottom:SetPoint("TOPLEFT", Main_Title, 10, -200);
	Main_cb_TopDescending:SetPoint("TOPLEFT", 30, -30);
	Main_cb_TopAscending:SetPoint("TOPLEFT", 30, -55);
	Main_cb_BottomDescending:SetPoint("TOPLEFT", 30, -30);
	Main_cb_BottomAscending:SetPoint("TOPLEFT", 30, -55);
	Main_cb_AlwaysActive:SetPoint("TOPLEFT", Main_Title, 340, -100);
	Main_cb_AutoActivate:SetPoint("TOPLEFT",30,-30);	
	getglobal(Main_cb_Top:GetName() .. 'Text'):SetText(ColorText(L["SortGroup_Main_cb_Top_Text"], "white"));
	getglobal(Main_cb_Bottom:GetName() .. 'Text'):SetText(ColorText(L["SortGroup_Main_cb_Bottom_Text"], "white"));
	getglobal(Main_cb_TopDescending:GetName() .. 'Text'):SetText(ColorText(L["SortGroup_Main_cb_Descending_Text"], "white"));
	getglobal(Main_cb_TopAscending:GetName() .. 'Text'):SetText(ColorText(L["SortGroup_Main_cb_Ascending_Text"], "white"));
	getglobal(Main_cb_BottomDescending:GetName() .. 'Text'):SetText(ColorText(L["SortGroup_Main_cb_Descending_Text"], "white"));
	getglobal(Main_cb_BottomAscending:GetName() .. 'Text'):SetText(ColorText(L["SortGroup_Main_cb_Ascending_Text"], "white"));
	getglobal(Main_cb_AutoActivate:GetName() .. 'Text'):SetText(ColorText(L["SortGroup_Main_cb_AutoActivate_Text"], "white"));
	getglobal(Main_cb_AlwaysActive:GetName() .. 'Text'):SetText(ColorText(L["SortGroup_Main_cb_AlwaysActive_Text"], "white"));
	--Main frame
	
	Option_cb_ChatMessagesOn:SetPoint("TOPLEFT", 15, -20);
	Option_cb_RaidProfilesUpdateInCombat:SetPoint("TOPLEFT", 15, -20);
	getglobal(Option_cb_ChatMessagesOn:GetName() .. 'Text'):SetText(ColorText(L["SortGroup_Option_cb_ChatMessagesOn_Text"], "white"));	
	getglobal(Option_cb_RaidProfilesUpdateInCombat:GetName() .. 'Text'):SetText(ColorText(L["SortGroup_Option_cb_RaidProfilesUpdateInCombat_Text"], "white"));
	--Option frame
end

local function createButton()
	Debug("createButton", "", 2);
	
	Main_btn_Reload:SetSize(120, 24);
	Main_btn_Reload:SetText(L["SortGroup_Option_btn_Reload_Text"]);
	Main_btn_Reload:SetPoint("TOPLEFT", 450, -300)
end

local function createDropDownMenu()
	Debug("createDropDownMenu", "", 2);
	Main_ddm_Profiles.text = _G["MainDdmProfiles"];
	Main_ddm_Profiles.text:SetText("Empty ddm");
	Main_ddm_Profiles:SetPoint("TOPLEFT", -10, -30);		
	Main_ddm_Profiles.info = {};
	Main_ddm_Profiles.initialize = function(self, level)
		if ( internValues_DB.inCombat == false and level == 1 ) then
			wipe(self.info);
			ProfileExists();
			for i, value in pairs(internValues_DB.ddmItems) do
				self.info.text = value;
				self.info.value = i;
				self.info.func = function(item)
					if ( ProfileExists(value) == true ) then
						self.selectedID = item:GetID();
						self.text:SetText(item);
						self.value = i;
						defaultValues_DB.Profile = value;
						UIDropDownMenu_SetText(Main_ddm_Profiles, defaultValues_DB.Profile);
						internValues_DB.showChatMessages = true;
						SortInterstation(true);
					else
						Debug("createDropDownMenu", "error - RaidProfile doesn't exists", 3);
					end
				end
				self.info.checked = i == self.text:GetText();
				UIDropDownMenu_AddButton(self.info, level);
				if ( defaultValues_DB.Profile == self.info.text ) then
					UIDropDownMenu_SetSelectedID(Main_ddm_Profiles, i);
				end
			end
		else
			if ( defaultValues_DB.ChatMessagesOn == true and SortGroup_Variable_Page3_ChatMessagesWarnings == true ) then
				print(ColorText(L["SortGroup_in_combat_options_output"], "option"));
			end
		end
	end
	Main_ddm_Profiles:SetScript("OnEnter", 
		function(self)
			GameTooltip:SetOwner(self,"ANCHOR_RIGHT");
			GameTooltip:AddLine(L["SortGroup_Main_ddm_Profiles_Text"] .. "\n\n" .. ColorText(L["SortGroup_Main_ddm_Profiles_ToolTip"], "white"), nil, nil, nil, 1);
			GameTooltip:Show();
		end);
	Main_ddm_Profiles:SetScript("OnLeave", function(self) GameTooltip:Hide() end)	
end
--DropDownMenu creating, include items
--- End Creating



local function frameEvent()
	Debug("frameEvent", "", 2);
	Main_Frame:RegisterEvent("COMPACT_UNIT_FRAME_PROFILES_LOADED");
	Main_Frame:RegisterEvent("PLAYER_ENTERING_WORLD");
	Main_Frame:RegisterEvent("PLAYER_LOGOUT");
	Main_Frame:RegisterEvent("PLAYER_REGEN_DISABLED");
	Main_Frame:RegisterEvent("PLAYER_REGEN_ENABLED");
	Main_Frame:RegisterEvent("GROUP_ROSTER_UPDATE");
	Main_Frame:SetScript("OnEvent", 
		function(self, event, ...)	
			if ( event == "PLAYER_LOGOUT" ) then 
				Debug("PLAYER_LOGOUT", "", 2);
				SaveOptions();
				Main_Frame:UnregisterEvent(event);
			elseif ( event == "PLAYER_REGEN_DISABLED" ) then
				Debug("PLAYER_REGEN_DISABLED", "", 2);
				internValues_DB.inCombat = true;
				internValues_DB.GroupMembersOfC = GetNumGroupMembers();
			elseif ( event == "PLAYER_REGEN_ENABLED" ) then
				Debug("PLAYER_REGEN_ENABLED", "", 2);
				internValues_DB.inCombat = false;
				internValues_DB.GroupMembersOfC = 0;
				for k, v in pairs(UpdateTable) do
					UpdateTable[k] = nil
					_G[v](_G[k])
				end
				if ( defaultValues_DB.AutoActivate == true or SortGroup_Variable_Page2_AdditionalSwitchActive == true ) then
					SortInterstation(true);
				else
					SortInterstation(false);
				end
			elseif ( event == "GROUP_ROSTER_UPDATE" ) then
				Debug("GROUP_ROSTER_UPDATE", "", 2);
				if ( defaultValues_DB.AutoActivate == true or SortGroup_Variable_Page2_AdditionalSwitchActive == true ) then
					SortInterstation(true);
				else
					SortInterstation(false);
				end
				if ( internValues_DB.inCombat == true ) then
					local cacheText = L["SortGroup_numberOfMembers_output"];
					cacheText = cacheText:gsub("'replacement'", GetNumGroupMembers());
					if ( (GetNumGroupMembers() - internValues_DB.GroupMembersOfC) > 0 ) then
						cacheText = cacheText:gsub("'replacement2'", ColorText( (GetNumGroupMembers() - internValues_DB.GroupMembersOfC), "green" ) );
					elseif ( (GetNumGroupMembers() - internValues_DB.GroupMembersOfC) < 0 ) then
						cacheText = cacheText:gsub("'replacement2'", ColorText( (GetNumGroupMembers() - internValues_DB.GroupMembersOfC), "red" ) );
					else
						cacheText = cacheText:gsub("'replacement2'", (GetNumGroupMembers() - internValues_DB.GroupMembersOfC) );
					end
					print(ColorText(cacheText, "option"));
					--print("Actuall members: "..GetNumGroupMembers().." , displayed members: ".. (GetNumGroupMembers() - internValues_DB.GroupMembersOfC) );
				else
					internValues_DB.GroupMembersOfC = 0;
				end
			elseif ( event == "COMPACT_UNIT_FRAME_PROFILES_LOADED" ) then
				Debug("COMPACT_UNIT_FRAME_PROFILES_LOADED", "", 2)
				defaultValues_DB.Profile = GetRaidProfileName(1);
				-- first time it's possibly to get the profile name - to set the default value
				if ( CountTable(SortGroupInformation) > 0 ) then
					if ( SortGroupInformation.NewDB ~= true ) then
						SortGroupInformation = nil;
						SortGroupInformation = defaultValues_DB;
						--print(ColorText(L["Sortgroup_reset_output"], "option"));
						StaticPopupDialogs["SortGroup_reset_output_Dialog"] = {
							text = ColorText(L["Sortgroup_reset_output"], "option"),
							button1 = "Ok",
							timeout = 0,
							whileDead = true,
							hideOnEscape = true,
							preferredIndex = 3,
						}
						StaticPopup_Show("SortGroup_reset_output_Dialog");
					end
				else
					SortGroupInformation = nil;
					SortGroupInformation = defaultValues_DB;
					Debug("COMPACT_UNIT_FRAME_PROFILES_LOADED", "new db", 3)
				end

				defaultValues_DB.Top = SortGroupInformation.Top;
				defaultValues_DB.TopDescending = SortGroupInformation.TopDescending;
				defaultValues_DB.TopAscending = SortGroupInformation.TopAscending;
				defaultValues_DB.Bottom = SortGroupInformation.Bottom;
				defaultValues_DB.BottomDescending = SortGroupInformation.BottomDescending;
				defaultValues_DB.BottomAscending = SortGroupInformation.BottomAscending;
				defaultValues_DB.AutoActivate = SortGroupInformation.AutoActivate;
				defaultValues_DB.AlwaysActive = SortGroupInformation.AlwaysActive;
				defaultValues_DB.Profile = SortGroupInformation.Profile;
				defaultValues_DB.ChatMessagesOn = SortGroupInformation.ChatMessagesOn;
				defaultValues_DB.RaidProfileBlockInCombat = SortGroupInformation.RaidProfileBlockInCombat;
				defaultValues_DB.NewDB = SortGroupInformation.NewDB;
				
				UIDropDownMenu_SetText(Main_ddm_Profiles, defaultValues_DB.Profile);
				UpdateComboBoxes();
				--Get informations
				
				resetRaidContainer();
				ProfileChangedEvent();
				-- Both are only activatable by changeableValues_DB
				
				internValues_DB.showChatMessages = true;
				SortInterstation(true);
				Main_Frame:UnregisterEvent(event);	
			elseif ( event == "PLAYER_ENTERING_WORLD" and HasLoadedCUFProfiles() == true and internValues_DB.inCombat == false ) then	
				Debug("PLAYER_ENTERING_WORLD", "", 2);		
				SortInterstation(false);
				-- Start sort
			end
		end);
end

local function checkBoxEvent()
	Debug("checkBoxEvent", "", 2);
	Main_cb_Top:SetScript("OnClick",
		function()
			Debug("Main_cb_Top", "", 2);
			if ( internValues_DB.inCombat == false or changeableValues_DB.ChangesInCombat == true ) then
				internValues_DB.showChatMessages = true;
				if ( Main_cb_Top:GetChecked() == true ) then
					defaultValues_DB.Top = true;
					defaultValues_DB.Bottom = false;
					if ( Main_cb_TopDescending:GetChecked() == false and Main_cb_TopAscending:GetChecked() == false ) then
						defaultValues_DB.TopDescending = true;
					end
				elseif ( Main_cb_Top:GetChecked() == false ) then	
					defaultValues_DB.Top = false;
				end
				SaveOptions();
				UpdateComboBoxes();
				SortInterstation(false);
				Debug("checkBoxEvent", "", 1);
			else
				UpdateComboBoxes();
				if ( defaultValues_DB.ChatMessagesOn == true ) then
					print(ColorText(L["SortGroup_in_combat_options_output"], "option"));
				end
			end
		end);		
	Main_cb_Top:SetScript("OnEnter", 
		function(self)
			GameTooltip:SetOwner(self,"ANCHOR_RIGHT");
			GameTooltip:AddLine(L["SortGroup_Main_cb_Top_Text"] .."\n\n" .. ColorText(L["SortGroup_Main_cb_Top_ToolTip"], "white") , nil, nil, nil, 1);
			GameTooltip:Show();
		end);
	Main_cb_Top:SetScript("OnLeave", function(self) GameTooltip:Hide() end)	
	--Combobox Top
		
	Main_cb_Bottom:SetScript("OnClick",
		function()
			Debug("Main_cb_Bottom", "", 2);
			if ( internValues_DB.inCombat == false or changeableValues_DB.ChangesInCombat == true ) then
				internValues_DB.showChatMessages = true;
				if ( Main_cb_Bottom:GetChecked() == true ) then
					defaultValues_DB.Top = false;
					defaultValues_DB.Bottom = true;
					if ( Main_cb_BottomDescending:GetChecked() == false and Main_cb_BottomAscending:GetChecked() == false ) then
						defaultValues_DB.BottomAscending = true;
						Main_cb_BottomAscending:SetChecked(true);
					end
				elseif ( Main_cb_Bottom:GetChecked() == false ) then	
					defaultValues_DB.Bottom = false;
				end
				SaveOptions();
				UpdateComboBoxes();
				SortInterstation(false);
				Debug("checkBoxEvent", "", 1);
			else
				UpdateComboBoxes();
				if ( defaultValues_DB.ChatMessagesOn == true ) then
					print(ColorText(L["SortGroup_in_combat_options_output"], "option"));
				end
			end
		end);
	Main_cb_Bottom:SetScript("OnEnter", 
		function(self)
			GameTooltip:SetOwner(self,"ANCHOR_RIGHT");
			GameTooltip:AddLine(L["SortGroup_Main_cb_Bottom_Text"] .."\n\n" .. ColorText(L["SortGroup_Main_cb_Bottom_ToolTip"], "white") , nil, nil, nil, 1);
			GameTooltip:Show();
		end);
	Main_cb_Bottom:SetScript("OnLeave", function(self) GameTooltip:Hide() end)	
	--Combobox Bottom
	
	Main_cb_TopDescending:SetScript("OnClick",
		function()
			Debug("Main_cb_TopDescending", "", 2);
			if ( internValues_DB.inCombat == false or changeableValues_DB.ChangesInCombat == true ) then
				internValues_DB.showChatMessages = true;
				if ( Main_cb_TopDescending:GetChecked() == true ) then
					defaultValues_DB.TopDescending = true;
					defaultValues_DB.TopAscending = false;
				elseif ( Main_cb_TopDescending:GetChecked() == false ) then	
					defaultValues_DB.TopDescending = false;
				end
				SaveOptions();
				UpdateComboBoxes();
				SortInterstation(false);
				Debug("checkBoxEvent", "", 1);
			else
				UpdateComboBoxes();
				if ( defaultValues_DB.ChatMessagesOn == true ) then
					print(ColorText(L["SortGroup_in_combat_options_output"], "option"));
				end
			end
		end);		
	Main_cb_TopDescending:SetScript("OnEnter", 
		function(self)
			GameTooltip:SetOwner(self,"ANCHOR_RIGHT");
			GameTooltip:AddLine(L["SortGroup_Main_cb_Descending_Text"] .."\n\n" .. ColorText(L["SortGroup_Main_cb_Descending_ToolTip"], "white") , nil, nil, nil, 1);
			GameTooltip:Show();
		end);
	Main_cb_TopDescending:SetScript("OnLeave", function(self) GameTooltip:Hide() end)	
	--Combobox Main_cb_TopDescending
	
	Main_cb_TopAscending:SetScript("OnClick",
		function()
			Debug("Main_cb_TopAscending", "", 2);
			if ( internValues_DB.inCombat == false or changeableValues_DB.ChangesInCombat == true ) then
				internValues_DB.showChatMessages = true;
				if ( Main_cb_TopAscending:GetChecked() == true ) then
					defaultValues_DB.TopDescending = false;
					defaultValues_DB.TopAscending = true;
				elseif ( Main_cb_TopAscending:GetChecked() == false ) then	
					defaultValues_DB.TopAscending = false;
				end
				SaveOptions();
				UpdateComboBoxes();
				SortInterstation(false);
				Debug("checkBoxEvent", "", 1);
			else
				UpdateComboBoxes();
				if ( defaultValues_DB.ChatMessagesOn == true ) then
					print(ColorText(L["SortGroup_in_combat_options_output"], "option"));
				end
			end
		end);		
	Main_cb_TopAscending:SetScript("OnEnter", 
		function(self)
			GameTooltip:SetOwner(self,"ANCHOR_RIGHT");
			GameTooltip:AddLine(L["SortGroup_Main_cb_Ascending_Text"] .."\n\n" .. ColorText(L["SortGroup_Main_cb_Ascending_ToolTip"], "white") , nil, nil, nil, 1);
			GameTooltip:Show();
		end);
	Main_cb_TopAscending:SetScript("OnLeave", function(self) GameTooltip:Hide() end)	
	--Combobox Main_cb_TopDescending
	
	Main_cb_BottomDescending:SetScript("OnClick",
		function()
			Debug("Main_cb_BottomDescending", "", 2);
			if ( internValues_DB.inCombat == false or changeableValues_DB.ChangesInCombat == true ) then
				internValues_DB.showChatMessages = true;
				if ( Main_cb_BottomDescending:GetChecked() == true ) then
					defaultValues_DB.BottomDescending = true;
					defaultValues_DB.BottomAscending = false;
				elseif ( Main_cb_BottomDescending:GetChecked() == false ) then	
					defaultValues_DB.BottomDescending = false;
				end
				SaveOptions();
				SortInterstation(false);
				UpdateComboBoxes();
				Debug("checkBoxEvent", "", 1);
			else
				UpdateComboBoxes();
				if ( defaultValues_DB.ChatMessagesOn == true ) then
					print(ColorText(L["SortGroup_in_combat_options_output"], "option"));
				end
			end
		end);		
	Main_cb_BottomDescending:SetScript("OnEnter", 
		function(self)
			GameTooltip:SetOwner(self,"ANCHOR_RIGHT");
			GameTooltip:AddLine(L["SortGroup_Main_cb_Descending_Text"] .."\n\n" .. ColorText(L["SortGroup_Main_cb_Descending_ToolTip"], "white") , nil, nil, nil, 1);
			GameTooltip:Show();
		end);
	Main_cb_BottomDescending:SetScript("OnLeave", function(self) GameTooltip:Hide() end)	
	--Combobox Main_cb_TopDescending
	
	Main_cb_BottomAscending:SetScript("OnClick",
		function()
			Debug("Main_cb_BottomAscending", "", 2);
			if ( internValues_DB.inCombat == false or changeableValues_DB.ChangesInCombat == true ) then
				internValues_DB.showChatMessages = true;
				if ( Main_cb_BottomAscending:GetChecked() == true ) then
					defaultValues_DB.BottomDescending = false;
					defaultValues_DB.BottomAscending = true;
				elseif ( Main_cb_BottomAscending:GetChecked() == false ) then	
					defaultValues_DB.BottomAscending = false;
				end
				SaveOptions();
				SortInterstation(false);
				UpdateComboBoxes();
				Debug("checkBoxEvent", "", 1);
			else
				UpdateComboBoxes();
				if ( defaultValues_DB.ChatMessagesOn == true ) then
					print(ColorText(L["SortGroup_in_combat_options_output"], "option"));
				end
			end
		end);		
	Main_cb_BottomAscending:SetScript("OnEnter", 
		function(self)
			GameTooltip:SetOwner(self,"ANCHOR_RIGHT");
			GameTooltip:AddLine(L["SortGroup_Main_cb_Ascending_Text"] .."\n\n" .. ColorText(L["SortGroup_Main_cb_Ascending_ToolTip"], "white") , nil, nil, nil, 1);
			GameTooltip:Show();
		end);
	Main_cb_BottomAscending:SetScript("OnLeave", function(self) GameTooltip:Hide() end)	
	--Combobox Main_cb_TopDescending
		
	Main_cb_AutoActivate:SetScript("OnClick",
		function()
			Debug("Main_cb_AutoActivate", "", 2);
			if ( internValues_DB.inCombat == false or changeableValues_DB.ChangesInCombat == true ) then
				internValues_DB.showChatMessages = true;
				if ( Main_cb_AutoActivate:GetChecked() == true ) then
					defaultValues_DB.AutoActivate = true;
					if ( defaultValues_DB.AutoActivate == true or SortGroup_Variable_Page2_AdditionalSwitchActive == true ) then
						SortInterstation(true);
					else
						SortInterstation(false);
					end
				elseif ( Main_cb_AutoActivate:GetChecked() == false ) then
					defaultValues_DB.AutoActivate = false;
				end
				SaveOptions();
				SortInterstation(false);
				Debug("checkBoxEvent", "", 1);
				UpdateComboBoxes();
			else
				UpdateComboBoxes();
				if ( defaultValues_DB.ChatMessagesOn == true ) then
					print(ColorText(L["SortGroup_in_combat_options_output"], "option"));
				end
			end
		end);		
	Main_cb_AutoActivate:SetScript("OnEnter", 
		function(self)
			GameTooltip:SetOwner(self,"ANCHOR_RIGHT");
			GameTooltip:AddLine(L["SortGroup_Main_cb_AutoActivate_Text"] .."\n\n" .. ColorText(L["SortGroup_Main_cb_AutoActivate_ToolTip"], "white") , nil, nil, nil, 1);
			GameTooltip:Show();
		end);
	Main_cb_AutoActivate:SetScript("OnLeave", function(self) GameTooltip:Hide() end)
	--Combobox AutoActive
		
	Main_cb_AlwaysActive:SetScript("OnClick",
		function()
			Debug("Main_cb_AlwaysActive", "", 2);
			if ( internValues_DB.inCombat == false or changeableValues_DB.ChangesInCombat == true ) then
				internValues_DB.showChatMessages = true;
				if ( Main_cb_AlwaysActive:GetChecked() == true ) then
					defaultValues_DB.AlwaysActive = true;
					UIDropDownMenu_DisableDropDown(Main_ddm_Profiles);
					SortInterstation(false);
				elseif ( Main_cb_AlwaysActive:GetChecked() == false ) then
					defaultValues_DB.AlwaysActive = false;
					Main_cb_AutoActivate:Enable();
					UIDropDownMenu_EnableDropDown(Main_ddm_Profiles);
					getglobal(Main_cb_AutoActivate:GetName() .. 'Text'):SetText(L["SortGroup_Main_cb_AutoActivate_Text"]);
				end
				SaveOptions();
				UpdateComboBoxes();
				SortInterstation(false);
				Debug("checkBoxEvent", "", 1);
			else
				UpdateComboBoxes();
				if ( defaultValues_DB.ChatMessagesOn == true ) then
					print(ColorText(L["SortGroup_in_combat_options_output"], "option"));
				end
			end
		end);		
	Main_cb_AlwaysActive:SetScript("OnEnter", 
		function(self)
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
			GameTooltip:AddLine(L["SortGroup_Main_cb_AlwaysActive_Text"] .."\n\n" .. ColorText(L["SortGroup_Main_cb_AlwaysActive_ToolTip"], "white") , nil, nil, nil, 1);
			GameTooltip:Show();
		end);
	Main_cb_AlwaysActive:SetScript("OnLeave", function(self) GameTooltip:Hide() end)
	--Combobox defaultValues_DB.AlwaysActive
			
	
	Option_cb_ChatMessagesOn:SetScript("OnClick",
		function()
			Debug("Option_cb_ChatMessagesOn", "", 2);
			if ( internValues_DB.inCombat == false or changeableValues_DB.ChangesInCombat == true ) then
				if ( Option_cb_ChatMessagesOn:GetChecked() == true ) then
					defaultValues_DB.ChatMessagesOn = true;
					print(ColorText(L["SortGroup_sort_chat_Messages_On_output"], "option"));
				elseif ( Option_cb_ChatMessagesOn:GetChecked() == false ) then
					defaultValues_DB.ChatMessagesOn = false;
				end
				SaveOptions();
				Debug("checkBoxEvent", "", 1);
				UpdateComboBoxes();
			else
				UpdateComboBoxes(true);
				if ( defaultValues_DB.ChatMessagesOn == true ) then
					print(ColorText(L["SortGroup_in_combat_options_output"], "option"));
				end
			end
		end);
	Option_cb_ChatMessagesOn:SetScript("OnEnter", 
		function(self)
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
			GameTooltip:AddLine(L["SortGroup_Option_cb_ChatMessagesOn_Text"] .."\n\n" .. ColorText(L["SortGroup_Main_cb_ChatMessagesOn_ToolTip"], "white") , nil, nil, nil, 1);
			GameTooltip:Show();
		end);
	Option_cb_ChatMessagesOn:SetScript("OnLeave", function(self) GameTooltip:Hide() end)
	--Combobox defaultValues_DB.ChatMessagesOn
	
	Option_cb_RaidProfilesUpdateInCombat:SetScript("OnClick",
		function()
			Debug("Option_cb_RaidProfilesUpdateInCombat", "", 2);
			if ( internValues_DB.inCombat == false or changeableValues_DB.ChangesInCombat == true ) then
				if ( Option_cb_RaidProfilesUpdateInCombat:GetChecked() == true ) then
					defaultValues_DB.RaidProfileBlockInCombat = true;
				elseif ( Option_cb_RaidProfilesUpdateInCombat:GetChecked() == false ) then
					defaultValues_DB.RaidProfileBlockInCombat = false;
				end
				SaveOptions();
				Debug("Option_cb_RaidProfilesUpdateInCombat", "", 1);
				UpdateComboBoxes();
			else
				UpdateComboBoxes();
				if ( defaultValues_DB.ChatMessagesOn == true ) then
					print(ColorText(L["SortGroup_in_combat_options_output"], "option"));
				end
			end
		end);
	Option_cb_RaidProfilesUpdateInCombat:SetScript("OnEnter", 
		function(self)
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
			GameTooltip:AddLine(L["SortGroup_Option_cb_RaidProfilesUpdateInCombat_Text"] .."\n\n" .. ColorText(L["SortGroup_Option_cb_RaidProfilesUpdateInCombat_ToolTip"], "white") , nil, nil, nil, 1);
			GameTooltip:Show();
		end);
	Option_cb_RaidProfilesUpdateInCombat:SetScript("OnLeave", function(self) GameTooltip:Hide() end)
	--Combobox defaultValues_DB.RaidProfileBlockInCombat
end
--ComboBox Events

local function buttonEvent()
	Debug("buttonEvent", "", 2);
	
	Main_btn_Reload:SetScript("OnClick",
		function()
			ReloadUI();
	end);
end
---End Events



local loader = CreateFrame("Frame")
loader:RegisterEvent("ADDON_LOADED")
loader:SetScript("OnEvent", function(self, event, arg1)
	if event == "ADDON_LOADED" and arg1 == "SortGroup" then
		Debug("StartAddon", "", 2);
		createFrame();
		createText();
		createCheckbox();
		createButton();
		createDropDownMenu();
		frameEvent();	
		checkBoxEvent();
		buttonEvent();
		self:UnregisterEvent("ADDON_LOADED")
	end
end)