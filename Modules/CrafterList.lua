local addon, CraftilityNS = ...
local _G = _G
local ElvUI = nil -- Import: ElvUI if it is loaded when frames are initialized
local E = nil -- Import: ElvUI Engine module when frames are initialized
local S = nil -- Import: ElvUI Skins module when frames are initialized

local CrafterList = CraftilityNS.Craftility:NewModule("CrafterList", "AceConsole-3.0", "AceEvent-3.0", "AceHook-3.0", "AceComm-3.0")
CraftilityNS.CrafterList = CrafterList
local CraftingPage = _G.ProfessionsFrame.CraftingPage

function CrafterList:OnEnable()
    self:RegisterEvent("CRAFTINGORDERS_SHOW_CUSTOMER")
    self:RegisterEvent("CRAFTINGORDERS_HIDE_CUSTOMER")
    self:RegisterEvent("TRADE_SKILL_SHOW")
end

function CrafterList:CRAFTINGORDERS_SHOW_CUSTOMER()
    if not self.Crafters then
        self:InitCrafters()
    end
end

function CrafterList:CRAFTINGORDERS_HIDE_CUSTOMER()
    self.Crafters.Frame:Hide()
end

function CrafterList:TRADE_SKILL_SHOW()
    if not self.Services then
        self:InitServices()
    end
    self.Services.Frame.Background:SetAtlas(Professions.GetProfessionBackgroundAtlas(Professions:GetProfessionInfo()), TextureKitConstants.IgnoreAtlasSize)
end

function CrafterList:InitCrafters()
    self.Crafters = {}
    self.Crafters.Frame = CreateFrame("Frame", "Craftility_ServicesFrame", CraftingPage)
    self.Crafters.Frame:Hide()
end

function CrafterList:InitServices()
    if CraftilityNS:IsCraftingProfession(CraftilityNS.professionInfo.prof1) or CraftilityNS:IsCrafterProfession(CraftilityNS.professionInfo.prof2) then
        self.Services = {}
        self.Services.ServiceButton = CreateFrame("Button", "Craftility_ServiceButton", CraftingPage, "UIPanelButtonTemplate")
        self.Services.ServiceButton:SetSize(120, 22)
        self.Services.ServiceButton:SetPoint("RIGHT", CraftingPage.CreateAllButton, "LEFT", -30, 0)
        self.Services.ServiceButton.Text:SetText("List Services")
        self.Services.ServiceButton:SetScript("OnClick", CrafterList.ListServices)

        self.Services.Frame = CreateFrame("Frame", "Craftility_ServicesFrame", CraftingPage)
        self.Services.Frame:SetSize(799, 553)
        self.Services.Frame:SetPoint("TOPLEFT", CraftingPage.RecipeList, "TOPRIGHT", 2, 0)
        self.Services.Frame:Hide()
        self.Services.Frame.Background = self.Services.Frame:CreateTexture("Background", "BACKGROUND")
        self.Services.Frame.Background:SetPoint("TOPLEFT", self.Services.Frame, "TOPLEFT")
        self.Services.Frame.Background:SetSize(799, 553)
    end
end

function CrafterList:ListServices()
    if CraftingPage.SchematicForm:IsShown() then
        CrafterList.SchematicStatus = 1
        CraftingPage.SchematicForm:Hide()
    elseif CraftilityNS.ProfessionsSim.SchematicForm:IsShown() then
        CrafterList.SchematicStatus = 2
        CraftilityNS.ProfessionsSim.SchematicForm:Hide()
    end
    CrafterList.Services.Frame:Show()
    CrafterList.Services.ServiceButton.Text:SetText("Hide Services")
    CrafterList.Services.ServiceButton:SetScript("OnClick", function() CrafterList.HideServices() end)
end

function CrafterList:HideServices()
    CrafterList.Services.Frame:Hide()
    CrafterList.Services.ServiceButton.Text:SetText("List Services")
    CrafterList.Services.ServiceButton:SetScript("OnClick", CrafterList.ListServices)
    if CrafterList.SchematicStatus == 1 then
        CraftingPage.SchematicForm:Show()
    elseif CrafterList.SchematicStatus == 2 then
        CraftilityNS.ProfessionsSim.SchematicForm:Show()
    end
end