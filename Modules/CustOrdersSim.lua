local addon, CraftilityNS = ...
local _G = _G
local ElvUI = nil -- Import: ElvUI if it is loaded when frames are initialized
local E = nil -- Import: ElvUI Engine module when frames are initialized
local S = nil -- Import: ElvUI Skins module when frames are initialized

local CustOrdersSim = CraftilityNS.Craftility:NewModule("CustOrdersSim", "AceConsole-3.0", "AceEvent-3.0", "AceHook-3.0", "AceComm-3.0")
CraftilityNS.CustOrdersSim = CustOrdersSim
local CustOrdersFrame = nil
CustOrdersSim.RecraftOverride = false
CustOrdersSim.CrafterSelected = false
CustOrdersSim.OriginalRecraft = false

function CustOrdersSim:OnEnable()
    self:RegisterEvent("CRAFTINGORDERS_SHOW_CUSTOMER")
    self:RegisterEvent("CRAFTINGORDERS_HIDE_CUSTOMER")
    self:RegisterMessage("CRAFTILITY_INITIALIZE")
end

function CustOrdersSim:CRAFTILITY_INITIALIZE()
    CustOrdersFrame = _G.ProfessionsCustomerOrdersFrame
    if CustOrdersFrame and not CustOrdersSim.ShowSimButton then
        self:InitializeButtons()
        self:SecureHook(CustOrdersFrame.Form, "Init", CustOrdersSim.HookInit)
        self:SecureHook(CustOrdersFrame.Form, "SetRecraftItemGUID", CustOrdersSim.HookRecraft)
    end
end

function CustOrdersSim:CRAFTINGORDERS_SHOW_CUSTOMER()
end

function CustOrdersSim:CRAFTINGORDERS_HIDE_CUSTOMER()
    CustOrdersSim.Form:Hide()
end

