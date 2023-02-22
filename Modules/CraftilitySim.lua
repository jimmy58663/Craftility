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

local CraftilitySim = CraftilityNS.Craftility:NewModule("CraftilitySim", "AceConsole-3.0", "AceEvent-3.0", "AceHook-3.0")
CraftilityNS.CraftilitySim = CraftilitySim
CraftilitySim.RecraftOverride = false

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

function CraftilitySim:OnEnable()
    self:RegisterEvent("TRADE_SKILL_SHOW")
end

function CraftilitySim:TRADE_SKILL_SHOW()
    local professionInfo = Professions:GetProfessionInfo()
    if not self.SchematicForm then
        self.ShowSimButton = CreateFrame("Button", "Craftility_ShowSimButton", CraftingPage.SchematicForm, "UIPanelButtonTemplate")
        self.ShowSimButton:SetSize(120, 22)
        self.ShowSimButton:SetPoint("RIGHT", CraftingPage.SchematicForm.OptionalReagents, "BOTTOMRIGHT", 0, -10)
        self.ShowSimButton.Text:SetText("Show Sim Mode")
        self.ShowSimButton:SetScript("OnClick", CraftilitySim.ShowSimMode)
        
        self.SchematicForm = CreateFrame("Frame", "Craftility_SchematicForm", CraftingPage,"ProfessionsRecipeSchematicFormTemplate")
    
        self.SchematicForm:SetSize(799, 553)
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
        CraftilitySim:SecureHook(CraftingPage.SchematicForm,"Init", CraftilitySim.HookInit)
        CraftilitySim:SecureHook(CraftilitySim.SchematicForm, "UpdateDetailsStats", CraftilitySim.UpdateInspirationIcon)

        self.SchematicForm.Background = self.SchematicForm:CreateTexture("Background", "BACKGROUND")
        self.SchematicForm.Background:SetPoint("TOPLEFT", self.SchematicForm, "TOPLEFT")
        self.SchematicForm.Background:SetSize(799, 553)
        self.SchematicForm.Background:SetAtlas("Professions-Recipe-Background-"..professionInfo.displayName, false)

        self.HideSimButton = CreateFrame("Button", "Craftility_HideSimButton", self.SchematicForm, "UIPanelButtonTemplate")
        self.HideSimButton:SetSize(120, 22)
        self.HideSimButton:SetPoint("RIGHT", self.SchematicForm.OptionalReagents, "BOTTOMRIGHT", 0, -35)
        self.HideSimButton.Text:SetText("Hide Sim Mode")
        self.HideSimButton:SetScript("OnClick", CraftilitySim.HideSimMode)

        self.R1MatsButton = CreateFrame("Button", "Craftility_R1MatsButton", self.SchematicForm, "UIPanelButtonTemplate")
        self.R1MatsButton:SetSize(70, 22)
        self.R1MatsButton:SetPoint("LEFT", self.SchematicForm.Reagents, "BOTTOMLEFT", 0, -35)
        self.R1MatsButton.Text:SetText("R1 Mats")
        self.R1MatsButton:SetScript("OnClick", function() CraftilitySim:ChangeMaterials(1) end)

        self.R2MatsButton = CreateFrame("Button", "Craftility_R2MatsButton", self.SchematicForm, "UIPanelButtonTemplate")
        self.R2MatsButton:SetSize(70, 22)
        self.R2MatsButton:SetPoint("LEFT", self.R1MatsButton, "RIGHT", 10, 0)
        self.R2MatsButton.Text:SetText("R2 Mats")
        self.R2MatsButton:SetScript("OnClick", function() CraftilitySim:ChangeMaterials(2) end)

        self.R3MatsButton = CreateFrame("Button", "Craftility_R3MatsButton", self.SchematicForm, "UIPanelButtonTemplate")
        self.R3MatsButton:SetSize(70, 22)
        self.R3MatsButton:SetPoint("LEFT", self.R2MatsButton, "RIGHT", 10, 0)
        self.R3MatsButton.Text:SetText("R3 Mats")
        self.R3MatsButton:SetScript("OnClick", function() CraftilitySim:ChangeMaterials(3) end)

        self.RecraftCheckBox = CreateFrame("CheckButton", "Craftility_RecraftCheckBox", self.SchematicForm, "UICheckButtonTemplate")
        self.RecraftCheckBox:SetSize(26, 26)
        self.RecraftCheckBox:SetPoint("RIGHT", self.SchematicForm.OptionalReagents, "BOTTOMRIGHT", 0, -10)
        self.RecraftCheckBox.text:SetText("Show Recraft  ")
        self.RecraftCheckBox.text:SetPoint("RIGHT", self.RecraftCheckBox, "LEFT", -100, 0)
        self.RecraftCheckBox:SetScript("OnClick", function () 
            local checked = CraftilitySim.RecraftCheckBox:GetChecked()
            if not checked then
                Professions:EraseRecraftingTransitionData()
                local previousRecipeID = CraftingPage.RecipeList:GetPreviousRecipeID()
                local recipeInfo = _G.C_TradeSkillUI.GetRecipeInfo(previousRecipeID)
                CraftingPage.SchematicForm.currentRecipeInfo = recipeInfo
            end
            CraftilitySim.RecraftOverride = checked
            CraftilitySim:HookInit()
        end)

        if ElvUI == nil then
            ElvUI = _G.ElvUI
        end

        if ElvUI then
            E = _G.ElvUI[1] --Import: Engine
            S = E:GetModule("Skins")
        end
    end
    if E == nil or not E.private.skins.blizzard.tradeskill or not E.private.skins.blizzard.enable then
        self.SchematicForm.Background:SetAtlas("Professions-Recipe-Background-"..professionInfo.displayName, false)
    else
        self:ElvSkinning(self)
    end
    self.SchematicForm:Hide()
    if not CraftingPage.SchematicForm:IsShown() then
        CraftingPage.SchematicForm:Show()
    end
