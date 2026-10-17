local ASCENSION_PROTECTED_ADDONS

TOOLTIP_UPDATE_TIME = 0.2;
ROTATIONS_PER_SECOND = .5;
ASCENSION_PATCH = 1.15;

-- Alpha animation stuff
FADEFRAMES = {};
FLASHFRAMES = {};

-- Pulsing stuff
PULSEBUTTONS = {};

-- Shine animation
SHINES_TO_ANIMATE = {};

-- Per panel settings
UIPanelWindows = {};
UIPanelWindows["EscapeMenu"] =		{ area = "center",	pushable = 0,	whileDead = 1 };
UIPanelWindows["VideoOptionsFrame"] =		{ area = "center",	pushable = 0,	whileDead = 1 };
UIPanelWindows["AudioOptionsFrame"] =		{ area = "center",	pushable = 0,	whileDead = 1 };
UIPanelWindows["InterfaceOptionsFrame"] =	{ area = "center",	pushable = 0,	whileDead = 1 };
UIPanelWindows["CharacterFrame"] =		{ area = "left",	pushable = 3 , width = 622,	whileDead = 1 };
UIPanelWindows["AscensionCharacterFrame"] =		{ area = "left",	pushable = 3 , width = 574,	whileDead = 1, xoffset="22" };
UIPanelWindows["ItemTextFrame"] =		{ area = "left",	pushable = 0 };
UIPanelWindows["AscensionSpellbookFrame"] =		{ area = "left",	pushable = 0, width = 604, whileDead = 1, xoffset="22", yoffset="-22"};
UIPanelWindows["LootFrame"] =			{ area = "left",	pushable = 7 };
UIPanelWindows["TaxiFrame"] =			{ area = "left",	pushable = 0 };
UIPanelWindows["QuestFrame"] =			{ area = "left",	pushable = 0 };
UIPanelWindows["QuestLogFrame"] =		{ area = "doublewide",	pushable = 0,	whileDead = 1 };
UIPanelWindows["QuestLogDetailFrame"] =		{ area = "left",	pushable = 1,	whileDead = 1 };
UIPanelWindows["MerchantFrame"] =		{ area = "left",	pushable = 0 };
UIPanelWindows["TradeFrame"] =			{ area = "left",	pushable = 1 };
UIPanelWindows["BankFrame"] =			{ area = "left",	pushable = 6,	width = 425 };
UIPanelWindows["FriendsFrame"] =		{ area = "left",	pushable = 0,	whileDead = 1 };
UIPanelWindows["WorldMapFrame"] =		{ area = "full",	pushable = 0,	whileDead = 1 };
UIPanelWindows["CinematicFrame"] =		{ area = "full",	pushable = 0 };
UIPanelWindows["TabardFrame"] =			{ area = "left",	pushable = 0 };
UIPanelWindows["PVPBannerFrame"] =		{ area = "left",	pushable = 0 };
UIPanelWindows["GuildRegistrarFrame"] =		{ area = "left",	pushable = 0 };
UIPanelWindows["ArenaRegistrarFrame"] =		{ area = "left",	pushable = 0 };
UIPanelWindows["PetitionFrame"] =		{ area = "left",	pushable = 0 };
UIPanelWindows["GossipFrame"] =			{ area = "left",	pushable = 0 };
UIPanelWindows["MailFrame"] =			{ area = "left",	pushable = 0 };
UIPanelWindows["BattlefieldFrame"] =		{ area = "left",	pushable = 0,	whileDead = 1 };
UIPanelWindows["PetStableFrame"] =		{ area = "left",	pushable = 0 };
UIPanelWindows["WorldStateScoreFrame"] =	{ area = "center",	pushable = 0,	whileDead = 1 };
UIPanelWindows["DressUpFrame"] =		{ area = "left",	pushable = 2 };
UIPanelWindows["MinigameFrame"] =		{ area = "left",	pushable = 0 };
UIPanelWindows["LFGParentFrame"] =		{ area = "left",	pushable = 0,	whileDead = 1 };
UIPanelWindows["AscensionLFGFrame"] = 	{ area = "left",	pushable = 1, 	whileDead = 1, xoffset="58", yoffset="22" };
UIPanelWindows["LFDParentFrame"] =		{ area = "left",	pushable = 0,	whileDead = 1 };
UIPanelWindows["LFRParentFrame"] =		{ area = "left",	pushable = 1,	whileDead = 1 };
UIPanelWindows["ArenaFrame"] =			{ area = "left",	pushable = 0 };
UIPanelWindows["ChatConfigFrame"] =		{ area = "center",	pushable = 0,	whileDead = 1 };
UIPanelWindows["PVPParentFrame"] =			{ area = "left",	pushable = 0,	whileDead = 1 };
UIPanelWindows["Collections"] = { area = "center", pushable = 0, whileDead = 1, allowOtherPanels = true, dontCloseForNonCenterPanels = true }
UIPanelWindows["PathToAscensionFrame"] = { area = "center", pushable = 0, whileDead = 1, dontCloseForNonCenterPanels = true }
UIPanelWindows["AscensionInspectFrame"] = { area = "left", pushable = 3 , width = 574, whileDead = 1, xoffset="22" };
UIPanelWindows["RandomModeGossipFrame"] = { area = "center", pushable = 0, whileDead = 1, allowOtherPanels = true, dontCloseForNonCenterPanels = true }

local function GetUIPanelWindowInfo(frame, name)
	if ( not frame:GetAttribute("UIPanelLayout-defined") ) then
	    local info = UIPanelWindows[frame:GetName()];
	    if ( not info ) then
			return;
	    end
		frame:SetAttribute("UIPanelLayout-defined", true);
	    for name,value in pairs(info) do
			frame:SetAttribute("UIPanelLayout-"..name, value);
		end
		frame:SetAttribute("UIPanelLayout-enabled", true);
	end
	if ( frame:GetAttribute("UIPanelLayout-enabled") ) then
		return frame:GetAttribute("UIPanelLayout-"..name);
	end
end

-- These are windows that rely on a parent frame to be open.  If the parent closes or a pushable frame overlaps them they must be hidden.
UIChildWindows = {
	"OpenMailFrame",
	"GuildControlPopupFrame",
	"GuildMemberDetailFrame",
	"TokenFramePopup",
	"GuildInfoFrame",
	"PVPTeamDetails",
	"GuildBankPopupFrame",
	"GearManagerDialog",
};

UISpecialFrames = {
	"ItemRefTooltip",
	"ColorPickerFrame",
	"ChallengesFrame",
	"HelpMenuFrame",
	"ManastormQueueFrame",
	"ErrorHandler",
	"TicketFrame",
};

UIMenus = {
	"ChatMenu",
	"EmoteMenu",
	"LanguageMenu",
	"DropDownList1",
	"DropDownList2",
};

function UIParent_OnLoad(self)
	self:RegisterEvent("PLAYER_LOGIN");
	self:RegisterEvent("PLAYER_DEAD");
	self:RegisterEvent("PLAYER_ALIVE");
	self:RegisterEvent("PLAYER_UNGHOST");
	self:RegisterEvent("RESURRECT_REQUEST");
	self:RegisterEvent("PLAYER_SKINNED");
	self:RegisterEvent("TRADE_REQUEST");
	self:RegisterEvent("CHANNEL_INVITE_REQUEST");
	self:RegisterEvent("CHANNEL_PASSWORD_REQUEST");
	self:RegisterEvent("PARTY_INVITE_REQUEST");
	self:RegisterEvent("PARTY_INVITE_CANCEL");
	self:RegisterEvent("REQUEST_GROUP_INVITE")
	self:RegisterEvent("REQUEST_GROUP_FINDER_INVITE")
	self:RegisterEvent("SUGGESTED_GROUP_INVITE")
	self:RegisterEvent("GUILD_INVITE_REQUEST");
	self:RegisterEvent("GUILD_INVITE_CANCEL");
	self:RegisterEvent("ARENA_TEAM_INVITE_REQUEST");
	self:RegisterEvent("PLAYER_CAMPING");
	self:RegisterEvent("PLAYER_QUITING");
	self:RegisterEvent("LOGOUT_CANCEL");
	self:RegisterEvent("LOOT_BIND_CONFIRM");
	self:RegisterEvent("EQUIP_BIND_CONFIRM");
	self:RegisterEvent("AUTOEQUIP_BIND_CONFIRM");
	self:RegisterEvent("USE_BIND_CONFIRM");
	self:RegisterEvent("DELETE_ITEM_CONFIRM");
	self:RegisterEvent("QUEST_ACCEPT_CONFIRM");
	self:RegisterEvent("QUEST_LOG_UPDATE");
	self:RegisterEvent("UNIT_QUEST_LOG_CHANGED");
	self:RegisterEvent("CURSOR_UPDATE");
	self:RegisterEvent("LOCALPLAYER_PET_RENAMED");
	self:RegisterEvent("PLAYER_ENTERING_WORLD");
	self:RegisterEvent("MIRROR_TIMER_START");
	self:RegisterEvent("DUEL_REQUESTED");
	self:RegisterEvent("DUEL_OUTOFBOUNDS");
	self:RegisterEvent("DUEL_INBOUNDS");
	self:RegisterEvent("DUEL_FINISHED");
	self:RegisterEvent("TRADE_REQUEST_CANCEL");
	self:RegisterEvent("CONFIRM_XP_LOSS");
	self:RegisterEvent("CORPSE_IN_RANGE");
	self:RegisterEvent("CORPSE_IN_INSTANCE");
	self:RegisterEvent("CORPSE_OUT_OF_RANGE");
	self:RegisterEvent("AREA_SPIRIT_HEALER_IN_RANGE");
	self:RegisterEvent("AREA_SPIRIT_HEALER_OUT_OF_RANGE");
	self:RegisterEvent("BIND_ENCHANT");
	self:RegisterEvent("REPLACE_ENCHANT");
	self:RegisterEvent("TRADE_REPLACE_ENCHANT");
	self:RegisterEvent("END_REFUND");
	self:RegisterEvent("END_BOUND_TRADEABLE");
	self:RegisterEvent("CURRENT_SPELL_CAST_CHANGED");
	self:RegisterEvent("MACRO_ACTION_BLOCKED");
	self:RegisterEvent("ADDON_ACTION_BLOCKED");
	self:RegisterEvent("MACRO_ACTION_FORBIDDEN");
	self:RegisterEvent("ADDON_ACTION_FORBIDDEN");
	self:RegisterEvent("PLAYER_CONTROL_LOST");
	self:RegisterEvent("PLAYER_CONTROL_GAINED");
	self:RegisterEvent("START_LOOT_ROLL");
	self:RegisterEvent("CONFIRM_LOOT_ROLL");
	self:RegisterEvent("CONFIRM_DISENCHANT_ROLL");
	self:RegisterEvent("INSTANCE_BOOT_START");
	self:RegisterEvent("INSTANCE_BOOT_STOP");
	self:RegisterEvent("INSTANCE_LOCK_START");
	self:RegisterEvent("INSTANCE_LOCK_STOP");
	self:RegisterEvent("CONFIRM_TALENT_WIPE");
	self:RegisterEvent("CONFIRM_BINDER");
	self:RegisterEvent("CONFIRM_SUMMON");
	self:RegisterEvent("CANCEL_SUMMON");
	self:RegisterEvent("GOSSIP_CONFIRM");
	self:RegisterEvent("GOSSIP_CONFIRM_CANCEL");
	self:RegisterEvent("GOSSIP_ENTER_CODE");
	self:RegisterEvent("GOSSIP_CLOSED");
	self:RegisterEvent("BILLING_NAG_DIALOG");
	self:RegisterEvent("IGR_BILLING_NAG_DIALOG");
	self:RegisterEvent("VARIABLES_LOADED");
	self:RegisterEvent("RAID_ROSTER_UPDATE");
	self:RegisterEvent("RAID_INSTANCE_WELCOME");
	self:RegisterEvent("LEVEL_GRANT_PROPOSED");
	self:RegisterEvent("RAISED_AS_GHOUL");
	self:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
	self:RegisterEvent("PARTY_MEMBERS_CHANGED")
	self:RegisterEvent("DISPLAY_SIZE_CHANGED")
	self:RegisterEvent("UPDATE_INSTANCE_INFO")

	-- Events for auction UI handling
	self:RegisterEvent("AUCTION_HOUSE_SHOW");
	self:RegisterEvent("AUCTION_HOUSE_CLOSED");
	self:RegisterEvent("AUCTION_HOUSE_DISABLED");
	
	-- Events for trainer UI handling
	self:RegisterEvent("TRAINER_SHOW");
	self:RegisterEvent("TRAINER_CLOSED");

	-- Events for trade skill UI handling
	self:RegisterEvent("TRADE_SKILL_SHOW");
	self:RegisterEvent("TRADE_SKILL_CLOSE");

	-- Events for Item socketing UI
	self:RegisterEvent("SOCKET_INFO_UPDATE");

	-- Events for taxi benchmarking
	self:RegisterEvent("ENABLE_TAXI_BENCHMARK");
	self:RegisterEvent("DISABLE_TAXI_BENCHMARK");

	-- Push to talk
	self:RegisterEvent("VOICE_PUSH_TO_TALK_START");
	self:RegisterEvent("VOICE_PUSH_TO_TALK_STOP");

	-- Events for BarberShop Handling
	self:RegisterEvent("BARBER_SHOP_OPEN");
	self:RegisterEvent("BARBER_SHOP_CLOSE");

	-- Events for Guild bank UI
	self:RegisterEvent("GUILDBANKFRAME_OPENED");
	self:RegisterEvent("GUILDBANKFRAME_CLOSED");

	-- Events for Achievements!
	self:RegisterEvent("ACHIEVEMENT_EARNED");

	-- Events for Glyphs!
	self:RegisterEvent("USE_GLYPH");

	--Events for GMChatUI
	self:RegisterEvent("CHAT_MSG_WHISPER");
	
	-- Events for WoW Mouse
	self:RegisterEvent("WOW_MOUSE_NOT_FOUND");
	
	-- Events for talent wipes
	self:RegisterEvent("TALENTS_INVOLUNTARILY_RESET");

	-- Events for Addons Loaded
	--self:RegisterEvent("ADDON_LOADED");
	
	-- Challenges Sync
	self:RegisterEvent("CHALLENGE_SYNC_REQUEST")
	
	-- Manastorm
	self:RegisterEvent("ACTIVE_MANASTORM_UPDATED")
	
	self:RegisterEvent("PLAYER_LEVEL_UP")
	
	-- Appearance Collection
	self:RegisterEvent("UNLOCKED_APPEARANCE_ITEM_USED")
	self:RegisterEvent("APPEARANCE_COLLECTED")
	self:RegisterEvent("APPEARANCE_UNCOLLECTED")
	
	-- Path to Ascension
	self:RegisterEvent("TUTORIAL_ENTRY_ADDED")
	self:RegisterEvent("TUTORIAL_ENTRY_COMPLETE")

	self:RegisterEvent("PLAYER_UPDATE_RESTING")

	self:RegisterEvent("SKILL_CARD_BLOCKED")
    self:RegisterEvent("PLAYER_POLL_NEW_POLL")
	
	self.RequestedInvites = {}
	self.firstTimeLoaded = 1
	self.useScaledUI = true
	self._SetScale = self.SetScale
	self.SetScale = function(self, scale)
		self.useScaledUI = false
		self:_SetScale(scale)
	end
end

function UIParent_OnShow(self)
	if self.firstTimeLoaded ~= 1 then
		CloseAllWindows()
	end
	self.firstTimeLoaded = nil
end

local cachedScreenResolution
function GetScreenResolution()
	if cachedScreenResolution then
		return unpack(cachedScreenResolution)
	end
	local resolution = select(GetCurrentResolution(), GetScreenResolutions())
	if not resolution then
		return GetScreenWidth(), GetScreenHeight()
	end
	local w, h = string.match(resolution, "(%d+)x(%d+)")
	if issecure() then
		cachedScreenResolution = { tonumber(w) or GetScreenWidth(), tonumber(h) or GetScreenHeight() }
		return unpack(cachedScreenResolution)
	else
		return tonumber(w) or GetScreenWidth(), tonumber(h) or GetScreenHeight()
	end
end
hooksecurefunc("SetScreenResolution", function()
	cachedScreenResolution = nil
end)


-- Addons --

local FailedAddOnLoad = {};

function UIParentLoadAddOn(name)
	local loaded, reason = LoadAddOn(name);
	if ( not loaded ) then
		if ( not FailedAddOnLoad[name] ) then
			message(format(ADDON_LOAD_FAILED, name, _G["ADDON_"..reason]));
			FailedAddOnLoad[name] = true;
		end
	end
	return loaded;
end

function Manastorm_LoadUI()
	UIParent:UnregisterEvent("ACTIVE_MANASTORM_UPDATED")
	UIParentLoadAddOn("Ascension_Manastorm")
end

function Poll_LoadUI()
    UIParentLoadAddOn("Ascension_Poll")
end

function CharacterAdvancement_LoadUI()
	if IsCustomClass() then
		UIParentLoadAddOn("Ascension_CoATalents")
		return
	end

	if IsDefaultClass() then
		UIParentLoadAddOn("Ascension_CharacterAdvancement")
		return
	end

	local useLegacy = C_Config.GetBoolConfig("CONFIG_LEGACY_CHARACTER_ADVANCEMENT_ENABLED")
	if useLegacy == nil or useLegacy == true or CA_FORCE_LEGACY then
		UIParentLoadAddOn("Ascension_CharacterAdvancementSeason9")
	else
		UIParentLoadAddOn("Ascension_CharacterAdvancement")
	end
end

function ForcedPrimaryStat_LoadUI()
	CharacterAdvancement_LoadUI()
	UIParentLoadAddOn("Ascension_ForcedPrimaryStat")
end

function BuildCreator_LoadUI()
	-- this has to be done here so we can beat OnShow for everything. 
	-- Collections tab PreClick will trigger this
	if C_Player:IsMaxLevel() or C_Player:IsPrestiged() then
		C_CVar.Set("ShowFullBuildCreator", "1")
	end
	UIParentLoadAddOn("Ascension_BuildCreator")
end

function Draft_LoadUI()
	UIParentLoadAddOn("Ascension_RandomModeShared")
	UIParentLoadAddOn("Ascension_Draft")
end

function WildCard_LoadUI()
	if IsAddOnLoaded("Ascension_WildCard") then
		WildCard:RegisterEvents()
		WildCard:CheckForRolls()
	else
		UIParentLoadAddOn("Ascension_RandomModeShared")
		UIParentLoadAddOn("Ascension_WildCard")
	end
end

function SkillCards_LoadUI()
	UIParentLoadAddOn("Ascension_SkillCards")
end

function NamePlates_LoadUI()
	C_CVar.Set("useNewNameplates", true)
	UIParentLoadAddOn("Ascension_NamePlates")
end
function AscensionChallenges_LoadUI()
	UIParentLoadAddOn("Ascension_ChallengesUI")
end

function AscensionHelpUI_LoadUI()
	UIParentLoadAddOn("Ascension_HelpUI")
end

function PathToAscensionUI_LoadUI()
	UIParentLoadAddOn("Ascension_PathToAscension")
end

function AuctionFrame_LoadUI()
	UIParentLoadAddOn("Blizzard_AuctionUI");
end

function BattlefieldMinimap_LoadUI()
	UIParentLoadAddOn("Blizzard_BattlefieldMinimap");
end

function ClassTrainerFrame_LoadUI()
	UIParentLoadAddOn("Blizzard_TrainerUI");
end

function AppearanceUI_LoadUI()
	UIParentLoadAddOn("Ascension_AppearanceUI")
end

function VanityCollection_LoadUI()
	UIParentLoadAddOn("Ascension_VanityCollection")
end

function OpenStoreCollectionAndSearch(text)
	VanityCollection_LoadUI()
	if VanityCollectionUtil and VanityCollectionUtil.OpenAndSearch then
		VanityCollectionUtil.OpenAndSearch(text)
	end
end

function OpenStoreCollectionToCategory(category, searchText)
	VanityCollection_LoadUI()
	if VanityCollectionUtil and VanityCollectionUtil.OpenToCategory then
		VanityCollectionUtil.OpenToCategory(category, searchText)
	end
end

function SeasonCollection_LoadUI()
	UIParentLoadAddOn("Ascension_SeasonCollection")
end

function MysticEnchant_LoadUI()
	UIParentLoadAddOn("Ascension_EnchantCollection")
end

function MythicPlus_LoadUI()
	UIParentLoadAddOn("Ascension_MythicPlus")
end

