local addon, CraftilityNS = ...
local _G = _G
local ElvUI = nil -- Import: ElvUI if it is loaded when frames are initialized
local E = nil -- Import: ElvUI Engine module when frames are initialized
local S = nil -- Import: ElvUI Skins module when frames are initialized
local AceSerializer = LibStub:GetLibrary("AceSerializer-3.0")
local libC = LibStub:GetLibrary("LibCompress")
local EncodeTable = libC:GetAddonEncodeTable()
local CraftingPage = _G.ProfessionsFrame.CraftingPage
local Professions = _G.Professions

local ProfessionsSim = CraftilityNS.Craftility:NewModule("ProfessionsSim", "AceConsole-3.0", "AceEvent-3.0", "AceHook-3.0")
CraftilityNS.ProfessionsSim = ProfessionsSim
ProfessionsSim.RecraftOverride = false

local IgnoreRecipes = {
    --Recipe IDs to hide simulation buttons on
    385304, --BS Recraft
    389190, --Alch Recraft
    389192, --Eng Recraft
    389193, --Inscrip Recraft
    389194, --JC Recraft
    389195, --LW Recraft
    382981, --Inscrip Milling
    395696, --JC Crushing
    374627 --JC Prospecting
}

function ProfessionsSim:OnEnable()
    self:RegisterEvent("TRADE_SKILL_SHOW")
    self:RegisterMessage("CRAFTILITY_INITIALIZE")
end

function ProfessionsSim:CRAFTILITY_INITIALIZE()
    if not ProfessionsSim.ShowSimButton then
        self:InitButtons()
        self:TRADE_SKILL_SHOW()
    end
end

function ProfessionsSim:TRADE_SKILL_SHOW()
    local professionInfo = Professions:GetProfessionInfo()
    if self.SchematicForm then
        if E == nil or not E.private.skins.blizzard.tradeskill or not E.private.skins.blizzard.enable then
            self.SchematicForm.Background:SetAtlas(Professions.GetProfessionBackgroundAtlas(professionInfo), TextureKitConstants.IgnoreAtlasSize)
        else
            self:ElvSkinning(self)
        end
        self.SchematicForm:Hide()
    end
    if not CraftingPage.SchematicForm:IsShown() then
        CraftingPage.SchematicForm:Show()
    end
end

