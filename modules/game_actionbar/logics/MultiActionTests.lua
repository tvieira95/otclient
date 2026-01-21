-- /*=============================================
-- =     Multi-Action System - Test Examples   =
-- =============================================*/
-- File de testes e exemplos práticos

-- Funções de teste
local MultiActionTests = {}

-- /*=============================================
-- =        Setup de Exemplos             =
-- =============================================*/

function MultiActionTests.setupExample1_SimpleAttack()
    -- Exemplo 1: Ataque + Cura Simples
    -- Setup: 3 botões (1.2 = Attack, 1.3 = Heal Spell, 1.4 = Buff)
    
    local mainButton = getButtonById("1.1")
    if not mainButton then
        print("[TEST] Button 1.1 not found")
        return false
    end
    
    local attackButton = getButtonById("1.2")
    local healButton = getButtonById("1.3")
    local buffButton = getButtonById("1.4")
    
    if not attackButton or not healButton or not buffButton then
        print("[TEST] Some buttons not found for example 1")
        return false
    end
    
    local actions = { attackButton, healButton, buffButton }
    local mode = getMultiActionIntegrator().MODES.SEQUENTIAL
    
    if setMultiAction(mainButton, actions, mode) then
        print("[TEST✓] Example 1: Attack + Heal + Buff configured")
        debugMultiAction(mainButton)
        return true
    else
        print("[TEST✗] Failed to setup example 1")
        return false
    end
end