function CustOrdersSim:InitializeButtons()
    self.Form = CreateFrame("Frame", "Craftility_Form", CustOrdersFrame,"ProfessionsCustomerOrderFormTemplate")
    local formFrameLevel = CustOrdersFrame.Form:GetFrameLevel()
    self.Form:SetFrameLevel(formFrameLevel + 1)
    self.Form:SetPoint("TOPLEFT", CustOrdersFrame, "TOPLEFT", 5, -60)
    self.Form:Hide()

    CustOrdersSim:RawHook(self.Form, "GetPendingRecraftItemQuality", CustOrdersSim.GetPendingRecraftItemQuality, true)

    self.ShowSimButton = CreateFrame("Button", "Craftility_ShowSimButton", CustOrdersFrame.Form, "UIPanelButtonTemplate")
    self.ShowSimButton:SetSize(120, 22)
    self.ShowSimButton:SetPoint("RIGHT", CustOrdersFrame.Form.ReagentContainer.OptionalReagents, "BOTTOMRIGHT", 0, -10)
    self.ShowSimButton.Text:SetText("Show Sim Mode")
    self.ShowSimButton:SetScript("OnClick", CustOrdersSim.ShowSimMode)

    self.HideSimButton = CreateFrame("Button", "Craftility_HideSimButton", self.Form, "UIPanelButtonTemplate")
    self.HideSimButton:SetSize(120, 22)
    self.HideSimButton:SetPoint("RIGHT", self.Form.ReagentContainer.OptionalReagents, "BOTTOMRIGHT", 0, -35)
    self.HideSimButton.Text:SetText("Hide Sim Mode")
    self.HideSimButton:SetScript("OnClick", CustOrdersSim.HideSimMode)

    self.R1MatsButton = CreateFrame("Button", "Craftility_R1MatsButton", self.Form, "UIPanelButtonTemplate")
    self.R1MatsButton:SetSize(70, 22)
    self.R1MatsButton:SetPoint("LEFT", self.Form.ReagentContainer.Reagents, "BOTTOMLEFT", 0, -10)
    self.R1MatsButton.Text:SetText("R1 Mats")
    self.R1MatsButton:SetScript("OnClick", function() CustOrdersSim:ChangeMaterials(1) end)

    self.R2MatsButton = CreateFrame("Button", "Craftility_R2MatsButton", self.Form, "UIPanelButtonTemplate")
    self.R2MatsButton:SetSize(70, 22)
    self.R2MatsButton:SetPoint("LEFT", self.R1MatsButton, "RIGHT", 10, 0)
    self.R2MatsButton.Text:SetText("R2 Mats")
    self.R2MatsButton:SetScript("OnClick", function() CustOrdersSim:ChangeMaterials(2) end)

    self.R3MatsButton = CreateFrame("Button", "Craftility_R3MatsButton", self.Form, "UIPanelButtonTemplate")
    self.R3MatsButton:SetSize(70, 22)
    self.R3MatsButton:SetPoint("LEFT", self.R2MatsButton, "RIGHT", 10, 0)
    self.R3MatsButton.Text:SetText("R3 Mats")
    self.R3MatsButton:SetScript("OnClick", function() CustOrdersSim:ChangeMaterials(3) end)

    self.Form.BackButton:SetScript("OnClick", function()
        self.Form:Hide()
        CustOrdersFrame:ShowCurrentPage()
    end)

    self.Details = CreateFrame("Frame", "Craftility_Details", self.Form, "ProfessionsRecipeCrafterDetailsTemplate")
    self.Details:SetPoint("BOTTOMRIGHT", self.Form, "BOTTOMRIGHT", -15, 15)
    local qualityFrameLevel = self.Details.QualityMeter:GetFrameLevel()
    self.Details.QualityMeter.Center:SetFrameLevel(qualityFrameLevel + 1)
    self.Details.QualityMeter.InteriorMask:SetFrameLevel(qualityFrameLevel + 1)
    self.Details.QualityMeter.DividerGlow:SetFrameLevel(qualityFrameLevel + 2)
    self.Details.QualityMeter.Border:SetFrameLevel(qualityFrameLevel + 3)
    self.Details.QualityMeter.Marker:SetFrameLevel(qualityFrameLevel + 4)
    self.Details.QualityMeter.Flare:SetFrameLevel(qualityFrameLevel + 5)
    self.Details.QualityMeter.Left:SetFrameLevel(qualityFrameLevel + 6)
    self.Details.QualityMeter.Right:SetFrameLevel(qualityFrameLevel + 7)
    self.Details:Layout()

    self.RecraftCheckBox = CreateFrame("CheckButton", "Craftility_RecraftCheckBox", self.Form, "UICheckButtonTemplate")
    self.RecraftCheckBox:SetSize(26, 26)
    self.RecraftCheckBox:SetPoint("RIGHT", self.Form.ReagentContainer.OptionalReagents, "BOTTOMRIGHT", 0, -10)
    self.RecraftCheckBox.text:SetText("Show Recraft  ")
    self.RecraftCheckBox.text:SetPoint("RIGHT", self.RecraftCheckBox, "LEFT", -100, 0)
    self.RecraftCheckBox:SetScript("OnClick", function () 
        local checked = CustOrdersSim.RecraftCheckBox:GetChecked()
        CustOrdersSim.RecraftOverride = checked
        if checked then
            CustOrdersSim:HookRecraft()
        else
            Professions:EraseRecraftingTransitionData()
            CustOrdersFrame.Form.order.isRecraft = false
            CustOrdersSim:HookInit(CustOrdersFrame.Form.order)
        end
    end)

    if ElvUI == nil then
        ElvUI = _G.ElvUI
    end

    if ElvUI then
        E = _G.ElvUI[1] --Import: Engine
        S = E:GetModule("Skins")
        if not E.private.skins.blizzard.tradeskill or not E.private.skins.blizzard.enable then
        else
            self:ElvSkinning(self)
        end
    end
end

function CustOrdersSim:HookInit(order)
    --CustOrdersSim.currentRecipeInfo = C_TradeSkillUI.GetRecipeInfo(CustOrdersFrame.Form.transaction.recipeID)
    CustOrdersSim.Form:Init(order)

    if order.spellID then
        CustOrdersSim.ShowSimButton:Show()
        CustOrdersSim.recipeSchematic = order.spellID and C_TradeSkillUI.GetRecipeSchematic(order.spellID, order.isRecraft)
        CustOrdersSim:ChangeMaterials(1)
        if CustOrdersSim.CrafterSelected then
            CustOrdersSim.Details:SetData(order.transaction, CustOrdersSim.currentRecipeInfo, false)
            CustOrdersSim.operationInfo = CustOrdersSim:GetRecipeOperationInfo()
            CustOrdersSim:UpdateDetailsStats(CustOrdersSim.operationInfo)
        else
            CustOrdersSim.Details:Hide()
        end
    else
        CustOrdersSim.ShowSimButton:Hide()
    end
    CustOrdersSim:HideUnused()
end