function ProfessionsSim:InitButtons()
    local width = CraftingPage.SchematicForm:GetWidth()
    local height = CraftingPage.SchematicForm:GetHeight()
    
    self.ShowSimButton = CreateFrame("Button", "Craftility_ShowSimButton", CraftingPage.SchematicForm, "UIPanelButtonTemplate")
    self.ShowSimButton:SetSize(120, 22)
    self.ShowSimButton:SetPoint("RIGHT", CraftingPage.SchematicForm.OptionalReagents, "BOTTOMRIGHT", 0, -10)
    self.ShowSimButton.Text:SetText("Show Sim Mode")
    self.ShowSimButton:SetScript("OnClick", ProfessionsSim.ShowSimMode)
    
    self.SchematicForm = CreateFrame("Frame", "Craftility_SchematicForm", CraftingPage,"ProfessionsRecipeSchematicFormTemplate")
    self.SchematicForm:SetSize(width, height)
    self.SchematicForm:SetPoint("TOPLEFT", CraftingPage.RecipeList, "TOPRIGHT", 2, 0)
    self.SchematicForm:EnableMouse(true)
    self.SchematicForm:EnableKeyboard(true)
    
    local qualityFrameLevel = self.SchematicForm.Details.QualityMeter:GetFrameLevel()
    self.SchematicForm.Details.QualityMeter.Center:SetFrameLevel(qualityFrameLevel + 1)
    self.SchematicForm.Details.QualityMeter.InteriorMask:SetFrameLevel(qualityFrameLevel + 1)
    self.SchematicForm.Details.QualityMeter.DividerGlow:SetFrameLevel(qualityFrameLevel + 2)
    self.SchematicForm.Details.QualityMeter.Border:SetFrameLevel(qualityFrameLevel + 3)
    self.SchematicForm.Details.QualityMeter.Marker:SetFrameLevel(qualityFrameLevel + 4)
    self.SchematicForm.Details.QualityMeter.Flare:SetFrameLevel(qualityFrameLevel + 5)
    self.SchematicForm.Details.QualityMeter.Left:SetFrameLevel(qualityFrameLevel + 6)
    self.SchematicForm.Details.QualityMeter.Right:SetFrameLevel(qualityFrameLevel + 7)
    self.SchematicForm.Details:Layout()
    ProfessionsSim:SecureHook(CraftingPage.SchematicForm,"Init", ProfessionsSim.HookInit)
    ProfessionsSim:SecureHook(ProfessionsSim.SchematicForm, "UpdateDetailsStats", ProfessionsSim.UpdateInspirationIcon)

    self.SchematicForm.Background = self.SchematicForm:CreateTexture("Background", "BACKGROUND")
    self.SchematicForm.Background:SetPoint("TOPLEFT", self.SchematicForm, "TOPLEFT")
    self.SchematicForm.Background:SetSize(width, height)
    self.SchematicForm.Background:SetAtlas(Professions.GetProfessionBackgroundAtlas(professionInfo), TextureKitConstants.IgnoreAtlasSize)

    self.HideSimButton = CreateFrame("Button", "Craftility_HideSimButton", self.SchematicForm, "UIPanelButtonTemplate")
    self.HideSimButton:SetSize(120, 22)
    self.HideSimButton:SetPoint("RIGHT", self.SchematicForm.OptionalReagents, "BOTTOMRIGHT", 0, -35)
    self.HideSimButton.Text:SetText("Hide Sim Mode")
    self.HideSimButton:SetScript("OnClick", ProfessionsSim.HideSimMode)

    self.R1MatsButton = CreateFrame("Button", "Craftility_R1MatsButton", self.SchematicForm, "UIPanelButtonTemplate")
    self.R1MatsButton:SetSize(70, 22)
    self.R1MatsButton:SetPoint("LEFT", self.SchematicForm.Reagents, "BOTTOMLEFT", 0, -10)
    self.R1MatsButton.Text:SetText("R1 Mats")
    self.R1MatsButton:SetScript("OnClick", function() ProfessionsSim:ChangeMaterials(1) end)

    self.R2MatsButton = CreateFrame("Button", "Craftility_R2MatsButton", self.SchematicForm, "UIPanelButtonTemplate")
    self.R2MatsButton:SetSize(70, 22)
    self.R2MatsButton:SetPoint("LEFT", self.R1MatsButton, "RIGHT", 10, 0)
    self.R2MatsButton.Text:SetText("R2 Mats")
    self.R2MatsButton:SetScript("OnClick", function() ProfessionsSim:ChangeMaterials(2) end)

    self.R3MatsButton = CreateFrame("Button", "Craftility_R3MatsButton", self.SchematicForm, "UIPanelButtonTemplate")
    self.R3MatsButton:SetSize(70, 22)
    self.R3MatsButton:SetPoint("LEFT", self.R2MatsButton, "RIGHT", 10, 0)
    self.R3MatsButton.Text:SetText("R3 Mats")
    self.R3MatsButton:SetScript("OnClick", function() ProfessionsSim:ChangeMaterials(3) end)

    self.RecraftCheckBox = CreateFrame("CheckButton", "Craftility_RecraftCheckBox", self.SchematicForm, "UICheckButtonTemplate")
    self.RecraftCheckBox:SetSize(26, 26)
    self.RecraftCheckBox:SetPoint("RIGHT", self.SchematicForm.OptionalReagents, "BOTTOMRIGHT", 0, -10)
    self.RecraftCheckBox.text:SetText("Show Recraft  ")
    self.RecraftCheckBox.text:SetPoint("RIGHT", self.RecraftCheckBox, "LEFT", -100, 0)
    self.RecraftCheckBox:SetScript("OnClick", function () 
        local checked = ProfessionsSim.RecraftCheckBox:GetChecked()
        if not checked then
            Professions:EraseRecraftingTransitionData()
            local previousRecipeID = CraftingPage.RecipeList:GetPreviousRecipeID()
            local recipeInfo = _G.C_TradeSkillUI.GetRecipeInfo(previousRecipeID)
            CraftingPage.SchematicForm.currentRecipeInfo = recipeInfo
        end
        ProfessionsSim.RecraftOverride = checked
        ProfessionsSim:HookInit()
    end)

    if ElvUI == nil then
        ElvUI = _G.ElvUI
    end

    if ElvUI then
        E = _G.ElvUI[1] --Import: Engine
        S = E:GetModule("Skins")
    end
    self.SchematicForm:Hide()
end

