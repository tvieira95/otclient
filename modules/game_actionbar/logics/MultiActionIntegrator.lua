-- /*=============================================
-- =     Multi-Action Button Integration      =
-- =============================================*/
-- Integra o sistema de multi-action ao ActionButtonLogic

local MultiActionIntegrator = {}

-- Cache de botões com múltiplas ações
local multiActionButtons = {} -- [buttonId] = { slot1, slot2, slot3, ... }

-- Configurações de multi-action por botão
local multiActionConfig = {} -- [buttonId] = { enabled, mode, actions }

-- Modos de multi-action
MultiActionIntegrator.MODES = {
    SEQUENTIAL = 1,  -- Executa ações na sequência, uma por vez
    PARALLEL = 2,    -- Tenta executar todas que puderem (não recomendado por exhaust)
    SMART = 3        -- Sequencial com retry inteligente
}

-- /*=============================================
-- =        Setup Multi-Action Button         =
-- =============================================*/

function MultiActionIntegrator.setMultiAction(button, actions, mode)
    if not button or not actions or #actions == 0 then
        return false
    end
    
    mode = mode or MultiActionIntegrator.MODES.SEQUENTIAL
    local buttonId = button:getId()
    
    multiActionButtons[buttonId] = actions
    multiActionConfig[buttonId] = {
        enabled = true,
        mode = mode,
        actions = actions,
        lastExecutionTime = 0
    }
    
    return true
end

function MultiActionIntegrator.isMultiAction(button)
    if not button then
        return false
    end
    return multiActionButtons[button:getId()] ~= nil
end

function MultiActionIntegrator.getMultiActions(button)
    if not button then
        return nil
    end
    return multiActionButtons[button:getId()]
end

function MultiActionIntegrator.clearMultiAction(button)
    if not button then
        return false
    end
    
    local buttonId = button:getId()
    multiActionButtons[buttonId] = nil
    multiActionConfig[buttonId] = nil
    
    return true
end

-- /*=============================================
-- =        Multi-Action Execution            =
-- =============================================*/

function MultiActionIntegrator.executeMultiAction(button, isPress)
    if not MultiActionIntegrator.isMultiAction(button) then
        return false
    end
    
    local config = multiActionConfig[button:getId()]
    if not config or not config.enabled then
        return false
    end
    
    local actions = multiActionButtons[button:getId()]
    if not actions or #actions == 0 then
        return false
    end
    
    -- Limpa fila anterior se houver
    if MultiActionQueue and #MultiActionQueue:getQueue() > 0 then
        -- Se há menos de 500ms desde a última execução, ignora (debounce)
        if g_clock.millis() - config.lastExecutionTime < 500 then
            return true
        end
        MultiActionQueue:clear()
    end
    
    config.lastExecutionTime = g_clock.millis()
    
    -- Carrega fila de ações
    for _, actionButton in ipairs(actions) do
        if actionButton then
            local cache = getButtonCache(actionButton)
            local actionType = cache.actionType
            
            if actionType and actionType ~= 0 then
                local params = {
                    isPress = isPress,
                    originalButton = button
                }
                
                MultiActionQueue:addAction(actionType, actionButton, params)
            end
        end
    end
    
    if MultiActionQueue:getQueueSize() > 0 then
        MultiActionQueue:processQueue()
        return true
    end
    
    return false
end

-- /*=============================================
-- =        UI Integration Helpers            =
-- =============================================*/

function MultiActionIntegrator.addActionToSlot(button, slotButton)
    if not button or not slotButton then
        return false
    end
    
    local buttonId = button:getId()
    if not multiActionButtons[buttonId] then
        multiActionButtons[buttonId] = {}
        multiActionConfig[buttonId] = {
            enabled = true,
            mode = MultiActionIntegrator.MODES.SEQUENTIAL,
            actions = multiActionButtons[buttonId],
            lastExecutionTime = 0
        }
    end
    
    -- Verifica se já existe
    for _, action in ipairs(multiActionButtons[buttonId]) do
        if action == slotButton then
            return false
        end
    end
    
    table.insert(multiActionButtons[buttonId], slotButton)
    multiActionConfig[buttonId].actions = multiActionButtons[buttonId]
    
    return true
end

function MultiActionIntegrator.removeActionFromSlot(button, slotIndex)
    if not button then
        return false
    end
    
    local buttonId = button:getId()
    local actions = multiActionButtons[buttonId]
    
    if not actions or not actions[slotIndex] then
        return false
    end
    
    table.remove(actions, slotIndex)
    
    if #actions == 0 then
        multiActionButtons[buttonId] = nil
        multiActionConfig[buttonId] = nil
    end
    
    return true
end

function MultiActionIntegrator.getMultiActionCount(button)
    if not button then
        return 0
    end
    
    local actions = multiActionButtons[button:getId()]
    return actions and #actions or 0
end

function MultiActionIntegrator.getMultiActionMode(button)
    if not button then
        return nil
    end
    
    local config = multiActionConfig[button:getId()]
    return config and config.mode or nil
end

function MultiActionIntegrator.setMultiActionMode(button, mode)
    if not button or not mode then
        return false
    end
    
    local config = multiActionConfig[button:getId()]
    if not config then
        return false
    end
    
    config.mode = mode
    return true
end

-- /*=============================================
-- =        Debug Utilities                   =
-- =============================================*/

function MultiActionIntegrator.debugPrintMultiActions(button)
    if not button then
        print("Button is nil")
        return
    end
    
    local buttonId = button:getId()
    local actions = multiActionButtons[buttonId]
    
    if not actions or #actions == 0 then
        print("No multi-actions for button: " .. buttonId)
        return
    end
    
    print("\n=== Multi-Action Debug: " .. buttonId .. " ===")
    print("Total Actions: " .. #actions)
    
    for i, action in ipairs(actions) do
        if action then
            local cache = getButtonCache(action)
            local actionType = cache.actionType
            local actionName = getActionName(actionType) or "Unknown"
            print("  [" .. i .. "] " .. action:getId() .. " - " .. actionName)
        else
            print("  [" .. i .. "] <nil>")
        end
    end
    
    local config = multiActionConfig[buttonId]
    if config then
        local modeName = "SEQUENTIAL"
        if config.mode == MultiActionIntegrator.MODES.PARALLEL then
            modeName = "PARALLEL"
        elseif config.mode == MultiActionIntegrator.MODES.SMART then
            modeName = "SMART"
        end
        print("Mode: " .. modeName)
        print("Enabled: " .. tostring(config.enabled))
    end
    print("===========================================\n")
end

function MultiActionIntegrator.getAllMultiActions()
    return multiActionButtons
end

function MultiActionIntegrator.getAllConfigs()
    return multiActionConfig
end

return MultiActionIntegrator