function CustOrdersSim:HideUnused()
    self.Form.FavoriteButton:Hide()
    self.Form.TrackRecipeCheckBox:Hide()
    self.Form.PaymentContainer:Hide()
    self.Form.OrderRecipientDropDown:Hide()
    self.Form.MinimumQuality:Hide()
    self.Form.AllocateBestQualityCheckBox:Hide()
end

function CustOrdersSim:ShowSimMode()
    CustOrdersSim.OriginalRecraft = CustOrdersFrame.Form.order.isRecraft
    CustOrdersFrame.Form:Hide()
    CustOrdersFrame.Form.order.isRecraft = false
    CustOrdersSim:HookInit(CustOrdersFrame.Form.order)
    CustOrdersFrame.Form.order.isRecraft = CustOrdersSim.OriginalRecraft
    CustOrdersSim.Form:Show()
    if CustOrdersFrame.Form.order.isRecraft then
        CustOrdersSim:HookInit(CustOrdersFrame.Form.order)
        CustOrdersSim.RecraftCheckBox:Hide()
        CustOrdersSim.Form.RecraftRecipeName:Hide()
        CustOrdersSim.Form.RecraftSlot:Hide()

        CustOrdersSim.Form.RecipeName:Show()
        CustOrdersSim.Form.ProfessionText:SetPoint("TOPLEFT", CustOrdersSim.Form.RecipeName, "BOTTOMLEFT", 0, -5)
        CustOrdersSim.Form.OutputIcon:Show()
    else
        CustOrdersSim.RecraftCheckBox:Show()
    end
end

function CustOrdersSim:HideSimMode()
    CustOrdersSim.Form:Hide()
    CustOrdersSim.RecraftCheckBox:SetChecked(false)
    CustOrdersSim.RecraftOverride = false
    Professions:EraseRecraftingTransitionData()
    CustOrdersFrame.Form.order.isRecraft = CustOrdersSim.OriginalRecraft
    CustOrdersSim.Form:Init(CustOrdersFrame.Form.order)
    CustOrdersFrame.Form:Show()
end

