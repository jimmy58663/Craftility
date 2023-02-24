local addonName, CraftilityNS = ...
local _G = _G
local ElvUI = nil -- Import: ElvUI if it is loaded when frames are initialized
local E = nil -- Import: ElvUI Engine module when frames are initialized
local S = nil -- Import: ElvUI Skins module when frames are initialized
CraftilityNS.AceSerializer = LibStub:GetLibrary("AceSerializer-3.0")
CraftilityNS.libC = LibStub:GetLibrary("LibCompress")
CraftilityNS.EncodeTable = CraftilityNS.libC:GetAddonEncodeTable()
local Craftility = LibStub("AceAddon-3.0"):NewAddon("Craftility", "AceConsole-3.0", "AceEvent-3.0", "AceTimer-3.0")
CraftilityNS.Craftility = Craftility
_G.CraftilityNS = CraftilityNS

local OrdersPage = _G.ProfessionsFrame.OrdersPage

Craftility.OrdersSeen = {[Enum.CraftingOrderType.Public] = {}, [Enum.CraftingOrderType.Guild] = {}, [Enum.CraftingOrderType.Personal] = {}}
Craftility.selectedSkillLineAbility = nil
Craftility.searchFavorites = false
Craftility.initialNonPublicSearch = false

local ProfessionSkillLineLookup = {
    [129] = 0, --First Aid
    [164] = 1, --Blacksmithing
    [165] = 2, --Leatherworking
    [171] = 3, --Alchemy
    [182] = 4, --Herbalism
    [184] = 5, --Cooking
    [186] = 6, --Mining
    [197] = 7, --Tailoring
    [202] = 8, --Engineering
    [333] = 9, --Enchanting
    [356] = 10, --Fishing
    [393] = 11, --Skinning
    [755] = 12, --Jewelcrafting
    [773] = 13, --Inscription
    [794] = 14 --Archaeology
}
local CraftingProfessions = {
    1, --Blacksmithing
    2, --Leatherworking
    3, --Alchemy
    7, --Tailoring
    8, --Engineering
    9, --Enchanting
    12, --Jewelcrafting
    13 --Inscription
}

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
    self:RegisterEvent("CRAFTINGORDERS_SHOW_CUSTOMER")
    self:RegisterEvent("CHAT_MSG_SYSTEM")
end

function Craftility:OnDisable()
    
end

function Craftility:TRADE_SKILL_SHOW()
    self:INITIALIZE()
    self:UnregisterEvent("TRADE_SKILL_SHOW")
end

function Craftility:CRAFTINGORDERS_SHOW_CUSTOMER()
    self:INITIALIZE()
    self:UnregisterEvent("CRAFTINGORDERS_SHOW_CUSTOMER")
end

function Craftility:CHAT_MSG_SYSTEM(eventName, message, ...)
    if message == "You have received a new Personal Crafting Order." then
        FlashClientIcon()
        PlaySound(Craftility.db.profile.SoundByteId, "SFX")
        RaidNotice_AddMessage(RaidWarningFrame, "!!! NEW PERSONAL CRAFTING ORDER !!!", ChatTypeInfo["RAID_WARNING"])
    end
end

function Craftility:INITIALIZE()
    if not self.AutoSearchCheckBox then
        CraftilityNS:SetProfessionInfo()
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
                end
                Craftility.Timer = Craftility:ScheduleRepeatingTimer("SearchOrders", Craftility.db.profile.SearchInterval)
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
    end
    Craftility:SendMessage("CRAFTILITY_INITIALIZE")
end

function Craftility:SearchOrders()
    OrdersPage:RequestOrders(self.selectedSkillLineAbility, self.searchFavorites, self.initialNonPublicSearch)
    if OrdersPage:GetBrowseType() == 2 then --Buckets are returned
        Craftility:RequestOrders(self.selectedSkillLineAbility, self.searchFavorites, self.initialNonPublicSearch)
    elseif OrdersPage:GetBrowseType() == 1 then --Orders are returned
        local orders = C_CraftingOrders.GetCrafterOrders()
        self:ParseOrders(orders)
    end
end

function Craftility:ParseOrders(orders)
    for i, order in pairs(orders) do
        local orderType = order.orderType
        local orderID = order.orderID
        if not tContains(Craftility.OrdersSeen[orderType], orderID) then
            tinsert(Craftility.OrdersSeen[orderType], orderID)
            FlashClientIcon()
            PlaySound(Craftility.db.profile.SoundByteId, "SFX")
        end
    end
end