function CombatLog_LoadUI()
	UIParentLoadAddOn("Blizzard_CombatLog");
end

function GuildBankFrame_LoadUI()
	UIParentLoadAddOn("Blizzard_GuildBankUI");
end

function InspectFrame_LoadUI()
	UIParentLoadAddOn("Blizzard_InspectUI");
end

function AscensionInspectFrame_LoadUI()
	UIParentLoadAddOn("Ascension_InspectUI");
end

function KeyBindingFrame_LoadUI()
	UIParentLoadAddOn("Blizzard_BindingUI");
end

function MacroFrame_LoadUI()
	UIParentLoadAddOn("Blizzard_MacroUI");
end

function AddonPanel_LoadUI()
	UIParentLoadAddOn("Ascension_AddonPanel");
end

function MacroFrame_SaveMacro()
	-- this will be overwritten with the real thing when the addon is loaded
end

function RaidFrame_LoadUI()
	UIParentLoadAddOn("Blizzard_RaidUI");
end

function TalentFrame_LoadUI()
	UIParentLoadAddOn("Blizzard_TalentUI");
end

function TradeSkillFrame_LoadUI()
	UIParentLoadAddOn("Blizzard_TradeSkillUI");
end

function GMSurveyFrame_LoadUI()
	UIParentLoadAddOn("Blizzard_GMSurveyUI");
end

function ItemSocketingFrame_LoadUI()
	UIParentLoadAddOn("Blizzard_ItemSocketingUI");
end

function BarberShopFrame_LoadUI()
	UIParentLoadAddOn("Blizzard_BarberShopUI");
end

function AchievementFrame_LoadUI()
	UIParentLoadAddOn("Blizzard_AchievementUI");
end

function TimeManager_LoadUI()
	UIParentLoadAddOn("Blizzard_TimeManager");
end

function TokenFrame_LoadUI()
	UIParentLoadAddOn("Blizzard_TokenUI");
end

function GlyphFrame_LoadUI()
	UIParentLoadAddOn("Blizzard_GlyphUI");
end

function Calendar_LoadUI()
	UIParentLoadAddOn("Blizzard_Calendar");
end

function GMChatFrame_LoadUI(...)
	if ( IsAddOnLoaded("Blizzard_GMChatUI") ) then
		return;
	else
		UIParentLoadAddOn("Blizzard_GMChatUI");
		if ( select(1, ...) ) then
			GMChatFrame_OnEvent(GMChatFrame, ...);
		end
	end
end

function Arena_LoadUI()
	UIParentLoadAddOn("Blizzard_ArenaUI");
end

function NewPlayerExperience_LoadUI()
	UIParentLoadAddOn("Ascension_NewPlayerExperience");
end

function ShowTicketFrame()
	AscensionHelpUI_LoadUI()
	if HelpMenuFrame then
		ShowUIPanel(HelpMenuFrame)
		HelpMenuFrame:OpenTicketTab()
	end
end

function ShowItemRecovery(category)
	CloseGossip()
	AscensionHelpUI_LoadUI()
	if HelpMenuFrame then
		ShowUIPanel(HelpMenuFrame)
		HelpMenuFrame:OpenItemRecovery(category)
	end
end

function ShowMacroFrame()
	MacroFrame_LoadUI();
	if ( MacroFrame_Show ) then
		MacroFrame_Show();
	end
end

function ShowAddonsPanel()
	AddonPanel_LoadUI()
	if AddonPanel then
		ShowUIPanel(AddonPanel)
	end
end

function ShowAppearanceWardrobe()
	Collections:GoToTab(Collections.Tabs.Wardrobe)
end

function ShowAppearanceCategory(appearanceType, categoryID)
	Collections:GoToTab(Collections.Tabs.Wardrobe)
	AppearanceUI.OpenCategory(appearanceType, categoryID)
end

function TryOnAppearance(appearanceType, categoryID, appearanceID, itemName)
	Collections:GoToTab(Collections.Tabs.Wardrobe)
	AppearanceUI.OpenToTryOn(appearanceType, categoryID, appearanceID, itemName)
end

function ShowSkillCards()
	SkillCards_LoadUI()
	
	CloseGossip()
	if Collections then

		if (C_GameMode:IsGameModeActive(Enum.GameMode.WildCard) or C_GameMode:IsGameModeActive(Enum.GameMode.Draft)) then
			if SkillCardsFrame and SkillCardsFrame:GetParent() ~= Collections then
				SkillCardsFrame:SetParent(Collection)
				SkillCardsFrame:ClearAndSetPoint("BOTTOM", 0, 8)
			end

			if not(Collections.Tabs.SkillCards) then
				Collections:SwapHeroArchitectTabToSkillCards()
			end

			Collections:GoToTab(Collections.Tabs.SkillCards) 
		else
			if SkillCardsFrame then
				SkillCardsFrame:SetParent(UIParent)
				SkillCardsFrame:ClearAndSetPoint("CENTER", 0, 0)
				SkillCardsFrame:Show()
			end
		end
	end
end

function ShowForcedPrimaryStat(skipCheck, crossLayout)
	local canChoosePrimaryStat = C_Player:IsHero()

	if not(canChoosePrimaryStat) then
		return false
	end

	if not(skipCheck) and C_PrimaryStat:GetActivePrimaryStat() then
		return false
	end
	
	ForcedPrimaryStat_LoadUI()
	ForcedPrimaryStatFrame.crossLayout = crossLayout

	if crossLayout and CharacterAdvancement then
		ForcedPrimaryStatFrame:ClearAndSetPoint("TOP", CharacterAdvancement.SideBar.SpellList.Header.NineSlice.PrimaryStat1, "BOTTOM", 0, 0)
	else
		ForcedPrimaryStatFrame:ClearAndSetPoint("TOP", UIParent, 0, -96)
	end

	BaseFrameFadeIn(ForcedPrimaryStatFrame)

	return true
end

function InspectAchievements (unit)
	AchievementFrame_LoadUI();
	AchievementFrame_DisplayComparison(unit);
end

function ToggleAchievementFrame(stats)
	if ( not CanShowAchievementUI() or not HasCompletedAnyAchievement() ) then
		return;
	end
	AchievementFrame_LoadUI();
	AchievementFrame_ToggleAchievementFrame(stats);
end

function ToggleTalentFrame()
	if HasPetUI() and PetCanBeAbandoned() then
		TalentFrame_LoadUI();
		if ( PlayerTalentFrame_Toggle ) then
			PlayerTalentFrame_Toggle(true, 3);
		end
	end
end

function ToggleCollections()
	HelpTip:Hide("HELP_TIP_NEW_SPELL_RANK")
	HelpTip:Hide("HELP_TIP_UNSPENT_ESSENCE")

	if Collections:IsShown() then
		HideUIPanel(Collections)
	elseif (IsCustomClass() and (UnitLevel("player") < 10)) then
		Collections:GoToTab(Collections.Tabs.Vanity) -- go to vanity collection if level is below 10
	elseif C_GameMode:IsGameModeActive(Enum.GameMode.BuildDraft) then
		Collections:GoToTab(Collections.Tabs.HeroArchitect)
	else
		Collections:GoToTab(Collections.Tabs.CharacterAdvancement)
	end
end

function ToggleGlyphFrame()
	if ( UnitLevel("player") < SHOW_INSCRIPTION_LEVEL ) then
		return;
	end

	GlyphFrame_LoadUI();
	if ( GlyphFrame_Toggle ) then
		GlyphFrame_Toggle();
	end
end

function OpenGlyphFrame()
	if ( UnitLevel("player") < SHOW_INSCRIPTION_LEVEL ) then
		return;
	end

	GlyphFrame_LoadUI();
	if ( GlyphFrame_Open ) then
		GlyphFrame_Open();
	end
end

function ToggleBattlefieldMinimap()
	BattlefieldMinimap_LoadUI();
	if ( BattlefieldMinimap_Toggle ) then
		BattlefieldMinimap_Toggle();
	end
end

function ToggleTimeManager()
	TimeManager_LoadUI();
	if ( TimeManager_Toggle ) then
		TimeManager_Toggle();
	end
end

function ToggleCalendar()
	Calendar_LoadUI();
	if ( Calendar_Toggle ) then
		Calendar_Toggle();
	end
end

function ToggleLFDParentFrame()
	if AscensionPVEFrame:IsVisible() then
		HideUIPanel(AscensionLFGFrame)
	elseif C_Player:GetLevel() >= SHOW_LFD_LEVEL then
		AscensionLFGFrame:ShowFrame("AscensionPVEFrame")
	elseif C_Manastorm.IsInManastorm() or C_Manastorm.CanEnter(1) then
		AscensionLFGFrame:ShowFrame("AscensionPVEFrame")
	end
end

function ToggleLFRParentFrame()
	if AscensionPVEFrame:IsVisible() then
        HideUIPanel(AscensionLFGFrame)
    elseif C_Player:GetLevel() >= SHOW_LFD_LEVEL then
        AscensionLFGFrame:ShowFrame("AscensionPVEFrame", 1)
    end
end

function TogglePathToAscensionFrame()
	PathToAscensionUI_LoadUI()
	if PathToAscensionFrame then
		ToggleFrame(PathToAscensionFrame)
	end
end

function OpenPathToAscensionAppendix(keywordID)
	PathToAscensionUI_LoadUI()
	if PathToAscensionFrame then
		ShowUIPanel(PathToAscensionFrame)
		PathToAscensionFrame:SelectTabID(PathToAscensionFrame.AppendixTab)
		if keywordID then
			PathToAscensionFrame.AppendixPanel:SelectSpecificKeyword(keywordID)
		end
	end
end

function ToggleHelpFrame()
	AscensionHelpUI_LoadUI()
	if HelpMenuFrame then
		if ( HelpMenuFrame:IsShown() ) then
			HideUIPanel(HelpMenuFrame);
		else
			StaticPopup_Hide("HELP_TICKET");
			StaticPopup_Hide("HELP_TICKET_ABANDON_CONFIRM");
			StaticPopup_Hide("GM_RESPONSE_NEED_MORE_HELP");
			StaticPopup_Hide("GM_RESPONSE_RESOLVE_CONFIRM");
			StaticPopup_Hide("GM_RESPONSE_MUST_RESOLVE_RESPONSE");
			ShowUIPanel(HelpMenuFrame)
		end
	end
end

function ToggleChallengesUI()
	if not ChallengesFrame then
		UIParentLoadAddOn("Ascension_ChallengesUI");
	end
	if ChallengesFrame then
		if ChallengesFrame:IsShown() then
			HideUIPanel(ChallengesFrame)
		else
			ShowUIPanel(ChallengesFrame)
		end
	end
end

function OpenChallengesUI()
	if not ChallengesFrame then
		UIParentLoadAddOn("Ascension_ChallengesUI");
	end
	if ChallengesFrame then
		if not ChallengesFrame:IsShown() then
			ShowUIPanel(ChallengesFrame)
		end
	end
end

function CloseChallengesUI()
	if not ChallengesFrame then
		return
	end
	if ChallengesFrame:IsShown() then
		HideUIPanel(ChallengesFrame)
	end
end

function OpenTicketUI()
	if not TicketFrame then
		UIParentLoadAddOn("Ascension_TicketUI")
	end

	if HelpMenuFrame and HelpMenuFrame:IsShown() then
		HideUIPanel(HelpMenuFrame)
	end
	
	ShowUIPanel(TicketFrame)
end

function ToggleTicketUI()
	if TicketFrame and TicketFrame:IsShown() then
		HideUIPanel(TicketFrame)
	else
		OpenTicketUI()
	end
end

function InspectUnit(unit)
	AscensionInspectFrame_LoadUI();
	if AscensionInspectFrame then
		AscensionInspectFrame:InspectUnit(unit)
	end
end


-- UIParent_OnEvent --