function ProfessionsSim:HookInit(recipeInfo)
    --Logic is found in BlizzardInterfaceCode/Interface/AddOns/Blizzard_ProfessionsTemplates/Blizzard_ProfessionsRecipeSchematicForm.lua
    if not Professions.InLocalCraftingMode() then
        ProfessionsSim.ShowSimButton:Hide()
        return
    else
        ProfessionsSim.ShowSimButton:Show()
    end

    if not recipeInfo then
        ProfessionsSim.currentRecipeInfo = CraftingPage.SchematicForm:GetRecipeInfo()
    else
        ProfessionsSim.currentRecipeInfo = recipeInfo
    end

    if CraftingPage.SchematicForm.transaction.isRecraft then
        ProfessionsSim.RecraftCheckBox:Hide()
    else
        ProfessionsSim.RecraftCheckBox:Show()
    end

    ProfessionsSim.SchematicForm:ClearTransaction()
    if ProfessionsSim.currentRecipeInfo ~= nil then
        if ProfessionsSim.RecraftOverride then
            ProfessionsSim.SchematicForm:Init(ProfessionsSim.currentRecipeInfo, ProfessionsSim.RecraftOverride)
            ProfessionsSim.SchematicForm.recraftSlot:Hide()
            ProfessionsSim.SchematicForm.RecraftingOutputText:Hide()
            ProfessionsSim.SchematicForm.RecraftingRequiredTools:Hide()
            ProfessionsSim.SchematicForm.OutputIcon:Show()
            ProfessionsSim.SchematicForm.OutputText:Show()
            ProfessionsSim.SchematicForm.RequiredTools:Show()
            ProfessionsSim.SchematicForm.Reagents:ClearAllPoints()
            ProfessionsSim.SchematicForm.Reagents:SetPoint("TOPLEFT", ProfessionsSim.SchematicForm.Description, "BOTTOMLEFT", 0, -20)
        else
            ProfessionsSim.SchematicForm:Init(ProfessionsSim.currentRecipeInfo)
        end
        ProfessionsSim.SchematicForm:UpdateDetailsStats()
        ProfessionsSim:HideUnused()
        
        local recipeID = ProfessionsSim.currentRecipeInfo.recipeID
        if not ProfessionsSim.currentRecipeInfo.supportsQualities or tContains(IgnoreRecipes, recipeID) then
            ProfessionsSim.ShowSimButton:Hide()
        elseif ProfessionsSim.currentRecipeInfo.supportsQualities then
            if not ProfessionsSim.ShowSimButton:IsShown() then
                ProfessionsSim.ShowSimButton:Show()
            end
            ProfessionsSim:UpdateInspirationIcon()
            ProfessionsSim:UpdateSkillVarianceIcon()
        end

        if ProfessionsSim.currentRecipeInfo.isEnchantingRecipe then
            ProfessionsSim.ShowSimButton:SetPoint("RIGHT", CraftingPage.SchematicForm.enchantSlot, "BOTTOMRIGHT", 0, -10)
            ProfessionsSim.HideSimButton:SetPoint("RIGHT", ProfessionsSim.SchematicForm.enchantSlot, "BOTTOMRIGHT", 0, -10)
            ProfessionsSim.RecraftCheckBox:Hide()
        else
            ProfessionsSim.ShowSimButton:SetPoint("RIGHT", CraftingPage.SchematicForm.OptionalReagents, "BOTTOMRIGHT", 0, -10)
            ProfessionsSim.HideSimButton:SetPoint("RIGHT", ProfessionsSim.SchematicForm.OptionalReagents, "BOTTOMRIGHT", 0, -35)
            ProfessionsSim.RecraftCheckBox:Show()
        end

        if ProfessionsSim.SchematicForm:IsShown() then
            if tContains(IgnoreRecipes, recipeID) then
                ProfessionsSim.R1MatsButton:Hide()
                ProfessionsSim.R2MatsButton:Hide()
                ProfessionsSim.R3MatsButton:Hide()
                ProfessionsSim.RecraftCheckBox:Hide()
                ProfessionsSim.HideSimButton:Hide()
            else
                ProfessionsSim:ChangeMaterials(1)
                ProfessionsSim.R1MatsButton:Show()
                ProfessionsSim.R2MatsButton:Show()
                ProfessionsSim.R3MatsButton:Show()
                ProfessionsSim.RecraftCheckBox:Show()
                ProfessionsSim.HideSimButton:Show()
            end
        end
    end
    ProfessionsSim.SchematicForm.Background:SetAtlas(Professions.GetProfessionBackgroundAtlas(Professions:GetProfessionInfo()), TextureKitConstants.IgnoreAtlasSize)
end

