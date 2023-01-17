local addonName, CraftilityNS = ...
local _G = _G
local ElvUI = nil
Craftility = LibStub("AceAddon-3.0"):NewAddon("Craftility", "AceConsole-3.0", "AceEvent-3.0", "AceTimer-3.0")
CraftilityNS.Craftility = Craftility
_G.CraftilityNS = CraftilityNS


local OrdersPage = _G.ProfessionsFrame.OrdersPage
local GetOrderClaimInfo = _G.C_CraftingOrders.GetOrderClaimInfo
local RaidNotice_AddMessage = _G.RaidNotice_AddMessage

Craftility.Profession = nil
Craftility.OrdersSeen = {[Enum.CraftingOrderType.Public] = {}, [Enum.CraftingOrderType.Guild] = {}, [Enum.CraftingOrderType.Personal] = {}}
Craftility.OrderList = {}
Craftility.IsButtonInitialized = false
Craftility.selectedSkillLineAbility = nil
Craftility.searchFavorites = false
Craftility.initialNonPublicSearch = false

local options = {
    name = "Craftility",
    handler = Craftility,
    type = 'group',
    args = {
        SearchInterval = {
			name = "Search Interval",
			desc = "The amount of wait time between searches in seconds.",
			type = "input",
			width = "normal",
			order = 1,
			pattern = "%d",
			usage = "Enter the amount of seconds.",
			set = function(_, val) Craftility.db.profile.SearchInterval = val end,
			get = function(_) return tostring(Craftility.db.profile.SearchInterval) end
		},
        Tip = {
			name = "Smallest acceptable tip",
			desc = "Orders with a smaller tip will be ignored.",
			type = "input",
			width = "normal",
			order = 2,
			pattern = "%d",
			usage = "Enter the amount of gold.",
			set = function(_, val) Craftility.db.profile.MinimumTipInCopper = val * 10000 end,
			get = function(_) return tostring(Craftility.db.profile.MinimumTipInCopper / 10000) end
		},
        IgnoredItems = {
			name = "Ignored items",
			desc = "Comma-separated list of ItemIDs whose orders will be ignored.",
			type = "input",
			width = "double",
			order = 3,
			set = function(_, val)
				local input = {strsplit(",", val)}
				for k, v in pairs(input) do
					input[k] = tonumber(v)
				 end
				Craftility.db.profile.IgnoredItemIDs = input
			end,
			get = function(_) return table.concat(Craftility.db.profile.IgnoredItemIDs, ",") end
		}--[[,
        --Unable to get scanning of multiple pages to function without the UI constantly updating between the tabs. 
        --Maybe create a new frame to update with orders? Likely would need backend C_RequestCrafterOrders(request) and C_GetCrafterOrders() to function.
        --Maybe utilize backend functions just to trigger notifications and not update the UI
        ScanGuildOrders = {
			name = "Scan guild orders",
			desc = "Trigger notifications for guild craft orders.",
			type = "toggle",
			width = "full",
			order = 4,
			set = function(_, val) Craftility.db.profile.ScanGuildOrders = val end,
			get = function(_) return Craftility.db.profile.ScanGuildOrders end
		},
        ScanPersonalOrders = {
            name = "Scan personal orders",
			desc = "Trigger notifications for personal craft orders.",
			type = "toggle",
			width = "full",
			order = 5,
			set = function(_, val) Craftility.db.profile.ScanPersonalOrders = val end,
			get = function(_) return Craftility.db.profile.ScanPersonalOrders end
        }]]
    }
}

Craftility.DefaultConfig = {
    profile = {
        SearchInterval = 2,
        MinimumTipInCopper = 0,
        IgnoredItemIDs = {}--[[,
        ScanGuildOrders = true,
        ScanPersonalOrders = true]]
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
    self:RegisterEvent("ADDON_LOADED")
    self:RegisterEvent("CHAT_MSG_SYSTEM")
    self:RegisterEvent("TRADE_SKILL_SHOW")
end

function Craftility:OnDisable()
    
end

function Craftility:ADDON_LOADED(event, addOnName)

end

function Craftility:CHAT_MSG_SYSTEM(message, ...)
    if message == _G.ERR_CRAFTING_ORDER_RECEIVED then
        _G:FlashClientIcon()
        PlaySoundFile("Interface\\AddOns\\Craftility\\Media\\TadaFanfare.ogg")
        RaidNotice_AddMessage(_G.RaidWarningFrame, strupper(_G.PROFESSIONS_CRAFTING_FORM_ORDER_RECIPIENT_PRIVATE), _G.ChatTypeInfo["RAID_WARNING"])
    end
end

function Craftility:TRADE_SKILL_SHOW()
    self.Profession = _G.ProfessionsFrame.professionInfo.profession

    if ElvUI == nil then
        ElvUI = _G.ElvUI
    end

    if not self.IsButtonInitialized then
        local refreshButton = CreateFrame("Button", "Craftility_RefreshButton", OrdersPage.BrowseFrame, "RefreshButtonTemplate")
        if ElvUI then
            ElvUI[1]:GetModule("Skins"):HandleButton(refreshButton)
            refreshButton:Size(22)
        end
        refreshButton:SetPoint("LEFT", OrdersPage.BrowseFrame.SearchButton, "RIGHT")
        refreshButton:SetScript("OnClick", Craftility.SearchToggle)
        self.IsButtonInitialized = true

        _G.ProfessionsFrame:HookScript("OnHide", function() Craftility:SearchToggle("cancel") end)
    end
end

function Craftility:SearchToggle(button)
    if not Craftility.Timer and button ~= "cancel" then
        Craftility.Timer = Craftility:ScheduleRepeatingTimer("SearchOrders", Craftility.db.profile.SearchInterval)
    elseif Craftility.Timer then
        Craftility:CancelAllTimers()
        Craftility.Timer = nil
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
            tinsert(self.OrderList, order.option)
            if order.option.tipAmount >= self.db.profile.MinimumTipInCopper and not tContains(Craftility.db.profile.IgnoredItemIDs, order.option.itemID) then
                FlashClientIcon()
                PlaySoundFile("Interface\\AddOns\\Craftility\\Media\\TadaFanfare.ogg")
                if orderType == Enum.CraftingOrderType.Public then
                    RaidNotice_AddMessage(_G.RaidWarningFrame, strupper(_G.PROFESSIONS_CRAFTING_FORM_ORDER_RECIPIENT_PUBLIC), _G.ChatTypeInfo["RAID_WARNING"])
                    OrdersPage:RequestOrders(self.selectedSkillLineAbility, self.searchFavorites, self.initialNonPublicSearch)
                elseif orderType == Enum.CraftingOrderType.Guild then
                    RaidNotice_AddMessage(_G.RaidWarningFrame, strupper(_G.PROFESSIONS_CRAFTING_FORM_ORDER_RECIPIENT_GUILD), _G.ChatTypeInfo["RAID_WARNING"])
                    OrdersPage:RequestOrders(self.selectedSkillLineAbility, self.searchFavorites, self.initialNonPublicSearch)
                elseif orderType == Enum.CraftingOrderType.Personal then
                    RaidNotice_AddMessage(_G.RaidWarningFrame, strupper(_G.PROFESSIONS_CRAFTING_FORM_ORDER_RECIPIENT_PRIVATE), _G.ChatTypeInfo["RAID_WARNING"])
                    OrdersPage:RequestOrders(self.selectedSkillLineAbility, self.searchFavorites, self.initialNonPublicSearch)
                end
            end
        end
    end
end