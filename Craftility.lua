local addonName, CraftilityNS = ...
local _G = _G
local ElvUI = nil -- Import: ElvUI if it is loaded when frames are initialized
local E = nil -- Import: ElvUI Engine module when frames are initialized
local S = nil -- Import: ElvUI Skins module when frames are initialized
local Craftility = LibStub("AceAddon-3.0"):NewAddon("Craftility", "AceConsole-3.0", "AceEvent-3.0", "AceTimer-3.0")
CraftilityNS.Craftility = Craftility
_G.CraftilityNS = CraftilityNS


local OrdersPage = _G.ProfessionsFrame.OrdersPage

Craftility.OrdersSeen = {[Enum.CraftingOrderType.Public] = {}, [Enum.CraftingOrderType.Guild] = {}, [Enum.CraftingOrderType.Personal] = {}}
Craftility.selectedSkillLineAbility = nil
Craftility.searchFavorites = false
Craftility.initialNonPublicSearch = false

local soundBytes = {
    [SOUNDKIT.AUCTION_WINDOW_OPEN] = "Auction Window Open",
	[SOUNDKIT.AUCTION_WINDOW_CLOSE] = "Auction Window Close",
	[SOUNDKIT.MONEY_FRAME_OPEN] = "Money Frame Open",
	[SOUNDKIT.MONEY_FRAME_CLOSE] = "Money Frame Close",
	[SOUNDKIT.RAID_WARNING] = "Raid Warning",
	[SOUNDKIT.READY_CHECK] = "Ready Check"
}

local options = {
    name = "Craftility",
    handler = Craftility,
    type = 'group',
    args = {
		SearchInterval = {
			name = "Search Interval",
			desc = "The amount of wait time between searches in seconds.",
			type = "range",
			min = 1,
			max = 15,
			step = 1,
			order = 1,
			set = function(_, val) Craftility.db.profile.SearchInterval = val end,
			get = function() return Craftility.db.profile.SearchInterval end,
		},
		SoundByteId = {
			name = "Sound Byte",
			desc = "The sound that plays when a new public order is found.",
			type = "select",
			values = soundBytes,
			order = 2,
            set = function(_, val) Craftility.db.profile.SoundByteId = val end,
			get = function() return Craftility.db.profile.SoundByteId end,
		},
        TestSound = {
            name = "Test Sound Byte",
            desc = "Plays the select sound byte.",
            type = "execute",
            order = 3,
            func = function() PlaySound(Craftility.db.profile.SoundByteId, "SFX") end,
        }
    }
}

Craftility.DefaultConfig = {
    profile = {
        SearchInterval = 2,
		SoundByteId = SOUNDKIT.AUCTION_WINDOW_CLOSE
    }
}

function Craftility:OnInitialize()
    self.db = LibStub("AceDB-3.0"):New("CraftilityDB", self.DefaultConfig, true)
    LibStub("AceConfig-3.0"):RegisterOptionsTable("Craftility", options, {"Craftility", "Cfly"})
    self.optionsFrame = LibStub("AceConfigDialog-3.0"):AddToBlizOptions("Craftility", "Craftility")
    local profiles = LibStub("AceDBOptions-3.0"):GetOptionsTable(self.db)
    LibStub("AceConfig-3.0"):RegisterOptionsTable("Craftility_Profiles", profiles)
    LibStub("AceConfigDialog-3.0"):AddToBlizOptions("Craftility_Profiles", "Profiles", "Craftility")
end

function Craftility:OnEnable()
    self:RegisterEvent("TRADE_SKILL_SHOW")
end

function Craftility:OnDisable()
    
end

function Craftility:TRADE_SKILL_SHOW()
    if not self.AutoSearchCheckBox then
        self.AutoSearchCheckBox = CreateFrame("CheckButton", "Craftility_AutoSearchCheckBox", OrdersPage.BrowseFrame, "UICheckButtonTemplate")
        self.AutoSearchCheckBox:SetSize(26, 26)
        self.AutoSearchCheckBox:SetPoint("LEFT", OrdersPage.BrowseFrame.SearchButton, "TOPLEFT", 0, 8)
        self.AutoSearchCheckBox.text:SetText("Auto Search Orders")
        self.AutoSearchCheckBox:SetScript("OnClick", function()
            local checked = Craftility.AutoSearchCheckBox:GetChecked()
            if checked then
                if Craftility.Timer then
                    Craftility:CancelAllTimers()
                    Craftility.Timer = nil
                else
                    Craftility.Timer = Craftility:ScheduleRepeatingTimer("SearchOrders", Craftility.db.profile.SearchInterval)
                end
            elseif not checked then
                if Craftility.Timer then
                    Craftility:CancelAllTimers()
                    Craftility.Timer = nil
                end
            end
        end)

        _G.ProfessionsFrame:HookScript("OnHide", function()
            Craftility.AutoSearchCheckBox:SetChecked(false)
            if Craftility.Timer then
                Craftility:CancelAllTimers()
                Craftility.Timer = nil
            end
        end)

        if ElvUI == nil then
            ElvUI = _G.ElvUI
        end

        if ElvUI then
            E = ElvUI[1]
            S = E:GetModule("Skins")
            S:HandleCheckBox(self.AutoSearchCheckBox)
            self.AutoSearchCheckBox:SetSize(24, 24)
			self.AutoSearchCheckBox:SetPoint("LEFT", OrdersPage.BrowseFrame.FavoritesSearchButton, "TOPLEFT", -3, 12)
        end
        self:UnregisterEvent("TRADE_SKILL_SHOW")
    end
end

function Craftility:SearchOrders()
    OrdersPage:RequestOrders(self.selectedSkillLineAbility, self.searchFavorites, self.initialNonPublicSearch)
    self:ParseOrders()
end

function Craftility:ParseOrders()
    for i=1, select("#", OrdersPage.BrowseFrame.OrderList.ScrollBox.ScrollTarget:GetChildren()) do
        local order = select(i, OrdersPage.BrowseFrame.OrderList.ScrollBox.ScrollTarget:GetChildren())
        local orderType = order.option.orderType
        if not tContains(self.OrdersSeen[orderType], order.option.orderID) then
            tinsert(self.OrdersSeen[orderType], order.option.orderID)
            FlashClientIcon()
            PlaySound(self.db.profile.SoundByteId, "SFX")
            if orderType == Enum.CraftingOrderType.Public then
                OrdersPage:RequestOrders(self.selectedSkillLineAbility, self.searchFavorites, self.initialNonPublicSearch)
            elseif orderType == Enum.CraftingOrderType.Guild then
                OrdersPage:RequestOrders(self.selectedSkillLineAbility, self.searchFavorites, self.initialNonPublicSearch)
            elseif orderType == Enum.CraftingOrderType.Personal then
                OrdersPage:RequestOrders(self.selectedSkillLineAbility, self.searchFavorites, self.initialNonPublicSearch)
            end
        end
    end
end