function MultiActionTests.setupExample2_DefensiveRotation()
    -- Exemplo 2: Rotação Defensiva
    -- Setup: 4 botões (2.2 = Distance, 2.3 = Protect, 2.4 = Barrier, 2.5 = Heal)
    
    local mainButton = getButtonById("2.1")
    if not mainButton then
        print("[TEST] Button 2.1 not found")
        return false
    end
    
    local actions = {
        getButtonById("2.2"),  -- Distance spell
        getButtonById("2.3"),  -- Protect spell
        getButtonById("2.4"),  -- Barrier spell
        getButtonById("2.5"),  -- Heal spell
    }
    
    -- Filtrar botões nulos
    local validActions = {}
    for _, btn in ipairs(actions) do
        if btn then table.insert(validActions, btn) end
    end
    
    if #validActions == 0 then
        print("[TEST] No valid buttons found for example 2")
        return false
    end
    
    local mode = getMultiActionIntegrator().MODES.SEQUENTIAL
    if setMultiAction(mainButton, validActions, mode) then
        print("[TEST✓] Example 2: Defensive Rotation configured (" .. #validActions .. " actions)")
        debugMultiAction(mainButton)
        return true
    else
        print("[TEST✗] Failed to setup example 2")
        return false
    end
end

function MultiActionTests.setupExample3_DamageRotation()
    -- Exemplo 3: Rotação de Dano
    -- Setup: 5 botões de feitiços de ataque
    
    local mainButton = getButtonById("3.1")
    if not mainButton then
        print("[TEST] Button 3.1 not found")
        return false
    end
    
    local actions = {
        getButtonById("3.2"),  -- Damage spell 1
        getButtonById("3.3"),  -- Damage spell 2
        getButtonById("3.4"),  -- Damage spell 3
        getButtonById("3.5"),  -- Damage spell 4
        getButtonById("3.6"),  -- Finish spell
    }
    
    local validActions = {}
    for _, btn in ipairs(actions) do
        if btn then table.insert(validActions, btn) end
    end
    
    if #validActions == 0 then
        print("[TEST] No valid buttons found for example 3")
        return false
    end
    
    local mode = getMultiActionIntegrator().MODES.SEQUENTIAL
    if setMultiAction(mainButton, validActions, mode) then
        print("[TEST✓] Example 3: Damage Rotation configured (" .. #validActions .. " actions)")
        debugMultiAction(mainButton)
        return true
    else
        print("[TEST✗] Failed to setup example 3")
        return false
    end
end

-- /*=============================================
-- =        Queue State Monitoring           =
-- =============================================*/

function MultiActionTests.printQueueState()
    local queue = getMultiActionQueue()
    if not queue then
        print("[QUEUE] MultiActionQueue not initialized")
        return
    end
    
    print("\n=== Queue State ===")
    print("Status: " .. queue:getStateName())
    print("Size: " .. queue:getQueueSize())
    print("Delay: " .. queue:getActionDelay() .. "ms")
    
    local queueItems = queue:getQueue()
    if #queueItems > 0 then
        print("Actions in queue:")
        for i, action in ipairs(queueItems) do
            if action.button then
                print("  [" .. i .. "] Button: " .. action.button:getId() .. 
                      " | Retries: " .. action.retries .. "/" .. action.maxRetries)
            end
        end
    end
    print("===================\n")
end

function MultiActionTests.setupQueueMonitoring()
    local queue = getMultiActionQueue()
    if not queue then return false end
    
    queue.onQueueAdd = function(action, size)
        print("[QUEUE-ADD] Size: " .. size)
    end
    
    queue.onQueueStart = function(total)
        print("[QUEUE-START] " .. total .. " actions")
    end
    
    queue.onQueueFail = function(action, reason)
        print("[QUEUE-FAIL] " .. tostring(reason))
    end
    
    queue.onQueueComplete = function()
        print("[QUEUE-COMPLETE] All actions executed")
    end
    
    print("[MONITOR] Queue monitoring enabled")
    return true
end

-- /*=============================================
-- =        Validation Tests                 =
-- =============================================*/

function MultiActionTests.testValidation()
    print("\n=== Validation Test ===")
    
    local queue = getMultiActionQueue()
    if not queue then
        print("Queue not initialized")
        return false
    end
    
    local testButton = getButtonById("1.2")
    if not testButton then
        print("Test button not found")
        return false
    end
    
    local cache = getButtonCache(testButton)
    print("Button: " .. testButton:getId())
    print("Action Type: " .. (cache.actionType or 0))
    print("Is Spell: " .. tostring(cache.isSpell))
    print("Item ID: " .. (cache.itemId or 0))
    
    local isValid = queue.validateAction({ button = testButton })
    print("Valid: " .. tostring(isValid))
    print("=======================\n")
    
    return isValid
end

-- /*=============================================
-- =        Performance Tests                =
-- =============================================*/

function MultiActionTests.benchmarkQueue()
    print("\n=== Queue Benchmark ===")
    
    local queue = getMultiActionQueue()
    if not queue then return false end
    
    -- Teste com 10 ações
    local startTime = g_clock.millis()
    
    local mainButton = getButtonById("4.1")
    if mainButton then
        for i = 1, 10 do
            queue:addAction(1, mainButton, {})
        end
    end
    
    local endTime = g_clock.millis()
    print("Time to add 10 actions: " .. (endTime - startTime) .. "ms")
    print("Queue size: " .. queue:getQueueSize())
    
    queue:clear()
    print("Queue cleared")
    print("=======================\n")
end

-- /*=============================================
-- =        Stress Tests                    =
-- =============================================*/

function MultiActionTests.stressTestMultipleButtons()
    print("\n=== Stress Test: Multiple Buttons ===")
    
    local integrator = getMultiActionIntegrator()
    if not integrator then return false end
    
    local mode = integrator.MODES.SEQUENTIAL
    local setupCount = 0
    
    -- Tentar setup em múltiplos botões
    for barId = 1, 3 do
        for btnId = 1, 12 do
            local btnId_str = barId .. "." .. btnId
            local mainBtn = getButtonById(btnId_str)
            
            if mainBtn and btnId > 1 then
                -- Usar próximo botão como ação
                local actionBtn = getButtonById(barId .. "." .. (btnId + 1))
                if actionBtn then
                    if setMultiAction(mainBtn, { actionBtn }, mode) then
                        setupCount = setupCount + 1
                    end
                end
            end
        end
    end
    
    print("Successfully setup: " .. setupCount .. " multi-action buttons")
    print("======================================\n")
    
    return setupCount > 0
end

-- /*=============================================
-- =        Command Interface               =
-- =============================================*/

function MultiActionTests.runAllTests()
    print("\n========================================")
    print("    MULTI-ACTION SYSTEM TEST SUITE")
    print("========================================\n")
    
    local results = {}
    
    print("1. Setting up queue monitoring...")
    results.monitoring = MultiActionTests.setupQueueMonitoring()
    
    print("\n2. Running setup examples...")
    results.example1 = MultiActionTests.setupExample1_SimpleAttack()
    results.example2 = MultiActionTests.setupExample2_DefensiveRotation()
    results.example3 = MultiActionTests.setupExample3_DamageRotation()
    
    print("\n3. Checking queue state...")
    MultiActionTests.printQueueState()
    
    print("4. Testing validation...")
    results.validation = MultiActionTests.testValidation()
    
    print("5. Running benchmark...")
    MultiActionTests.benchmarkQueue()
    
    print("6. Stress testing...")
    results.stress = MultiActionTests.stressTestMultipleButtons()
    
    -- Resumo
    print("\n========================================")
    print("           TEST RESULTS SUMMARY")
    print("========================================")
    for test, result in pairs(results) do
        local status = result and "✓ PASS" or "✗ FAIL"
        print(test .. ": " .. status)
    end
    print("========================================\n")
end

-- Exportar para uso global
_G.MultiActionTests = MultiActionTests

return MultiActionTests
