local addon, CraftilityNS = ...
local _G = _G
local ElvUI = nil -- Import: ElvUI if it is loaded when frames are initialized
local E = nil -- Import: ElvUI Engine module when frames are initialized
local S = nil -- Import: ElvUI Skins module when frames are initialized

local CrafterList = CraftilityNS.Craftility:NewModule("CrafterList", "AceConsole-3.0", "AceEvent-3.0", "AceHook-3.0", "AceComm-3.0")
CraftilityNS.CrafterList = CrafterList
local CraftingPage = _G.ProfessionsFrame.CraftingPage

CrafterList.AdvertisedProf = {[1] = {}, [2] = {}}
CrafterList.Crafters = {
    [1] = {}, --Blacksmithing
    [2] = {}, --Leatherworking
    [3] = {}, --Alchemy
    [7] = {}, --Tailoring
    [8] = {}, --Engineering
    [9] = {}, --Enchanting
    [12] = {}, --Jewelcrafting
    [13] = {} --Inscription
}

function CrafterList:OnEnable()
    self:RegisterEvent("CRAFTINGORDERS_SHOW_CUSTOMER")
    self:RegisterEvent("CRAFTINGORDERS_HIDE_CUSTOMER")
    self:RegisterEvent("TRADE_SKILL_SHOW")
    self:RegisterMessage("CRAFTILITY_INITIALIZE")
    self:RegisterComm("CFLY_Crafter", CrafterList.ImportCrafter)
    self:RegisterComm("CFLY_RmCrafter", CrafterList.RemoveCrafter)
end

function CrafterList:CRAFTILITY_INITIALIZE()
    if not self.Services then
        self:InitServices()
        self:TRADE_SKILL_SHOW()
        JoinChannelByName("CraftilityComm")
        CraftilityNS.ChannelID = GetChannelName("CraftilityComm")
    end
end

function CrafterList:CRAFTINGORDERS_SHOW_CUSTOMER()
    if not self.Crafters.Frame then
        self:InitCrafters()
    end
end

function CrafterList:CRAFTINGORDERS_HIDE_CUSTOMER()
    self.Crafters.Frame:Hide()
end

function CrafterList:TRADE_SKILL_SHOW()
    if self.Services then
        self.Services.Frame.Background:SetAtlas(Professions.GetProfessionBackgroundAtlas(Professions:GetProfessionInfo()), TextureKitConstants.IgnoreAtlasSize)
    end
end

function CrafterList:InitCrafters()
    self.Crafters.Frame = CreateFrame("Frame", "Craftility_ServicesFrame", CraftingPage)
    self.Crafters.Frame:Hide()
end

function CrafterList:InitServices()
    if CraftilityNS:IsCraftingProfession(CraftilityNS.professionInfo.prof1) or CraftilityNS:IsCraftingProfession(CraftilityNS.professionInfo.prof2) then
        local width = CraftingPage.SchematicForm:GetWidth()
        local height = CraftingPage.SchematicForm:GetHeight()
        
        self.Services = {}
        self.Services.ServiceButton = CreateFrame("Button", "Craftility_ServiceButton", CraftingPage, "UIPanelButtonTemplate")
        self.Services.ServiceButton:SetSize(120, 22)
        self.Services.ServiceButton:SetPoint("RIGHT", CraftingPage.CreateAllButton, "LEFT", -30, 0)
        self.Services.ServiceButton.Text:SetText("List Services")
        self.Services.ServiceButton:SetScript("OnClick", CrafterList.ListServices)

        self.Services.Frame = CreateFrame("Frame", "Craftility_ServicesFrame", CraftingPage)
        self.Services.Frame:SetSize(width, height)
        self.Services.Frame:SetPoint("TOPLEFT", CraftingPage.RecipeList, "TOPRIGHT", 2, 0)
        self.Services.Frame:Hide()
        self.Services.Frame.Background = self.Services.Frame:CreateTexture("Background", "BACKGROUND")
        self.Services.Frame.Background:SetPoint("TOPLEFT", self.Services.Frame, "TOPLEFT")
        self.Services.Frame.Background:SetSize(width, height)

        self.Services.Frame.prof1 = CreateFrame("Frame", "Craftility_Prof1Frame", self.Services.Frame)
        self.Services.Frame.prof1:SetPoint("TOPLEFT", self.Services.Frame, "TOPLEFT")
        self.Services.Frame.prof2 = CreateFrame("Frame", "Craftility_Prof2Frame", self.Services.Frame)
        self.Services.Frame.prof2:SetPoint("TOPLEFT", self.Services.Frame.prof1, "BOTTOMLEFT")
        self:SetupServiceBox(CraftilityNS.professionInfo.prof1, self.Services.Frame.prof1)
        self:SetupServiceBox(CraftilityNS.professionInfo.prof2, self.Services.Frame.prof2)

        self.Services.Frame.ListAllButton = CreateFrame("Button", "Craftility_ListAllButton", self.Services.Frame, "UIPanelButtonTemplate")
        self.Services.Frame.ListAllButton:SetSize(150, 22)
        self.Services.Frame.ListAllButton:SetPoint("BOTTOMRIGHT", self.Services.Frame, "BOTTOMRIGHT", -5, 10)
        self.Services.Frame.ListAllButton.Text:SetText("List All Professions")
        self.Services.Frame.ListAllButton:SetScript("OnClick", self.ListAllProfessions)

        self.Services.Frame.UnlistAllButton = CreateFrame("Button", "Craftility_UnlistAllButton", self.Services.Frame, "UIPanelButtonTemplate")
        self.Services.Frame.UnlistAllButton:SetSize(150, 22)
        self.Services.Frame.UnlistAllButton:SetPoint("RIGHT", self.Services.Frame.ListAllButton, "LEFT", -20, 0)
        self.Services.Frame.UnlistAllButton.Text:SetText("Unlist All Professions")
        self.Services.Frame.UnlistAllButton:SetScript("OnClick", self.UnlistAllProfessions)
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

    local width = CraftingPage.SchematicForm:GetWidth()
    local height = CraftingPage.SchematicForm:GetHeight()
    CrafterList.Services.Frame:SetSize(width, height)
    CrafterList.Services.Frame.Background:SetSize(width, height)
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