function ProfessionsSim:ElvSkinning(ProfessionsSim)
    --The below is from ElvUI/Mainline/Modules/Skins/Professions.lua
    local function HandleInputBox(box)
        box:DisableDrawLayer('BACKGROUND')
        S:HandleEditBox(box)
        S:HandleNextPrevButton(box.DecrementButton, 'left')
        S:HandleNextPrevButton(box.IncrementButton, 'right')
    end

    local function ReskinQualityContainer(container)
        local button = container.Button
        button:StripTextures()
        button:SetNormalTexture(E.ClearTexture)
        button:SetPushedTexture(E.ClearTexture)
        button:SetHighlightTexture(E.ClearTexture)
        S:HandleIcon(button.Icon, true)
        S:HandleIconBorder(button.IconBorder, button.Icon.backdrop)
        HandleInputBox(container.EditBox)
    end

    local function ReskinSlotButton(button)
        if button and not button.isSkinned then
            local texture = button.Icon:GetTexture()
            button:StripTextures()
            button:SetNormalTexture(E.ClearTexture)
            button:SetPushedTexture(E.ClearTexture)
    
            S:HandleIcon(button.Icon, true)
            S:HandleIconBorder(button.IconBorder, button.Icon.backdrop)
            button.Icon:SetOutside(button)
            button.Icon:SetTexture(texture)
    
            local hl = button:GetHighlightTexture()
            hl:SetColorTexture(1, 1, 1, .25)
            hl:SetOutside(button)
    
            if button.SlotBackground then
                button.SlotBackground:Hide()
            end
    
            button.isSkinned = true
        end
    end

    local SchematicForm = ProfessionsSim.SchematicForm
    SchematicForm:StripTextures()

	if E.private.skins.parchmentRemoverEnable then
		SchematicForm.Background:SetAlpha(0)
	else
		SchematicForm.Background:SetAlpha(.25)
	end
	SchematicForm:CreateBackdrop('Transparent')
	SchematicForm.backdrop:SetInside()

    hooksecurefunc(SchematicForm, 'Init', function(frame)
		for slot in frame.reagentSlotPool:EnumerateActive() do
			ReskinSlotButton(slot.Button)
		end

		local slot = SchematicForm.salvageSlot
		if slot then
			ReskinSlotButton(slot.Button)
		end

        local enchantSlot = SchematicForm.enchantSlot
		if enchantSlot then
			ReskinSlotButton(enchantSlot.Button)
		end
	end)

    local TrackRecipeCheckBox = SchematicForm.TrackRecipeCheckBox
	if TrackRecipeCheckBox then
		S:HandleCheckBox(TrackRecipeCheckBox)
		TrackRecipeCheckBox:SetSize(24, 24)
	end

	local QualityCheckBox = SchematicForm.AllocateBestQualityCheckBox
	if QualityCheckBox then
		S:HandleCheckBox(QualityCheckBox)
		QualityCheckBox:SetSize(24, 24)
	end

	local QualityDialog = SchematicForm.QualityDialog
	if QualityDialog then
		QualityDialog:StripTextures()
		QualityDialog:CreateBackdrop('Transparent')
		S:HandleCloseButton(QualityDialog.ClosePanelButton)
		S:HandleButton(QualityDialog.AcceptButton)
		S:HandleButton(QualityDialog.CancelButton)

		ReskinQualityContainer(QualityDialog.Container1)
		ReskinQualityContainer(QualityDialog.Container2)
		ReskinQualityContainer(QualityDialog.Container3)
	end

	local OutputIcon = SchematicForm.OutputIcon
	if OutputIcon then
		S:HandleIcon(OutputIcon.Icon, true)
		S:HandleIconBorder(OutputIcon.IconBorder, OutputIcon.Icon.backdrop)
		OutputIcon:GetHighlightTexture():Hide()
		OutputIcon.CircleMask:Hide()
	end

    local ShowSimButton = ProfessionsSim.ShowSimButton
    S:HandleButton(ShowSimButton)

    local HideSimButton = ProfessionsSim.HideSimButton
    S:HandleButton(HideSimButton)

    local R1MatsButton = ProfessionsSim.R1MatsButton
    S:HandleButton(R1MatsButton)

    local R2MatsButton = ProfessionsSim.R2MatsButton
    S:HandleButton(R2MatsButton)

    local R3MatsButton = ProfessionsSim.R3MatsButton
    S:HandleButton(R3MatsButton)

    local RecraftCheckBox = ProfessionsSim.RecraftCheckBox
    S:HandleCheckBox(RecraftCheckBox)
    RecraftCheckBox:SetSize(24, 24)
end

function ProfessionsSim:ShowSimMode()
    CraftingPage.SchematicForm:Hide()

    local width = CraftingPage.SchematicForm:GetWidth()
    local height = CraftingPage.SchematicForm:GetHeight()
    ProfessionsSim.SchematicForm:SetSize(width, height)
    ProfessionsSim.SchematicForm.Background:SetSize(width, height)
    ProfessionsSim.SchematicForm.Background:SetAtlas(Professions.GetProfessionBackgroundAtlas(professionInfo), TextureKitConstants.IgnoreAtlasSize)
    ProfessionsSim.SchematicForm:Show()
    ProfessionsSim:HideUnused()
    if ProfessionsSim.SchematicForm.transaction.isRecraft then
        ProfessionsSim.RecraftCheckBox:Hide()
    else
        ProfessionsSim.RecraftCheckBox:Show()
    end
    ProfessionsSim:ChangeMaterials(1)    
end

function ProfessionsSim:HideSimMode()
    ProfessionsSim.SchematicForm:Hide()
    local checked = ProfessionsSim.RecraftCheckBox:GetChecked()
    if checked then
        ProfessionsSim.RecraftCheckBox:SetChecked(false)
        Professions:EraseRecraftingTransitionData()
        local previousRecipeID = CraftingPage.RecipeList:GetPreviousRecipeID()
        local recipeInfo = _G.C_TradeSkillUI.GetRecipeInfo(previousRecipeID)
        CraftingPage.SchematicForm.currentRecipeInfo = recipeInfo
        ProfessionsSim.RecraftOverride = false
        ProfessionsSim:HookInit()
    end
    CraftingPage.SchematicForm:Show()
end

function ProfessionsSim:HideUnused()
    self.SchematicForm.FavoriteButton:Hide()
    self.SchematicForm.AllocateBestQualityCheckBox:Hide()
    self.SchematicForm.TrackRecipeCheckBox:Hide()