end

function CraftilitySim:HookInit(recipeInfo)
    --Logic is found in BlizzardInterfaceCode/Interface/AddOns/Blizzard_ProfessionsTemplates/Blizzard_ProfessionsRecipeSchematicForm.lua
    if not recipeInfo then
        CraftilitySim.currentRecipeInfo = CraftingPage.SchematicForm:GetRecipeInfo()
    else
        CraftilitySim.currentRecipeInfo = recipeInfo
    end

    if CraftingPage.SchematicForm.transaction.isRecraft then
        CraftilitySim.RecraftCheckBox:Hide()
    else
        CraftilitySim.RecraftCheckBox:Show()
    end

    CraftilitySim.SchematicForm:ClearTransaction()
    if CraftilitySim.currentRecipeInfo ~= nil then
        if CraftilitySim.RecraftOverride then
            CraftilitySim.SchematicForm:Init(CraftilitySim.currentRecipeInfo, CraftilitySim.RecraftOverride)
            CraftilitySim.SchematicForm.recraftSlot:Hide()
            CraftilitySim.SchematicForm.RecraftingOutputText:Hide()
            CraftilitySim.SchematicForm.RecraftingRequiredTools:Hide()
            CraftilitySim.SchematicForm.OutputIcon:Show()
            CraftilitySim.SchematicForm.OutputText:Show()
            CraftilitySim.SchematicForm.RequiredTools:Show()
            CraftilitySim.SchematicForm.Reagents:ClearAllPoints()
            CraftilitySim.SchematicForm.Reagents:SetPoint("TOPLEFT", CraftilitySim.SchematicForm.Description, "BOTTOMLEFT", 0, -20)
        else
            CraftilitySim.SchematicForm:Init(CraftilitySim.currentRecipeInfo)
        end
        CraftilitySim.SchematicForm:UpdateDetailsStats()
        CraftilitySim:HideUnused()
        
        local recipeID = CraftilitySim.currentRecipeInfo.recipeID
        if not CraftilitySim.currentRecipeInfo.supportsQualities or tContains(IgnoreRecipes, recipeID) then
            CraftilitySim.ShowSimButton:Hide()
        elseif CraftilitySim.currentRecipeInfo.supportsQualities then
            if not CraftilitySim.ShowSimButton:IsShown() then
                CraftilitySim.ShowSimButton:Show()
            end
            CraftilitySim:UpdateInspirationIcon()
            CraftilitySim:UpdateSkillVarianceIcon()
        end

        if CraftilitySim.currentRecipeInfo.isEnchantingRecipe then
            CraftilitySim.ShowSimButton:SetPoint("RIGHT", CraftingPage.SchematicForm.enchantSlot, "BOTTOMRIGHT", 0, -10)
            CraftilitySim.HideSimButton:SetPoint("RIGHT", CraftilitySim.SchematicForm.enchantSlot, "BOTTOMRIGHT", 0, -10)
            CraftilitySim.RecraftCheckBox:Hide()
        else
            CraftilitySim.ShowSimButton:SetPoint("RIGHT", CraftingPage.SchematicForm.OptionalReagents, "BOTTOMRIGHT", 0, -10)
            CraftilitySim.HideSimButton:SetPoint("RIGHT", CraftilitySim.SchematicForm.OptionalReagents, "BOTTOMRIGHT", 0, -35)
            CraftilitySim.RecraftCheckBox:Show()
        end

        if CraftilitySim.SchematicForm:IsShown() then
            if tContains(IgnoreRecipes, recipeID) then
                CraftilitySim.R1MatsButton:Hide()
                CraftilitySim.R2MatsButton:Hide()
                CraftilitySim.R3MatsButton:Hide()
                CraftilitySim.RecraftCheckBox:Hide()
                CraftilitySim.HideSimButton:Hide()
            else
                CraftilitySim:ChangeMaterials(1)
                CraftilitySim.R1MatsButton:Show()
                CraftilitySim.R2MatsButton:Show()
                CraftilitySim.R3MatsButton:Show()
                CraftilitySim.RecraftCheckBox:Show()
                CraftilitySim.HideSimButton:Show()
            end
        end
    end
