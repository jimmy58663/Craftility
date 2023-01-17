local addon, CraftilityNS = ...
local _G = _G
local ElvUI = nil
local CraftingPage = _G.ProfessionsFrame.CraftingPage
CraftilitySim = CraftilityNS.Craftility:NewModule("CraftilitySim", "AceConsole-3.0", "AceEvent-3.0", "AceHook-3.0")
CraftilityNS.CraftilitySim = CraftilitySim
CraftilitySim.Details = {}
CraftilitySim.Details.IsFrameInitialized = false

function CraftilitySim:OnEnable()
    self:RegisterEvent("TRADE_SKILL_SHOW")

    local function PoolReset(pool, slot)
		slot:Reset();
		slot.Button:SetScript("OnEnter", nil);
		slot.Button:SetScript("OnClick", nil);
		slot.Button:SetScript("OnMouseDown", nil);
		FramePool_HideAndClearAnchors(pool, slot);
	end

	self.reagentSlotPool = CreateFramePool("FRAME", self, "ProfessionsReagentSlotTemplate", PoolReset);
end

function CraftilitySim:TRADE_SKILL_SHOW()
    self.Profession = _G.ProfessionsFrame.professionInfo.profession

    if ElvUI == nil then
        ElvUI = _G.ElvUI
    end

    if not self.Details.IsFrameInitialized then
        CraftilitySim.SimFrame = CreateFrame("Frame", "Craftility_SimFrame", CraftingPage.SchematicForm,"BasicFrameTemplateWithInset")
        if ElvUI then
            ElvUI[1]:GetModule("Skins"):HandleFrame(self.SimFrame)
        end
        self.SimFrame:SetSize(400, 450)
        self.SimFrame:SetPoint("LEFT", CraftingPage.SchematicForm, "RIGHT")
        self.SimFrame:SetMovable(true)
        self.SimFrame:EnableMouse(true)
        self.SimFrame:EnableKeyboard(true)
        self.SimFrame:RegisterForDrag("LeftButton")
        self.SimFrame:SetScript("OnDragStart", function(self) self:StartMoving() end)
        self.SimFrame:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)
        self.SimFrame:SetClampedToScreen(true)
        self.SimFrame.TitleText:SetText("Craftility Sim")

        CraftilitySim.Details:Init()
    end

    CraftilitySim.Details:UpdateDetails()

    if not self.SimFrame:IsShown() then
        self.SimFrame:Show()
    end
end

function CraftilitySim.Details:Init()
    self.Frame = CreateFrame("Frame", "Craftility_SimDetails", CraftilitySim.SimFrame, "ProfessionsRecipeCrafterDetailsTemplate")
	self.Frame:SetPoint("TOPRIGHT", CraftilitySim.SimFrame, "TOPRIGHT", -25, -35)
    local qualityFrameLevel = self.Frame.QualityMeter:GetFrameLevel()
    self.Frame.QualityMeter.Center:SetFrameLevel(qualityFrameLevel + 1)
    self.Frame.QualityMeter.InteriorMask:SetFrameLevel(qualityFrameLevel + 1)
    self.Frame.QualityMeter.DividerGlow:SetFrameLevel(qualityFrameLevel + 2)
    self.Frame.QualityMeter.Border:SetFrameLevel(qualityFrameLevel + 3)
    self.Frame.QualityMeter.Marker:SetFrameLevel(qualityFrameLevel + 4)
    self.Frame.QualityMeter.Flare:SetFrameLevel(qualityFrameLevel + 5)
    self.Frame.QualityMeter.Left:SetFrameLevel(qualityFrameLevel + 6)
    self.Frame.QualityMeter.Right:SetFrameLevel(qualityFrameLevel + 7)
    self.Frame:Layout()

	CraftilitySim:SecureHook(CraftingPage.SchematicForm,"UpdateDetailsStats", CraftilitySim.Details.UpdateDetails)
    self.IsFrameInitialized = true
end

function CraftilitySim.Details:UpdateDetails()
    local finishingSlots = CraftingPage.SchematicForm:GetSlotsByReagentType(Enum.CraftingReagentType.Finishing)
    local hasFinishingSlots = finishingSlots ~= nil
    local recipeInfo = CraftingPage.SchematicForm:GetRecipeInfo()
    local transaction = CraftingPage.SchematicForm.transaction
    _G.Professions:LayoutFinishingSlots(finishingSlots, CraftilitySim.Details.Frame.FinishingReagentSlotContainer)

    CraftilitySim.Details.Frame:SetData(transaction, recipeInfo, hasFinishingSlots)

    CraftilitySim.Details.operationInfo = CraftingPage.SchematicForm.Details.operationInfo
    
    CraftilitySim.Details.Frame:SetStats(CraftilitySim.Details.operationInfo,  CraftilitySim.Details.Frame.recipeInfo.supportsQualities, CraftilitySim.Details.Frame.recipeInfo.isGatheringRecipe)
end