end

function ProfessionsSim:ChangeMaterials(materialRank)
    local iterator = ipairs
    if materialRank == 3 then
        iterator = ipairs_reverse
    end

    for slot in ProfessionsSim.SchematicForm.reagentSlotPool:EnumerateActive() do
        local reagentSlotSchematic = slot:GetReagentSlotSchematic()
        local slotIndex = slot:GetSlotIndex()
        local quantityRequired = reagentSlotSchematic.quantityRequired
        local recipeInfo = ProfessionsSim.currentRecipeInfo
        local recipeID = recipeInfo.recipeID
        if reagentSlotSchematic.reagentType == Enum.CraftingReagentType.Basic then
            if materialRank ~=2 then
                for reagentIndex, reagent in iterator(reagentSlotSchematic.reagents) do
                    ProfessionsSim.SchematicForm.transaction:OverwriteAllocation(slotIndex, reagent, quantityRequired)
                    break
                end
            elseif materialRank == 2 then
                if reagentSlotSchematic.reagents[2] ~= nil then
                    ProfessionsSim.SchematicForm.transaction:OverwriteAllocation(slotIndex, reagentSlotSchematic.reagents[2], quantityRequired)
                else
                    ProfessionsSim.SchematicForm.transaction:OverwriteAllocation(slotIndex, reagentSlotSchematic.reagents[1], quantityRequired)
                end
            end
            slot:SetOverrideQuantity(quantityRequired)

            --This section is from BlizzardInterfaceCode/Interface/AddOns/Blizzard_ProfessionsTemplates/Blizzard_ProfessionsRecipeSchematicForm.lua
            --It overrides the item quantity checking to mock up having all reagents for simulations
            --Replace all self references with ProfessionsSim.SchematicForm
            if Professions.GetReagentInputMode(reagentSlotSchematic) == Professions.ReagentInputMode.Quality then
                slot.Button:SetScript("OnClick", function(button, buttonName, down)
                    if IsShiftKeyDown() then
                        local qualityIndex = Professions.FindFirstQualityAllocated(ProfessionsSim.SchematicForm.transaction, reagentSlotSchematic) or 1;
                        local handled, link = Professions.HandleQualityReagentItemLink(recipeID, reagentSlotSchematic, qualityIndex);
                        if not handled then
                            Professions.TriggerReagentClickedEvent(link);
                        end
                        return;
                    end

                    if not slot:IsUnallocatable() then
                        if buttonName == "LeftButton" then
                            local function OnAllocationsAccepted(dialog, allocations, reagentSlotSchematic)
                                ProfessionsSim.SchematicForm.transaction:OverwriteAllocations(reagentSlotSchematic.slotIndex, allocations);
                                ProfessionsSim.SchematicForm.transaction:SetManuallyAllocated(true);

                                slot:Update();

                                ProfessionsSim.SchematicForm:TriggerEvent(ProfessionsRecipeSchematicFormMixin.Event.AllocationsModified);
                            end

                            ProfessionsSim.SchematicForm.QualityDialog:RegisterCallback(ProfessionsQualityDialogMixin.Event.Accepted, OnAllocationsAccepted, slot);
                            
                            local allocationsCopy = ProfessionsSim.SchematicForm.transaction:GetAllocationsCopy(slotIndex);
                            local disallowZeroAllocations = true;
                            ProfessionsSim.SchematicForm.QualityDialog:Open(recipeID, reagentSlotSchematic, allocationsCopy, slotIndex, disallowZeroAllocations);

                            --Added below to override quantity and enable buttons
                            local function Allocate(qualityIndex, value)
                                local QualityDialog = ProfessionsSim.SchematicForm.QualityDialog
                                QualityDialog.allocations:Allocate(QualityDialog:GetReagent(qualityIndex), value)

                                local overflow = math.max(0, QualityDialog:Accumulate() - QualityDialog:GetQuantityRequired());
                                if overflow > 0 then
                                    for deallocateIndex = 1, QualityDialog:GetReagentSlotCount() do
                                        if deallocateIndex ~= qualityIndex then
                                            local reagent = QualityDialog:GetReagent(deallocateIndex);
                                            local oldQuantity = QualityDialog.allocations:GetQuantityAllocated(reagent);
                                            local deallocatable = math.min(overflow, oldQuantity);
                                            if deallocatable > 0 then
                                                overflow = overflow - deallocatable;

                                                local newQuantity = oldQuantity - deallocatable;
                                                QualityDialog.allocations:Allocate(reagent, newQuantity);
                                            end
                                        end

                                        if overflow <= 0 then
                                            break;
                                        end
                                    end
                                end

                                for qualityIndex = 1, QualityDialog:GetReagentSlotCount() do
                                    local container = QualityDialog.containers[qualityIndex];
                                    local editBox = container.EditBox;
                                    editBox:SetValue(QualityDialog.allocations:GetQuantityAllocated(QualityDialog:GetReagent(qualityIndex)));
                                end

                                return value
                            end
                            for qualityIndex, reagent in ipairs(reagentSlotSchematic.reagents) do
                                local QualityDialog = ProfessionsSim.SchematicForm.QualityDialog
                                local container = QualityDialog.containers[qualityIndex]
                                local reagentButton = container.Button
                                local editBox = container.EditBox

                                editBox:SetScript("OnTextChanged", function (editBox, userChanged)
                                    if not userChanged then
                                        Allocate(qualityIndex, tonumber(editBox:GetText()) or 0)
                                    end
                                end)

                                reagentButton:SetScript("OnClick", function(button, buttonName, down)
                                    if IsShiftKeyDown() then
                                        Professions.HandleQualityReagentItemLink(QualityDialog.recipeID, QualityDialog.reagentSlotSchematic, qualityIndex)
                                    else
                                        if buttonName == "LeftButton" then
                                            Allocate(qualityIndex, QualityDialog:GetQuantityRequired())
                                        elseif buttonName == "RightButton" then
                                            Allocate(qualityIndex, 0)
                                        end
                                    end
                                end)

                                reagentButton:SetItemButtonCount(quantityRequired)
                                reagentButton:DesaturateHierarchy(0)
                                editBox:Enable()
                                editBox:SetMinMaxValues(0, quantityRequired)
                                local quantity = QualityDialog:GetQuantityAllocated(qualityIndex)
                                editBox:SetText(quantity)
                            end
                            ProfessionsSim.SchematicForm.QualityDialog.AcceptButton:SetEnabled(true)
                        end
                    end
                end);
            end
        elseif reagentSlotSchematic.reagentType == Enum.CraftingReagentType.Optional or reagentSlotSchematic.reagentType == Enum.CraftingReagentType.Finishing then
            --This section is from BlizzardInterfaceCode/Interface/AddOns/Blizzard_ProfessionsTemplates/Blizzard_ProfessionsRecipeSchematicForm.lua
            --It overrides the item quantity checking to mock up having all reagents for simulations
            --Replace all self references with ProfessionsSim.SchematicForm
            local locked, lockedReason = Professions.GetReagentSlotStatus(reagentSlotSchematic, recipeInfo);
            slot.Button:SetScript("OnMouseDown", function(button, buttonName, down)
				if locked then
					return;
				end

				if not slot:IsUnallocatable() then
					if buttonName == "LeftButton" then
						local flyout = ToggleProfessionsItemFlyout(slot.Button, ProfessionsFrame);
						if flyout then
							local function OnFlyoutItemSelected(o, flyout, elementData)
								local item = elementData.item;
								
								local function AllocateFlyoutItem()
									--This section is commented out to override quantity checking
                                    --[[if ItemUtil.GetCraftingReagentCount(item:GetItemID()) == 0 then
										return;
									end]]

									local reagent = Professions.CreateCraftingReagentByItemID(item:GetItemID());
									ProfessionsSim.SchematicForm.transaction:OverwriteAllocation(slotIndex, reagent, reagentSlotSchematic.quantityRequired);
									
									slot:SetItem(item);

									ProfessionsSim.SchematicForm:TriggerEvent(ProfessionsRecipeSchematicFormMixin.Event.AllocationsModified);
								end

								local modification = ProfessionsSim.SchematicForm.transaction:GetModification(reagentSlotSchematic.dataSlotIndex);
								local allocate = not (modification and ProfessionsSim.SchematicForm.transaction:HasAllocatedItemID(modification.itemID));
								if allocate then
									AllocateFlyoutItem();
								else
									local modItem = Item:CreateFromItemID(modification.itemID);
									local dialogData = {callback = AllocateFlyoutItem, itemName = modItem:GetItemName()};
									StaticPopup_Show("PROFESSIONS_RECRAFT_REPLACE_OPTIONAL_REAGENT", nil, nil, dialogData);	
								end
							end

							flyout.GetElementsImplementation = function(self, filterOwned)
								local itemIDs = Professions.ExtractItemIDsFromCraftingReagents(reagentSlotSchematic.reagents);
								local items = Professions.GenerateFlyoutItemsTable(itemIDs, filterOwned);
								local elementData = {items = items};
								return elementData;
							end
							
							flyout.OnElementEnterImplementation = function(elementData, tooltip)
								Professions.FlyoutOnElementEnterImplementation(elementData, tooltip, recipeID, ProfessionsSim.SchematicForm.transaction:GetAllocationItemGUID());
							end

							flyout.OnElementEnabledImplementation = nil;

							flyout:Init(slot.Button, ProfessionsSim.SchematicForm.transaction);
							flyout:RegisterCallback(ProfessionsItemFlyoutMixin.Event.ItemSelected, OnFlyoutItemSelected, slot);

                            --Added below to override quantity and enable buttons
                            for i=1, select("#", flyout.ScrollBox.ScrollTarget:GetChildren()) do
                                local flyoutButton = select(i, flyout.ScrollBox.ScrollTarget:GetChildren())
                                flyoutButton:SetItemButtonCount(1)
                                flyoutButton.enabled = true
                                flyoutButton:DesaturateHierarchy(0)
                            end
						end
					elseif buttonName == "RightButton" then
						if ProfessionsSim.SchematicForm.transaction:HasAllocations(slotIndex) then
							local function Deallocate()
								ProfessionsSim.SchematicForm.transaction:ClearAllocations(slotIndex);

								slot:ClearItem();

								ProfessionsSim.SchematicForm:TriggerEvent(ProfessionsRecipeSchematicFormMixin.Event.AllocationsModified);
							end
							
							local modification = ProfessionsSim.SchematicForm.transaction:GetModification(reagentSlotSchematic.dataSlotIndex);
							local allocate = not (modification and ProfessionsSim.SchematicForm.transaction:HasAllocatedItemID(modification.itemID));
							if allocate then
								Deallocate();
							else
								local modItem = Item:CreateFromItemID(modification.itemID);
								local dialogData = {callback = Deallocate, itemName = modItem:GetItemName()};
								StaticPopup_Show("PROFESSIONS_RECRAFT_REPLACE_OPTIONAL_REAGENT", nil, nil, dialogData);	
							end
						end
					end
				end
			end);
        end
    end
    ProfessionsSim.SchematicForm:UpdateAllSlots()
    ProfessionsSim.SchematicForm:UpdateDetailsStats()