end

function CraftilitySim:ElvSkinning(CraftilitySim)
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

    local SchematicForm = CraftilitySim.SchematicForm
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

    local ShowSimButton = CraftilitySim.ShowSimButton
    S:HandleButton(ShowSimButton)

    local HideSimButton = CraftilitySim.HideSimButton
    S:HandleButton(HideSimButton)

    local R1MatsButton = CraftilitySim.R1MatsButton
    S:HandleButton(R1MatsButton)

    local R2MatsButton = CraftilitySim.R2MatsButton
    S:HandleButton(R2MatsButton)

    local R3MatsButton = CraftilitySim.R3MatsButton
    S:HandleButton(R3MatsButton)

    local RecraftCheckBox = CraftilitySim.RecraftCheckBox
    S:HandleCheckBox(RecraftCheckBox)
    RecraftCheckBox:SetSize(24, 24)
end

function CraftilitySim:ShowSimMode()
    CraftingPage.SchematicForm:Hide()
    CraftilitySim.SchematicForm:Show()
    CraftilitySim:HideUnused()
    if CraftilitySim.SchematicForm.transaction.isRecraft then
        CraftilitySim.RecraftCheckBox:Hide()
    else
        CraftilitySim.RecraftCheckBox:Show()
    end
    CraftilitySim:ChangeMaterials(1)    
end

function CraftilitySim:HideSimMode()
    CraftilitySim.SchematicForm:Hide()
    local checked = CraftilitySim.RecraftCheckBox:GetChecked()
    if checked then
        CraftilitySim.RecraftCheckBox:SetChecked(false)
        Professions:EraseRecraftingTransitionData()
        local previousRecipeID = CraftingPage.RecipeList:GetPreviousRecipeID()
        local recipeInfo = _G.C_TradeSkillUI.GetRecipeInfo(previousRecipeID)
        CraftingPage.SchematicForm.currentRecipeInfo = recipeInfo
        CraftilitySim.RecraftOverride = false
        CraftilitySim:HookInit()
    end
    CraftingPage.SchematicForm:Show()
end

function CraftilitySim:HideUnused()
    self.SchematicForm.FavoriteButton:Hide()
    self.SchematicForm.AllocateBestQualityCheckBox:Hide()
    self.SchematicForm.TrackRecipeCheckBox:Hide()
end

