-- /*=============================================
-- =     Multi-Action Window Logic             =
-- =============================================*/

local multiActionWindow = nil
local selectedButton = nil  -- Botão sendo configurado
local selectedSlots = {}    -- [slotId] = buttonData

-- /*=============================================
-- =        Window Management                 =
-- =============================================*/

function openMultiActionWindow(actionButton)
    if multiActionWindow then
        multiActionWindow:destroy()
    end
    
    if not actionButton then
        print("[MULTI-ACTION WINDOW] No button selected")
        return false
    end
    
    selectedButton = actionButton
    selectedSlots = {}
    
    multiActionWindow = g_ui.createWidget('MultiActionWindow', gameRootPanel)
    if not multiActionWindow then
        print("[MULTI-ACTION WINDOW] Failed to create window")
        return false
    end
    
    -- Carregar slots existentes se houver
    loadExistingMultiActions()
    
    -- Setup do modo
    setupModeCombo()
    
    -- Setup dos slots
    setupSlots()
    
    print("[MULTI-ACTION WINDOW] Window opened for button: " .. actionButton:getId())
    return true
end

function closeMultiActionWindow()
    if multiActionWindow then
        multiActionWindow:destroy()
        multiActionWindow = nil
    end
    selectedButton = nil
    selectedSlots = {}
end

-- /*=============================================
-- =        Slot Setup                        =
-- =============================================*/

function setupSlots()
    if not multiActionWindow then return end
    
    local slotPanel = multiActionWindow:recursiveGetChildById('slotPanel')
    if not slotPanel then return end
    
    -- Obter todos os slots
    local slots = {
        multiActionWindow:recursiveGetChildById('slot1'),
        multiActionWindow:recursiveGetChildById('slot2'),
        multiActionWindow:recursiveGetChildById('slot3'),
        multiActionWindow:recursiveGetChildById('slot4'),
        multiActionWindow:recursiveGetChildById('slot5'),
    }
    
    for slotId, slot in ipairs(slots) do
        if slot then
            setupSlotDragDrop(slot, slotId)
            setupSlotContext(slot, slotId)
        end
    end
end

function setupSlotDragDrop(slot, slotId)
    if not slot then return end
    
    -- Drag & Drop: receber ações
    slot:setAcceptDragDrop(true)
    
    slot.onDragEnter = function(self, mousePos)
        local dragWidget = g_ui.getDraggingWidget()
        if not dragWidget then return end
        
        -- Verificar se é um botão de ação
        if isValidActionButton(dragWidget) then
            self:setOpacity(0.8)
            self:setBorderColor('#FFD700')
        end
    end
    
    slot.onDragLeave = function(self, mousePos)
        self:setOpacity(1.0)
        self:setBorderColor('#333333')
    end
    
    slot.onDrop = function(self, mousePos)
        local dragWidget = g_ui.getDraggingWidget()
        if not dragWidget then return end
        
        if isValidActionButton(dragWidget) then
            assignActionToSlot(slotId, dragWidget)
            self:setOpacity(1.0)
            self:setBorderColor('#333333')
        end
    end
    
    -- Iniciar drag do slot
    slot.onMousePress = function(self, mouseButton)
        if mouseButton == MouseMiddleButton then
            clearSlot(slotId)
        end
    end
end

function setupSlotContext(slot, slotId)
    if not slot then return end
    
    slot.onMouseRightPress = function(self, mousePos)
        local menu = createPopupMenu()
        
        if selectedSlots[slotId] then
            menu:addOption('View Action', function()
                print('[SLOT] Button ID: ' .. selectedSlots[slotId].id)
            end)
            menu:addOption('Remove', function()
                clearSlot(slotId)
            end)
        else
            menu:addOption('(Empty - Drag action here)', function() end, nil, nil, true)
        end
        
        menu:display(mousePos)
        return true
    end
end

-- /*=============================================
-- =        Action Assignment               =
-- =============================================*/

function assignActionToSlot(slotId, actionButton)
    if not actionButton or not selectedButton then
        return false
    end
    
    -- Validar que é um botão de ação válido
    if not isValidActionButton(actionButton) then
        print("[MULTI-ACTION WINDOW] Invalid action button")
        return false
    end
    
    -- Verificar duplicata
    for sId, data in pairs(selectedSlots) do
        if data.button == actionButton then
            print("[MULTI-ACTION WINDOW] Action already in slot " .. sId)
            return false
        end
    end
    
    -- Armazenar
    selectedSlots[slotId] = {
        button = actionButton,
        id = actionButton:getId(),
        cache = getButtonCache(actionButton)
    }
    
    -- Atualizar visual
    updateSlotVisual(slotId)
    
    print("[MULTI-ACTION WINDOW] Action assigned to slot " .. slotId)
    return true
end

function clearSlot(slotId)
    if selectedSlots[slotId] then
        selectedSlots[slotId] = nil
        updateSlotVisual(slotId)
        print("[MULTI-ACTION WINDOW] Slot " .. slotId .. " cleared")
    end
end