end

function ProfessionsSim:SerializeCraft(data)
    local serializedData = AceSerializer:Serialize(data)
    local compressedData = libC:Compress(serializedData)
    local encodedData = EncodeTable:Encode(compressedData)
    return encodedData
end

function ProfessionsSim:DeserializeCraft(encodedData)
    local compressedData = EncodeTable:Decode(encodedData)
    local decompressSuccess, serializedData = libC:Decompress(compressedData)
    if not decompressSuccess then
        error("Craftility: Error decompressing: " .. serializedData)
    end

    local deserialzeSuccess, data = AceSerializer:Deserialize(serializedData)
    if not deserialzeSuccess then
        error("Craftility: Error deserializing: " .. data)
    end
    return data
end

function ProfessionsSim:UpdateInspirationIcon()
    if not ProfessionsSim.currentRecipeInfo.supportsQualities then
        return
    end
    local Details = ProfessionsSim.SchematicForm.Details
    local operationInfo = Details.operationInfo
    local craftingQuality = operationInfo.craftingQuality
    local maxQuality = ProfessionsSim.currentRecipeInfo.maxQuality
    local maxDifficulty = operationInfo.baseDifficulty + operationInfo.bonusDifficulty

    local inspirationPercent = nil
    local inspirationSkill = nil
    for _, bonusStat in ipairs(operationInfo.bonusStats) do
        if bonusStat.bonusStatName == "Inspiration" then
            inspirationPercent, inspirationSkill = bonusStat.ratingDescription:match("(%d*%.%d*%%)%D*(%d[%d]*)")
            inspirationSkill = tonumber(inspirationSkill)
        end
    end

    if craftingQuality ~= maxQuality and inspirationSkill then
        local inspiredSkill = operationInfo.baseSkill + operationInfo.bonusSkill + inspirationSkill
        if maxQuality == 5 then
            if inspiredSkill >= maxDifficulty then 
                craftingQuality = maxQuality
            elseif inspiredSkill >= (maxDifficulty * .8) then
                craftingQuality = maxQuality - 1
            elseif inspiredSkill >= (maxDifficulty * .5) then
                craftingQuality = maxQuality - 2
            elseif inspiredSkill >= (maxDifficulty * .2) then
                craftingQuality = maxQuality - 3
            else
                craftingQuality = maxQuality - 4
            end
        elseif maxQuality == 3 then
            if inspiredSkill >= maxDifficulty then 
                craftingQuality = maxQuality
            elseif inspiredSkill >= operationInfo.upperSkillTreshold then
                craftingQuality = craftingQuality + 1
            end
        end
    end

    if not ProfessionsSim.InspirationIcon then
        ProfessionsSim.InspirationIcon = CreateFrame("Frame", "Craftility_InspirationIcon", Details, "ProfessionsQualityMeterCapTemplate")
        ProfessionsSim.InspirationIcon.text = ProfessionsSim.InspirationIcon:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
        ProfessionsSim.InspirationIcon.text:SetSize("140", "20")
        ProfessionsSim.InspirationIcon.text:SetPoint("RIGHT", ProfessionsSim.InspirationIcon, "LEFT")
        ProfessionsSim.InspirationIcon.text:SetText("Inspiration Result: ")
    end
    ProfessionsSim.InspirationIcon.AppearIcon:SetAtlas(("GemAppear_T%d_Flipbook"):format(craftingQuality))
    ProfessionsSim.InspirationIcon:ClearAllPoints()
    ProfessionsSim.InspirationIcon:SetPoint("CENTER", Details, "BOTTOM", 0, -14)
    ProfessionsSim.InspirationIcon.AppearIcon.Anim:Restart()
    ProfessionsSim:UpdateSkillVarianceIcon()
