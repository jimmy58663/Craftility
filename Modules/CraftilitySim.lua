local addon, CraftilityNS = ...
local _G = _G
local E, L, V, P, G = nil --Import: Engine, Locales, PrivateDB, ProfileDB, GlobalDB from ElvUI when frames are initialized
local S = nil -- Import: ElvUI Skins module when frames are initialized
local AceSerializer = LibStub:GetLibrary("AceSerializer-3.0")
local libC = LibStub:GetLibrary("LibCompress")
local EncodeTable = libC:GetAddonEncodeTable()
local CraftingPage = _G.ProfessionsFrame.CraftingPage
local Professions = _G.Professions

local CraftilitySim = CraftilityNS.Craftility:NewModule("CraftilitySim", "AceConsole-3.0", "AceEvent-3.0", "AceHook-3.0")
CraftilityNS.CraftilitySim = CraftilitySim
CraftilitySim.IsInitialized = false
CraftilitySim.RecraftOverride = false

function CraftilitySim:OnEnable()
    self:RegisterEvent("TRADE_SKILL_SHOW")
end

function CraftilitySim:TRADE_SKILL_SHOW()
    self.Profession = _G.ProfessionsFrame.professionInfo.profession

    if not self.IsInitialized then
        self.ShowSimButton = CreateFrame("Button", "Craftility_ShowSimButton", CraftingPage.SchematicForm, "UIPanelButtonTemplate")
        self.ShowSimButton:SetSize(120, 22)
        self.ShowSimButton:SetPoint("LEFT", CraftingPage.SchematicForm.Details, "BOTTOMLEFT", -125, 30)
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

        self.SchematicForm.Background = self.SchematicForm:CreateTexture("Background", "BACKGROUND")
        self.SchematicForm.Background:SetPoint("TOPLEFT", self.SchematicForm, "TOPLEFT")
        self.SchematicForm.Background:SetSize(799, 553)
        self.SchematicForm.Background:SetAtlas("Professions-Recipe-Background-".._G.ProfessionsFrame.professionInfo.displayName, false)

        if E == nil then
            E, L, V, P, G = unpack(ElvUI) --Import: Engine, Locales, PrivateDB, ProfileDB, GlobalDB
            S = E:GetModule("Skins")
        end

        self.HideSimButton = CreateFrame("Button", "Craftility_HideSimButton", self.SchematicForm, "UIPanelButtonTemplate")
        self.HideSimButton:SetSize(120, 22)
        self.HideSimButton:SetPoint("LEFT", self.SchematicForm.Details, "BOTTOMLEFT", -125, 30)
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
        self.RecraftCheckBox:SetPoint("LEFT", self.HideSimButton, "TOPLEFT", 0, 25)
        self.RecraftCheckBox.text:SetText("  Show Recraft")
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

        self.IsInitialized = true
    end
    if E == nil or not E.private.skins.blizzard.tradeskill or not E.private.skins.blizzard.enable then
        self.SchematicForm.Background:SetAtlas("Professions-Recipe-Background-".._G.ProfessionsFrame.professionInfo.displayName, false)
    else
        self:ElvSkinning(self)
    end
    self.SchematicForm:Hide()
    if not CraftingPage.SchematicForm:IsShown() then
        CraftingPage.SchematicForm:Show()
    end
end

function CraftilitySim:HookInit()
    --Logic is found in BlizzardInterfaceCode/Interface/AddOns/Blizzard_ProfessionsTemplates/Blizzard_ProfessionsRecipeSchematicForm.lua
    CraftilitySim.currentRecipeInfo = CraftingPage.SchematicForm:GetRecipeInfo()
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
        else
            CraftilitySim.SchematicForm:Init(CraftilitySim.currentRecipeInfo)
        end
        CraftilitySim.SchematicForm:UpdateDetailsStats()
        CraftilitySim:HideUnused()
        
        if not CraftilitySim.currentRecipeInfo.supportsQualities then
            CraftilitySim.ShowSimButton:Hide()
        elseif CraftilitySim.currentRecipeInfo.supportsQualities and not CraftilitySim.ShowSimButton:IsShown() then
            CraftilitySim.ShowSimButton:Show()
        end

        if CraftilitySim.SchematicForm:IsShown() then
            CraftilitySim:ChangeMaterials(1)
            if CraftilitySim.currentRecipeInfo.recipeID == 385304 then
                CraftilitySim.R1MatsButton:Hide()
                CraftilitySim.R2MatsButton:Hide()
                CraftilitySim.R3MatsButton:Hide()
                CraftilitySim.RecraftCheckBox:Hide()
                CraftilitySim.HideSimButton:Hide()
            else
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
    CraftilitySim:ChangeMaterials(1)    
end

function CraftilitySim:HideSimMode()
    CraftilitySim.SchematicForm:Hide()
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
                        for qualityIndex, reagent in ipairs(reagentSlotSchematic.reagents) do
                            local container = CraftilitySim.SchematicForm.QualityDialog.containers[qualityIndex]
                            local reagentButton = container.Button
                            local editBox = container.EditBox
                            reagentButton:SetItemButtonCount(quantityRequired)
                            reagentButton:DesaturateHierarchy(0)
                            editBox:SetEnabled(true)
                            editBox:SetMinMaxValues(0, quantityRequired)
                        end
                        CraftilitySim.SchematicForm.QualityDialog.AcceptButton:SetEnabled(true)
                    end
                end
            end);
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
    CraftilitySim:Print(encodedData)
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
    CraftilitySim:Print(data)
end