function clearAllSlots()
    selectedSlots = {}
    updateAllSlotsVisual()
    print("[MULTI-ACTION WINDOW] All slots cleared")
end

-- /*=============================================
-- =        Visual Update                    =
-- =============================================*/

function updateSlotVisual(slotId)
    if not multiActionWindow then return end
    
    local slot = multiActionWindow:recursiveGetChildById('slot' .. slotId)
    if not slot then return end
    
    local data = selectedSlots[slotId]
    
    if data then
        -- Slot com ação
        local cache = data.cache
        local actionName = getActionName(cache.actionType) or "Unknown"
        
        if data.button.item then
            slot:setItemId(data.button.item:getItemId())
            if cache.itemId > 0 then
                slot:setItemSubType(cache.upgradeTier or 0)
            end
        elseif cache.isSpell then
            -- Para spells, usar ícone genérico
            slot:setItemId(0)
            slot:setText(cache.spellData and cache.spellData.words:sub(1, 3) or "SPL")
        elseif cache.actionType == UseTypes["chatText"] then
            slot:setItemId(0)
            slot:setText("TXT")
        else
            slot:setItemId(0)
            slot:setText(actionName:sub(1, 3))
        end
        
        slot:setTooltip(
            'Slot ' .. slotId .. '\n' ..
            'Action: ' .. actionName .. '\n' ..
            'Button: ' .. data.id .. '\n' ..
            '[RClick to remove]'
        )
    else
        -- Slot vazio
        slot:setItemId(0)
        slot:setText('')
        slot:setTooltip('Slot ' .. slotId .. '\n[Drag action here]\n[RClick for options]')
    end
end

function updateAllSlotsVisual()
    for i = 1, 5 do
        updateSlotVisual(i)
    end
end

-- /*=============================================
-- =        Mode Selection                   =
-- =============================================*/

function setupModeCombo()
    if not multiActionWindow then return end
    
    local modeCombo = multiActionWindow:recursiveGetChildById('modeCombo')
    if not modeCombo then return end
    
    modeCombo:addOption('SEQUENTIAL', 1)
    modeCombo:addOption('PARALLEL', 2)
    modeCombo:addOption('SMART', 3)
    
    modeCombo:setCurrentIndex(1)
end

function getSelectedMode()
    if not multiActionWindow then return 1 end
    
    local modeCombo = multiActionWindow:recursiveGetChildById('modeCombo')
    if not modeCombo then return 1 end
    
    local text = modeCombo:getText()
    if text == 'PARALLEL' then return 2 end
    if text == 'SMART' then return 3 end
    return 1  -- SEQUENTIAL
end

-- /*=============================================
-- =        Confirmation                     =
-- =============================================*/

function confirmMultiAction()
    if not selectedButton then
        print("[MULTI-ACTION WINDOW] No button selected")
        return false
    end
    
    -- Coletar ações em ordem
    local actionButtons = {}
    for i = 1, 5 do
        if selectedSlots[i] then
            table.insert(actionButtons, selectedSlots[i].button)
        end
    end
    
    if #actionButtons == 0 then
        print("[MULTI-ACTION WINDOW] No actions selected")
        return false
    end
    
    -- Obter modo
    local mode = getSelectedMode()
    
    -- Aplicar multi-action
    if setMultiAction(selectedButton, actionButtons, mode) then
        print("[MULTI-ACTION WINDOW] Multi-action configured successfully!")
        print("[MULTI-ACTION WINDOW] Button: " .. selectedButton:getId() .. 
              " | Actions: " .. #actionButtons .. " | Mode: " .. mode)
        
        closeMultiActionWindow()
        return true
    else
        print("[MULTI-ACTION WINDOW] Failed to configure multi-action")
        return false
    end
end

-- /*=============================================
-- =        Existing Multi-Actions           =
-- =============================================*/

function loadExistingMultiActions()
    if not selectedButton or not isMultiAction(selectedButton) then
        return false
    end
    
    local existingActions = getMultiActions(selectedButton)
    if not existingActions then
        return false
    end
    
    for slotId, actionButton in ipairs(existingActions) do
        if slotId <= 5 then
            assignActionToSlot(slotId, actionButton)
        end
    end
    
    print("[MULTI-ACTION WINDOW] Loaded " .. #existingActions .. " existing actions")
    return true
end

-- /*=============================================
-- =        Validation                       =
-- =============================================*/

function isValidActionButton(button)
    if not button then
        return false
    end
    
    -- Verificar se tem a estrutura de botão de ação
    local cache = getButtonCache(button)
    if not cache or cache.actionType == 0 then
        return false
    end
    
    return true
end

-- /*=============================================
-- =        Export Functions                 =
-- =============================================*/

function multiActionWindow:clearAllSlots()
    clearAllSlots()
end

function multiActionWindow:confirmMultiAction()
    confirmMultiAction()
end

return {
    openMultiActionWindow = openMultiActionWindow,
    closeMultiActionWindow = closeMultiActionWindow,
    confirmMultiAction = confirmMultiAction,
}