function CraftilitySim:ChangeMaterials(materialRank)
    local iterator = ipairs
    if materialRank == 3 then
        iterator = ipairs_reverse
    end

    for slot in CraftilitySim.SchematicForm.reagentSlotPool:EnumerateActive() do
        local reagentSlotSchematic = slot:GetReagentSlotSchematic()
        local slotIndex = slot:GetSlotIndex()
        local quantityRequired = reagentSlotSchematic.quantityRequired
        local recipeInfo = CraftilitySim.currentRecipeInfo
        local recipeID = recipeInfo.recipeID
        if reagentSlotSchematic.reagentType == Enum.CraftingReagentType.Basic then
            if materialRank ~=2 then
                for reagentIndex, reagent in iterator(reagentSlotSchematic.reagents) do
                    CraftilitySim.SchematicForm.transaction:OverwriteAllocation(slotIndex, reagent, quantityRequired)
                    break
                end
            elseif materialRank == 2 then
                if reagentSlotSchematic.reagents[2] ~= nil then
                    CraftilitySim.SchematicForm.transaction:OverwriteAllocation(slotIndex, reagentSlotSchematic.reagents[2], quantityRequired)
                else
                    CraftilitySim.SchematicForm.transaction:OverwriteAllocation(slotIndex, reagentSlotSchematic.reagents[1], quantityRequired)
                end
            end
            slot:SetOverrideQuantity(quantityRequired)

            --This section is from BlizzardInterfaceCode/Interface/AddOns/Blizzard_ProfessionsTemplates/Blizzard_ProfessionsRecipeSchematicForm.lua
            --It overrides the item quantity checking to mock up having all reagents for simulations
            --Replace all self references with CraftilitySim.SchematicForm
            if Professions.GetReagentInputMode(reagentSlotSchematic) == Professions.ReagentInputMode.Quality then
                slot.Button:SetScript("OnClick", function(button, buttonName, down)
                    if IsShiftKeyDown() then
                        local qualityIndex = Professions.FindFirstQualityAllocated(CraftilitySim.SchematicForm.transaction, reagentSlotSchematic) or 1;
                        local handled, link = Professions.HandleQualityReagentItemLink(recipeID, reagentSlotSchematic, qualityIndex);
                        if not handled then
                            Professions.TriggerReagentClickedEvent(link);
                        end
                        return;
                    end

                    if not slot:IsUnallocatable() then
                        if buttonName == "LeftButton" then
                            local function OnAllocationsAccepted(dialog, allocations, reagentSlotSchematic)
                                CraftilitySim.SchematicForm.transaction:OverwriteAllocations(reagentSlotSchematic.slotIndex, allocations);
                                CraftilitySim.SchematicForm.transaction:SetManuallyAllocated(true);

                                slot:Update();

                                CraftilitySim.SchematicForm:TriggerEvent(ProfessionsRecipeSchematicFormMixin.Event.AllocationsModified);
                            end

                            CraftilitySim.SchematicForm.QualityDialog:RegisterCallback(ProfessionsQualityDialogMixin.Event.Accepted, OnAllocationsAccepted, slot);
                            
                            local allocationsCopy = CraftilitySim.SchematicForm.transaction:GetAllocationsCopy(slotIndex);
                            local disallowZeroAllocations = true;
                            CraftilitySim.SchematicForm.QualityDialog:Open(recipeID, reagentSlotSchematic, allocationsCopy, slotIndex, disallowZeroAllocations);

                            --Added below to override quantity and enable buttons
                            local function Allocate(qualityIndex, value)
                                local QualityDialog = CraftilitySim.SchematicForm.QualityDialog
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
                                local QualityDialog = CraftilitySim.SchematicForm.QualityDialog
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
                            CraftilitySim.SchematicForm.QualityDialog.AcceptButton:SetEnabled(true)
                        end
                    end
                end);
            end
        elseif reagentSlotSchematic.reagentType == Enum.CraftingReagentType.Optional or reagentSlotSchematic.reagentType == Enum.CraftingReagentType.Finishing then
            --This section is from BlizzardInterfaceCode/Interface/AddOns/Blizzard_ProfessionsTemplates/Blizzard_ProfessionsRecipeSchematicForm.lua
            --It overrides the item quantity checking to mock up having all reagents for simulations
            --Replace all self references with CraftilitySim.SchematicForm
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
									CraftilitySim.SchematicForm.transaction:OverwriteAllocation(slotIndex, reagent, reagentSlotSchematic.quantityRequired);
									
									slot:SetItem(item);

									CraftilitySim.SchematicForm:TriggerEvent(ProfessionsRecipeSchematicFormMixin.Event.AllocationsModified);
								end

								local modification = CraftilitySim.SchematicForm.transaction:GetModification(reagentSlotSchematic.dataSlotIndex);
								local allocate = not (modification and CraftilitySim.SchematicForm.transaction:HasAllocatedItemID(modification.itemID));
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
								Professions.FlyoutOnElementEnterImplementation(elementData, tooltip, recipeID, CraftilitySim.SchematicForm.transaction:GetAllocationItemGUID());
							end

							flyout.OnElementEnabledImplementation = nil;

							flyout:Init(slot.Button, CraftilitySim.SchematicForm.transaction);
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
						if CraftilitySim.SchematicForm.transaction:HasAllocations(slotIndex) then
							local function Deallocate()
								CraftilitySim.SchematicForm.transaction:ClearAllocations(slotIndex);

								slot:ClearItem();

								CraftilitySim.SchematicForm:TriggerEvent(ProfessionsRecipeSchematicFormMixin.Event.AllocationsModified);
							end
							
							local modification = CraftilitySim.SchematicForm.transaction:GetModification(reagentSlotSchematic.dataSlotIndex);
							local allocate = not (modification and CraftilitySim.SchematicForm.transaction:HasAllocatedItemID(modification.itemID));
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
    CraftilitySim.SchematicForm:UpdateAllSlots()
    CraftilitySim.SchematicForm:UpdateDetailsStats()