function UIParent_OnEvent(self, event, ...)
	local arg1, arg2, arg3, arg4, arg5, arg6 = ...;
	if ( event == "VARIABLES_LOADED" ) then
		self.variablesLoaded = true
		-- force overlap nameplates. 
		if not C_CVar.GetBool("nameplateAllowOverlap") then
			C_CVar.Set("nameplateAllowOverlap", true)
		end
		if C_CVar.GetBool("useNewNameplates") then
			UIParentLoadAddOn("Ascension_NamePlates")
		end
		LocalizeFrames();
		if ( WorldStateFrame_CanShowBattlefieldMinimap() ) then
			if ( not BattlefieldMinimap ) then
				BattlefieldMinimap_LoadUI();
			end
			BattlefieldMinimap:Show();
		end
		if ( not TimeManagerFrame and GetCVar("timeMgrAlarmEnabled") == "1" ) then
			-- We have to load the time manager here if the alarm is enabled because the alarm can go off
			-- even if the clock is not shown. WorldFrame_OnUpdate handles alarm checking while the clock
			-- is hidden.
			TimeManager_LoadUI();
		end
		local lastTalkedToGM = GetCVar("lastTalkedToGM");
		if ( lastTalkedToGM ~= "" ) then
			GMChatFrame_LoadUI();
			GMChatFrame:Show()
			local info = ChatTypeInfo["WHISPER"];
			GMChatFrame:AddMessage(format(GM_CHAT_LAST_SESSION, GM_CHAT_BADGE.."|HplayerGM:"..lastTalkedToGM.."|h".."["..lastTalkedToGM.."]".."|h"), info.r, info.g, info.b, info.id);
		end

		if not C_CVar.GetBool("useUiScale") then
			RunNextFrame(function()
				if self.useScaledUI and not C_CVar.GetBool("useUiScale") then
					self:_SetScale(0.9)
					self.rescaled = true
				end
			end)
		end
		return;
	end
	if ( event == "PLAYER_LOGIN" ) then
		-- You can override this if you want a Combat Log replacement
        if C_PVP:IsLegacyWarmode() then
            UIParentLoadAddOn("Ascension_WarmodeLegacy")
        else
            UIParentLoadAddOn("Ascension_Warmode")
        end
		CombatLog_LoadUI();
		return;
	end
	if ( event == "PLAYER_DEAD" ) then
		if ( not StaticPopup_Visible("DEATH") ) then
			CloseAllWindows(1);
			if ( GetReleaseTimeRemaining() > 0 or GetReleaseTimeRemaining() == -1 ) then
				StaticPopup_Show("DEATH");
			end
		end
		return;
	end	
	if ( event == "PLAYER_ALIVE" or event == "RAISED_AS_GHOUL" ) then
		StaticPopup_Hide("DEATH");
		StaticPopup_Hide("RESURRECT_NO_SICKNESS");
		IronSoulNotificationFrame:Hide()
		return;
	end
	if (event == "PLAYER_EQUIPMENT_CHANGED") then
		if (arg1 == INVSLOT_RANGED or arg1 == INVSLOT_AMMO) and arg2 then
			if IsSpellIDKnown(75) then
				SetAutoRangedCombatSpell(75)
			end
		end
		return
	end
	if ( event == "PLAYER_UNGHOST" ) then
		StaticPopup_Hide("RESURRECT");
		StaticPopup_Hide("RESURRECT_NO_SICKNESS");
		StaticPopup_Hide("RESURRECT_NO_TIMER");
		StaticPopup_Hide("SKINNED");
		StaticPopup_Hide("SKINNED_REPOP");
		IronSoulNotificationFrame:Hide()
		return;
	end
	if ( event == "RESURRECT_REQUEST" ) then
		ShowResurrectRequest(arg1);
		return;
	end
	if ( event == "PLAYER_SKINNED" ) then
		StaticPopup_Hide("RESURRECT");
		StaticPopup_Hide("RESURRECT_NO_SICKNESS");
		StaticPopup_Hide("RESURRECT_NO_TIMER");

		--[[
		if (arg1 == 1) then
			StaticPopup_Show("SKINNED_REPOP");
		else
			StaticPopup_Show("SKINNED");
		end
		]]
		UIErrorsFrame:AddMessage(DEATH_CORPSE_SKINNED, 1.0, 0.1, 0.1, 1.0);
		return;		
	end
	if ( event == "TRADE_REQUEST" ) then
		StaticPopup_Show("TRADE", arg1);
		return;
	end
	if ( event == "CHANNEL_INVITE_REQUEST" ) then
		local dialog = StaticPopup_Show("CHAT_CHANNEL_INVITE", arg1, arg2);
		if ( dialog ) then
			dialog.data = arg1;
		end
		return;
	end
	if ( event == "CHANNEL_PASSWORD_REQUEST" ) then
		local dialog = StaticPopup_Show("CHAT_CHANNEL_PASSWORD", arg1);
		if ( dialog ) then
			dialog.data = arg1;
		end
		return;
	end
	if ( event == "PARTY_INVITE_REQUEST" ) then
		if not ChallengeUtil.CanGroup() then return end
		if UIParent.RequestedInvites[arg1] then
			UIParent.RequestedInvites[arg1] = nil
			AcceptGroup();
			return
		end
		StaticPopup_Show("PARTY_INVITE", arg1);
		return;
	end
	if ( event == "PARTY_INVITE_CANCEL" ) then
		StaticPopup_Hide("PARTY_INVITE");
		return;
	end
	if event == "CHALLENGE_SYNC_REQUEST" then
		local timeleft = tonumber(arg1)
		if timeleft then
			timeleft = timeleft / 1000
		else
			timeleft = 60
		end

		if next(C_Challenge.GetPendingChallenges()) ~= nil then
			StaticPopup_Show("CHALLENGES_SYNC", "", 60, timeleft);
		else
			StaticPopup_Show("CHALLENGES_SYNC_REMOVE", 60, nil, timeleft);
		end
	end
	if event == "REQUEST_GROUP_INVITE" then
		if not ChallengeUtil.CanGroup() then return end
		if arg1 == UnitName("player") then return end
		StaticPopup_Show("REQUESTED_INVITE", arg1, nil, arg1)
		SendSystemMessage(format(MSG_REQUESTED_INVITE_TO_GROUP, arg1))
	end
	if event == "REQUEST_GROUP_FINDER_INVITE" then
		if not ChallengeUtil.CanGroup() then return end
		local player, role, ilvl, note, class, level = arg1, arg2, arg3, arg4, arg5, arg6

		if player == UnitName("player") then return end
		
		if not C_GroupFinder.GetListedGroupID() then return end

		if LFG_AUTO_ACCEPT_ENABLED then
			InviteUnit(player)
			return
		end

		if not class then
			class = "HERO"
		end

		if not level then
			level = 60
		end

		local roleStr = ""
		if bit.contains(role, Enum.LFGRoles.Tank) then
			roleStr = roleStr .. CreateTextureMarkup("Interface\\LFGFrame\\lfgrole", 64, 16, 20, 20, 0.5, 0.75, 0, 1, 0, 0)
		end
		
		if bit.contains(role, Enum.LFGRoles.Healer) then
			roleStr = roleStr .. CreateTextureMarkup("Interface\\LFGFrame\\lfgrole", 64, 16, 20, 20, 0.75, 1, 0, 1, 0, 0)
		end

		if bit.contains(role, Enum.LFGRoles.Damager) then
			roleStr = roleStr .. CreateTextureMarkup("Interface\\LFGFrame\\lfgrole", 64, 16, 20, 20, 0.25, 0.5, 0, 1, 0, 0)
		end

		player = RAID_CLASS_COLORS[class]:WrapText(player) .. " (" .. format(UNIT_TYPE_LEVEL_TEMPLATE, level, RAID_CLASS_COLORS[class]:WrapText(LOCALIZED_CLASS_NAMES_MALE[class])) .. ")"

		local extraText
		if ilvl > 0 then
			extraText = format(GROUP_FINDER_INVITE_ROLE_WITH_ILVL, ilvl, roleStr)
		else
			extraText = format(GROUP_FINDER_INVITE_ROLE_WITHOUT_ILVL, roleStr)
		end

		if note and note:len() > 0 then
			extraText = extraText .. "\n\n|cff888888\""..note.."\"|r"
		end
		StaticPopup_Show("REQUESTED_GROUP_FINDER_INVITE", player, extraText, arg1)

		if ilvl > 0 then
			SendSystemMessage(format(MSG_REQUESTED_INVITE_TO_GROUP_FINDER, arg1, format(GROUP_FINDER_INVITE_ROLE_WITH_ILVL, ilvl, roleStr)))
		else
			SendSystemMessage(format(MSG_REQUESTED_INVITE_TO_GROUP_FINDER, arg1, format(GROUP_FINDER_INVITE_ROLE_WITHOUT_ILVL, roleStr)))
		end
	end
	if event == "SUGGESTED_GROUP_INVITE" then
		if not ChallengeUtil.CanGroup() then return end
		if arg2 == UnitName("player") then return end
		if arg1 == UnitName("player") then
			InviteUnit(arg2)
			return
		end
		StaticPopup_Show("SUGGESTED_INVITE", arg1, arg2, arg2)
		SendSystemMessage(format(MSG_SUGGESTED_INVITE_TO_GROUP, arg1, arg2))
	end
	if event == "PARTY_MEMBERS_CHANGED" then
		RaidOptionsFrame_UpdatePartyFrames()
		if not C_Player:IsInGroup() then
			StaticPopup_Hide("CHALLENGES_SYNC")
			StaticPopup_Hide("CHALLENGES_SYNC_REMOVE")
		end
	end
	if ( event == "GUILD_INVITE_REQUEST" ) then
		StaticPopup_Show("GUILD_INVITE", arg1, arg2);
		return;
	end
	if ( event == "GUILD_INVITE_CANCEL" ) then
		StaticPopup_Hide("GUILD_INVITE");
		return;
	end
	if ( event == "ARENA_TEAM_INVITE_REQUEST" ) then
		StaticPopup_Show("ARENA_TEAM_INVITE", arg1, arg2);
		return;
	end
	if ( event == "ARENA_TEAM_INVITE_CANCEL" ) then
		StaticPopup_Hide("ARENA_TEAM_INVITE");
		return;
	end
	if ( event == "PLAYER_CAMPING" ) then
		StaticPopup_Show("CAMP");
		return;
	end
	if ( event == "PLAYER_QUITING" ) then
		StaticPopup_Show("QUIT");
		return;
	end
	if ( event == "LOGOUT_CANCEL" ) then
		StaticPopup_Hide("CAMP");
		StaticPopup_Hide("QUIT");
		return;
	end
	if ( event == "LOOT_BIND_CONFIRM" ) then
		local texture, item, quantity, quality, locked = GetLootSlotInfo(arg1);
		local dialog = StaticPopup_Show("LOOT_BIND", ITEM_QUALITY_COLORS[quality].hex..item.."|r");
		if ( dialog ) then
			dialog.data = arg1;
		end
		return;
	end
	if ( event == "EQUIP_BIND_CONFIRM" ) then
		StaticPopup_Hide("AUTOEQUIP_BIND");
		local dialog = StaticPopup_Show("EQUIP_BIND");
		if ( dialog ) then
			dialog.data = arg1;
		end
		return;
	end
	if ( event == "AUTOEQUIP_BIND_CONFIRM" ) then
		StaticPopup_Hide("EQUIP_BIND");
		local dialog = StaticPopup_Show("AUTOEQUIP_BIND");
		if ( dialog ) then
			dialog.data = arg1;
		end
		return;
	end
	if ( event == "USE_BIND_CONFIRM" ) then
		StaticPopup_Show("USE_BIND");
		return;
	end
	if ( event == "DELETE_ITEM_CONFIRM" ) then
		-- Check quality
		if ( arg2 >= 3 ) then
			StaticPopup_Show("DELETE_GOOD_ITEM", arg1);
		else
			StaticPopup_Show("DELETE_ITEM", arg1);
		end
		return;
	end
	if ( event == "QUEST_ACCEPT_CONFIRM" ) then
		local numEntries, numQuests = GetNumQuestLogEntries();
		if( numQuests >= MAX_QUESTS) then
			StaticPopup_Show("QUEST_ACCEPT_LOG_FULL", arg1, arg2);
		else
			StaticPopup_Show("QUEST_ACCEPT", arg1, arg2);
		end
		return;
	end
	if ( event =="QUEST_LOG_UPDATE" or event == "UNIT_QUEST_LOG_CHANGED" ) then
		local frameName = StaticPopup_Visible("QUEST_ACCEPT_LOG_FULL");
		if( frameName ) then
			local numEntries, numQuests = GetNumQuestLogEntries();
			local button = _G[frameName.."Button1"];
			if( numQuests < MAX_QUESTS ) then
				button:Enable();
			else
				button:Disable();
			end
		end 
	end

	if ( event == "CURSOR_UPDATE" ) then
		if ( not CursorHasItem() ) then
			StaticPopup_Hide("EQUIP_BIND");
			StaticPopup_Hide("AUTOEQUIP_BIND");
		end
		return;
	end
	if ( event == "PLAYER_ENTERING_WORLD" ) then
		C_LootLockout.QueryInstanceBinds()
		-- Get multi-actionbar states (before CloseAllWindows() since that may be hooked by AddOns)
		-- We don't want to call this, as the values GetActionBarToggles() returns are incorrect if it's called before the client mirrors SetActionBarToggles values from the server.
		SHOW_MULTI_ACTIONBAR_1, SHOW_MULTI_ACTIONBAR_2, SHOW_MULTI_ACTIONBAR_3, SHOW_MULTI_ACTIONBAR_4 = GetActionBarToggles();
		ALWAYS_SHOW_MULTIBARS = GetCVar("alwaysShowActionBars")
		MultiActionBar_Update();
		MultiActionBar_UpdateGridVisibility()
		InterfaceOptions_UpdateMultiActionBars()
		
		-- check if party frames should be shown or not
		RaidOptionsFrame_UpdatePartyFrames()

		-- Close any windows that were previously open
		CloseAllWindows(1);

		-- Until PVPFrame is checked in, this is placed here.
		for i=1, MAX_ARENA_TEAMS do
			GetArenaTeam(i);
		end

		VoiceChat_Toggle();

		-- Fix for Bug 124392
		StaticPopup_Hide("LEVEL_GRANT_PROPOSED");
		
		local inInstance, instanceType = IsInInstance();
		if ( instanceType == "arena" ) then
			Arena_LoadUI();
		end

		if C_MythicPlus.IsKeystoneActive() and C_Instance.IsInDungeon() then
			MythicPlus_LoadUI()
		end

		if C_Manastorm.IsInManastorm() then
			Manastorm_LoadUI()
		end

		-- Item Recovery Gossip
		C_Gossip:RemoveRedirectNPC(80061)
		if not inInstance then
			C_Gossip:RedirectNPC(80061, ShowItemRecovery)
		end

		-- transmog redirect
		C_Gossip:RedirectNPC(190015, ShowAppearanceWardrobe)
		C_Gossip:RedirectNPC(1002087, ShowAppearanceWardrobe)
		C_Gossip:RedirectNPC(79027, ShowAppearanceWardrobe)

		GarbageCollectionUtil.SecureCollectGarbage()

		if TutorialUtil.CanShowAnyTutorials() then
			NewPlayerExperience_LoadUI()
		end

		if C_Tutorial.AnyUnclaimedRewards() and TutorialUtil.CanOpenPathToAscension() and not (C_AccountInfo.GetGMLevel() > 0) then
			SetButtonPulse(PathToAscensionMicroButton, 60, 1)
			HelpTip:Show("HELP_TIP_PTA_REWARD_PENDING")
		else
			HelpTip:Show("WARDROBE_CHANGE_TRANSMOG_HINT")
		end

		if not C_Realm.IsDevelopment() then
			CheckUnspentEssences()
		end

        CheckPlayerPoll()
		return;
	end
	if ( event == "ACTIVE_MANASTORM_UPDATED" ) then
		Manastorm_LoadUI()
	end
	if ( event == "RAID_ROSTER_UPDATE" ) then
		-- Hide/Show party member frames
		RaidOptionsFrame_UpdatePartyFrames();
	end
	if ( event == "MIRROR_TIMER_START" ) then
		MirrorTimer_Show(arg1, arg2, arg3, arg4, arg5, arg6);
		return;
	end
	if ( event == "DUEL_REQUESTED" ) then
		StaticPopup_Show("DUEL_REQUESTED", arg1);
		return;
	end
	if ( event == "DUEL_OUTOFBOUNDS" ) then
		StaticPopup_Show("DUEL_OUTOFBOUNDS");
		return;
	end
	if ( event == "DUEL_INBOUNDS" ) then
		StaticPopup_Hide("DUEL_OUTOFBOUNDS");
		return;
	end
	if ( event == "DUEL_FINISHED" ) then
		StaticPopup_Hide("DUEL_REQUESTED");
		StaticPopup_Hide("DUEL_OUTOFBOUNDS");
		return;
	end
	if ( event == "TRADE_REQUEST_CANCEL" ) then
		StaticPopup_Hide("TRADE");
		return;
	end
	if ( event == "CONFIRM_XP_LOSS" ) then
		local resSicknessTime = GetResSicknessDuration();
		if ( resSicknessTime ) then
			local dialog = nil;
			if (UnitLevel("player") <= 10) then
				dialog = StaticPopup_Show("XP_LOSS_NO_DURABILITY", resSicknessTime);
			else
				dialog = StaticPopup_Show("XP_LOSS", resSicknessTime);
			end
			if ( dialog ) then
				dialog.data = resSicknessTime;
			end
		else
			local dialog = nil;
			if (UnitLevel("player") <= 10) then
				dialog = StaticPopup_Show("XP_LOSS_NO_SICKNESS_NO_DURABILITY");
			else
				dialog = StaticPopup_Show("XP_LOSS_NO_SICKNESS");
			end
			if ( dialog ) then
				dialog.data = 1;
			end
		end
		HideUIPanel(GossipFrame);
		return;
	end
	if ( event == "CORPSE_IN_RANGE" ) then
		StaticPopup_Show("RECOVER_CORPSE");
		return;
	end
	if ( event == "CORPSE_IN_INSTANCE" ) then
		StaticPopup_Show("RECOVER_CORPSE_INSTANCE");
		return;
	end
	if ( event == "CORPSE_OUT_OF_RANGE" ) then
		StaticPopup_Hide("RECOVER_CORPSE");
		StaticPopup_Hide("RECOVER_CORPSE_INSTANCE");
		StaticPopup_Hide("XP_LOSS");
		return;
	end
	if ( event == "AREA_SPIRIT_HEALER_IN_RANGE" ) then
		AcceptAreaSpiritHeal();
		StaticPopup_Show("AREA_SPIRIT_HEAL");
		return;
	end
	if ( event == "AREA_SPIRIT_HEALER_OUT_OF_RANGE" ) then
		StaticPopup_Hide("AREA_SPIRIT_HEAL");
		return;
	end
	if ( event == "BIND_ENCHANT" ) then
		StaticPopup_Show("BIND_ENCHANT");
		return;
	end
	if ( event == "REPLACE_ENCHANT" ) then
		if arg1:find("@re") then
			local enchant = C_MysticEnchant.GetEnchantInfoBySpell(arg1)
			arg1 = enchant and enchant.SpellName
		end

		if arg2:find("@re") then
			local enchant = C_MysticEnchant.GetEnchantInfoBySpell(arg2)
			arg2 = enchant and enchant.SpellName
		end
		
		if not arg1 or not arg2 then return end
		StaticPopup_Show("REPLACE_ENCHANT", arg1, arg2);
		return;
	end
	if ( event == "TRADE_REPLACE_ENCHANT" ) then
		if arg1:find("@") then
			local enchant = C_MysticEnchant.GetEnchantInfoBySpell(arg1)
			arg1 = enchant and enchant.SpellName
		end

		if arg2:find("@") then
			local enchant = C_MysticEnchant.GetEnchantInfoBySpell(arg2)
			arg2 = enchant and enchant.SpellName
		end

		if not arg1 or not arg2 then return end
		StaticPopup_Show("TRADE_REPLACE_ENCHANT", arg1, arg2);
		return;
	end
	if ( event == "END_REFUND" ) then
		local dialog = StaticPopup_Show("END_REFUND");
		if(dialog) then
			dialog.data = arg1;
		end
		return;
	end
	if ( event == "END_BOUND_TRADEABLE" ) then
		local dialog = StaticPopup_Show("END_BOUND_TRADEABLE", nil, nil, arg1);
		return;
	end
	if ( event == "CURRENT_SPELL_CAST_CHANGED" ) then
		StaticPopup_Hide("BIND_ENCHANT");
		StaticPopup_Hide("REPLACE_ENCHANT");
		StaticPopup_Hide("TRADE_REPLACE_ENCHANT");
		StaticPopup_Hide("END_REFUND");
		StaticPopup_Hide("END_BOUND_TRADEABLE");
		return;
	end
	if ( event == "MACRO_ACTION_BLOCKED" or event == "ADDON_ACTION_BLOCKED" ) then
		if ( not INTERFACE_ACTION_BLOCKED_SHOWN ) then
			local info = ChatTypeInfo["SYSTEM"];
			DEFAULT_CHAT_FRAME:AddMessage(INTERFACE_ACTION_BLOCKED, info.r, info.g, info.b, info.id);
			INTERFACE_ACTION_BLOCKED_SHOWN = true;
		end
		return;
	end
	if ( event == "MACRO_ACTION_FORBIDDEN" ) then
		StaticPopup_Show("MACRO_ACTION_FORBIDDEN");
		return;
	end
	if ( event == "ADDON_ACTION_FORBIDDEN" ) then
		local dialog = StaticPopup_Show("ADDON_ACTION_FORBIDDEN", arg1);
		if ( dialog ) then
			dialog.data = arg1;
		end
		return;
	end
	if ( event == "PLAYER_CONTROL_LOST" ) then
		if ( UnitOnTaxi("player") ) then
			return;
		end
		CloseAllWindows_WithExceptions();
		
		--[[
		-- Disable all microbuttons except the main menu
		SetDesaturation(MicroButtonPortrait, 1);
		
		Designers previously wanted these disabled when feared, they seem to have changed their minds
		CharacterMicroButton:Disable();
		SpellbookMicroButton:Disable();
		TalentMicroButton:Disable();
		QuestLogMicroButton:Disable();
		SocialsMicroButton:Disable();
		WorldMapMicroButton:Disable();
		]]

		UIParent.isOutOfControl = 1;
		return;
	end
	if ( event == "PLAYER_CONTROL_GAINED" ) then
		--[[
		-- Enable all microbuttons
		SetDesaturation(MicroButtonPortrait, nil);

		CharacterMicroButton:Enable();
		SpellbookMicroButton:Enable();
		TalentMicroButton:Enable();
		QuestLogMicroButton:Enable();
		SocialsMicroButton:Enable();
		WorldMapMicroButton:Enable();
		]]

		UIParent.isOutOfControl = nil;
		return;
	end
	if ( event == "START_LOOT_ROLL" ) then
		GroupLootFrame_OpenNewFrame(arg1, arg2);
		return;
	end
	if ( event == "CONFIRM_LOOT_ROLL" ) then
		local texture, name, count, quality, bindOnPickUp = GetLootRollItemInfo(arg1);
		local dialog = StaticPopup_Show("CONFIRM_LOOT_ROLL", ITEM_QUALITY_COLORS[quality].hex..name.."|r");
		if ( dialog ) then
			dialog.text:SetFormattedText(LOOT_NO_DROP, ITEM_QUALITY_COLORS[quality].hex..name.."|r");
			StaticPopup_Resize(dialog, "CONFIRM_LOOT_ROLL");
			dialog.data = arg1;
			dialog.data2 = arg2;
		end
		return;
	end
	if ( event == "CONFIRM_DISENCHANT_ROLL" ) then
		local texture, name, count, quality, bindOnPickUp = GetLootRollItemInfo(arg1);
		local dialog = StaticPopup_Show("CONFIRM_LOOT_ROLL", ITEM_QUALITY_COLORS[quality].hex..name.."|r");
		if ( dialog ) then
			dialog.text:SetFormattedText(LOOT_NO_DROP_DISENCHANT, ITEM_QUALITY_COLORS[quality].hex..name.."|r");
			StaticPopup_Resize(dialog, "CONFIRM_LOOT_ROLL");
			dialog.data = arg1;
			dialog.data2 = arg2;
		end
		return;
	end
	if ( event == "INSTANCE_BOOT_START" ) then
		StaticPopup_Show("INSTANCE_BOOT");
		return;
	end
	if ( event == "INSTANCE_BOOT_STOP" ) then
		StaticPopup_Hide("INSTANCE_BOOT");
		return;
	end
	if ( event == "INSTANCE_LOCK_START" ) then
		StaticPopup_Show("INSTANCE_LOCK");
		return;
	end
	if ( event == "INSTANCE_LOCK_STOP" ) then
		StaticPopup_Hide("INSTANCE_LOCK");
		return;
	end
	if ( event == "CONFIRM_TALENT_WIPE" ) then
		local dialog = StaticPopup_Show("CONFIRM_TALENT_WIPE");
		if ( dialog ) then
			MoneyFrame_Update(dialog:GetName().."MoneyFrame", arg1);
			-- open the talent UI to the player's active talent group...just so the player knows
			-- exactly which talent spec he is wiping
			TalentFrame_LoadUI();
			if ( PlayerTalentFrame_Open ) then
				PlayerTalentFrame_Open(false, GetActiveTalentGroup());
			end
		end
		return;
	end
	if ( event == "CONFIRM_BINDER" ) then
		StaticPopup_Show("CONFIRM_BINDER", arg1);
		return;
	end
	if ( event == "CONFIRM_SUMMON" ) then
		StaticPopup_Show("CONFIRM_SUMMON");
		return;
	end
	if ( event == "CANCEL_SUMMON" ) then
		StaticPopup_Hide("CONFIRM_SUMMON");
		return;
	end
	if ( event == "BILLING_NAG_DIALOG" ) then
		StaticPopup_Show("BILLING_NAG", arg1);
		return;
	end
	if ( event == "IGR_BILLING_NAG_DIALOG" ) then
		StaticPopup_Show("IGR_BILLING_NAG");
		return;
	end
	if ( event == "GOSSIP_CONFIRM" ) then
		if ( arg3 > 0 ) then
			StaticPopupDialogs["GOSSIP_CONFIRM"].hasMoneyFrame = 1;
		else
			StaticPopupDialogs["GOSSIP_CONFIRM"].hasMoneyFrame = nil;
		end	
		local dialog = StaticPopup_Show("GOSSIP_CONFIRM", arg2);
		if ( dialog ) then
			dialog.data = arg1;
			if ( arg3 > 0 ) then
				MoneyFrame_Update(dialog:GetName().."MoneyFrame", arg3);
			end
		end
		return;
	end
	if ( event == "GOSSIP_ENTER_CODE" ) then
		local dialog = StaticPopup_Show("GOSSIP_ENTER_CODE");
		if ( dialog ) then
			dialog.data = arg1;
		end
		return;
	end
	if ( event == "GOSSIP_CONFIRM_CANCEL" or event == "GOSSIP_CLOSED" ) then
		StaticPopup_Hide("GOSSIP_CONFIRM");
		StaticPopup_Hide("GOSSIP_ENTER_CODE");
		return;
	end

	-- Events for auction UI handling
	if ( event == "AUCTION_HOUSE_SHOW" ) then
		AuctionFrame_LoadUI();
		if ( AuctionFrame_Show ) then
			AuctionFrame_Show();
		end
		return;
	end
	if ( event == "AUCTION_HOUSE_CLOSED" ) then
		if ( AuctionFrame_Hide ) then
			AuctionFrame_Hide();
		end
		return;
	end
	if ( event == "AUCTION_HOUSE_DISABLED" ) then
		StaticPopup_Show("AUCTION_HOUSE_DISABLED");
	end

	-- Events for trainer UI handling
	if ( event == "TRAINER_SHOW" ) then
		ClassTrainerFrame_LoadUI();
		if ( ClassTrainerFrame_Show ) then
			ClassTrainerFrame_Show();
		end
		return;
	end
	if ( event == "TRAINER_CLOSED" ) then
		if ( ClassTrainerFrame_Hide ) then
			ClassTrainerFrame_Hide();
		end
		return;
	end
	-- Events for trade skill UI handling
	if ( event == "TRADE_SKILL_SHOW" ) then
		TradeSkillFrame_LoadUI();
		if ( TradeSkillFrame_Show ) then
			TradeSkillFrame_Show();
		end
		return;
	end
	if ( event == "TRADE_SKILL_CLOSE" ) then
		if ( TradeSkillFrame_Hide ) then
			TradeSkillFrame_Hide();
		end
		return;
	end
	-- Event for item socketing handling
	if ( event == "SOCKET_INFO_UPDATE" ) then
		ItemSocketingFrame_LoadUI();
		ItemSocketingFrame_Update();
		ShowUIPanel(ItemSocketingFrame);
		return;
	end

	-- Event for BarberShop handling
	if ( event == "BARBER_SHOP_OPEN" ) then
		BarberShopFrame_LoadUI();
		if ( BarberShopFrame ) then
			ShowUIPanel(BarberShopFrame);
		end
		return;
	end
	if ( event == "BARBER_SHOP_CLOSE" ) then
		if ( BarberShopFrame and BarberShopFrame:IsVisible() ) then
			BarberShopFrame:Hide();
		end
		return;
	end
	
	-- Event for guildbank handling
	if ( event == "GUILDBANKFRAME_OPENED" ) then
		GuildBankFrame_LoadUI();
		if ( GuildBankFrame ) then
			local isPersonalBank, isRealmBank = GetBankPermissions()
			if isPersonalBank ~= nil then
				GuildBankFrame.IsPersonalBank = isPersonalBank
				GuildBankFrame.IsRealmBank = isRealmBank
			end
			ShowUIPanel(GuildBankFrame);
			if ( not GuildBankFrame:IsVisible() ) then
				CloseGuildBankFrame();
			end
		end
		return;
	end
	if ( event == "GUILDBANKFRAME_CLOSED" ) then
		if ( GuildBankFrame ) then
			HideUIPanel(GuildBankFrame);
		end
		return;
	end

	-- Event for barbershop handling
	if ( event == "BARBER_SHOP_OPEN" ) then
		BarberShopFrame_LoadUI();
		if ( BarberShopFrame ) then
			ShowUIPanel(BarberShopFrame);
		end
	elseif ( event == "BARBER_SHOP_CLOSE" ) then
		BarberShopFrame_LoadUI();
		if ( BarberShopFrame ) then
			HideUIPanel(BarberShopFrame);
		end
	end
	
	-- Events for achievement handling
	if ( event == "ACHIEVEMENT_EARNED" ) then
		-- if ( not AchievementFrame ) then
			-- AchievementFrame_LoadUI();
			-- AchievementAlertFrame_ShowAlert(...);
		-- end
		-- self:UnregisterEvent(event);
	end
	
	-- Events for Glyphs
	if ( event == "USE_GLYPH" ) then
		OpenGlyphFrame();
		return;
	end

	-- Display instance reset info
	if ( event == "RAID_INSTANCE_WELCOME" ) then
		local dungeonName = arg1;
		local lockExpireTime = arg2;
		local locked = arg3;
		local extended = arg4;
		local message;

		if ( locked == 0 ) then
			message = format(RAID_INSTANCE_WELCOME, dungeonName, SecondsToTime(lockExpireTime, nil, 1))
		else
			if ( lockExpireTime == 0 ) then
				message = format(RAID_INSTANCE_WELCOME_EXTENDED, dungeonName);
			else
				if ( extended == 0 ) then
					message = format(RAID_INSTANCE_WELCOME_LOCKED, dungeonName, SecondsToTime(lockExpireTime, nil, 1));
				else
					message = format(RAID_INSTANCE_WELCOME_LOCKED_EXTENDED, dungeonName, SecondsToTime(lockExpireTime, nil, 1));
				end
			end
		end

		local info = ChatTypeInfo["SYSTEM"];
		DEFAULT_CHAT_FRAME:AddMessage(message, info.r, info.g, info.b, info.id);
		return;
	end
	
	-- Events for taxi benchmarking
	if ( event == "ENABLE_TAXI_BENCHMARK" ) then
		if ( not FramerateText:IsShown() ) then
			ToggleFramerate(true);
		end
		local info = ChatTypeInfo["SYSTEM"];
		DEFAULT_CHAT_FRAME:AddMessage(BENCHMARK_TAXI_MODE_ON, info.r, info.g, info.b, info.id);
		return;
	end
	if ( event == "DISABLE_TAXI_BENCHMARK" ) then
		if ( FramerateText.benchmark ) then
			ToggleFramerate();
		end
		local info = ChatTypeInfo["SYSTEM"];
		DEFAULT_CHAT_FRAME:AddMessage(BENCHMARK_TAXI_MODE_OFF, info.r, info.g, info.b, info.id);
		return;
	end
	
	-- Push to talk
	if ( event == "VOICE_PUSH_TO_TALK_START" and GetVoiceCurrentSessionID() ) then
		if ( GetCVarBool("PushToTalkSound") ) then
			PlaySound("VoiceChatOn");
		end
		-- Animate the player frame speaker even if not broadcasting
		if  ( GetCVar("VoiceChatMode") == "0" ) then
			UIFrameFadeIn(PlayerSpeakerFrame, 0.2, PlayerSpeakerFrame:GetAlpha(), 1);
		end
		return;
	end
	if ( event == "VOICE_PUSH_TO_TALK_STOP" ) then
		if ( GetCVarBool("PushToTalkSound") and GetVoiceCurrentSessionID() ) then
			PlaySound("VoiceChatOff");
		end
		-- Stop Animation
		if  ( GetCVar("VoiceChatMode") == "0" and PlayerSpeakerFrame:GetAlpha() > 0 ) then
			UIFrameFadeOut(PlayerSpeakerFrame, 0.2, PlayerSpeakerFrame:GetAlpha(), 0);
		end
		return;
	end
	if ( event == "LEVEL_GRANT_PROPOSED" ) then
		StaticPopup_Show("LEVEL_GRANT_PROPOSED", arg1);
		return;
	end
	
	if ( event == "CHAT_MSG_WHISPER" and arg6 == "GM" ) then	--GMChatUI
		GMChatFrame_LoadUI(event, ...);
	end
	
	if ( event == "WOW_MOUSE_NOT_FOUND" ) then
		StaticPopup_Show("WOW_MOUSE_NOT_FOUND");
	end
	
	if ( event == "TALENTS_INVOLUNTARILY_RESET" ) then
		if ( arg1 ) then
			StaticPopup_Show("TALENTS_INVOLUNTARILY_RESET_PET");
		else
			StaticPopup_Show("TALENTS_INVOLUNTARILY_RESET");
		end
	end
	if event == "PLAYER_LEVEL_UP" then
		if IsResting() then
			C_Spell:PLAYER_LEVEL_UP({{UnitLevel("player")}})
		end

		if arg1 == AUTO_QUEST_RANK_UP_SPELLS_LEVEL then
			C_Quest:AddAutoQuestPopUp(Enum.Quests.PTAscension.RankUpYourSpells)
		end

		UpdateMicroButtons(arg1)
		CheckUnspentEssences()
	end
    if event == "PLAYER_POLL_NEW_POLL" then
        CheckPlayerPoll()
    end

	--[[if event == "ADDON_LOADED" then
	end]]

	if event == "DISPLAY_SIZE_CHANGED" then
		if not C_CVar.GetBool("useUiScale") and self.rescaled and self.useScaledUI then
			RunNextFrame(function()
				self:_SetScale(0.9)
			end)
		end
	end


	if event == "UPDATE_INSTANCE_INFO" then
		if C_LootLockout.QueryInstanceBinds then
			C_LootLockout.QueryInstanceBinds()
		end
	end

	-- auto-lock skill card spells
	if event == "SKILL_CARD_BLOCKED" then
		local skillCardInfo = SkillCardUtil.GetCardInfoAtIndex(arg2, arg1)
		self.recentlyLockedSpellID = skillCardInfo and skillCardInfo.SpellID

		if self.recentlyLockedSpellID then
			self:RegisterEvent("WILDCARD_ENTRY_LEARNED")
		end
	end

	if event == "WILDCARD_ENTRY_LEARNED" then
		if self.recentlyLockedSpellID then
			local entry = C_CharacterAdvancement.GetEntryBySpellID(self.recentlyLockedSpellID)

			for _, spellID in pairs(entry.Spells) do
				if spellID == self.recentlyLockedSpellID then

					if not C_CharacterAdvancement.IsLockedID(arg1) then
						C_CharacterAdvancement.LockID(arg1)
					end

					break
				end
			end
		end

		self:UnregisterEvent("WILDCARD_ENTRY_LEARNED")
		self.recentlyLockedSpellID = nil
	end

	if event == "UNLOCKED_APPEARANCE_ITEM_USED" then
		TryOnAppearance(arg2, arg1, arg3, arg4)
	elseif event == "APPEARANCE_COLLECTED" then
		local appearanceID = arg1
		local displayType, displayID, _, displayName = C_Appearance.GetAppearanceDisplayInfo(appearanceID)
		if displayName then
			if displayType == "APPEARANCE_DISPLAY_TYPE_ITEM" or displayType == "APPEARANCE_DISPLAY_TYPE_CREATURE" then
				SendSystemMessage(APPEARANCE_COLLECTED_LINK:format(appearanceID, displayName))
			else
				SendSystemMessage(APPEARANCE_COLLECTED:format(displayName))
			end
		end
	elseif event == "APPEARANCE_UNCOLLECTED" then
		local appearanceID = arg1
		local displayType, displayID, _, displayName = C_Appearance.GetAppearanceDisplayInfo(appearanceID)
		if displayName then
			if displayType == "APPEARANCE_DISPLAY_TYPE_ITEM" or displayType == "APPEARANCE_DISPLAY_TYPE_CREATURE" then
				SendSystemMessage(APPEARANCE_UNCOLLECTED_LINK:format(appearanceID, displayName))
			else
				SendSystemMessage(APPEARANCE_UNCOLLECTED:format(displayName))
			end
		end
	elseif event == "TUTORIAL_ENTRY_ADDED" then
		UpdateMicroButtons()
		if TutorialUtil.CanOpenPathToAscension() and (not PathToAscensionFrame or not PathToAscensionFrame:IsShown()) then
			SetButtonPulse(PathToAscensionMicroButton, 60, 1)
			if TutorialUtil.CanShowAnyTutorials() then
				HelpTip:Show("HELP_TIP_NEW_PTA_TUTORIAL")
			end
		end
	elseif event == "TUTORIAL_ENTRY_COMPLETE" then
		UpdateMicroButtons()
		local tutorialID = arg2
		local _, _, _, questID = C_Tutorial.GetTutorialByID(tutorialID)
		if questID and questID > 0 then
			WatchFrameAutoQuest_ClearPopUp(questID)
		end
		if (not PathToAscensionFrame or not PathToAscensionFrame:IsShown()) and TutorialUtil.CanOpenPathToAscension() then
			SetButtonPulse(PathToAscensionMicroButton, 60, 1)
			HelpTip:Show("HELP_TIP_PTA_REWARD_PENDING")
		end
	end