function CrafterList:SetupServiceBox(professionInfo, frame)
    if not CraftilityNS:IsCraftingProfession(professionInfo) then
        frame:SetSize(0,0)
        frame:Hide()
        return
    end

    local width = CraftingPage.SchematicForm:GetWidth()
    local height = CraftingPage.SchematicForm:GetHeight()

    frame:SetSize(width, 250)
    frame.Text = frame:CreateFontString("ProfessionName", "ARTWORK", "GameFontNormal")
    frame.Text:SetText(professionInfo.professionName)
    frame.Text:SetPoint("TOPLEFT", frame, "TOPLEFT", 5, -5)

    frame.skillText = frame:CreateFontString("SkillText", "ARTWORK", "GameFontNormal")
    frame.skillText:SetText("Skill: ")
    frame.skillText:SetPoint("TOPLEFT", frame.Text, "BOTTOMLEFT", 5, -10)

    frame.skill = frame:CreateFontString("Skill", "ARTWORK", "GameFontHighlight")
    frame.skill:SetText((professionInfo.skillLevel + professionInfo.skillModifier))
    frame.skill:SetPoint("LEFT", frame.skillText, "RIGHT")

    frame.CommentBox = CreateFrame("Frame", "CommentBox", frame)
    frame.CommentBox:SetSize(450, 200)
    frame.CommentBox:SetPoint("TOPLEFT", frame.skillText, "BOTTOMLEFT", 0, -20)
    frame.CommentBox.Border = frame.CommentBox:CreateTexture("Border", "ARTWORK")
    frame.CommentBox.Border:SetAtlas("CraftingOrders-NoteFrameNarrow", false)
    frame.CommentBox.Border:SetPoint("TOPLEFT", frame.CommentBox, "TOPLEFT", -8, 23)
    frame.CommentBox.Border:SetSize(450, 225)

    frame.CommentBox.TitleBox = CreateFrame("Frame", "TitleBox", frame.CommentBox)
    frame.CommentBox.TitleBox:SetSize(200, 1)
    frame.CommentBox.TitleBox:SetPoint("TOPLEFT", frame.CommentBox, "TOPLEFT")

    frame.CommentBox.TitleBox.Title = frame.CommentBox.TitleBox:CreateFontString("Title", "OVERLAY", "GameFontNormal")
    frame.CommentBox.TitleBox.Title:SetText("Comment:")
    frame.CommentBox.TitleBox.Title:SetSize(200, 1)
    frame.CommentBox.TitleBox.Title:SetPoint("LEFT", frame.CommentBox.TitleBox, "LEFT", 10, 0)
    frame.CommentBox.TitleBox.Title:SetJustifyH("LEFT")

    frame.CommentBox.ScrollingEditBox = CreateFrame("Frame", "ScrollingEditBox", frame.CommentBox, "ScrollingEditBoxTemplate")
    frame.CommentBox.ScrollingEditBox:SetPoint("TOPLEFT", frame.CommentBox.TitleBox, "BOTTOMLEFT", 10, -11)
    frame.CommentBox.ScrollingEditBox:SetSize(400, 150)
    frame.CommentBox.ScrollingEditBox:SetFrameStrata("HIGH")
    local editBox = frame.CommentBox.ScrollingEditBox:GetEditBox()
    editBox:SetMaxLetters(250)
    frame.CommentBox.ScrollingEditBox.ScrollBox.EditBox.scrollable = false

    frame.ListProfessionButton = CreateFrame("Button", "Craftility_ListProfessionButton", frame, "UIPanelButtonTemplate")
    frame.ListProfessionButton:SetSize(150, 22)
    frame.ListProfessionButton:SetPoint("BOTTOMRIGHT", frame.CommentBox, "BOTTOMRIGHT", -35, 10)
    frame.ListProfessionButton.Text:SetText("List "..professionInfo.parentProfessionName)
    frame.ListProfessionButton:SetScript("OnClick", function(self, button) 
        if self:GetParent() == CrafterList.Services.Frame.prof1 then
            CrafterList:ListProfession(CraftilityNS.professionInfo.prof1, 1)
        elseif self:GetParent() == CrafterList.Services.Frame.prof2 then
            CrafterList:ListProfession(CraftilityNS.professionInfo.prof2, 2)
        end
    end)

    frame.ListStatus = CreateFrame("CheckButton", "Craftility_ListStatus", frame, "UICheckButtonTemplate")
    frame.ListStatus:SetSize(26, 26)
    frame.ListStatus:SetPoint("RIGHT", frame.CommentBox, "TOPRIGHT", -35, 30)
    frame.ListStatus.Text:SetText("Listed")
    frame.ListStatus.Text:SetPoint("RIGHT", frame.ListStatus, "LEFT", -70, 0)
    frame.ListStatus:EnableMouse(false)
    frame.ListStatus:EnableKeyboard(false)

    frame.UnlistProfessionButton = CreateFrame("Button", "Craftility_UnlistProfessionButton", frame, "UIPanelButtonTemplate")
    frame.UnlistProfessionButton:SetSize(150, 22)
    frame.UnlistProfessionButton:SetPoint("RIGHT", frame.ListProfessionButton, "LEFT", -20, 0)
    frame.UnlistProfessionButton.Text:SetText("Unlist "..professionInfo.parentProfessionName)
    frame.UnlistProfessionButton:SetScript("OnClick", function(self, button) 
        if self:GetParent() == CrafterList.Services.Frame.prof1 then
            CrafterList:UnlistProfession(CraftilityNS.professionInfo.prof1, 1)
        elseif self:GetParent() == CrafterList.Services.Frame.prof2 then
            CrafterList:UnlistProfession(CraftilityNS.professionInfo.prof2, 2)
        end
    end)