end

function CraftilitySim:SerializeCraft(data)
    local serializedData = AceSerializer:Serialize(data)
    local compressedData = libC:Compress(serializedData)
    local encodedData = EncodeTable:Encode(compressedData)
    return encodedData
end

function CraftilitySim:DeserializeCraft(encodedData)
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

function CraftilitySim:UpdateInspirationIcon()
    if not CraftilitySim.currentRecipeInfo.supportsQualities then
        return
    end
    local Details = CraftilitySim.SchematicForm.Details
    local operationInfo = Details.operationInfo
    local craftingQuality = operationInfo.craftingQuality
    local maxQuality = CraftilitySim.currentRecipeInfo.maxQuality
    local maxDifficulty = operationInfo.baseDifficulty + operationInfo.bonusDifficulty

    local inspirationPercent = nil
    local inspirationSkill = nil
    for _, bonusStat in ipairs(operationInfo.bonusStats) do
        if bonusStat.bonusStatName == "Inspiration" then
            inspirationPercent, inspirationSkill = bonusStat.ratingDescription:match("(%d*%.%d*%%)%D*(%d[%d]*)")
            inspirationSkill = tonumber(inspirationSkill)
        end
    end

    if craftingQuality ~= maxQuality then
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

    if not CraftilitySim.InspirationIcon then
        CraftilitySim.InspirationIcon = CreateFrame("Frame", "Craftility_InspirationIcon", Details, "ProfessionsQualityMeterCapTemplate")
        CraftilitySim.InspirationIcon.text = CraftilitySim.InspirationIcon:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
        CraftilitySim.InspirationIcon.text:SetSize("140", "20")
        CraftilitySim.InspirationIcon.text:SetPoint("RIGHT", CraftilitySim.InspirationIcon, "LEFT")
        CraftilitySim.InspirationIcon.text:SetText("Inspiration Result: ")
    end
    CraftilitySim.InspirationIcon.AppearIcon:SetAtlas(("GemAppear_T%d_Flipbook"):format(craftingQuality))
    CraftilitySim.InspirationIcon:ClearAllPoints()
    CraftilitySim.InspirationIcon:SetPoint("CENTER", Details, "BOTTOM", 0, -14)
    CraftilitySim.InspirationIcon.AppearIcon.Anim:Restart()
    CraftilitySim:UpdateSkillVarianceIcon()
end