end

-- Frame Management --

-- UIPARENT_MANAGED_FRAME_POSITIONS stores all the frames that have positioning dependencies based on other frames.  

-- UIPARENT_MANAGED_FRAME_POSITIONS["FRAME"] = {
	-- none = This value is used if no dependent frames are shown
	-- reputation = This is the offset used if the reputation watch bar is shown
	-- anchorTo = This is the object that the stored frame is anchored to
	-- point = This is the point on the frame used as the anchor
	-- rpoint = This is the point on the "anchorTo" frame that the stored frame is anchored to
	-- bottomEither = This offset is used if either bottom multibar is shown
	-- bottomLeft
	-- var = If this is set use _G[varName] = value instead of setpoint
-- };


-- some standard offsets
local actionBarOffset = 45;
local menuBarTop = 55;
local vehicleMenuBarTop = 40;

function UpdateMenuBarTop ()
	--Determines the optimal magic number based on resolution and action bar status.
	menuBarTop = 55;
	local width, height = string.match((({GetScreenResolutions()})[GetCurrentResolution()] or ""), "(%d+).-(%d+)");
	if ( tonumber(width) / tonumber(height ) > 4/3 ) then
		--Widescreen resolution
		menuBarTop = 75;
	end
end

UIPARENT_MANAGED_FRAME_POSITIONS = {
	--Items with baseY set to "true" are positioned based on the value of menuBarTop and their offset needs to be repeatedly evaluated as menuBarTop can change. 
	--"yOffset" gets added to the value of "baseY", which is used for values based on menuBarTop.
	["MultiBarBottomLeft"] = {baseY = 17, reputation = 1, maxLevel = 1, anchorTo = "ActionButton1", point = "BOTTOMLEFT", rpoint = "TOPLEFT"};
	["MultiBarRight"] = {baseY = 98, reputation = 1, anchorTo = "UIParent", point = "BOTTOMRIGHT", rpoint = "BOTTOMRIGHT"};
	["VoiceChatTalkers"] = {baseY = true, bottomEither = actionBarOffset, vehicleMenuBar = vehicleMenuBarTop, reputation = 1};
	["GroupLootFrame1"] = {baseY = true, bottomEither = actionBarOffset, vehicleMenuBar = vehicleMenuBarTop, pet = 1, reputation = 1};
	["TutorialFrameAlertButton"] = {baseY = true, yOffset = -10, bottomEither = actionBarOffset, vehicleMenuBar = vehicleMenuBarTop, reputation = 1};
	["FramerateLabel"] = {baseY = true, bottomEither = actionBarOffset, vehicleMenuBar = vehicleMenuBarTop, pet = 1, reputation = 1};
	["CastingBarFrame"] = {baseY = true, yOffset = 40, bottomEither = actionBarOffset, vehicleMenuBar = vehicleMenuBarTop, pet = 1, reputation = 1, tutorialAlert = 1};
	["ChatFrame1"] = {baseY = true, yOffset = 40, bottomLeft = actionBarOffset-8, justBottomRightAndShapeshift = actionBarOffset, vehicleMenuBar = vehicleMenuBarTop, pet = 1, reputation = 1, maxLevel = 1, point = "BOTTOMLEFT", rpoint = "BOTTOMLEFT", xOffset = 32};
	["ChatFrame2"] = {baseY = true, yOffset = 40, bottomRight = actionBarOffset-8, vehicleMenuBar = vehicleMenuBarTop, rightLeft = -2*actionBarOffset, rightRight = -actionBarOffset, reputation = 1, maxLevel = 1, point = "BOTTOMRIGHT", rpoint = "BOTTOMRIGHT", xOffset = -32};
	["ShapeshiftBarFrame"] = {baseY = 0, bottomLeft = actionBarOffset, reputation = 1, maxLevel = 1, anchorTo = "MainMenuBar", point = "BOTTOMLEFT", rpoint = "TOPLEFT", xOffset = 30};
	["PossessBarFrame"] = {baseY = 0, bottomLeft = actionBarOffset, reputation = 1, maxLevel = 1, anchorTo = "MainMenuBar", point = "BOTTOMLEFT", rpoint = "TOPLEFT", xOffset = 30};
	["MultiCastActionBarFrame"] = {baseY = 0, bottomLeft = actionBarOffset, reputation = 1, maxLevel = 1, anchorTo = "MainMenuBar", point = "BOTTOMLEFT", rpoint = "TOPLEFT", xOffset = 30};
	["AuctionProgressFrame"] = {baseY = true, yOffset = 18, bottomEither = actionBarOffset, vehicleMenuBar = vehicleMenuBarTop, pet = 1, reputation = 1, tutorialAlert = 1};
	
	-- Vars
	-- These indexes require global variables of the same name to be declared. For example, if I have an index ["FOO"] then I need to make sure the global variable
	-- FOO exists before this table is constructed. The function UIParent_ManageFramePosition will use the "FOO" table index to change the value of the FOO global
	-- variable so that other modules can use the most up-to-date value of FOO without having knowledge of the UIPARENT_MANAGED_FRAME_POSITIONS table.
	["CONTAINER_OFFSET_X"] = {baseX = 0, rightLeft = 2*actionBarOffset+3, rightRight = actionBarOffset+3, isVar = "xAxis"};
	["CONTAINER_OFFSET_Y"] = {baseY = true, yOffset = 10, bottomEither = actionBarOffset, reputation = 1, isVar = "yAxis"};
	["BATTLEFIELD_TAB_OFFSET_Y"] = {baseY = 210, bottomRight = actionBarOffset, reputation = 1, isVar = "yAxis"};
	["PETACTIONBAR_YPOS"] = {baseY = 97, bottomLeft = actionBarOffset, justBottomRightAndShapeshift = actionBarOffset, reputation = 1, maxLevel = 1, isVar = "yAxis"};
	["MULTICASTACTIONBAR_YPOS"] = {baseY = 0, bottomLeft = actionBarOffset, reputation = 1, maxLevel = 1, isVar = "yAxis"};
};

-- If any Var entries in UIPARENT_MANAGED_FRAME_POSITIONS are used exclusively by addons, they should be declared here and not in one of the addon's files.
-- The reason why is that it is possible for UIParent_ManageFramePosition to be run before the addon loads.
BATTLEFIELD_TAB_OFFSET_Y = 0;


-- constant offsets
for _, data in pairs(UIPARENT_MANAGED_FRAME_POSITIONS) do
	for flag, value in pairs(data) do
		if ( flag == "reputation" ) then
			data[flag] = value * 9;
		elseif ( flag == "maxLevel" ) then
			data[flag] = value * -5;
		elseif ( flag == "pet" ) then
			data[flag] = value * 35;
		elseif ( flag == "tutorialAlert" ) then
			data[flag] = value * 35;
		end
	end
end

function UIParent_ManageFramePosition(index, value, yOffsetFrames, xOffsetFrames, hasBottomLeft, hasBottomRight, hasPetBar)
	local frame, xOffset, yOffset, anchorTo, point, rpoint;

	frame = _G[index];
	if ( not frame or (type(frame)=="table" and frame.ignoreFramePositionManager)) then
		return;
	end
	
	-- Always start with base as the base offset or default to zero if no "none" specified
	xOffset = 0;
	if ( value["baseX"] ) then
		xOffset = value["baseX"];
	elseif ( value["xOffset"] ) then
		xOffset = value["xOffset"];
	end
	yOffset = 0;
	if ( tonumber(value["baseY"]) ) then
		--tonumber(nil) and tonumber(boolean) evaluate as nil, tonumber(number) evaluates as a number, which evaluates as true.
		--This allows us to use the true value in baseY for flagging a frame's positioning as dependent upon the value of menuBarTop.
		yOffset = value["baseY"];
	elseif ( value["baseY"] ) then
		--value["baseY"] is true, use menuBarTop.
		yOffset = menuBarTop;
	end
	
	if ( value["yOffset"] ) then
		--This is so things based on menuBarTop can still have an offset. Otherwise you'd just use put the offset value in baseY.
		yOffset = yOffset + value["yOffset"];
	end
	
	-- Iterate through frames that affect y offsets
	local hasBottomEitherFlag;
	for _, flag in pairs(yOffsetFrames) do
		if ( value[flag] ) then
			if ( flag == "bottomEither" ) then
				hasBottomEitherFlag = 1;
			end
			yOffset = yOffset + value[flag];
		end
	end
	
	-- don't offset for the pet bar and bottomEither if the player has
	-- the bottom right bar shown and not the bottom left
	if ( hasBottomEitherFlag and hasBottomRight and hasPetBar and not hasBottomLeft ) then
		yOffset = yOffset - (value["pet"] or 0);
	end

	-- Iterate through frames that affect x offsets
	for _, flag in pairs(xOffsetFrames) do
		if ( value[flag] ) then
			xOffset = xOffset + value[flag];
		end
	end

	-- Set up anchoring info
	anchorTo = value["anchorTo"];
	point = value["point"];
	rpoint = value["rpoint"];
	if ( not anchorTo ) then
		anchorTo = "UIParent";
	end
	if ( not point ) then
		point = "BOTTOM";
	end
	if ( not rpoint ) then
		rpoint = "BOTTOM";
	end

	-- Anchor frame
	if ( value["isVar"] ) then
		if ( value["isVar"] == "xAxis" ) then
			_G[index] = xOffset;
		else
			_G[index] = yOffset;
		end
	else
		if ( frame ~= ChatFrame2 and not(frame:IsObjectType("frame") and frame:IsUserPlaced()) ) then
			frame:SetPoint(point, anchorTo, rpoint, xOffset, yOffset);
		end
	end
end

local function FramePositionDelegate_OnAttributeChanged(self, attribute)
	if ( attribute == "panel-show" ) then
		local force = self:GetAttribute("panel-force");
		local frame = self:GetAttribute("panel-frame");
		self:ShowUIPanel(frame, force);
	elseif ( attribute == "panel-hide" ) then
		local frame = self:GetAttribute("panel-frame");
		local skipSetPoint = self:GetAttribute("panel-skipSetPoint");
		self:HideUIPanel(frame, skipSetPoint);
	elseif ( attribute == "panel-update" ) then
		local frame = self:GetAttribute("panel-frame");
		self:UpdateUIPanelPositions(frame);
	elseif ( attribute == "uiparent-manage" ) then
		self:UIParentManageFramePositions();
	end
end

local FramePositionDelegate = CreateFrame("FRAME");
FramePositionDelegate:SetScript("OnAttributeChanged", FramePositionDelegate_OnAttributeChanged);