function Craftility:RequestOrders(selectedSkillLineAbility, searchFavorites, initialNonPublicSearch)
    local defaultBucketSecondarySort = {
        sortType = Enum.CraftingOrderSortType.MaxTip,
        reversed = true,
    }

    local defaultFlatSecondarySort = {
        sortType = Enum.CraftingOrderSortType.Tip,
        reversed = true,
    }

    local isFlatSearch = selectedSkillLineAbility ~= nil
    
    local request = {
        orderType = Enum.CraftingOrderType.Public,
        selectedSkillLineAbility =  selectedSkillLineAbility,
        searchFavorites = searchFavorites,
        initialNonPublicSearch = initialNonPublicSearch,
        primarySort = Professions.TranslateSearchSort(OrdersPage.primarySort),
        secondarySort = Professions.TranslateSearchSort(OrdersPage.secondarySort) or (isFlatSearch and defaultFlatSecondarySort or defaultBucketSecondarySort),
        forCrafter = true,
        offset = 0,
        callback =  C_FunctionContainers.CreateCallback(function(...) Craftility:OrderRequestCallback(...) end),
        profession = _G.ProfessionsFrame.professionInfo.profession,
    }
    C_CraftingOrders.RequestCrafterOrders(request)
end

function Craftility:OrderRequestCallback(orderResult, orderType, displayBuckets, expectMoreRows, offset, isSorted)
    if displayBuckets then
        local buckets = C_CraftingOrders.GetCrafterBuckets()
        Craftility:ParseBuckets(buckets)
    else
        local orders = C_CraftingOrders.GetCrafterOrders()
        Craftility:ParseOrders(orders)
    end
end

function Craftility:ParseBuckets(buckets)
    for i, bucket in pairs(buckets) do
        local selectedSkillLineAbility = bucket.skillLineAbilityID
        local searchFavorites = false
        local initialNonPublicSearch = false
        if bucket.orderType == Enum.CraftingOrderType.Public then
            initialNonPublicSearch = false
        elseif bucket.orderType == Enum.CraftingOrderType.Guild then
            initialNonPublicSearch = true
        end
        Craftility:RequestOrders(selectedSkillLineAbility, searchFavorites, initialNonPublicSearch)
    end

    --reset search to defaults
    OrdersPage.BrowseFrame.RecipeList:ClearSelectedRecipe()
    OrdersPage.selectedRecipe = nil
end


--CraftilityNS
function CraftilityNS:dumpTable(table, maxDepth, currentDepth)
    if currentDepth == nil then
        currentDepth = 0
    end

    if maxDepth == nil then
        maxDepth = 20
    end

    if (currentDepth > maxDepth) then
        return
    end
    
    for k,v in pairs(table) do
        if (type(k) == "table") then
			CraftilityNS:dumpTable(k, maxDepth, currentDepth+1)
        elseif (type(v) == "table") then
            print(string.rep(" ", currentDepth)..k..":")
            CraftilityNS:dumpTable(v, maxDepth, currentDepth+1)
        else
            if (type(v) == "function") then
				print(string.rep(" ", currentDepth)..k..": <function>")
			elseif (type(v) == "userdata") then
				print(string.rep(" ", currentDepth)..k..": <userdata>")
			else
				print(string.rep(" ", currentDepth)..k..": ",v)	
			end
        end
    end
end

function CraftilityNS:SetProfessionInfo()
    local function GetProfInfo(profIndex)
        if profIndex then
            local name, icon, skillLevel, maxSkillLevel, numAbilities, spelloffset, skillLine, skillModifier, specializationIndex, specializationOffset, professionName = GetProfessionInfo(profIndex)
            local profInfo = {
                skillLevel = skillLevel,
                skillModifier = skillModifier,
                parentProfessionName = name,
                parentProfessionID = skillLine,
                profession = ProfessionSkillLineLookup[skillLine],
                professionName = professionName,
                maxSkillLevel = maxSkillLevel,
                expansionName = professionName:gsub(' '..name, '')
            }
            return profInfo
        end
    end 

    CraftilityNS.professionInfo = {
        prof1 = nil,
        prof2 = nil
    }
    local prof1, prof2= GetProfessions()
    
    CraftilityNS.professionInfo.prof1 = GetProfInfo(prof1)
    CraftilityNS.professionInfo.prof2 = GetProfInfo(prof2)
end

function CraftilityNS:IsCraftingProfession(professionInfo)
    if tContains(CraftingProfessions, professionInfo.profession) then
        return true
    else
        return false
    end
end

function CraftilityNS:SerializeData(data)
    local serializedData = self.AceSerializer:Serialize(data)
    local compressedData = self.libC:Compress(serializedData)
    local encodedData = self.EncodeTable:Encode(compressedData)
    return encodedData
end

function CraftilityNS:DeserializeData(encodedData)
    local compressedData = self.EncodeTable:Decode(encodedData)
    local decompressSuccess, message = self.libC:Decompress(compressedData)
    if not decompressSuccess then
        error("Craftility: Error decompressing: " .. message)
    end

    local deserialzeSuccess, data = self.AceSerializer:Deserialize(decompressSuccess)
    if not deserialzeSuccess then
        error("Craftility: Error deserializing: " .. data)
    end
    return data
end