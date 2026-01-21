-- /*=============================================
-- =        Multi-Action Queue System          =
-- =============================================*/
-- Gerencia fila de ações sequenciais e validação

local MultiActionQueue = {}
MultiActionQueue.queue = {} -- [{ action, button, params, retries, maxRetries }]
MultiActionQueue.isProcessing = false
MultiActionQueue.currentEventId = nil
MultiActionQueue.lastActionTime = 0
MultiActionQueue.actionDelay = 50 -- ms entre tentativas de validação

-- Estados da fila
MultiActionQueue.STATE = {
    IDLE = 0,
    PROCESSING = 1,
    WAITING = 2,
    FAILED = 3,
    COMPLETED = 4
}

MultiActionQueue.state = MultiActionQueue.STATE.IDLE

-- Callbacks para debugging/logging
MultiActionQueue.onQueueAdd = nil
MultiActionQueue.onQueueRemove = nil
MultiActionQueue.onQueueStart = nil
MultiActionQueue.onQueueFail = nil
MultiActionQueue.onQueueComplete = nil

-- /*=============================================
-- =            Queue Management              =
-- =============================================*/

function MultiActionQueue.clear()
    if MultiActionQueue.currentEventId then
        removeEvent(MultiActionQueue.currentEventId)
        MultiActionQueue.currentEventId = nil
    end
    
    MultiActionQueue.queue = {}
    MultiActionQueue.isProcessing = false
    MultiActionQueue.state = MultiActionQueue.STATE.IDLE
end