end

function CrafterList:ListProfession(professionInfo, index)
    local professionComment = nil
    if index == 1 then
        professionComment = CrafterList.Services.Frame.prof1.CommentBox.ScrollingEditBox:GetInputText()
        CrafterList.Services.Frame.prof1.ListStatus:SetChecked(true)
    elseif index == 2 then
        professionComment = CrafterList.Services.Frame.prof2.CommentBox.ScrollingEditBox:GetInputText()
        CrafterList.Services.Frame.prof2.ListStatus:SetChecked(true)
    end
    
    local AdvertisedProf = {
        ProfessionEnum = professionInfo.profession,
        Name = professionInfo.parentProfessionName,
        Skill = (professionInfo.skillLevel + professionInfo.skillModifier),
        Comment = professionComment,
        CrafterName = UnitName("player"),
        listed = true
    }

    CrafterList.AdvertisedProf[index] = AdvertisedProf
    local serializedData = CraftilityNS:SerializeData(AdvertisedProf)
    CrafterList:SendCommMessage("CFLY_Crafter", serializedData, "CHANNEL", CraftilityNS.ChannelID)

end

function CrafterList:UnlistProfession(professionInfo, index)
    if index == 1 then
        CrafterList.Services.Frame.prof1.ListStatus:SetChecked(false)
    elseif index == 2 then
        CrafterList.Services.Frame.prof2.ListStatus:SetChecked(false)
    end

    if CrafterList.AdvertisedProf[index].listed then
        local AdvertisedProf = {
            ProfessionEnum = professionInfo.profession,
            CrafterName = UnitName("player")
        }

        CrafterList.AdvertisedProf[index] = {listed = false}
        local serializedData = CraftilityNS:SerializeData(AdvertisedProf)
        CrafterList:SendCommMessage("CFLY_RmCrafter", serializedData, "CHANNEL", CraftilityNS.ChannelID)
    end
end

function CrafterList:ListAllProfessions()
    if CrafterList.Services.Frame.prof1.Text then
        CrafterList:ListProfession(CraftilityNS.professionInfo.prof1, 1)
    end

    if CrafterList.Services.Frame.prof2.Text then
        CrafterList:ListProfession(CraftilityNS.professionInfo.prof2, 2)
    end
end

function CrafterList:UnlistAllProfessions()
    if CrafterList.Services.Frame.prof1.Text then
        CrafterList:UnlistProfession(CraftilityNS.professionInfo.prof1, 1)
    end

    if CrafterList.Services.Frame.prof2.Text then
        CrafterList:UnlistProfession(CraftilityNS.professionInfo.prof2, 2)
    end
end

function CrafterList:ImportCrafter(data)
    local AdvertisedProf = CraftilityNS:DeserializeData(data)
    if type(AdvertisedProf.ProfessionEnum) == "number" then
        local profTable = CrafterList.Crafters[AdvertisedProf.ProfessionEnum]
        profTable[AdvertisedProf.CrafterName] = AdvertisedProf
    end
end

function CrafterList:RemoveCrafter(data)
    local AdvertisedProf = CraftilityNS:DeserializeData(data)
    local profTable = CrafterList.Crafters[AdvertisedProf.ProfessionEnum]
    if profTable[AdvertisedProf.CrafterName].Skill then
        profTable[AdvertisedProf.CrafterName] = nil
    end
end