function CustOrdersSim:ChangeMaterials(materialRank)
    local iterator = ipairs
    local order = CustOrdersSim.Form.order
    if materialRank == 3 then
        iterator = ipairs_reverse
    end

    local recipeID = order.spellID

    for slot in CustOrdersSim.Form.reagentSlotPool:EnumerateActive() do
        local reagentSlotSchematic = slot:GetReagentSlotSchematic()
        local slotIndex = slot:GetSlotIndex()
        local quantityRequired = reagentSlotSchematic.quantityRequired
        
        if reagentSlotSchematic.reagentType == Enum.CraftingReagentType.Basic then
            if materialRank ~=2 then
                for reagentIndex, reagent in iterator(reagentSlotSchematic.reagents) do
                    CustOrdersSim.Form.transaction:OverwriteAllocation(slotIndex, reagent, quantityRequired)
                    break
                end
            elseif materialRank == 2 then
                if reagentSlotSchematic.reagents[2] ~= nil then
                    CustOrdersSim.Form.transaction:OverwriteAllocation(slotIndex, reagentSlotSchematic.reagents[2], quantityRequired)
                else
                    CustOrdersSim.Form.transaction:OverwriteAllocation(slotIndex, reagentSlotSchematic.reagents[1], quantityRequired)
                end
            end
            slot:SetOverrideQuantity(quantityRequired)

            --This section is from BlizzardInterfaceCode/Interface/AddOns/Blizzard_ProfessionsTemplates/Blizzard_ProfessionsRecipeSchematicForm.lua
            --It overrides the item quantity checking to mock up having all reagents for simulations
            --Replace all self references with ProfessionsSim.SchematicForm
            if Professions.GetReagentInputMode(reagentSlotSchematic) == Professions.ReagentInputMode.Quality then
                slot.Button:SetScript("OnClick", function(button, buttonName, down)
                if IsShiftKeyDown() then
                    local qualityIndex = Professions.FindFirstQualityAllocated(CustOrdersSim.Form.transaction, reagentSlotSchematic) or 1;
                    local handled, link = Professions.HandleQualityReagentItemLink(recipeID, reagentSlotSchematic, qualityIndex);
                    if not handled then
                        Professions.TriggerReagentClickedEvent(link);
                    end
                    return;
                end

                if not slot:IsUnallocatable() then
                    if buttonName == "LeftButton" then
                        local function OnAllocationsAccepted(dialog, allocations, reagentSlotSchematic)
                            CustOrdersSim.Form.transaction:OverwriteAllocations(reagentSlotSchematic.slotIndex, allocations);
                            CustOrdersSim.Form.transaction:SetManuallyAllocated(true);

                            slot:Update();
                            CustOrdersSim:UpdateDetailsStats()
                        end

                        CustOrdersSim.Form.QualityDialog:RegisterCallback(ProfessionsQualityDialogMixin.Event.Accepted, OnAllocationsAccepted, slot);
                        
                        local allocationsCopy = CustOrdersSim.Form.transaction:GetAllocationsCopy(slotIndex);
                        local disallowZeroAllocations = true;
                        CustOrdersSim.Form.QualityDialog:Open(recipeID, reagentSlotSchematic, allocationsCopy, slotIndex, disallowZeroAllocations);

                        --Added below to override quantity and enable buttons
                        local function Allocate(qualityIndex, value)
                            local QualityDialog = CustOrdersSim.Form.QualityDialog
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
                            local QualityDialog = CustOrdersSim.Form.QualityDialog
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
                        CustOrdersSim.Form.QualityDialog.AcceptButton:SetEnabled(true)
                    end
                end
                end);
            end
        elseif reagentSlotSchematic.reagentType == Enum.CraftingReagentType.Optional or reagentSlotSchematic.reagentType == Enum.CraftingReagentType.Finishing then
            --This section is from BlizzardInterfaceCode/Interface/AddOns/Blizzard_ProfessionsTemplates/Blizzard_ProfessionsRecipeSchematicForm.lua
            --It overrides the item quantity checking to mock up having all reagents for simulations
            --Replace all self references with ProfessionsSim.SchematicForm
            slot.Button:SetScript("OnMouseDown", function(button, buttonName, down)
				if not slot:IsUnallocatable() then
					if buttonName == "LeftButton" then
						local flyout = ToggleProfessionsItemFlyout(slot.Button, CustOrdersFrame);
						if flyout then
							local function OnFlyoutItemSelected(o, flyout, elementData)
								local item = elementData.item;
								
								local function AllocateFlyoutItem()
									--This section is commented out to override quantity checking
                                    --[[if ItemUtil.GetCraftingReagentCount(item:GetItemID()) == 0 then
										return;
									end]]

									local reagent = Professions.CreateCraftingReagentByItemID(item:GetItemID());
									CustOrdersSim.Form.transaction:OverwriteAllocation(slotIndex, reagent, reagentSlotSchematic.quantityRequired);
									
									slot:SetItem(item);
                                    CustOrdersSim:UpdateDetailsStats()
								end

								local modification = CustOrdersSim.Form.transaction:GetModification(reagentSlotSchematic.dataSlotIndex);
								local allocate = not (modification and CustOrdersSim.Form.transaction:HasAllocatedItemID(modification.itemID));
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
								Professions.FlyoutOnElementEnterImplementation(elementData, tooltip, recipeID, CustOrdersSim.Form.transaction:GetAllocationItemGUID());
							end

							flyout.OnElementEnabledImplementation = nil;

							flyout:Init(slot.Button, CustOrdersSim.Form.transaction);
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
						if CustOrdersSim.Form.transaction:HasAllocations(slotIndex) then
							local function Deallocate()
								CustOrdersSim.Form.transaction:ClearAllocations(slotIndex);

								slot:ClearItem();
                                CustOrdersSim:UpdateDetailsStats()
							end
							
							local modification = CustOrdersSim.Form.transaction:GetModification(reagentSlotSchematic.dataSlotIndex);
							local allocate = not (modification and CustOrdersSim.Form.transaction:HasAllocatedItemID(modification.itemID));
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
        slot:SetOverrideNameColor(HIGHLIGHT_FONT_COLOR)
        slot.Checkbox:Hide()
        slot:Update()
    end
    CustOrdersSim:UpdateDetailsStats()
end

function CustOrdersSim:UpdateDetailsStats(operationInfo)
    if not CustOrdersSim.CrafterSelected then
        return
    end
    if not operationInfo then
        operationInfo = CustOrdersSim:GetRecipeOperationInfo()
    end

    self.Details:SetStats(operationInfo, self.currentRecipeInfo.supportsQualities, self.currentRecipeInfo.isGatheringRecipe)
end

function CustOrdersSim:GetRecipeOperationInfo()
    local recipeInfo = self.currentRecipeInfo;
	if recipeInfo then
		if self.recipeSchematic.hasGatheringOperationInfo then
			return C_TradeSkillUI.GetGatheringOperationInfo(recipeInfo.recipeID);
		elseif self.recipeSchematic.hasCraftingOperationInfo then
			local recraftItemGUID, recraftOrderID = self.Form.transaction:GetRecraftAllocation();
			if recraftOrderID then
				return C_TradeSkillUI.GetCraftingOperationInfoForOrder(recipeInfo.recipeID, self.Form.transaction:CreateCraftingReagentInfoTbl(), recraftOrderID);
			else
				return C_TradeSkillUI.GetCraftingOperationInfo(recipeInfo.recipeID, self.Form.transaction:CreateCraftingReagentInfoTbl(), self.Form.transaction:GetAllocationItemGUID());
			end
		end
	end
end

function CustOrdersSim:HookRecraft()
    CustOrdersSim.Form.order = CustOrdersFrame.Form.order
    if CustOrdersSim.RecraftOverride then
        CustOrdersSim.Form.order.isRecraft = CustOrdersSim.RecraftOverride
    end
    CustOrdersSim.ShowSimButton:Show()
    CustOrdersSim.Form:InitSchematic()
    CustOrdersSim.Form:SetupQualityDropDown()
    CustOrdersSim.Form:UpdateMinimumQuality()
    CustOrdersSim:ChangeMaterials(1)
    
    --Hide recraft info
    CustOrdersSim.Form.RecraftRecipeName:Hide()
    CustOrdersSim.Form.RecraftSlot:Hide()
    CustOrdersSim:HideUnused()

    --Show normal craft info
    CustOrdersSim.Form.RecipeName:Show()
    CustOrdersSim.Form.ProfessionText:SetPoint("TOPLEFT", CustOrdersSim.Form.RecipeName, "BOTTOMLEFT", 0, -5)
    CustOrdersSim.Form.OutputIcon:Show()
end

function CustOrdersSim:GetPendingRecraftItemQuality()
	local item = nil
    if self.recraftGUID then
        item = Item:CreateFromItemGUID(self.recraftGUID);
    else
        local recipeID = CustOrdersFrame.Form.order.spellID
        local reagents = nil
        local outputItemInfo = C_TradeSkillUI.GetRecipeOutputItemData(recipeID, reagents)
        item = Item:CreateFromItemLink(outputItemInfo.hyperlink)
    end
	return C_TradeSkillUI.GetItemCraftedQualityByItemInfo(item:GetItemLink());
end

function CustOrdersSim:ElvSkinning(frame)
    --The below is from ElvUI/Mainline/Modules/Skins/ProfessionsOrders.lua
    local hooksecurefunc = hooksecurefunc

    local function HandleListHeader(headerContainer)
        local maxHeaders = headerContainer:GetNumChildren()
    
        for i, header in next, { headerContainer:GetChildren() } do
            if not header.isSkinned then
                header:DisableDrawLayer('BACKGROUND')
                header:CreateBackdrop('Transparent')
    
                local highlight = header:GetHighlightTexture()
                highlight:SetColorTexture(1, 1, 1, .1)
                highlight:SetAllPoints(header.backdrop)
    
                header.isSkinned = true
            end
    
            if header.backdrop then
                header.backdrop:SetPoint('BOTTOMRIGHT', i < maxHeaders and -5 or 0, -2)
            end
        end
    end

    local function HandleMoneyInput(box)
        S:HandleEditBox(box)
    
        box.backdrop:SetPoint('TOPLEFT', 0, -3)
        box.backdrop:SetPoint('BOTTOMRIGHT', 0, 3)
    end

    local function FormInit(form)
        for slot in form.reagentSlotPool:EnumerateActive() do
            local button = slot and slot.Button
            if button and not button.IsSkinned then
                button:SetNormalTexture(0)
                button:SetPushedTexture(0)
                S:HandleIcon(button.Icon, true)
                S:HandleIconBorder(button.IconBorder, button.Icon.backdrop)
    
                if button.SlotBackground then
                    button.SlotBackground:Hide()
                end
    
                if button.HighlightTexture then
                    button.HighlightTexture:SetAlpha(0)
                end
    
                local highlight = button:GetHighlightTexture()
                highlight:SetColorTexture(1, 1, 1, .25)
                highlight:SetAllPoints(button)
    
                S:HandleCheckBox(slot.Checkbox)
    
                button.IsSkinned = true
            end
        end
    end

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

    -- Form
	S:HandleButton(frame.Form.BackButton)
	S:HandleCheckBox(frame.Form.TrackRecipeCheckBox.Checkbox)
	frame.Form.RecipeHeader:Hide()
	frame.Form.RecipeHeader:CreateBackdrop('Transparent')
	frame.Form.LeftPanelBackground:StripTextures()
	frame.Form.LeftPanelBackground:CreateBackdrop('Transparent')
	frame.Form.LeftPanelBackground.backdrop:SetInside(nil, 2, 2)
	frame.Form.RightPanelBackground:StripTextures()
	frame.Form.RightPanelBackground:CreateBackdrop('Transparent')
	frame.Form.RightPanelBackground.backdrop:SetInside(nil, 2, 2)

	local itemButton = frame.Form.OutputIcon
	itemButton.CircleMask:Hide()
	S:HandleIcon(itemButton.Icon, true)
	S:HandleIconBorder(itemButton.IconBorder, itemButton.Icon.backdrop)

	local itemHighlight = itemButton:GetHighlightTexture()
	itemHighlight:SetColorTexture(1, 1, 1, .25)
	itemHighlight:SetInside(itemButton.backdrop)

	S:HandleEditBox(frame.Form.OrderRecipientTarget)
	frame.Form.OrderRecipientTarget.backdrop:SetPoint('TOPLEFT', -8, -2)
	frame.Form.OrderRecipientTarget.backdrop:SetPoint('BOTTOMRIGHT', 0, 2)

	local payment = frame.Form.PaymentContainer
	if payment then
		payment.NoteEditBox:StripTextures()
		payment.NoteEditBox:CreateBackdrop('Transparent')
		payment.NoteEditBox.backdrop:SetPoint('TOPLEFT', 15, 5)
		payment.NoteEditBox.backdrop:SetPoint('BOTTOMRIGHT', -18, 0)
	end

	S:HandleDropDownBox(frame.Form.MinimumQuality.DropDown)
	S:HandleDropDownBox(frame.Form.OrderRecipientDropDown)
	HandleMoneyInput(payment.TipMoneyInputFrame.GoldBox)
	HandleMoneyInput(payment.TipMoneyInputFrame.SilverBox)
	S:HandleDropDownBox(payment.DurationDropDown)
	S:HandleButton(payment.ListOrderButton)

	local viewListingButton = payment.ViewListingsButton
	viewListingButton:SetAlpha(0)
	local viewListingRepair = CreateFrame('Frame', nil, payment)
	viewListingRepair:SetInside(viewListingButton)
	local viewListingTexture = viewListingRepair:CreateTexture(nil, 'ARTWORK')
	viewListingTexture:SetAllPoints()
	viewListingTexture:SetTexture([[Interface\CURSOR\Crosshair\Repair]])

	--[[local currentListings = frame.Form.CurrentListings
	if currentListings then
		currentListings:StripTextures()
		currentListings:SetTemplate('Transparent')
		S:HandleButton(currentListings.CloseButton)
		S:HandleTrimScrollBar(currentListings.OrderList.ScrollBar, true)
		HandleListHeader(currentListings.OrderList.HeaderContainer)
		currentListings.OrderList:StripTextures()
		currentListings:ClearAllPoints()
		currentListings:SetPoint('LEFT', frame, 'RIGHT', 10, 0)
	end]]

	local qualityDialog = frame.Form.QualityDialog
	if qualityDialog then
		qualityDialog:StripTextures()
		qualityDialog:SetTemplate('Transparent')
		S:HandleCloseButton(qualityDialog.ClosePanelButton)
		S:HandleButton(qualityDialog.AcceptButton)
		S:HandleButton(qualityDialog.CancelButton)

		ReskinQualityContainer(qualityDialog.Container1)
		ReskinQualityContainer(qualityDialog.Container2)
		ReskinQualityContainer(qualityDialog.Container3)
	end

	hooksecurefunc(frame.Form, 'Init', FormInit)

    local ShowSimButton = CustOrdersSim.ShowSimButton
    S:HandleButton(ShowSimButton)

    local HideSimButton = CustOrdersSim.HideSimButton
    S:HandleButton(HideSimButton)

    local R1MatsButton = CustOrdersSim.R1MatsButton
    S:HandleButton(R1MatsButton)

    local R2MatsButton = CustOrdersSim.R2MatsButton
    S:HandleButton(R2MatsButton)

    local R3MatsButton = CustOrdersSim.R3MatsButton
    S:HandleButton(R3MatsButton)

    local RecraftCheckBox = CustOrdersSim.RecraftCheckBox
    S:HandleCheckBox(RecraftCheckBox)
    RecraftCheckBox:SetSize(24, 24)
end