function FramePositionDelegate:ShowUIPanel(frame, force)
	local frameArea, framePushable;
	frameArea = GetUIPanelWindowInfo(frame, "area");
	if ( not CanOpenPanels() and frameArea ~= "center" and frameArea ~= "full" ) then
		self:ShowUIPanelFailed(frame);
		return;
	end
	framePushable = GetUIPanelWindowInfo(frame, "pushable") or 0;

	if ( UnitIsDead("player") and not GetUIPanelWindowInfo(frame, "whileDead") ) then
		NotWhileDeadError();
		return;
	end

	-- If we have a full-screen frame open, ignore other non-fullscreen open requests
	if ( self:GetUIPanel("fullscreen") and (frameArea ~= "full") ) then
		if ( force ) then
			self:SetUIPanel("fullscreen", nil, 1);
		else
			self:ShowUIPanelFailed(frame);
			return;
		end
	end

	-- If we have a "center" frame open, only listen to other "center" open requests
	-- Ascension Edit: allow center frames to override this behavior with dontCloseForNonCenterPanels = true. (used for Collections)
	local centerFrame = self:GetUIPanel("center");
	local centerArea, centerPushable;
	if ( centerFrame ) then
		local dontClose = GetUIPanelWindowInfo(centerFrame, "dontCloseForNonCenterPanels")
		if ( GetUIPanelWindowInfo(centerFrame, "allowOtherPanels") and not dontClose ) then
			HideUIPanel(centerFrame);
			centerFrame = nil;
		else	
			centerArea = GetUIPanelWindowInfo(centerFrame, "area");
			if ( centerArea and (centerArea == "center") and (frameArea ~= "center") and (frameArea ~= "full") ) then
				if ( force and not dontClose ) then
					self:SetUIPanel("center", nil, 1);
				elseif not dontClose then
					self:ShowUIPanelFailed(frame);
					return;
				end
			end
			centerPushable = GetUIPanelWindowInfo(centerFrame, "pushable") or 0;
		end
	end
	
	-- Full-screen frames just replace each other
	if ( frameArea == "full" ) then
		securecall("CloseAllWindows");
		self:SetUIPanel("fullscreen", frame);
		return;
	end
	
	-- Native "center" frames just replace each other, and they take priority over pushed frames
	if ( frameArea == "center" ) then
		securecall("CloseWindows");
		if ( not GetUIPanelWindowInfo(frame, "allowOtherPanels") ) then
			securecall("CloseAllBags");
		end
		self:SetUIPanel("center", frame, 1);
		return;
	end

	-- Doublewide frames take up the left and center spots
	if ( frameArea == "doublewide" ) then
		local leftFrame = self:GetUIPanel("left");
		if ( leftFrame ) then
			local leftPushable = GetUIPanelWindowInfo(leftFrame, "pushable") or 0;
			if ( leftPushable > 0 and CanShowRightUIPanel(leftFrame) ) then
				-- Push left to right
				self:MoveUIPanel("left", "right", 1);
			elseif ( centerFrame and CanShowRightUIPanel(centerFrame) ) then
				self:MoveUIPanel("center", "right", 1);
			end
		end
		self:SetUIPanel("doublewide", frame);
		return;
	end
	
	-- If not pushable, close any doublewide frames
	local doublewideFrame = self:GetUIPanel("doublewide");
	if ( doublewideFrame ) then
		if ( framePushable == 0 ) then
			-- Set as left (closes doublewide) and slide over the right frame
			self:SetUIPanel("left", frame, 1);
			self:MoveUIPanel("right", "center");
		elseif ( CanShowRightUIPanel(frame) ) then
			-- Set as right
			self:SetUIPanel("right", frame);
		else
			self:SetUIPanel("left", frame);
		end
		return;
	end
	
	-- Try to put it on the left
	local leftFrame = self:GetUIPanel("left");
	if ( not leftFrame ) then
		self:SetUIPanel("left", frame);
		return;
	end
	local leftPushable = GetUIPanelWindowInfo(leftFrame, "pushable") or 0;
	
	-- Two open already
	local rightFrame = self:GetUIPanel("right");
	if ( centerFrame and not rightFrame ) then
		-- If not pushable and left isn't pushable
		if ( leftPushable == 0 and framePushable == 0 ) then
			-- Replace left
			self:SetUIPanel("left", frame);
		elseif ( ( framePushable > centerPushable or centerArea == "center" ) and CanShowRightUIPanel(frame) ) then
			-- This one is highest priority, show as right
			self:SetUIPanel("right", frame);
		elseif ( framePushable < leftPushable ) then
			if ( centerArea == "center" ) then
				if ( CanShowRightUIPanel(leftFrame) ) then
					-- Skip center
					self:MoveUIPanel("left", "right", 1);
					self:SetUIPanel("left", frame);
				else
					-- Replace left
					self:SetUIPanel("left", frame);
				end
			else
				if ( CanShowUIPanels(frame, leftFrame, centerFrame) ) then
					-- Shift both
					self:MoveUIPanel("center", "right", 1);
					self:MoveUIPanel("left", "center", 1);
					self:SetUIPanel("left", frame);
				else
					-- Replace left
					self:SetUIPanel("left", frame);
				end
			end
		elseif ( framePushable <= centerPushable and centerArea ~= "center" and CanShowUIPanels(leftFrame, frame, centerFrame) ) then
			-- Push center
			self:MoveUIPanel("center", "right", 1);
			self:SetUIPanel("center", frame);
		elseif ( framePushable <= centerPushable and centerArea ~= "center" ) then
			-- Replace left
			self:SetUIPanel("left", frame);
		else
			-- Replace center
			self:SetUIPanel("center", frame);
		end
		
		return;
	end
	
	-- If there's only one open...
	if ( not centerFrame ) then
		-- If neither is pushable, replace
		if ( (leftPushable == 0) and (framePushable == 0) ) then
			self:SetUIPanel("left", frame);
			return;
		end

		-- Highest priority goes to center
		if ( leftPushable > framePushable ) then
			self:MoveUIPanel("left", "center", 1);
			self:SetUIPanel("left", frame);
		else
			self:SetUIPanel("center", frame);
		end
		
		return;
	end

	-- Three are shown
	local rightPushable = GetUIPanelWindowInfo(rightFrame, "pushable") or 0;
	if ( framePushable > rightPushable ) then
		-- This one is highest priority, slide the other two over
		if ( CanShowUIPanels(centerFrame, rightFrame, frame) ) then
			self:MoveUIPanel("center", "left", 1);
			self:MoveUIPanel("right", "center", 1);
			self:SetUIPanel("right", frame);
		else
			self:MoveUIPanel("right", "left", 1);
			self:SetUIPanel("center", frame);
		end
	elseif ( framePushable > centerPushable ) then
		-- This one is middle priority, so move the center frame to the left
		self:MoveUIPanel("center", "left", 1);
		self:SetUIPanel("center", frame);
	else
		self:SetUIPanel("left", frame);
	end
end

function FramePositionDelegate:ShowUIPanelFailed(frame)
	local showFailedFunc = _G[GetUIPanelWindowInfo(frame, "showFailedFunc")];
	if ( showFailedFunc ) then
		showFailedFunc(frame);
	end
end

function FramePositionDelegate:SetUIPanel(key, frame, skipSetPoint)
	if ( key == "fullscreen" ) then
		local oldFrame = self.fullscreen;
		self.fullscreen = frame;
	
		if ( oldFrame ) then
			oldFrame:Hide();
		end
	
		if ( frame ) then
			UIParent:Hide();
			frame:Show();
		else
			UIParent:Show();
			SetUIVisibility(true);
		end
		return;
	elseif ( key == "doublewide" ) then
		local oldLeft = self.left;
		local oldCenter = self.center;
		local oldDoubleWide = self.doublewide;
		self.doublewide = frame;
		self.left = nil;
		self.center = nil;
		
		if ( oldDoubleWide ) then
			oldDoubleWide:Hide();
		end
		
		if ( oldLeft ) then
			oldLeft:Hide();
		end
		
		if ( oldCenter ) then
			oldCenter:Hide();
		end
	elseif ( key ~= "left" and key ~= "center" and key ~= "right" ) then
		return;
	else
		local oldFrame = self[key];
		self[key] = frame;
		if ( oldFrame ) then
			oldFrame:Hide();
		else
			if ( self.doublewide ) then
				if ( key == "left" or key == "center" ) then
					self.doublewide:Hide();
					self.doublewide = nil;	
				end
			end
		end
	end
	
	if ( not skipSetPoint ) then
		securecall("UpdateUIPanelPositions");
	end
	
	if ( frame ) then
		frame:Show();
		-- Hide all child windows
		securecall("CloseChildWindows");
	end
end

function FramePositionDelegate:MoveUIPanel(current, new, skipSetPoint)
	if ( current ~= "left" and current ~= "center" and current ~= "right" and new ~= "left" and new ~= "center" and new ~= "right" ) then
		return;
	end

	self:SetUIPanel(new, nil, skipSetPoint);
	if ( self[current] ) then
		self[current]:Raise();
		self[new] = self[current];
		self[current] = nil;
		if ( not skipSetPoint ) then
			securecall("UpdateUIPanelPositions");
		end
	end
end

function FramePositionDelegate:HideUIPanel(frame, skipSetPoint)
	-- If we're hiding the full-screen frame, just hide it
	if ( frame == self:GetUIPanel("fullscreen") ) then
		self:SetUIPanel("fullscreen", nil);
		return;
	end
	
	-- If we're hiding the right frame, just hide it
	if ( frame == self:GetUIPanel("right") ) then
		self:SetUIPanel("right", nil, skipSetPoint);
		return;
	elseif ( frame == self:GetUIPanel("doublewide") ) then
		-- Slide over any right frame (hides the doublewide)
		self:MoveUIPanel("right", "left", skipSetPoint);
		return;
	end

	-- If we're hiding the center frame, slide over any right frame
	local centerFrame = self:GetUIPanel("center");
	if ( frame == centerFrame ) then
		self:MoveUIPanel("right", "center", skipSetPoint);
	elseif ( frame == self:GetUIPanel("left") ) then
		-- If we're hiding the left frame, move the other frames left, unless the center is a native center frame
		if ( centerFrame ) then
			local area = GetUIPanelWindowInfo(centerFrame, "area");
			if ( area ) then
				if ( area == "center" ) then
					-- Slide left, skip the center
					self:MoveUIPanel("right", "left", skipSetPoint);
					return;
				else
					-- Slide everything left
					self:MoveUIPanel("center", "left", 1);
					self:MoveUIPanel("right", "center", skipSetPoint);
					return;
				end
			end
		end
		self:SetUIPanel("left", nil, skipSetPoint);
	else
		frame:Hide();
	end
end

function FramePositionDelegate:GetUIPanel(key)
	if ( key ~= "left" and key ~= "center" and key ~= "right" and key ~= "doublewide" and key ~= "fullscreen" ) then
		return nil;
	end
	
	return self[key];
end

function FramePositionDelegate:UpdateUIPanelPositions(currentFrame)
	if ( self.updatingPanels ) then
		return;
	end
	self.updatingPanels = true;
	
	local topOffset = UIParent:GetAttribute("TOP_OFFSET");
	local leftOffset = UIParent:GetAttribute("LEFT_OFFSET");
	local centerOffset = UIParent:GetAttribute("CENTER_OFFSET");
	local rightOffset = UIParent:GetAttribute("RIGHT_OFFSET");

	local info;
	local frame = self:GetUIPanel("left");
	if ( frame ) then
		local xOff = GetUIPanelWindowInfo(frame,"xoffset") or 0;
		local yOff = GetUIPanelWindowInfo(frame,"yoffset") or 0;
		frame:ClearAllPoints();
		frame:SetPoint("TOPLEFT", "UIParent", "TOPLEFT", leftOffset + xOff, topOffset + yOff);
		centerOffset = leftOffset + GetUIPanelWidth(frame) + xOff;
		UIParent:SetAttribute("CENTER_OFFSET", centerOffset);
		frame:Raise();
	else
		frame = self:GetUIPanel("doublewide");
		if ( frame ) then
			local xOff = GetUIPanelWindowInfo(frame,"xoffset") or 0;
			local yOff = GetUIPanelWindowInfo(frame,"yoffset") or 0;
			frame:ClearAllPoints();
			frame:SetPoint("TOPLEFT", "UIParent", "TOPLEFT", leftOffset + xOff, topOffset + yOff);
			rightOffset = leftOffset + GetUIPanelWidth(frame) + xOff;
			UIParent:SetAttribute("RIGHT_OFFSET", rightOffset);
			frame:Raise();
		end
	end

	frame = self:GetUIPanel("center");
	if ( frame ) then
		local dontClose = GetUIPanelWindowInfo(frame, "dontCloseForNonCenterPanels");
		local allowOthers = GetUIPanelWindowInfo(frame, "allowOtherPanels");
		dontClose = dontClose and allowOthers
		if ( CanShowCenterUIPanel(frame) ) then
			local area = GetUIPanelWindowInfo(frame, "area");
			local xOff = GetUIPanelWindowInfo(frame,"xoffset") or 0;
			local yOff = GetUIPanelWindowInfo(frame,"yoffset") or 0;
			if ( area ~= "center" ) then
				frame:ClearAllPoints();
				frame:SetPoint("TOPLEFT", "UIParent", "TOPLEFT", centerOffset + xOff, topOffset + yOff);
			end
			rightOffset = centerOffset + GetUIPanelWidth(frame) + xOff;
		elseif not dontClose then
			if ( frame == currentFrame ) then
				frame = self:GetUIPanel("left") or self:GetUIPanel("doublewide");
				if ( frame ) then
					self:HideUIPanel(frame);
					self.updatingPanels = nil;
					self:UpdateUIPanelPositions(currentFrame);
					return;
				end
			end
			self:SetUIPanel("center", nil, 1);
			rightOffset = centerOffset + UIParent:GetAttribute("DEFAULT_FRAME_WIDTH");
		end
		frame:Raise();
	elseif ( not self:GetUIPanel("doublewide") ) then
		if ( self:GetUIPanel("left") ) then
			rightOffset = centerOffset + UIParent:GetAttribute("DEFAULT_FRAME_WIDTH");
		else
			rightOffset = leftOffset + UIParent:GetAttribute("DEFAULT_FRAME_WIDTH") * 2
		end
	end
	UIParent:SetAttribute("RIGHT_OFFSET", rightOffset);

	frame = self:GetUIPanel("right");
	if ( frame ) then
		if ( CanShowRightUIPanel(frame) ) then
			local xOff = GetUIPanelWindowInfo(frame,"xoffset") or 0;
			local yOff = GetUIPanelWindowInfo(frame,"yoffset") or 0;
			frame:ClearAllPoints();
			frame:SetPoint("TOPLEFT", "UIParent", "TOPLEFT", rightOffset  + xOff, topOffset + yOff);
		else
			if ( frame == currentFrame ) then
				frame = GetUIPanel("center") or GetUIPanel("left") or GetUIPanel("doublewide");
				if ( frame ) then
					self:HideUIPanel(frame);
					self.updatingPanels = nil;
					self:UpdateUIPanelPositions(currentFrame);
					return;
				end
			end
			self:SetUIPanel("right", nil, 1);
		end
		frame:Raise();
	end

	self.updatingPanels = nil;
end

function FramePositionDelegate:UIParentManageFramePositions()
	-- Update the variable with the happy magic number.
	UpdateMenuBarTop();
	
	-- Frames that affect offsets in y axis
	local yOffsetFrames = {};
	-- Frames that affect offsets in x axis
	local xOffsetFrames = {};
	
	-- Set up flags
	local hasBottomLeft, hasBottomRight, hasPetBar;
	
	if ( VehicleMenuBar and VehicleMenuBar:IsShown() ) then
		tinsert(yOffsetFrames, "vehicleMenuBar");
	else	
		if ( MultiBarBottomLeft:IsShown() or MultiBarBottomRight:IsShown() ) then
			tinsert(yOffsetFrames, "bottomEither");
		end
		if ( MultiBarBottomRight:IsShown() ) then
			tinsert(yOffsetFrames, "bottomRight");
			hasBottomRight = 1;
		end
		if ( MultiBarBottomLeft:IsShown() ) then
			tinsert(yOffsetFrames, "bottomLeft");
			hasBottomLeft = 1;
		end
		if ( MultiBarLeft:IsShown() ) then
			tinsert(xOffsetFrames, "rightLeft");
		elseif ( MultiBarRight:IsShown() ) then
			tinsert(xOffsetFrames, "rightRight");
		end
		if (PetActionBarFrame_IsAboveShapeshift and PetActionBarFrame_IsAboveShapeshift()) then
			tinsert(yOffsetFrames, "justBottomRightAndShapeshift");
		end
		if ( ( PetActionBarFrame and PetActionBarFrame:IsShown() ) or ( ShapeshiftBarFrame and ShapeshiftBarFrame:IsShown() ) or
			 ( MultiCastActionBarFrame and MultiCastActionBarFrame:IsShown() ) or ( PossessBarFrame and PossessBarFrame:IsShown() ) or
			 ( MainMenuBarVehicleLeaveButton and MainMenuBarVehicleLeaveButton:IsShown() ) ) then
			tinsert(yOffsetFrames, "pet");
			hasPetBar = 1;
		end
		if ( ReputationWatchBar:IsShown() and MainMenuExpBar:IsShown() ) then
			tinsert(yOffsetFrames, "reputation");
		end
		if ( TutorialFrameAlertButton:IsShown() ) then
			tinsert(yOffsetFrames, "tutorialAlert");
		end
	end
	
	if ( menuBarTop == 55 ) then
		UIPARENT_MANAGED_FRAME_POSITIONS["TutorialFrameAlertButton"].yOffset = -10;
	else
		UIPARENT_MANAGED_FRAME_POSITIONS["TutorialFrameAlertButton"].yOffset = -30;
	end
	
	
	-- Iterate through frames and set anchors according to the flags set
	for index, value in pairs(UIPARENT_MANAGED_FRAME_POSITIONS) do
		securecall("UIParent_ManageFramePosition", index, value, yOffsetFrames, xOffsetFrames, hasBottomLeft, hasBottomRight, hasPetBar);
	end
	
	-- Custom positioning not handled by the loop

	-- Update shapeshift bar appearance
	if ( MultiBarBottomLeft:IsShown() ) then
		SlidingActionBarTexture0:Hide();
		SlidingActionBarTexture1:Hide();
		if ( ShapeshiftBarFrame ) then
			ShapeshiftBarLeft:Hide();
			ShapeshiftBarRight:Hide();
			ShapeshiftBarMiddle:Hide();
			for i=1, GetNumShapeshiftForms() do
				_G["ShapeshiftButton"..i.."NormalTexture"]:SetWidth(50);
				_G["ShapeshiftButton"..i.."NormalTexture"]:SetHeight(50);
			end
		end
	else
		if (PetActionBarFrame_IsAboveShapeshift and PetActionBarFrame_IsAboveShapeshift()) then
			SlidingActionBarTexture0:Hide();
			SlidingActionBarTexture1:Hide();
		else
			SlidingActionBarTexture0:Show();
			SlidingActionBarTexture1:Show();
		end
		if ( ShapeshiftBarFrame ) then
			if ( GetNumShapeshiftForms() > 2 ) then
				ShapeshiftBarMiddle:Show();
			end
			ShapeshiftBarLeft:Show();
			ShapeshiftBarRight:Show();
			for i=1, GetNumShapeshiftForms() do
				_G["ShapeshiftButton"..i.."NormalTexture"]:SetWidth(64);
				_G["ShapeshiftButton"..i.."NormalTexture"]:SetHeight(64);
			end
		end
	end

	-- HACK: we have too many bars in this game now...
	-- if the shapeshift bar is shown then hide the multi-cast bar
	-- we'll have to figure out what we should do in this case if it ever really becomes a problem
	-- HACK 2: if the possession bar is shown then hide the multi-cast	 bar
	-- yeah, way too many bars...
	if PossessBarFrame and PossessBarFrame:IsShown() then
		HideMultiCastActionBar();
	elseif ( HasMultiCastActionBar and HasMultiCastActionBar() ) then
		if ShapeshiftBarFrame and ShapeshiftBarFrame:IsShown() then
			MULTICASTACTIONBAR_XPOS = 30 + ((ShapeshiftBarFrame:GetWidth() + 8) * GetNumShapeshiftForms()) + 20
		else
			MULTICASTACTIONBAR_XPOS = 30
		end
		-- I literally cannot figure out why in the world MULTICASTACTIONBAR_XPOS does not work in this function. 
		-- manually set the position of this dumb bar and forget it
		-- must be before ShowMultiCastActionBar() so addons can still hook that to position it
		MultiCastActionBarFrame:SetPoint("BOTTOMLEFT", MultiCastActionBarFrame:GetParent(), "TOPLEFT", MULTICASTACTIONBAR_XPOS, MULTICASTACTIONBAR_YPOS);
		ShowMultiCastActionBar();
	end

	-- If petactionbar is already shown, set its point in addition to changing its y target
	if ( PetActionBarFrame:IsShown() ) then
		PetActionBar_UpdatePositionValues();
		PetActionBarFrame:SetPoint("TOPLEFT", MainMenuBar, "BOTTOMLEFT", PETACTIONBAR_XPOS, PETACTIONBAR_YPOS);
	end

	-- Set battlefield minimap position
	if ( BattlefieldMinimapTab and not BattlefieldMinimapTab:IsUserPlaced() ) then
		BattlefieldMinimapTab:SetPoint("BOTTOMLEFT", "UIParent", "BOTTOMRIGHT", -225-CONTAINER_OFFSET_X, BATTLEFIELD_TAB_OFFSET_Y);
	end

	-- Setup y anchors
	local anchorY = 0;
	-- Capture bars
	if ( NUM_EXTENDED_UI_FRAMES ) then
		local captureBar;
		local numCaptureBars = 0;
		for i=1, NUM_EXTENDED_UI_FRAMES do
			captureBar = _G["WorldStateCaptureBar"..i];
			if ( captureBar and captureBar:IsShown() ) then
				captureBar:SetPoint("TOPRIGHT", MinimapCluster, "BOTTOMRIGHT", -CONTAINER_OFFSET_X, anchorY);
				anchorY = anchorY - captureBar:GetHeight();
			end
		end	
	end
	
	--Setup Vehicle seat indicator offset
	if ( VehicleSeatIndicator ) then
		if ( VehicleSeatIndicator and VehicleSeatIndicator:IsShown() ) then
			anchorY = anchorY - VehicleSeatIndicator:GetHeight() - 18;	--The -18 is there to give a small buffer for things like the QuestTimeFrame below the Seat Indicator
		end
		
	end
	
	-- Boss frames
	local numBossFrames = 0;
	local durabilityXOffset = CONTAINER_OFFSET_X;
	local durabilityYOffset = anchorY;
	if ( Boss1TargetFrame ) then
		for i = 1, MAX_BOSS_FRAMES do
			if ( _G["Boss"..i.."TargetFrame"]:IsShown() ) then
				numBossFrames = numBossFrames + 1;
			else
				break;
			end
		end
		if ( numBossFrames > 0 ) then
			Boss1TargetFrame:SetPoint("TOPRIGHT", "MinimapCluster", "BOTTOMRIGHT", -(CONTAINER_OFFSET_X * 1.3) + 60, anchorY + 20);
			anchorY = anchorY - 6 - numBossFrames * 66;
			durabilityXOffset = durabilityXOffset + 135;
		end
	end
	
	-- Setup durability offset
	if ( DurabilityFrame ) then
		if ( DurabilityShield:IsShown() or DurabilityOffWeapon:IsShown() or DurabilityRanged:IsShown() ) then
			durabilityXOffset = durabilityXOffset + 20;
		end
		DurabilityFrame:SetPoint("TOPRIGHT", "MinimapCluster", "BOTTOMRIGHT", -durabilityXOffset, durabilityYOffset);
		if ( DurabilityFrame:IsShown() and numBossFrames == 0 ) then
			anchorY = anchorY - DurabilityFrame:GetHeight() - 10;
		end
	end
	
	if ( ArenaEnemyFrames ) then
		ArenaEnemyFrames:ClearAllPoints();
		ArenaEnemyFrames:SetPoint("TOPRIGHT", MinimapCluster, "BOTTOMRIGHT", -CONTAINER_OFFSET_X, anchorY);
	end

	local numArenaOpponents = GetNumArenaOpponents();
	if ( not WatchFrame:IsUserPlaced() and ArenaEnemyFrames and ArenaEnemyFrames:IsShown() and (numArenaOpponents > 0) ) then
		WatchFrame:ClearAllPoints();
		WatchFrame:SetPoint("TOPRIGHT", "ArenaEnemyFrame"..numArenaOpponents, "BOTTOMRIGHT", 2, -35);
	elseif ( not WatchFrame:IsUserPlaced() ) then -- We're using Simple Quest Tracking, automagically size and position!
		WatchFrame:ClearAllPoints();
		-- move up if only the minimap cluster is above, move down a little otherwise
		if ( anchorY == 0 ) then
			anchorY = 20;
		end
		WatchFrame:SetPoint("TOPRIGHT", "MinimapCluster", "BOTTOMRIGHT", -CONTAINER_OFFSET_X, anchorY);
		-- OnSizeChanged for WatchFrame handles its redraw
	end
	
	WatchFrame:SetPoint("BOTTOMRIGHT", "UIParent", "BOTTOMRIGHT", -CONTAINER_OFFSET_X, CONTAINER_OFFSET_Y);
	
	-- Update chat dock since the dock could have moved
	FCF_DockUpdate();
	updateContainerFrameAnchors();
