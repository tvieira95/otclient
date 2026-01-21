-- /*=============================================
-- =     Multi-Action Setup & Example         =
-- =============================================*/
-- Este arquivo demonstra como integrar multi-action no ActionButtonLogic

local MultiActionQueue = dofile('logics/MultiActionQueue.lua')
local MultiActionIntegrator = dofile('logics/MultiActionIntegrator.lua')

-- /*=============================================
-- =        Integração com ActionButtonLogic  =
-- =============================================*/

-- PASSO 1: Modificar a função onExecuteAction() existente
-- em ActionButtonLogic.lua para suportar multi-action:

-- [[
function onExecuteAction(button, isPress)
    local cache = getButtonCache(button)
    if cache.lastClick > g_clock.millis() then
        return true
    end

    if modules.game_interface.getMainRightPanel():isFocusable() or modules.game_interface.getLeftPanel():isFocusable() then
        return true
    end

    if not isPress then
        button.cache.nextDownKey = g_clock.millis() + 500
    end

    if isPress and button.cache.nextDownKey > g_clock.millis() then
        return true
    end

    -- NOVO: Verificar se é multi-action
    if MultiActionIntegrator.isMultiAction(button) then
        return MultiActionIntegrator.executeMultiAction(button, isPress)
    end

    -- ... resto do código original ...
end
--]]

-- /*=============================================
-- =        Setup de Multi-Action            =
-- =============================================*/

-- Para criar um botão com múltiplas ações:
-- 1. Obter os botões que contêm as ações individuais
-- 2. Configurar o botão principal como multi-action
-- 3. Passar a lista de botões de ações

-- Exemplo:
-- [[
local function setupExampleMultiAction()
    -- Obter o botão principal (que receberá o multi-action)
    local mainButton = getButtonById("1.1") -- ActionBar 1, Button 1
    
    -- Obter botões com as ações individuais
    local actionButtons = {
        getButtonById("1.2"),  -- Attack rune
        getButtonById("1.3"),  -- Heal spell
        getButtonById("1.4"),  -- Support buff
    }
    
    -- Configurar como multi-action (modo sequencial)
    MultiActionIntegrator.setMultiAction(
        mainButton,
        actionButtons,
        MultiActionIntegrator.MODES.SEQUENTIAL
    )
    
    -- Debug
    MultiActionIntegrator.debugPrintMultiActions(mainButton)
end
--]]

-- /*=============================================
-- =        Callbacks para Debug             =
-- =============================================*/

-- Configurar callbacks opcionais para monitoramento
-- [[
function setupMultiActionCallbacks()
    MultiActionQueue.onQueueAdd = function(action, queueSize)
        print("Action added to queue. Size: " .. queueSize)
    end
    
    MultiActionQueue.onQueueStart = function(totalActions)
        print("Starting multi-action queue with " .. totalActions .. " actions")
    end
    
    MultiActionQueue.onQueueFail = function(action, reason)
        print("Action failed: " .. tostring(reason))
    end
    
    MultiActionQueue.onQueueComplete = function()
        print("Multi-action queue completed!")
    end
end
--]]

-- /*=============================================
-- =        API Pública                      =
-- =============================================*/

return {
    -- Queue Management
    MultiActionQueue = MultiActionQueue,
    clearQueue = function() MultiActionQueue:clear() end,
    getQueueSize = function() return MultiActionQueue:getQueueSize() end,
    getQueueState = function() return MultiActionQueue:getStateName() end,
    
    -- Multi-Action Button Setup
    MultiActionIntegrator = MultiActionIntegrator,
    setMultiAction = function(button, actions, mode)
        return MultiActionIntegrator.setMultiAction(button, actions, mode)
    end,
    isMultiAction = function(button)
        return MultiActionIntegrator.isMultiAction(button)
    end,
    getMultiActions = function(button)
        return MultiActionIntegrator.getMultiActions(button)
    end,
    executeMultiAction = function(button, isPress)
        return MultiActionIntegrator.executeMultiAction(button, isPress)
    end,
    clearMultiAction = function(button)
        return MultiActionIntegrator.clearMultiAction(button)
    end,
    debugPrint = function(button)
        MultiActionIntegrator.debugPrintMultiActions(button)
    end,
    
    -- Configuration
    MODES = MultiActionIntegrator.MODES,
    setActionDelay = function(ms)
        MultiActionQueue:setActionDelay(ms)
    end,
}
