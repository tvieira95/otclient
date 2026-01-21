-- /*=============================================
-- =    Multi-Action Practical Integration     =
-- =          (Integração Prática)            =
-- =============================================*/

-- Este arquivo mostra como integrar multi-action de forma prática
-- Se você preferir, pode colocar este código em um lugar específico do seu módulo

-- /*=============================================
-- =        Auto-Setup no Carregamento        =
-- =============================================*/

-- Quando o módulo carrega, podemos fazer setup automático de multi-actions
function setupDefaultMultiActions()
    if not setMultiAction then
        print("[MULTI-ACTION] API not yet loaded")
        return false
    end
    
    print("[MULTI-ACTION] Setting up default configurations...")
    local count = 0
    
    -- Exemplo 1: Se quiser, adicione aqui seus multi-actions padrão
    -- local btn1 = getButtonById("1.1")
    -- if btn1 then
    --     setMultiAction(btn1, { getButtonById("1.2"), getButtonById("1.3") })
    --     count = count + 1
    -- end
    
    print("[MULTI-ACTION] Default setup complete. Configured: " .. count)
    return true
end

-- /*=============================================
-- =        Utilitários Práticos              =
-- =============================================*/

-- Função helper: Criar multi-action fácil
local function createMultiAction(mainButtonId, actionButtonIds, mode)
    local integrator = getMultiActionIntegrator()
    if not integrator then
        print("Integrator not available")
        return false
    end
    
    local mainBtn = getButtonById(mainButtonId)
    if not mainBtn then
        print("Main button " .. mainButtonId .. " not found")
        return false
    end
    
    local actions = {}
    for _, actionId in ipairs(actionButtonIds) do
        local btn = getButtonById(actionId)
        if btn then
            table.insert(actions, btn)
        end
    end
    
    if #actions == 0 then
        print("No valid action buttons found")
        return false
    end
    
    mode = mode or integrator.MODES.SEQUENTIAL
    
    if setMultiAction(mainBtn, actions, mode) then
        print("[✓] Multi-action created: " .. mainButtonId .. " -> " .. #actions .. " actions")
        return true
    else
        print("[✗] Failed to create multi-action")
        return false
    end
end

-- Função helper: Listar todos multi-actions
local function listAllMultiActions()
    local integrator = getMultiActionIntegrator()
    if not integrator then return end
    
    local allConfigs = integrator.getAllConfigs()
    
    print("\n=== All Multi-Actions ===")
    local count = 0
    for buttonId, config in pairs(allConfigs) do
        if config.enabled then
            local mode = "SEQUENTIAL"
            if config.mode == integrator.MODES.PARALLEL then
                mode = "PARALLEL"
            elseif config.mode == integrator.MODES.SMART then
                mode = "SMART"
            end
            print("  " .. buttonId .. ": " .. #config.actions .. " actions (" .. mode .. ")")
            count = count + 1
        end
    end
    print("Total: " .. count)
    print("========================\n")
end

-- Função helper: Remover todos multi-actions
local function clearAllMultiActions()
    local integrator = getMultiActionIntegrator()
    if not integrator then return end
    
    local allConfigs = integrator.getAllConfigs()
    local count = 0
    
    for buttonId, _ in pairs(allConfigs) do
        local btn = getButtonById(buttonId)
        if btn then
            clearMultiAction(btn)
            count = count + 1
        end
    end
    
    print("[✓] Cleared " .. count .. " multi-actions")
end

-- /*=============================================
-- =        Context Menu Integration         =
-- =============================================*/

-- Se você quiser adicionar opções de contexto no botão direito
-- (Este é um exemplo - adapte conforme sua UI)

local function setupMultiActionContextMenu()
    -- Isto seria integrado no drag/drop de botões
    -- Exemplo: ao clicar com botão direito em um botão configurado
    
    --[[
    function onButtonRightClick(button, mousePos)
        if not isMultiAction(button) then
            return false
        end
        
        -- Mostrar menu contextual
        local menu = createPopupMenu()
        menu:addOption("View Multi-Action", function()
            debugMultiAction(button)
        end)
        menu:addOption("Clear Multi-Action", function()
            clearMultiAction(button)
        end)
        menu:display(mousePos)
        
        return true
    end
    --]]
end

-- /*=============================================
-- =        Integration Points               =
-- =============================================*/

-- Sugestões de onde integrar em diferentes partes do código:

-- 1. Na função initializeActionBars():
--    Chamar setupDefaultMultiActions()

-- 2. Na função loadActionBar():
--    Restaurar multi-actions do save file

-- 3. Na função saveActionBar():
--    Salvar multi-actions junto com ações

-- 4. No menu de opções:
--    Adicionar toggle para ativar/desativar multi-actions globalmente

-- /*=============================================
-- =        Performance Monitoring           =
-- =============================================*/

-- Função para monitorar performance
local function startPerformanceMonitoring()
    local queue = getMultiActionQueue()
    if not queue then return end
    
    local stats = {
        totalExecuted = 0,
        totalFailed = 0,
        totalRetries = 0,
        avgExecutionTime = 0,
    }
    
    queue.onQueueStart = function(total)
        print("[PERF] Starting queue with " .. total .. " actions")
    end
    
    queue.onQueueComplete = function()
        stats.totalExecuted = stats.totalExecuted + 1
        print("[PERF] Queue completed (" .. stats.totalExecuted .. " total)")
    end
    
    queue.onQueueFail = function(action, reason)
        stats.totalFailed = stats.totalFailed + 1
        print("[PERF] Action failed: " .. reason)
    end
    
    -- Função para ver estatísticas
    _G.showPerformanceStats = function()
        print("\n=== Performance Stats ===")
        print("Total Executed: " .. stats.totalExecuted)
        print("Total Failed: " .. stats.totalFailed)
        print("Total Retries: " .. stats.totalRetries)
        print("=========================\n")
    end
end

-- /*=============================================
-- =        Hotkey Integration Example       =
-- =============================================*/

-- Exemplo de como integrar comandos de teclado para multi-actions

--[[
function setupMultiActionHotkeys()
    -- Ctrl+M para listar multi-actions
    g_keyboard.bindKeyPress("Ctrl+M", function()
        listAllMultiActions()
    end, gameRootPanel)
    
    -- Ctrl+Shift+C para limpar todos
    g_keyboard.bindKeyPress("Ctrl+Shift+C", function()
        clearAllMultiActions()
    end, gameRootPanel)
end
--]]

-- /*=============================================
-- =        Export Functions                 =
-- =============================================*/

-- Exportar para uso fácil no console
_G.MultiActionAPI = {
    -- Criação
    create = createMultiAction,
    clear = clearMultiAction,
    clearAll = clearAllMultiActions,
    
    -- Listagem
    list = listAllMultiActions,
    debug = debugMultiAction,
    
    -- Verificação
    is = isMultiAction,
    get = getMultiActions,
    
    -- Configuração
    setDelay = function(ms)
        local queue = getMultiActionQueue()
        if queue then queue:setActionDelay(ms) end
    end,
    
    -- Queue
    getQueue = getMultiActionQueue,
    getIntegrator = getMultiActionIntegrator,
    
    -- Monitoramento
    startMonitoring = startPerformanceMonitoring,
    showStats = function() _G.showPerformanceStats() end,
}

print("[MULTI-ACTION] API Available at: MultiActionAPI")
print("[MULTI-ACTION] Usage: MultiActionAPI.create('1.1', {'1.2', '1.3'})")

-- /*=============================================
-- =        Exemplo de Uso Prático           =
-- =============================================*/

--[[
-- Para usar, abrir console (Ctrl+I) e fazer:

-- 1. Criar um multi-action simples
MultiActionAPI.create("1.1", {"1.2", "1.3"})

-- 2. Ver todos
MultiActionAPI.list()

-- 3. Debug de um botão
MultiActionAPI.debug(getButtonById("1.1"))

-- 4. Mudar delay
MultiActionAPI.setDelay(30)

-- 5. Limpar um
MultiActionAPI.clear(getButtonById("1.1"))

-- 6. Limpar todos
MultiActionAPI.clearAll()
--]]

return {
    createMultiAction = createMultiAction,
    listAllMultiActions = listAllMultiActions,
    clearAllMultiActions = clearAllMultiActions,
    setupDefaultMultiActions = setupDefaultMultiActions,
    startPerformanceMonitoring = startPerformanceMonitoring,
}