end

-- Call this function to update the positions of all frames that can appear on the right side of the screen
function UIParent_ManageFramePositions()
	--Dispatch to secure code
	FramePositionDelegate:SetAttribute("uiparent-manage", true);
end

function ToggleFrame(frame)
	if ( frame:IsShown() ) then
		HideUIPanel(frame);
	else
		ShowUIPanel(frame);
	end
end

function ShowUIPanel(frame, force)
	frame = _G[frame] or frame
	if ( not frame or frame:IsShown() ) then
		return;
	end
	if ( not GetUIPanelWindowInfo(frame, "area") ) then
		frame:Show();
		return;
	end
	
	-- Dispatch to secure code
	FramePositionDelegate:SetAttribute("panel-force", force);
	FramePositionDelegate:SetAttribute("panel-frame", frame);
	FramePositionDelegate:SetAttribute("panel-show", true);
end

function HideUIPanel(frame, skipSetPoint)
	if ( not frame or not frame:IsShown() ) then
		return;
	end
	
	if ( not GetUIPanelWindowInfo(frame, "area") ) then
		frame:Hide();
		return;
	end
	
	--Dispatch to secure code
	FramePositionDelegate:SetAttribute("panel-frame", frame);
	FramePositionDelegate:SetAttribute("panel-skipSetPoint", skipSetPoint);
	FramePositionDelegate:SetAttribute("panel-hide", true);
end

function HideParentPanel(self)	
	HideUIPanel(self:GetParent());
end

function GetUIPanel(key)
	return FramePositionDelegate:GetUIPanel(key);
end

function GetUIPanelWidth(frame)
	return GetUIPanelWindowInfo(frame, "width") or frame:GetWidth();
end

function GetMaxUIPanelsWidth()
	local bufferBoundry = UIParent:GetRight() - UIParent:GetAttribute("RIGHT_OFFSET_BUFFER");
	if ( Minimap:IsShown() and not MinimapCluster:IsUserPlaced() ) then
		-- If the Minimap is in the default place, make sure you wont overlap it either
		return min(MinimapCluster:GetLeft(), bufferBoundry);
	else
		-- If the minimap has been moved, make sure not to overlap the right side bars
		return bufferBoundry;
	end
end

function CanShowRightUIPanel(frame)
	local width;
	if ( frame ) then
		width = GetUIPanelWidth(frame);
	else
		width = UIParent:GetAttribute("DEFAULT_FRAME_WIDTH");
	end
	
	local rightSide = UIParent:GetAttribute("RIGHT_OFFSET") + width;
	if ( rightSide < GetMaxUIPanelsWidth() ) then
		return 1;
	end
end

function CanShowCenterUIPanel(frame)
	local width;
	if ( frame ) then
		width = GetUIPanelWidth(frame);
	else
		width = UIParent:GetAttribute("DEFAULT_FRAME_WIDTH");
	end
	
	local rightSide = UIParent:GetAttribute("CENTER_OFFSET") + width;
	if ( rightSide < GetMaxUIPanelsWidth() ) then
		return 1;
	end
end

function CanShowUIPanels(leftFrame, centerFrame, rightFrame)
	local offset = UIParent:GetAttribute("LEFT_OFFSET");

	if ( leftFrame ) then
		offset = offset + GetUIPanelWidth(leftFrame);
		if ( centerFrame ) then
			local area = GetUIPanelWindowInfo(centerFrame, "area");
			if ( area ~= "center" ) then
				offset = offset + ( GetUIPanelWindowInfo(centerFrame, "width") or UIParent:GetAttribute("DEFAULT_FRAME_WIDTH") );
			else
				offset = offset + GetUIPanelWidth(centerFrame);
			end
			if ( rightFrame ) then
				offset = offset + GetUIPanelWidth(rightFrame);
			end
		end
	elseif ( centerFrame ) then
		offset = GetUIPanelWidth(centerFrame);
	end
	
	if ( offset < GetMaxUIPanelsWidth() ) then
		return 1;
	end
end

function CanOpenPanels()
	--[[
	if ( UnitIsDead("player") ) then
		return nil;
	end
	
	Previously couldn't open frames if player was out of control i.e. feared
	if ( UnitIsDead("player") or UIParent.isOutOfControl ) then
		return nil;
	end
	]]

	local centerFrame = GetUIPanel("center");
	if ( not centerFrame ) then
		return 1;
	end

	local area = GetUIPanelWindowInfo(centerFrame, "area");
	local allowOtherPanels = GetUIPanelWindowInfo(centerFrame, "allowOtherPanels");
	if ( area and (area == "center") and not allowOtherPanels ) then
		return nil;
	end

	return 1;
end

-- this function handles possibly tainted values and so 
-- should always be called from secure code using securecall()
function CloseChildWindows()
	local childWindow;
	for index, value in pairs(UIChildWindows) do
		childWindow = _G[value];
		if ( childWindow ) then
			childWindow:Hide();
		end
	end
end

-- this function handles possibly tainted values and so 
-- should always be called from secure code using securecall()
function CloseSpecialWindows()
	local found;
	for index, value in pairs(UISpecialFrames) do
		local frame = _G[value];
		if ( frame and frame:IsShown() ) then
			frame:Hide();
			found = 1;
		end
	end

	if KeywordTooltip:ReleaseNested() then
		found = 1;
	end

	return found;
end

function CloseWindows(ignoreCenter, frameToIgnore)
	-- This function will close all frames that are not the current frame
	local leftFrame = GetUIPanel("left");
	local centerFrame = GetUIPanel("center");
	local rightFrame = GetUIPanel("right");
	local doublewideFrame = GetUIPanel("doublewide");
	local fullScreenFrame = GetUIPanel("fullscreen");
	local found = leftFrame or centerFrame or rightFrame or doublewideFrame or fullScreenFrame;

	if ( not frameToIgnore or frameToIgnore ~= leftFrame ) then
		HideUIPanel(leftFrame, 1);
	end
	
	HideUIPanel(fullScreenFrame, 1);
	HideUIPanel(doublewideFrame, 1);
	
	if ( not frameToIgnore or frameToIgnore ~= centerFrame ) then
		if ( centerFrame ) then
			local area = GetUIPanelWindowInfo(centerFrame, "area");
			if ( area ~= "center" or not ignoreCenter ) then
				HideUIPanel(centerFrame, 1);
			end	
		end
	end
	
	if ( not frameToIgnore or frameToIgnore ~= rightFrame ) then
		if ( rightFrame ) then
			HideUIPanel(rightFrame, 1);
		end
	end

	found = securecall("CloseSpecialWindows") or found;
	
	UpdateUIPanelPositions();

	return found;
end

function CloseAllWindows_WithExceptions()
	-- Insert exceptions here, right now we just don't close the scoreFrame when the player loses control i.e. the game over spell effect
	if ( GetUIPanel("center") == WorldStateScoreFrame ) then
		CloseAllWindows(1);
	elseif ( IsOptionFrameOpen() ) then
		CloseAllWindows(1);
	else
		CloseAllWindows();
	end
end

function CloseAllWindows(ignoreCenter)
	local bagsVisible = nil;
	local windowsVisible = nil;
	for i=1, NUM_CONTAINER_FRAMES, 1 do
		local containerFrame = _G["ContainerFrame"..i];
		if ( containerFrame:IsShown() ) then
			containerFrame:Hide();
			bagsVisible = 1;
		end
	end
	windowsVisible = CloseWindows(ignoreCenter);
	return (bagsVisible or windowsVisible);
end

-- this function handles possibly tainted values and so 
-- should always be called from secure code using securecall()
function CloseMenus()
	local menusVisible = nil;
	local menu
	for index, value in pairs(UIMenus) do
		menu = _G[value];
		if ( menu and menu:IsShown() ) then
			menu:Hide();
			menusVisible = 1;
		end
	end
	return menusVisible;
end

function UpdateUIPanelPositions(currentFrame)
	FramePositionDelegate:SetAttribute("panel-frame", currentFrame)
	FramePositionDelegate:SetAttribute("panel-update", true);
end

function IsOptionFrameOpen()
	if ( EscapeMenu:IsShown() or InterfaceOptionsFrame:IsShown() or (KeyBindingFrame and KeyBindingFrame:IsShown()) ) then
		return 1;
	else
		return nil;
	end
end

function LowerFrameLevel(frame)
	frame:SetFrameLevel(frame:GetFrameLevel()-1);
end

function RaiseFrameLevel(frame)
	frame:SetFrameLevel(frame:GetFrameLevel()+1);
end

-- Function to reposition frames if they get dragged off screen
function ValidateFramePosition(frame, offscreenPadding, returnOffscreen)
	if ( not frame ) then
		return;
	end
	local left = frame:GetLeft();
	local right = frame:GetRight();
	local top = frame:GetTop();
	local bottom = frame:GetBottom();
	local newAnchorX, newAnchorY;
	if ( not offscreenPadding ) then
		offscreenPadding = 15;
	end
	if ( bottom < (0 + MainMenuBar:GetHeight() + offscreenPadding)) then
		-- Off the bottom of the screen
		newAnchorY = MainMenuBar:GetHeight() + frame:GetHeight() - GetScreenHeight(); 
	elseif ( top > GetScreenHeight() ) then
		-- Off the top of the screen
		newAnchorY =  0;
	end
	if ( left < 0 ) then
		-- Off the left of the screen
		newAnchorX = 0;
	elseif ( right > GetScreenWidth() ) then
		-- Off the right of the screen
		newAnchorX = GetScreenWidth() - frame:GetWidth();
	end
	if ( newAnchorX or newAnchorY ) then
		if ( returnOffscreen ) then
			return 1;
		else
			if ( not newAnchorX ) then
				newAnchorX = left;
			elseif ( not newAnchorY ) then
				newAnchorY = top - GetScreenHeight();
			end
			frame:ClearAllPoints();
			frame:SetPoint("TOPLEFT", nil, "TOPLEFT", newAnchorX, newAnchorY);
		end
		
		
	else
		if ( returnOffscreen ) then
			return nil;
		end
	end
end

local function ButtonPulseContains(button)
	for index, pulseButton in pairs(PULSEBUTTONS) do
		if ( pulseButton == button ) then
			return true
		end
	end
	
	return false
end

-- Functions to handle button pulsing (Highlight, Unhighlight)
function SetButtonPulse(button, duration, pulseRate)
	button.pulseDuration = pulseRate;
	button.pulseTimeLeft = duration
	-- pulseRate is actually seconds per pulse state
	button.pulseRate = pulseRate;
	button.pulseOn = 0;
	if securecallfunction(ButtonPulseContains, button) then
		return
	end
	tinsert(PULSEBUTTONS, button);
end

-- Update the button pulsing
function ButtonPulse_OnUpdate(elapsed)
	for index, button in pairs(PULSEBUTTONS) do
		if not button.pulseTimeLeft or ( button.pulseTimeLeft > 0 ) then
			if ( button.pulseDuration < 0 ) then
				if ( button.pulseOn == 1 ) then
					button:UnlockHighlight();
					button.pulseOn = 0;
				else
					button:LockHighlight();
					button.pulseOn = 1;
				end
				button.pulseDuration = button.pulseRate;
			end
			button.pulseDuration = button.pulseDuration - elapsed;
			if button.pulseTimeLeft then
				button.pulseTimeLeft = button.pulseTimeLeft - elapsed;
			end
		else
			button:UnlockHighlight();
			button.pulseOn = nil;
			tDeleteItem(PULSEBUTTONS, button);
		end
		
	end 
end

function ButtonPulse_StopPulse(button)
	for index, pulseButton in pairs(PULSEBUTTONS) do
		if ( pulseButton == button ) then
			button.pulseOn = nil;
			button:UnlockHighlight();
			tDeleteItem(PULSEBUTTONS, button);
		end
	end
end

function UIDoFramesIntersect(frame1, frame2)
	if ( ( frame1:GetLeft() < frame2:GetRight() ) and ( frame1:GetRight() > frame2:GetLeft() ) and
		( frame1:GetBottom() < frame2:GetTop() ) and ( frame1:GetTop() > frame2:GetBottom() ) ) then
		return true;
	else
		return false;
	end
end

-- Lua Helper functions --

function BuildListString(...)
	local text = ...;
	if ( not text ) then
		return nil;
	end
	local string = text;
	for i=2, select("#", ...) do
		text = select(i, ...);
		if ( text ) then
			string = string..", "..text;
		end
	end
	return string;
end

function BuildColoredListString(...)
	if ( select("#", ...) == 0 ) then
		return nil;
	end

	-- Takes input where odd items are the text and even items determine whether the arg should be colored or not
	local text, normal = ...;
	local string;
	if ( normal ) then
		string = text;
	else
		string = RED_FONT_COLOR_CODE..text..FONT_COLOR_CODE_CLOSE;
	end
	for i=3, select("#", ...), 2 do
		text, normal = select(i, ...);
		if ( normal ) then
			-- If meets the condition
			string = string..", "..text;
		else
			-- If doesn't meet the condition
			string = string..", "..RED_FONT_COLOR_CODE..text..FONT_COLOR_CODE_CLOSE;
		end
	end

	return string;
end

function BuildNewLineListString(...)
	local text;
	local index = 1;
	for i=1, select("#", ...) do
		text = select(i, ...);
		index = index + 1;
		if ( text ) then
			break;
		end
	end
	if ( not text ) then
		return nil;
	end
	local string = text;
	for i=index, select("#", ...) do
		text = select(i, ...);
		if ( text ) then
			string = string.."\n"..text;
		end
	end
	return string;
end

function BuildMultilineTooltip(globalStringName, tooltip, r, g, b)
	if ( not tooltip ) then
		tooltip = GameTooltip;
	end
	if ( not r ) then
		r = 1.0;
		g = 1.0;
		b = 1.0;
	end
	local i = 1;
	local string = _G[globalStringName..i];
	while (string) do
		tooltip:AddLine(string, "", r, g, b);
		i = i + 1;
		string = _G[globalStringName..i];
	end
end

function tContains(table, item)
	local index = 1;
	while table[index] do
		if ( item == table[index] ) then
			return 1;
		end
		index = index + 1;
	end
	return nil;
end

function CopyTable(settings)
	local copy = {};
	for k, v in pairs(settings) do
		if ( type(v) == "table" ) then
			copy[k] = CopyTable(v);
		else
			copy[k] = v;
		end
	end
	return copy;
end

function MouseIsOver(region, topOffset, bottomOffset, leftOffset, rightOffset)
	return region:IsMouseOver(topOffset, bottomOffset, leftOffset, rightOffset);
end

-- Wrapper for the desaturation function
function SetDesaturation(texture, desaturation)
	local shaderSupported = texture:SetDesaturated(desaturation);
	if ( not shaderSupported ) then
		if ( desaturation ) then
			texture:SetVertexColor(0.5, 0.5, 0.5);
		else
			texture:SetVertexColor(1.0, 1.0, 1.0);
		end
	end
end

function GetMaterialTextColors(material)
	local textColor = MATERIAL_TEXT_COLOR_TABLE[material];
	local titleColor = MATERIAL_TITLETEXT_COLOR_TABLE[material];
	if ( not(textColor and titleColor) ) then
		textColor = MATERIAL_TEXT_COLOR_TABLE["Default"];
		titleColor = MATERIAL_TITLETEXT_COLOR_TABLE["Default"];
	end
	return textColor, titleColor;
end


-- Model --

-- Generic model rotation functions
function Model_OnLoad (self)
	self.rotation = 0.61;
	self:SetRotation(self.rotation);
end