function CraftilitySim:UpdateSkillVarianceIcon()
    if not CraftilitySim.currentRecipeInfo.supportsQualities then
        return
    end
    local Details = CraftilitySim.SchematicForm.Details
    local operationInfo = Details.operationInfo
    local craftingQuality = operationInfo.craftingQuality
    local maxQuality = CraftilitySim.currentRecipeInfo.maxQuality
    local maxDifficulty = operationInfo.baseDifficulty + operationInfo.bonusDifficulty
    local maxSkillVariance = maxDifficulty * .05
    local maxSkill = operationInfo.baseSkill + operationInfo.bonusSkill + maxSkillVariance

    local skillIcon = craftingQuality
    if maxSkill >= operationInfo.upperSkillTreshold and craftingQuality ~= maxQuality then
        skillIcon = craftingQuality + 1
    end

    if not CraftilitySim.SkillVarianceIcon then
        CraftilitySim.SkillVarianceIcon = CreateFrame("Frame", "Craftility_SkillVarianaceIcon", Details, "ProfessionsQualityMeterCapTemplate")
        CraftilitySim.SkillVarianceIcon.text = CraftilitySim.SkillVarianceIcon:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
        CraftilitySim.SkillVarianceIcon.text:SetSize("140", "20")
        CraftilitySim.SkillVarianceIcon.text:SetPoint("RIGHT", CraftilitySim.SkillVarianceIcon, "LEFT")
        CraftilitySim.SkillVarianceIcon.text:SetText("Skill Variance: ")

        CraftilitySim.SkillVarianceIcon:SetScript("OnEnter", function(icon) 
            GameTooltip:SetOwner(icon, "ANCHOR_RIGHT")
            GameTooltip_SetTitle(GameTooltip, "EXPERIMENTAL:")
            GameTooltip_AddNormalLine(GameTooltip, "Craft with up to "..(math.floor(((CraftilitySim.SchematicForm.Details.operationInfo.baseDifficulty + CraftilitySim.SchematicForm.Details.operationInfo.bonusDifficulty)*.05))).." additional skill.")
            GameTooltip:Show()
        end)

        CraftilitySim.SkillVarianceIcon:SetScript("OnLeave", GameTooltip_Hide)
    end

    local chance = "100%"
    if maxSkill >= operationInfo.upperSkillTreshold and craftingQuality ~= maxQuality then
        local chanceSteps = 100 / maxSkillVariance
        local bottomVariance = operationInfo.upperSkillTreshold - maxSkillVariance - 1
        local skillDifference = (operationInfo.baseSkill + operationInfo.bonusSkill) - bottomVariance
        local percent = skillDifference * chanceSteps
        chance = math.floor(percent).."%"
    end

    CraftilitySim.SkillVarianceIcon.text:SetText("Skill Variance: "..chance.." ")
    CraftilitySim.SkillVarianceIcon.AppearIcon:SetAtlas(("GemAppear_T%d_Flipbook"):format(skillIcon))
    CraftilitySim.SkillVarianceIcon:ClearAllPoints()
    CraftilitySim.SkillVarianceIcon:SetPoint("CENTER", Details, "BOTTOM", 0, -43)
    CraftilitySim.SkillVarianceIcon.AppearIcon.Anim:Restart()
end

function CraftilitySim:ExportCraft()
    local craftData = {}
    craftData.recipeInfo = CraftilitySim.SchematicForm.currentRecipeInfo
    craftData.transactionInfo = {}
    for index, item in pairs(CraftilitySim.SchematicForm.transaction.reagentTbls) do
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

    craftData.isRecraft = CraftilitySim.SchematicForm.transaction.isRecraft
    local encodedData = CraftilitySim:SerializeCraft(craftData)
    --print(encodedData)
    return encodedData
end

function CraftilitySim:ImportCraft(encodedData)
    local craftData = CraftilitySim:DeserializeCraft(encodedData)
    CraftilitySim.RecraftOverride = craftData.isRecraft
    CraftilitySim:HookInit(craftData.RecipeInfo)
    for slot in CraftilitySim.SchematicForm.reagentSlotPool:EnumerateActive() do
        local slotIndex = slot:GetSlotIndex()
        if craftData.transactionInfo[slotIndex].allocs then
            for i, alloc in pairs(craftData.transactionInfo[slotIndex].allocs) do
                local reagent = alloc.reagent
                local quantity = alloc.quantity
                CraftilitySim.SchematicForm.transaction:OverwriteAllocation(slotIndex, reagent, quantity)
            end
        end
    end
end