end

function ProfessionsSim:UpdateSkillVarianceIcon()
    if not ProfessionsSim.currentRecipeInfo.supportsQualities then
        return
    end
    local Details = ProfessionsSim.SchematicForm.Details
    local operationInfo = Details.operationInfo
    local craftingQuality = operationInfo.craftingQuality
    local maxQuality = ProfessionsSim.currentRecipeInfo.maxQuality
    local maxDifficulty = operationInfo.baseDifficulty + operationInfo.bonusDifficulty
    local maxSkillVariance = maxDifficulty * .05
    local maxSkill = operationInfo.baseSkill + operationInfo.bonusSkill + maxSkillVariance

    local skillIcon = craftingQuality
    if maxSkill >= operationInfo.upperSkillTreshold and craftingQuality ~= maxQuality then
        skillIcon = craftingQuality + 1
    end

    if not ProfessionsSim.SkillVarianceIcon then
        ProfessionsSim.SkillVarianceIcon = CreateFrame("Frame", "Craftility_SkillVarianaceIcon", Details, "ProfessionsQualityMeterCapTemplate")
        ProfessionsSim.SkillVarianceIcon.text = ProfessionsSim.SkillVarianceIcon:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
        ProfessionsSim.SkillVarianceIcon.text:SetSize("140", "20")
        ProfessionsSim.SkillVarianceIcon.text:SetPoint("RIGHT", ProfessionsSim.SkillVarianceIcon, "LEFT")
        ProfessionsSim.SkillVarianceIcon.text:SetText("Skill Variance: ")

        ProfessionsSim.SkillVarianceIcon:SetScript("OnEnter", function(icon) 
            GameTooltip:SetOwner(icon, "ANCHOR_RIGHT")
            GameTooltip_SetTitle(GameTooltip, "EXPERIMENTAL:")
            GameTooltip_AddNormalLine(GameTooltip, "Craft with up to "..(math.floor(((ProfessionsSim.SchematicForm.Details.operationInfo.baseDifficulty + ProfessionsSim.SchematicForm.Details.operationInfo.bonusDifficulty)*.05))).." additional skill.")
            GameTooltip:Show()
        end)

        ProfessionsSim.SkillVarianceIcon:SetScript("OnLeave", GameTooltip_Hide)
    end

    local chance = "100%"
    if maxSkill >= operationInfo.upperSkillTreshold and craftingQuality ~= maxQuality then
        local chanceSteps = 100 / maxSkillVariance
        local bottomVariance = operationInfo.upperSkillTreshold - maxSkillVariance - 1
        local skillDifference = (operationInfo.baseSkill + operationInfo.bonusSkill) - bottomVariance
        local percent = skillDifference * chanceSteps
        chance = math.floor(percent).."%"
    end

    ProfessionsSim.SkillVarianceIcon.text:SetText("Skill Variance: "..chance.." ")
    ProfessionsSim.SkillVarianceIcon.AppearIcon:SetAtlas(("GemAppear_T%d_Flipbook"):format(skillIcon))
    ProfessionsSim.SkillVarianceIcon:ClearAllPoints()
    ProfessionsSim.SkillVarianceIcon:SetPoint("CENTER", Details, "BOTTOM", 0, -43)
    ProfessionsSim.SkillVarianceIcon.AppearIcon.Anim:Restart()