function Model_RotateLeft(model, rotationIncrement)
	if ( not rotationIncrement ) then
		rotationIncrement = 0.03;
	end
	model.rotation = model.rotation - rotationIncrement;
	model:SetRotation(model.rotation);
	PlaySound("igInventoryRotateCharacter");
end

function Model_RotateRight(model, rotationIncrement)
	if ( not rotationIncrement ) then
		rotationIncrement = 0.03;
	end
	model.rotation = model.rotation + rotationIncrement;
	model:SetRotation(model.rotation);
	PlaySound("igInventoryRotateCharacter");
end

function Model_OnUpdate(self, elapsedTime, rotationsPerSecond)
	if ( not rotationsPerSecond ) then
		rotationsPerSecond = ROTATIONS_PER_SECOND;
	end
	if ( _G[self:GetName().."RotateLeftButton"]:GetButtonState() == "PUSHED" ) then
		self.rotation = self.rotation + (elapsedTime * 2 * PI * rotationsPerSecond);
		if ( self.rotation < 0 ) then
			self.rotation = self.rotation + (2 * PI);
		end
		self:SetRotation(self.rotation);
	end
	if ( _G[self:GetName().."RotateRightButton"]:GetButtonState() == "PUSHED" ) then
		self.rotation = self.rotation - (elapsedTime * 2 * PI * rotationsPerSecond);
		if ( self.rotation > (2 * PI) ) then
			self.rotation = self.rotation - (2 * PI);
		end
		self:SetRotation(self.rotation);
	end
end

-- Function that handles the escape key functions
function ToggleGameMenu()
	if ( not UIParent:IsShown() ) then
		UIParent:Show();
		SetUIVisibility(true);
	elseif ( securecall("StaticPopup_EscapePressed") ) then
	elseif ( EscapeMenu:IsShown() ) then
		HideUIPanel(EscapeMenu);
	elseif BuildCreatorUtil.GetHeldSpell() then
		BuildCreatorUtil.ReleaseHeldSpell()
	elseif ( VideoOptionsFrame:IsShown() ) then
		VideoOptionsFrameCancel:Click();
	elseif ( AudioOptionsFrame:IsShown() ) then
		AudioOptionsFrameCancel:Click();
	elseif ( InterfaceOptionsFrame:IsShown() ) then
		InterfaceOptionsFrameCancel:Click();
	elseif ( TimeManagerFrame and TimeManagerFrame:IsShown() ) then
		TimeManagerCloseButton:Click();
	elseif ( MultiCastFlyoutFrame:IsShown() ) then
		MultiCastFlyoutFrame_Hide(MultiCastFlyoutFrame, true);
	elseif ( securecall("FCFDockOverflow_CloseLists") ) then
	elseif ( securecall("CloseMenus") ) then
	elseif ( CloseCalendarMenus and securecall("CloseCalendarMenus") ) then
	elseif ( SpellStopCasting() ) then
	elseif ( SpellStopTargeting() ) then
	elseif ( securecall("CloseAllWindows") ) then
	elseif ( ClearTarget() and (not UnitIsCharmed("player")) ) then
	elseif ( OpacityFrame:IsShown() ) then
		OpacityFrame:Hide();
	else
		ShowUIPanel(EscapeMenu);
	end
end

-- Visual Misc --

function GetScreenHeightScale()
	local screenHeight = 768;
	return GetScreenHeight()/screenHeight;
end

function GetScreenWidthScale()
	local screenWidth = 1024;
	return GetScreenWidth()/screenWidth;
end

function ShowInspectCursor()
	SetCursor("INSPECT_CURSOR");
end

-- Helper function to show the inspect cursor if the ctrl key is down
function CursorUpdate(self)
	if ( IsModifiedClick("DRESSUP") and self.hasItem ) then
		ShowInspectCursor();
	else
		ResetCursor();
	end
end

function CursorOnUpdate(self)
	if ( GameTooltip:IsOwned(self) ) then
		CursorUpdate(self);
	end
end

function AnimateTexCoords(texture, textureWidth, textureHeight, frameWidth, frameHeight, numFrames, elapsed, throttle)
	if ( not texture.frame ) then
		-- initialize everything
		texture.frame = 1;
		texture.throttle = throttle;
		texture.numColumns = floor(textureWidth/frameWidth);
		texture.numRows = floor(textureHeight/frameHeight);
		texture.columnWidth = frameWidth/textureWidth;
		texture.rowHeight = frameHeight/textureHeight;
	end
	local frame = texture.frame;
	throttle = throttle or 0.1
	if ( not texture.throttle or texture.throttle > throttle ) then
		local framesToAdvance = texture.throttle and floor(texture.throttle / throttle) or 1;
		while ( frame + framesToAdvance > numFrames ) do
			frame = frame - numFrames;
		end
		frame = frame + framesToAdvance;
		texture.throttle = 0;
		local left = mod(frame-1, texture.numColumns)*texture.columnWidth;
		local right = left + texture.columnWidth;
		local bottom = ceil(frame/texture.numColumns)*texture.rowHeight;
		local top = bottom - texture.rowHeight;
		texture:SetTexCoord(left, right, top, bottom);

		texture.frame = frame;
	else
		texture.throttle = texture.throttle + elapsed;
	end
end


-- Bindings --

function GetBindingText(name, prefix, returnAbbr)
	if ( not name ) then
		return "";
	end
	local tempName = name;
	local i = strfind(name, "-");
	local dashIndex = nil;
	local count = 0;
	while ( i ) do
		if ( not dashIndex ) then
			dashIndex = i;
		else
			dashIndex = dashIndex + i;
		end
		count = count + 1;
		tempName = strsub(tempName, i + 1);
		i = strfind(tempName, "-");
	end

	local modKeys = '';
	if ( not dashIndex ) then
		dashIndex = 0;
	else
		modKeys = strsub(name, 1, dashIndex);

		if ( tempName == "CAPSLOCK" ) then
			gsub(tempName, "CAPSLOCK", "Caps");
		end
		
		-- replace for all languages
		-- for the "push-to-talk" binding
		modKeys = gsub(modKeys, "LSHIFT", LSHIFT_KEY_TEXT);
		modKeys = gsub(modKeys, "RSHIFT", RSHIFT_KEY_TEXT);
		modKeys = gsub(modKeys, "LCTRL", LCTRL_KEY_TEXT);
		modKeys = gsub(modKeys, "RCTRL", RCTRL_KEY_TEXT);
		modKeys = gsub(modKeys, "LALT", LALT_KEY_TEXT);
		modKeys = gsub(modKeys, "RALT", RALT_KEY_TEXT);
		
		-- use the SHIFT code if they decide to localize the CTRL further. The token is CTRL_KEY_TEXT
		if ( GetLocale() == "deDE") then
			modKeys = gsub(modKeys, "CTRL", "STRG");
		end
		-- Only doing French for now since all the other languages use SHIFT, remove the "if" if other languages localize it
		if ( GetLocale() == "frFR" ) then
			modKeys = gsub(modKeys, "SHIFT", SHIFT_KEY_TEXT);
		end
	end

	if ( returnAbbr ) then
		if ( count > 1 ) then
			return "·";
		else 
			modKeys = gsub(modKeys, "CTRL", "c");
			modKeys = gsub(modKeys, "SHIFT", "s");
			modKeys = gsub(modKeys, "ALT", "a");
			modKeys = gsub(modKeys, "STRG", "st");
		end
	end

	if ( not prefix ) then
		prefix = "";
	end

	-- fix for bug 103620: mouse buttons are not being translated properly
	if ( tempName == "LeftButton" ) then
		tempName = "BUTTON1";
	elseif ( tempName == "RightButton" ) then
		tempName = "BUTTON2";
	elseif ( tempName == "MiddleButton" ) then
		tempName = "BUTTON3";
	elseif ( tempName == "Button4" ) then
		tempName = "BUTTON4";
	elseif ( tempName == "Button5" ) then
		tempName = "BUTTON5";
	elseif ( tempName == "Button6" ) then
		tempName = "BUTTON6";
	elseif ( tempName == "Button7" ) then
		tempName = "BUTTON7";
	elseif ( tempName == "Button8" ) then
		tempName = "BUTTON8";
	elseif ( tempName == "Button9" ) then
		tempName = "BUTTON9";
	elseif ( tempName == "Button10" ) then
		tempName = "BUTTON10";
	elseif ( tempName == "Button11" ) then
		tempName = "BUTTON11";
	elseif ( tempName == "Button12" ) then
		tempName = "BUTTON12";
	elseif ( tempName == "Button13" ) then
		tempName = "BUTTON13";
	elseif ( tempName == "Button14" ) then
		tempName = "BUTTON14";
	elseif ( tempName == "Button15" ) then
		tempName = "BUTTON15";
	elseif ( tempName == "Button16" ) then
		tempName = "BUTTON16";
	elseif ( tempName == "Button17" ) then
		tempName = "BUTTON17";
	elseif ( tempName == "Button18" ) then
		tempName = "BUTTON18";
	elseif ( tempName == "Button19" ) then
		tempName = "BUTTON19";
	elseif ( tempName == "Button20" ) then
		tempName = "BUTTON20";
	elseif ( tempName == "Button21" ) then
		tempName = "BUTTON21";
	elseif ( tempName == "Button22" ) then
		tempName = "BUTTON22";
	elseif ( tempName == "Button23" ) then
		tempName = "BUTTON23";
	elseif ( tempName == "Button24" ) then
		tempName = "BUTTON24";
	elseif ( tempName == "Button25" ) then
		tempName = "BUTTON25";
	elseif ( tempName == "Button26" ) then
		tempName = "BUTTON26";
	elseif ( tempName == "Button27" ) then
		tempName = "BUTTON27";
	elseif ( tempName == "Button28" ) then
		tempName = "BUTTON28";
	elseif ( tempName == "Button29" ) then
		tempName = "BUTTON29";
	elseif ( tempName == "Button30" ) then
		tempName = "BUTTON30";
	elseif ( tempName == "Button31" ) then
		tempName = "BUTTON31";
	end

	local localizedName = nil;
	if ( IsMacClient() ) then
		-- see if there is a mac specific name for the key
		localizedName = _G[prefix..tempName.."_MAC"];
	end
	if ( not localizedName ) then
		localizedName = _G[prefix..tempName];
	end
	-- for the "push-to-talk" binding it can be just a modifier key
	if ( not localizedName ) then
		localizedName = _G[tempName.."_KEY_TEXT"];
	end
	if ( not localizedName ) then
		localizedName = tempName;
	end
	return modKeys..localizedName;
end


function GetBindingFromClick(input)
	local fullInput = "";

	-- MUST BE IN THIS ORDER (ALT, CTRL, SHIFT)
	if ( IsAltKeyDown() ) then
		fullInput = fullInput.."ALT-";
	end

	if ( IsControlKeyDown() ) then
		fullInput = fullInput.."CTRL-"
	end

	if ( IsShiftKeyDown() ) then
		fullInput = fullInput.."SHIFT-"
	end

	if ( input == "LeftButton" ) then
		fullInput = fullInput.."BUTTON1";
	elseif ( input == "RightButton" ) then
		fullInput = fullInput.."BUTTON2";
	elseif ( input == "MiddleButton" ) then
		fullInput = fullInput.."BUTTON3";
	elseif ( input == "Button4" ) then
		fullInput = fullInput.."BUTTON4";
	elseif ( input == "Button5" ) then
		fullInput = fullInput.."BUTTON5";
	elseif ( input == "Button6" ) then
		fullInput = fullInput.."BUTTON6";
	elseif ( input == "Button7" ) then
		fullInput = fullInput.."BUTTON7";
	elseif ( input == "Button8" ) then
		fullInput = fullInput.."BUTTON8";
	elseif ( input == "Button9" ) then
		fullInput = fullInput.."BUTTON9";
	elseif ( input == "Button10" ) then
		fullInput = fullInput.."BUTTON10";
	elseif ( input == "Button11" ) then
		fullInput = fullInput.."BUTTON11";
	elseif ( input == "Button12" ) then
		fullInput = fullInput.."BUTTON12";
	elseif ( input == "Button13" ) then
		fullInput = fullInput.."BUTTON13";
	elseif ( input == "Button14" ) then
		fullInput = fullInput.."BUTTON14";
	elseif ( input == "Button15" ) then
		fullInput = fullInput.."BUTTON15";
	elseif ( input == "Button16" ) then
		fullInput = fullInput.."BUTTON16";
	elseif ( input == "Button17" ) then
		fullInput = fullInput.."BUTTON17";
	elseif ( input == "Button18" ) then
		fullInput = fullInput.."BUTTON18";
	elseif ( input == "Button19" ) then
		fullInput = fullInput.."BUTTON19";
	elseif ( input == "Button20" ) then
		fullInput = fullInput.."BUTTON20";
	elseif ( input == "Button21" ) then
		fullInput = fullInput.."BUTTON21";
	elseif ( input == "Button22" ) then
		fullInput = fullInput.."BUTTON22";
	elseif ( input == "Button23" ) then
		fullInput = fullInput.."BUTTON23";
	elseif ( input == "Button24" ) then
		fullInput = fullInput.."BUTTON24";
	elseif ( input == "Button25" ) then
		fullInput = fullInput.."BUTTON25";
	elseif ( input == "Button26" ) then
		fullInput = fullInput.."BUTTON26";
	elseif ( input == "Button27" ) then
		fullInput = fullInput.."BUTTON27";
	elseif ( input == "Button28" ) then
		fullInput = fullInput.."BUTTON28";
	elseif ( input == "Button29" ) then
		fullInput = fullInput.."BUTTON29";
	elseif ( input == "Button30" ) then
		fullInput = fullInput.."BUTTON30";
	elseif ( input == "Button31" ) then
		fullInput = fullInput.."BUTTON31";
	else
		fullInput = fullInput..input;
	end

	return GetBindingByKey(fullInput);
end


-- Game Logic --

function RealPartyIsFull()
	if ( (GetRealNumPartyMembers() < MAX_PARTY_MEMBERS) or (GetRealNumRaidMembers() > 0 and (GetRealNumRaidMembers() < MAX_RAID_MEMBERS)) ) then
		return false;
	else
		return true;
	end
end

function CanGroupInvite()
	if ( (GetNumPartyMembers() > 0) or (GetNumRaidMembers() > 0) ) then
		if ( IsPartyLeader() or IsRaidOfficer() ) then
			return true;
		else
			return false;
		end
	else
		return true;
	end
end

function UnitHasMana(unit)
	local powerType, powerToken = UnitPowerType(unit);
	if ( powerToken == "MANA" and UnitPowerMax(unit, powerType) > 0 ) then
		return 1;
	end
	return nil;
end

function RaiseFrameLevelByTwo(frame)
	-- We do this enough that it saves closures.
	frame:SetFrameLevel(frame:GetFrameLevel()+2);
end

function ShowResurrectRequest(offerer)
	if ( ResurrectHasSickness() ) then
		StaticPopup_Show("RESURRECT", offerer);
	elseif ( ResurrectHasTimer() ) then
		StaticPopup_Show("RESURRECT_NO_SICKNESS", offerer);
	else
		StaticPopup_Show("RESURRECT_NO_TIMER", offerer);
	end
end

function RefreshAuras(frame, unit, numAuras, suffix, checkCVar, showBuffs)
	if ( showBuffs ) then
		RefreshBuffs(frame, unit, numAuras, suffix, checkCVar);
	else
		RefreshDebuffs(frame, unit, numAuras, suffix, checkCVar);
	end
end

function RefreshBuffs(frame, unit, numBuffs, suffix, checkCVar)
	local frameName = frame:GetName();

	frame.hasDispellable = nil;

	numBuffs = numBuffs or MAX_PARTY_BUFFS;
	suffix = suffix or "Buff";

	local unitStatus, statusColor;
	local debuffTotal = 0;
	local name, rank, icon, count, debuffType, duration, expirationTime;
	for i=1, numBuffs do
		local filter;
		if ( checkCVar and GetCVarBool("showCastableBuffs") ) then
			filter = "RAID";
		end
		name, rank, icon, count, debuffType, duration, expirationTime = UnitBuff(unit, i, filter);

		local buffName = frameName..suffix..i;
		if ( icon ) then
			-- if we have an icon to show then proceed with setting up the aura

			-- set the icon
			local buffIcon = _G[buffName.."Icon"];
			buffIcon:SetTexture(icon);

			-- setup the cooldown
			local coolDown = _G[buffName.."Cooldown"];
			if ( coolDown ) then
				CooldownFrame_SetTimer(coolDown, expirationTime - duration, duration, 1);
			end

			-- show the aura
			_G[buffName]:Show();
		else
			-- no icon, hide the aura
			_G[buffName]:Hide();
		end
	end
end

function RefreshDebuffs(frame, unit, numDebuffs, suffix, checkCVar)
	local frameName = frame:GetName();

	frame.hasDispellable = nil;

	numDebuffs = numDebuffs or MAX_PARTY_DEBUFFS;
	suffix = suffix or "Debuff";

	local unitStatus, statusColor;
	local debuffTotal = 0;
	local name, rank, icon, count, debuffType, duration, expirationTime, caster;
	local isEnemy = UnitCanAttack("player", unit);	
	for i=1, numDebuffs do
		if ( unit == "party"..i ) then
			unitStatus = _G[frameName.."Status"];
		end

		local filter;
		if ( checkCVar and GetCVarBool("showDispelDebuffs") ) then
			filter = "RAID";
		end
		name, rank, icon, count, debuffType, duration, expirationTime, caster = UnitDebuff(unit, i, filter);

		local debuffName = frameName..suffix..i;
		if ( icon and ( SHOW_CASTABLE_DEBUFFS == "0" or not isEnemy or caster == "player" ) ) then
			-- if we have an icon to show then proceed with setting up the aura

			-- set the icon
			local debuffIcon = _G[debuffName.."Icon"];
			debuffIcon:SetTexture(icon);

			-- setup the border
			local debuffBorder = _G[debuffName.."Border"];
			local debuffColor = DebuffTypeColor[debuffType] or DebuffTypeColor["none"];
			debuffBorder:SetVertexColor(debuffColor.r, debuffColor.g, debuffColor.b);

			-- record interesting data for the aura button
			statusColor = debuffColor;
			frame.hasDispellable = 1;
			debuffTotal = debuffTotal + 1;

			-- setup the cooldown
			local coolDown = _G[debuffName.."Cooldown"];
			if ( coolDown ) then
				CooldownFrame_SetTimer(coolDown, expirationTime - duration, duration, 1);
			end

			-- show the aura
			_G[debuffName]:Show();
		else
			-- no icon, hide the aura
			_G[debuffName]:Hide();
		end
	end

	frame.debuffTotal = debuffTotal;
	-- Reset unitStatus overlay graphic timer
	if ( frame.numDebuffs and debuffTotal >= frame.numDebuffs ) then
		frame.debuffCountdown = 30;
	end
	if ( unitStatus and statusColor ) then
		unitStatus:SetVertexColor(statusColor.r, statusColor.g, statusColor.b);
	end
end

function GetQuestDifficultyColor(level)
	local levelDiff = level - UnitLevel("player");
	local color;
	if ( levelDiff >= 5 ) then
		return QuestDifficultyColors["impossible"];
	elseif ( levelDiff >= 3 ) then
		return QuestDifficultyColors["verydifficult"];
	elseif ( levelDiff >= -2 ) then
		return QuestDifficultyColors["difficult"];
	elseif ( -levelDiff <= GetQuestGreenRange() ) then
		return QuestDifficultyColors["standard"];
	else
		return QuestDifficultyColors["trivial"];
	end
end

function GetDungeonNameWithDifficulty(name, difficultyName)
	name = name or "";
	if ( difficultyName == "" ) then
		name = NORMAL_FONT_COLOR_CODE..name..FONT_COLOR_CODE_CLOSE;
	else
		name = NORMAL_FONT_COLOR_CODE..format(DUNGEON_NAME_WITH_DIFFICULTY, name, difficultyName)..FONT_COLOR_CODE_CLOSE;
	end
	return name;
end


-- Animated shine stuff --

function AnimatedShine_Start(shine, r, g, b)
	if ( not tContains(SHINES_TO_ANIMATE, shine) ) then
		shine.timer = 0;
		tinsert(SHINES_TO_ANIMATE, shine);
	end
	local shineName = shine:GetName();
	_G[shineName.."Shine1"]:Show();
	_G[shineName.."Shine2"]:Show();
	_G[shineName.."Shine3"]:Show();
	_G[shineName.."Shine4"]:Show();
	if ( r ) then
		_G[shineName.."Shine1"]:SetVertexColor(r, g, b);
		_G[shineName.."Shine2"]:SetVertexColor(r, g, b);
		_G[shineName.."Shine3"]:SetVertexColor(r, g, b);
		_G[shineName.."Shine4"]:SetVertexColor(r, g, b);
	end
	