function MultiActionQueue.addAction(actionType, button, params, maxRetries)
    maxRetries = maxRetries or 10 -- 10 tentativas padrão = ~500ms
    
    local action = {
        type = actionType,
        button = button,
        params = params or {},
        retries = 0,
        maxRetries = maxRetries,
        addedTime = g_clock.millis()
    }
    
    table.insert(MultiActionQueue.queue, action)
    
    if MultiActionQueue.onQueueAdd then
        MultiActionQueue.onQueueAdd(action, #MultiActionQueue.queue)
    end
    
    if not MultiActionQueue.isProcessing then
        MultiActionQueue.processQueue()
    end
end

function MultiActionQueue.removeAction(index)
    if index and MultiActionQueue.queue[index] then
        local action = table.remove(MultiActionQueue.queue, index)
        if MultiActionQueue.onQueueRemove then
            MultiActionQueue.onQueueRemove(action, index)
        end
        return true
    end
    return false
end

function MultiActionQueue.getQueueSize()
    return #MultiActionQueue.queue
end

function MultiActionQueue.getQueue()
    return MultiActionQueue.queue
end

function MultiActionQueue.isQueueEmpty()
    return #MultiActionQueue.queue == 0
end

-- /*=============================================
-- =        Queue Processing                 =
-- =============================================*/

function MultiActionQueue.processQueue()
    if MultiActionQueue.isQueueEmpty() then
        MultiActionQueue.isProcessing = false
        MultiActionQueue.state = MultiActionQueue.STATE.IDLE
        if MultiActionQueue.onQueueComplete then
            MultiActionQueue.onQueueComplete()
        end
        return
    end
    
    MultiActionQueue.isProcessing = true
    MultiActionQueue.state = MultiActionQueue.STATE.PROCESSING
    
    if MultiActionQueue.onQueueStart then
        MultiActionQueue.onQueueStart(#MultiActionQueue.queue)
    end
    
    MultiActionQueue.processNextAction()
end

function MultiActionQueue.processNextAction()
    if MultiActionQueue.isQueueEmpty() or MultiActionQueue.currentEventId then
        return
    end
    
    local action = MultiActionQueue.queue[1]
    if not action then
        MultiActionQueue.processQueue()
        return
    end
    
    local canExecute = MultiActionQueue.validateAction(action)
    
    if canExecute then
        MultiActionQueue.executeAction(action)
        MultiActionQueue.removeAction(1)
        
        -- Próxima ação após delay
        MultiActionQueue.scheduleNextAction()
    else
        -- Incrementa tentativa
        action.retries = action.retries + 1
        
        if action.retries >= action.maxRetries then
            if MultiActionQueue.onQueueFail then
                MultiActionQueue.onQueueFail(action, "Max retries reached")
            end
            MultiActionQueue.removeAction(1)
            MultiActionQueue.scheduleNextAction()
        else
            MultiActionQueue.state = MultiActionQueue.STATE.WAITING
            -- Retry em breve
            MultiActionQueue.scheduleNextAction()
        end
    end
end

function MultiActionQueue.scheduleNextAction()
    if MultiActionQueue.currentEventId then
        removeEvent(MultiActionQueue.currentEventId)
    end
    
    MultiActionQueue.currentEventId = scheduleEvent(function()
        MultiActionQueue.currentEventId = nil
        MultiActionQueue.processNextAction()
    end, MultiActionQueue.actionDelay)
end

-- /*=============================================
-- =            Action Validation              =
-- =============================================*/

function MultiActionQueue.validateAction(action)
    if not action or not action.button then
        return false
    end
    
    local button = action.button
    local cache = getButtonCache(button)
    
    if not cache then
        return false
    end
    
    local actionType = cache.actionType
    
    -- Validação por tipo de ação
    if actionType == UseTypes["Use"] then
        if not button.item or button.item:getItemId() == 0 then
            return false
        end
        if player:getInventoryCount(cache.itemId) == 0 then
            return false
        end
    end
    
    if actionType == UseTypes["Equip"] then
        if not button.item or button.item:getItemId() == 0 then
            return false
        end
        local tier = g_game.getFeature(GameThingUpgradeClassification) and cache.upgradeTier or 0
        if player:getInventoryCount(cache.itemId, tier) == 0 then
            return false
        end
    end
    
    if actionType == UseTypes["UseOnYourself"] then
        if not button.item or button.item:getItemId() == 0 then
            return false
        end
        if player:getInventoryCount(cache.itemId) == 0 then
            return false
        end
    end
    
    if actionType == UseTypes["UseOnTarget"] then
        if not button.item or button.item:getItemId() == 0 then
            return false
        end
        if not g_game.getAttackingCreature() and not action.params.crosshair then
            return false
        end
        if player:getInventoryCount(cache.itemId) == 0 then
            return false
        end
    end
    
    if actionType == UseTypes["SelectUseTarget"] then
        if not button.item or button.item:getItemId() == 0 then
            return false
        end
        if player:getInventoryCount(cache.itemId) == 0 then
            return false
        end
    end
    
    if actionType == UseTypes["chatText"] then
        if cache.isSpell then
            return MultiActionQueue.validateSpell(cache)
        end
        return true
    end
    
    return true
end

function MultiActionQueue.validateSpell(spellCache)
    if not spellCache or not spellCache.spellData then
        return false
    end
    
    local spellData = spellCache.spellData
    
    -- Verificar se aprendeu o spell
    if spellData.needLearn and not spellListData[tostring(spellData.id)] then
        return false
    end
    
    -- Verificar mana
    if spellData.mana and player:getMana() < spellData.mana then
        return false
    end
    
    -- Verificar soul
    if spellData.soul and player:getSoul() < spellData.soul then
        return false
    end
    
    -- Verificar nível
    if spellData.level and player:getLevel() < spellData.level then
        return false
    end
    
    -- Verificar vocação
    if spellData.vocations then
        local playerVocation = translateVocation(player:getVocation())
        if not table.contains(spellData.vocations, playerVocation) then
            return false
        end
    end
    
    -- Verificar cooldown/exaustão
    if spellCooldownCache[spellData.id] then
        local cache = spellCooldownCache[spellData.id]
        local now = g_clock.millis()
        
        if cache.exhaustion and cache.exhaustion > now then
            return false
        end
        
        if cache.startTime and cache.startTime > now then
            return false
        end
    end
    
    return true
end

-- /*=============================================
-- =            Action Execution              =
-- =============================================*/

function MultiActionQueue.executeAction(action)
    if not action or not action.button then
        return false
    end
    
    local button = action.button
    local cache = getButtonCache(button)
    
    if not cache then
        return false
    end
    
    local actionType = cache.actionType
    
    -- Executa a ação conforme seu tipo
    if actionType == UseTypes["Use"] and button.item then
        if button.item:getItem():isContainer() then
            g_game.closeContainerByItemId(button.item:getItemId())
        else
            g_game.useInventoryItem(button.item:getItemId())
        end
        return true
    end
    
    if actionType == UseTypes["Equip"] and button.item then
        local tier = g_game.getFeature(GameThingUpgradeClassification) and cache.upgradeTier or 0
        g_game.equipItemId(cache.itemId, tier)
        return true
    end
    
    if actionType == UseTypes["UseOnYourself"] and button.item then
        g_game.useInventoryItemWith(button.item:getItemId(), player, button.item:getItemSubType() or -1)
        if not g_game.getFeature(GameEnterGameShowAppearance) then
            updateInventoryItems()
        end
        return true
    end
    
    if actionType == UseTypes["UseOnTarget"] then
        if button.item then
            local attackingCreature = g_game.getAttackingCreature()
            if attackingCreature then
                g_game.useWith(button.item:getItem(), attackingCreature, button.item:getItemSubType() or -1)
            else
                modules.game_interface.startUseWith(button.item:getItem(), button.item:getItemSubType() or -1)
            end
        end
        return true
    end
    
    if actionType == UseTypes["SelectUseTarget"] then
        if button.item then
            modules.game_interface.startUseWith(button.item:getItem(), button.item:getItemSubType() or -1)
        end
        return true
    end
    
    if actionType == UseTypes["chatText"] and cache.param then
        if cache.isSpell then
            spellGroupPressed[tostring(cache.primaryGroup)] = true
            g_game.talk(cache.param)
        else
            modules.game_console.sendMessage(cache.param)
        end
        modules.game_console.getConsole():setText('')
        return true
    end
    
    return false
end

-- /*=============================================
-- =            Utility Functions              =
-- =============================================*/

function MultiActionQueue.getState()
    return MultiActionQueue.state
end

function MultiActionQueue.getStateName()
    for k, v in pairs(MultiActionQueue.STATE) do
        if v == MultiActionQueue.state then
            return k
        end
    end
    return "UNKNOWN"
end

function MultiActionQueue.setActionDelay(ms)
    MultiActionQueue.actionDelay = math.max(10, ms)
end

function MultiActionQueue.getActionDelay()
    return MultiActionQueue.actionDelay
end

return MultiActionQueue