end

function ProfessionsSim:ExportCraft()
    local craftData = {}
    craftData.recipeInfo = ProfessionsSim.SchematicForm.currentRecipeInfo
    craftData.transactionInfo = {}
    for index, item in pairs(ProfessionsSim.SchematicForm.transaction.reagentTbls) do
        local allocs = {}
        for i, alloc in pairs(item.allocations.allocs) do
            allocs[i] = {
                reagent = alloc.reagent,
                quantity = alloc.quantity
            }
        end
        
        craftData.transactionInfo[item.reagentSlotSchematic.slotIndex] = {
            allocs = allocs
        }
    end

    craftData.isRecraft = ProfessionsSim.SchematicForm.transaction.isRecraft
    local encodedData = ProfessionsSim:SerializeCraft(craftData)
    --print(encodedData)
    return encodedData
end

function ProfessionsSim:ImportCraft(encodedData)
    local craftData = ProfessionsSim:DeserializeCraft(encodedData)
    ProfessionsSim.RecraftOverride = craftData.isRecraft
    ProfessionsSim:HookInit(craftData.RecipeInfo)
    for slot in ProfessionsSim.SchematicForm.reagentSlotPool:EnumerateActive() do
        local slotIndex = slot:GetSlotIndex()
        if craftData.transactionInfo[slotIndex].allocs then
            for i, alloc in pairs(craftData.transactionInfo[slotIndex].allocs) do
                local reagent = alloc.reagent
                local quantity = alloc.quantity
                ProfessionsSim.SchematicForm.transaction:OverwriteAllocation(slotIndex, reagent, quantity)
            end
        end
    end
end