end

function AnimatedShine_Stop(shine)
	tDeleteItem(SHINES_TO_ANIMATE, shine);
	local shineName = shine:GetName();
	_G[shineName.."Shine1"]:Hide();
	_G[shineName.."Shine2"]:Hide();
	_G[shineName.."Shine3"]:Hide();
	_G[shineName.."Shine4"]:Hide();
end

function AnimatedShine_OnUpdate(elapsed)
	local shine1, shine2, shine3, shine4;
	local speed = 2.5;
	local parent, distance;
	for index, value in pairs(SHINES_TO_ANIMATE) do
		shine1 = _G[value:GetName().."Shine1"];
		shine2 = _G[value:GetName().."Shine2"];
		shine3 = _G[value:GetName().."Shine3"];
		shine4 = _G[value:GetName().."Shine4"];
		value.timer = value.timer+elapsed;
		if ( value.timer > speed*4 ) then
			value.timer = 0;
		end
		parent = _G[value:GetName().."Shine"];
		distance = parent:GetWidth();
		if ( value.timer <= speed  ) then
			shine1:SetPoint("CENTER", parent, "TOPLEFT", value.timer/speed*distance, 0);
			shine2:SetPoint("CENTER", parent, "BOTTOMRIGHT", -value.timer/speed*distance, 0);
			shine3:SetPoint("CENTER", parent, "TOPRIGHT", 0, -value.timer/speed*distance);
			shine4:SetPoint("CENTER", parent, "BOTTOMLEFT", 0, value.timer/speed*distance);
		elseif ( value.timer <= speed*2 ) then
			shine1:SetPoint("CENTER", parent, "TOPRIGHT", 0, -(value.timer-speed)/speed*distance);
			shine2:SetPoint("CENTER", parent, "BOTTOMLEFT", 0, (value.timer-speed)/speed*distance);
			shine3:SetPoint("CENTER", parent, "BOTTOMRIGHT", -(value.timer-speed)/speed*distance, 0);
			shine4:SetPoint("CENTER", parent, "TOPLEFT", (value.timer-speed)/speed*distance, 0);
		elseif ( value.timer <= speed*3 ) then
			shine1:SetPoint("CENTER", parent, "BOTTOMRIGHT", -(value.timer-speed*2)/speed*distance, 0);
			shine2:SetPoint("CENTER", parent, "TOPLEFT", (value.timer-speed*2)/speed*distance, 0);
			shine3:SetPoint("CENTER", parent, "BOTTOMLEFT", 0, (value.timer-speed*2)/speed*distance);
			shine4:SetPoint("CENTER", parent, "TOPRIGHT", 0, -(value.timer-speed*2)/speed*distance);
		else
			shine1:SetPoint("CENTER", parent, "BOTTOMLEFT", 0, (value.timer-speed*3)/speed*distance);
			shine2:SetPoint("CENTER", parent, "TOPRIGHT", 0, -(value.timer-speed*3)/speed*distance);
			shine3:SetPoint("CENTER", parent, "TOPLEFT", (value.timer-speed*3)/speed*distance, 0);
			shine4:SetPoint("CENTER", parent, "BOTTOMRIGHT", -(value.timer-speed*3)/speed*distance, 0);
		end		
	end
end


-- Autocast shine stuff --

AUTOCAST_SHINE_R = .95;
AUTOCAST_SHINE_G = .95;
AUTOCAST_SHINE_B = .32;

AUTOCAST_SHINE_SPEEDS = { 2, 4, 6, 8 };
AUTOCAST_SHINE_TIMERS = { 0, 0, 0, 0 };

local AUTOCAST_SHINES = {};


function AutoCastShine_OnLoad(self)
	self.sparkles = {};
	
	local name = self:GetName();
	
	for i = 1, 16 do
		tinsert(self.sparkles, _G[name .. i]);
	end
end

function AutoCastShine_AutoCastStart(button, r, g, b)
	if ( AUTOCAST_SHINES[button] ) then
		return;
	end
	
	AUTOCAST_SHINES[button] = true;
	
	if ( not r ) then
		r, g, b = AUTOCAST_SHINE_R, AUTOCAST_SHINE_G, AUTOCAST_SHINE_B;
	end
	
	for _, sparkle in next, button.sparkles do
		sparkle:Show();
		sparkle:SetVertexColor(r, g, b);
	end
end

function AutoCastShine_AutoCastStop(button)
	AUTOCAST_SHINES[button] = nil;
	
	for _, sparkle in next, button.sparkles do
		sparkle:Hide();
	end
end

function AutoCastShine_OnUpdate(self, elapsed)	
	for i in next, AUTOCAST_SHINE_TIMERS do
		AUTOCAST_SHINE_TIMERS[i] = AUTOCAST_SHINE_TIMERS[i] + elapsed;
		if ( AUTOCAST_SHINE_TIMERS[i] > AUTOCAST_SHINE_SPEEDS[i]*4 ) then
			AUTOCAST_SHINE_TIMERS[i] = 0;
		end
	end
	
	for button in next, AUTOCAST_SHINES do
		self = button;
		local parent, distance = self, self:GetWidth();
		
		-- This is local to this function to save a lookup. If you need to use it elsewhere, might wanna make it global and use a local reference.
		local AUTOCAST_SHINE_SPACING = 6;	
			
		for i = 1, 4 do
			local timer = AUTOCAST_SHINE_TIMERS[i];
			local speed = AUTOCAST_SHINE_SPEEDS[i];
			
			if ( timer <= speed ) then
				local basePosition = timer/speed*distance;
				self.sparkles[0+i]:SetPoint("CENTER", parent, "TOPLEFT", basePosition, 0);
				self.sparkles[4+i]:SetPoint("CENTER", parent, "BOTTOMRIGHT", -basePosition, 0);
				self.sparkles[8+i]:SetPoint("CENTER", parent, "TOPRIGHT", 0, -basePosition);
				self.sparkles[12+i]:SetPoint("CENTER", parent, "BOTTOMLEFT", 0, basePosition);
			elseif ( timer <= speed*2 ) then
				local basePosition = (timer-speed)/speed*distance;
				self.sparkles[0+i]:SetPoint("CENTER", parent, "TOPRIGHT", 0, -basePosition);
				self.sparkles[4+i]:SetPoint("CENTER", parent, "BOTTOMLEFT", 0, basePosition);
				self.sparkles[8+i]:SetPoint("CENTER", parent, "BOTTOMRIGHT", -basePosition, 0);
				self.sparkles[12+i]:SetPoint("CENTER", parent, "TOPLEFT", basePosition, 0);	
			elseif ( timer <= speed*3 ) then
				local basePosition = (timer-speed*2)/speed*distance;
				self.sparkles[0+i]:SetPoint("CENTER", parent, "BOTTOMRIGHT", -basePosition, 0);
				self.sparkles[4+i]:SetPoint("CENTER", parent, "TOPLEFT", basePosition, 0);
				self.sparkles[8+i]:SetPoint("CENTER", parent, "BOTTOMLEFT", 0, basePosition);
				self.sparkles[12+i]:SetPoint("CENTER", parent, "TOPRIGHT", 0, -basePosition);	
			else
				local basePosition = (timer-speed*3)/speed*distance;
				self.sparkles[0+i]:SetPoint("CENTER", parent, "BOTTOMLEFT", 0, basePosition);
				self.sparkles[4+i]:SetPoint("CENTER", parent, "TOPRIGHT", 0, -basePosition);
				self.sparkles[8+i]:SetPoint("CENTER", parent, "TOPLEFT", basePosition, 0);
				self.sparkles[12+i]:SetPoint("CENTER", parent, "BOTTOMRIGHT", -basePosition, 0);
			end
		end	
	end
end

function ConsolePrint(...)
	ConsoleAddMessage(makeprintable(...))
end

function GetTexCoordsByGrid(xOffset, yOffset, textureWidth, textureHeight, gridWidth, gridHeight)
	local widthPerGrid = gridWidth/textureWidth;
	local heightPerGrid = gridHeight/textureHeight;
	return (xOffset-1)*widthPerGrid, (xOffset)*widthPerGrid, (yOffset-1)*heightPerGrid, (yOffset)*heightPerGrid;
end

function LFD_IsEmpowered()
	return not ( ((GetNumPartyMembers() > 0) or (GetNumRaidMembers() > 0)) and
		not (IsPartyLeader() or IsRaidLeader()) ) or HasLFGRestrictions();
end

function LFR_IsEmpowered()
	return not ( ((GetNumPartyMembers() > 0) or (GetNumRaidMembers() > 0)) and
		not (IsPartyLeader() or IsRaidLeader()) );
end

function GetLFGMode()
	local proposalExists, typeID, id, name, texture, role, hasResponded, totalEncounters, completedEncounters, numMembers = GetLFGProposal();
	local inParty, joined, queued, noPartialClear, achievements, lfgComment, slotCount = GetLFGInfoServer();
	local roleCheckInProgress, slots, members = GetLFGRoleUpdate();
	
	if ( proposalExists and not hasResponded ) then
		return "proposal", "unaccepted";
	elseif ( proposalExists ) then
		return "proposal", "accepted";
	elseif ( queued ) then
		return "queued", (LFD_IsEmpowered() and "empowered" or "unempowered");
	elseif ( roleCheckInProgress ) then
		return "rolecheck";
	elseif ( IsListedInLFR() ) then
		return "listed", (LFR_IsEmpowered() and "empowered" or "unempowered");
	elseif ( IsPartyLFG() and ((GetNumPartyMembers() > 0) or (GetNumRaidMembers() > 0)) ) then
		return "lfgparty";
	elseif ( IsPartyLFG() and IsInLFGDungeon() ) then
		return "abandonedInDungeon";
	end
end

--Like date(), but localizes AM/PM. In the future, could also localize other stuff.
function BetterDate(formatString, timeVal)
	if not formatString then return "" end
	local dateTable = date("*t", timeVal);
	local amString = (dateTable.hour >= 12) and TIMEMANAGER_PM or TIMEMANAGER_AM;
	
	--First, we'll replace %p with the appropriate AM or PM.
	formatString = gsub(formatString, "^%%p", amString)	--Replaces %p at the beginning of the string with the am/pm token
	formatString = gsub(formatString, "([^%%])%%p", "%1"..amString); -- Replaces %p anywhere else in the string, but doesn't replace %%p (since the first % escapes the second)
	
	return date(formatString, timeVal);
end

function GetScaledCursorPosition(frame)
	if not frame then frame = UIParent end
	local uiScale = frame:GetEffectiveScale();
	local x, y = GetCursorPosition();
	return x / uiScale, y / uiScale;
end

function GetUIScalar()
	return 1 + (1 - UIParent:GetEffectiveScale());
end

function GetScreenSize(scale)
	scale = scale or 1
	return GetScreenWidth() * scale, GetScreenHeight() * scale
end

function GetUIScale()
	return UIParent:GetEffectiveScale()
end

function GetDisplayedAllyFrames()
	local useCompact = C_CVar.GetBool("useCompactPartyFrames")
	if IsActiveBattlefieldArena() and not useCompact then
		return "party";
	elseif GroupUtil.IsInRaid() or useCompact and GroupUtil.IsInGroup() then
		return "raid";
	elseif GroupUtil.IsInGroup() then
		return "party";
	else
		return nil;
	end
end

function ToggleQuickKeybindMode()
	if not issecure() then return end
	if not IsQuickKeybinding() then
		ShowUIPanel(QuickKeybindFrame)
	end
end

function IsQuickKeybinding()
	if not issecurevariable(_G, "KEY_BINDING_MODE") then
		return false
	end
	
	return KEY_BINDING_MODE ~= nil
end

-- stony tark redirect
local gameModeNPCs = C_Gossip:MakeGroup(10157256, 10157257, 10157362, 10157361, 10157360, 10157359, 10157358, 10157357, 10157356, 10157263, 10157256)
C_Gossip:RedirectNPCs(gameModeNPCs, OpenChallengesUI, CloseChallengesUI)

function DumpNow(...)
	UIParentLoadAddOn("Blizzard_DebugTools")
	if select("#", ...) > 1 then
		for i = 1, select("#", ...) do
			print("==["..i.."]==")
			DevTools_Dump(select(i, ...))
		end
	else
		DevTools_Dump(...)
	end
end

-------------------------------------------------------------------------------
--                                  Range                                    --
-------------------------------------------------------------------------------
--[[local RangeSpellBlank = {
}

for i = 1, 60 do-- fill of RangeSpellBlank by spell names
	RangeSpellBlank[i] = "Range "..i
end 

IsActionInRange_Orig = IsActionInRange

function IsActionInRange_Ascension(...)
	local action = ...
	local valid = nil;

	-- custom range indicator based on blank spells --
	local actiontype, _, _, spellID = GetActionInfo(action)

	if (actiontype == "spell") then -- will need to rewrite it to work with all action types
		if TaggedSpells and SpellCost_ActionButtonAscension and (TaggedSpells[spellID] and SpellCost_ActionButtonAscension[spellID] and SpellCost_ActionButtonAscension[spellID][3]) then
			local Range = math.ceil(SpellCost_ActionButtonAscension[spellID][3])

			if (RangeSpellBlank[Range]) then
				valid = IsSpellInRange(RangeSpellBlank[Range])
			end
		end
	end

	if not(valid) then
		valid = IsActionInRange_Orig(action)
	end

	return valid
end

IsActionInRange = IsActionInRange_Ascension]]--
local MsgReceiver = CreateFrame("Frame")
local known_prefixes = {}
local msg_queue = {} -- addon can load AFTER message is recieved on login. Run handle for each msg on create
local queue_timer = 30 -- default: 120, wait and clear 

local function ONADDONMSG(self, event, prefix, msg, Type, sender)
    if event == "CHAT_MSG_ADDON" and sender == UnitName("player") then
    	if known_prefixes[prefix] then
            known_prefixes[prefix]:Handle(msg)
        elseif (msg_queue) then
        	if not(next(msg_queue)) then -- run cleaner
        		MsgReceiver.AG:Play()
        	end

        	if not(msg_queue[prefix]) then
        		msg_queue[prefix] = {}
        	end

        	table.insert(msg_queue[prefix], msg)
        end
    end
end

local function CLEARQUEUE()
	for prefix, data in pairs(msg_queue) do
		--print("Clear queue for msg "..prefix) -- DEBUG
		msg_queue[prefix] = nil
	end
	msg_queue = nil
end

MsgReceiver:RegisterEvent("CHAT_MSG_ADDON")
MsgReceiver:SetScript("OnEvent", ONADDONMSG)

MsgReceiver.AG = MsgReceiver:CreateAnimationGroup()
MsgReceiver.AG.Timer = MsgReceiver.AG:CreateAnimation()
MsgReceiver.AG.Timer:SetDuration(queue_timer)
MsgReceiver.AG.Timer:SetScript("OnFinished", CLEARQUEUE)

function MSGR_Create(prefix)
	known_prefixes[prefix] = {}
	local self = known_prefixes[prefix]
	self.prefix = prefix

	function self:Handle(msg) -- set up each use
	end

	function self:Init()
		if (msg_queue[self.prefix]) then
			for _, msg in pairs(msg_queue[self.prefix]) do
				self:Handle(msg)
			end
			msg_queue[self.prefix] = nil
			--print("Run for queue "..self.prefix) -- DEBUG
		end
	end

	return self
end

function MSGR_Request(prefix, msg)
	SendAddonMessage(prefix, msg, "WHISPER", UnitName("player"))
end

-- Block Disabling Ascension Adddons
hooksecurefunc(_G, "DisableAddOn", function(addon)
	if type(addon) == "number" then
		-- we got an index, get the name
		addon = GetAddOnInfo(addon)
	end

	if not ASCENSION_PROTECTED_ADDONS then
		ASCENSION_PROTECTED_ADDONS = table.invert({GetSecureAddons()})
	end

	if addon and ASCENSION_PROTECTED_ADDONS[addon] then
		EnableAddOn(addon)
	end
end)

hooksecurefunc(_G, "DisableAllAddOns", function()
	if not ASCENSION_PROTECTED_ADDONS then
		ASCENSION_PROTECTED_ADDONS = table.invert({GetSecureAddons()})
	end

	for addon in pairs(ASCENSION_PROTECTED_ADDONS) do
		EnableAddOn(addon)
	end
end)

--
-- Zone ID Corrections
--
NEW_ZONE_LOOKUP = {}
NEW_TO_OLD_ZONE_MAP = {}
OLD_TO_NEW_ZONE_MAP = {}
ZONE_BY_NAME = {}

PLAYER_CURRENT_ZONE = 0

local continents = { GetMapContinents() }


for continentId in pairs(continents) do
    NEW_ZONE_LOOKUP[continentId] = {}
    ZONE_BY_NAME[continentId] = {}

    OLD_TO_NEW_ZONE_MAP[continentId] = {}
    NEW_TO_OLD_ZONE_MAP[continentId] = {}

    local zones = { GetMapZones(continentId) }
    local offset = 0

    for id, zoneName in ipairs(zones) do
        -- create only 1 entry per zone by name
        if not ZONE_BY_NAME[continentId][zoneName] then
            -- store the zone by name with the current id + offset
            ZONE_BY_NAME[continentId][zoneName] = id + offset

            -- pass a new zone id to get the >first< old id
            NEW_TO_OLD_ZONE_MAP[continentId][id + offset] = id
        else
            -- we already have this zone saved, offset the id by -1 (skip this id)
            offset = offset - 1
        end
        -- pass an old id to get the new id
        OLD_TO_NEW_ZONE_MAP[continentId][id] = id + offset
    end

    -- go through each zone by name and store it as it's new id to zone name (should be sequential 1-# if not we failed somehow)
    for zone, id in pairs(ZONE_BY_NAME[continentId]) do
        NEW_ZONE_LOOKUP[continentId][id] = zone
    end
end

--
-- helper functions for my sanity
--

local function ConvertZoneNewToOld(c, id)
    return c and id and NEW_TO_OLD_ZONE_MAP[c] and NEW_TO_OLD_ZONE_MAP[c][id]
end

local function ConvertZoneOldToNew(c, id)
    return c and id and OLD_TO_NEW_ZONE_MAP[c] and OLD_TO_NEW_ZONE_MAP[c][id]
end

--
-- Map Zone Overwrites
--

Original_GetMapZones = GetMapZones
Original_GetCurrentMapZone = GetCurrentMapZone
Original_SetMapZoom = SetMapZoom

function GetMapZones(continentIndex)
    if NEW_ZONE_LOOKUP[continentIndex] then
        return unpack(NEW_ZONE_LOOKUP[continentIndex])
    end
    return Original_GetMapZones(continentIndex)
end

function SetMapZoom(c, z)
    if z and z > 0 then
        Original_SetMapZoom(c, ConvertZoneNewToOld(c, z))
    else
        Original_SetMapZoom(c, z)
    end
end

function GetCurrentMapZone()
    local continentId = GetCurrentMapContinent()
    local originalZoneId = Original_GetCurrentMapZone()

    local zoneId = ConvertZoneOldToNew(continentId, originalZoneId)
    return zoneId or originalZoneId
end

hooksecurefunc("SetMapToCurrentZone", function ()
    PLAYER_CURRENT_ZONE = Original_GetCurrentMapZone()
end)

--
-- Battleground Overwrites
--
Original_GetBattlefieldStatus = GetBattlefieldStatus

function GetBattlefieldStatus(index)
	local status, mapName, instanceID, levelRangeMin, levelRangeMax, teamSize, registeredMatch = Original_GetBattlefieldStatus(index)
	if teamSize == 5 then
        if IsDefaultClass() then
            teamSize = 3
        else
            teamSize = 1
        end
	end
	if mapName then
		mapName = mapName:gsub("\\", "")
	end
	return status, mapName, instanceID, levelRangeMin, levelRangeMax, teamSize, registeredMatch
end

--
-- Combat Log Fix (CLFix addon)
--

Timer.NewTicker(20, CombatLogClearEntries)

Timer.WaitFor(1, function() return LibStub and LibStub:GetLibrary("LibSharedMedia-3.0", true) ~= nil end, function(success)
	if not success then
		return
	end

	LibStub:GetLibrary("LibSharedMedia-3.0").MediaTable.font["PT Sans Narrow"] = "Fonts\\PTSansNarrow.ttf"
end, 30)
