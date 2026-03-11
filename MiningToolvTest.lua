local sampev = require 'lib.samp.events'

-- Настройки очереди
local active = false
local currentStep = 1 
-- Твои индексы видеокарт
local gpu_indexes = {1, 2, 3, 4, 7, 8, 9, 10, 13, 14, 15, 16, 19, 20, 21, 22, 25, 26, 27, 28}

function main()
    while not isSampAvailable() do wait(100) end
    
    -- Сообщения без сложных функций, чтобы точно работало
    sampAddChatMessage("{FFD700}[MiningBTC] {FFFFFF}Helper loaded! Type {00FF00}/fmf {FFFFFF}to start.", -1)

    sampRegisterChatCommand("fmf", function()
        active = not active
        currentStep = 1
        local status = active and "{00FF00}ON" or "{FF0000}OFF"
        sampAddChatMessage("{FFD700}[MiningBTC] {FFFFFF}Status: " .. status, -1)
        
        if active then
            sampProcessChatInput("/flashminer")
        end
    end)
    wait(-1)
end

-- Логика чата
function sampev.onServerMessage(color, text)
    if not active then return end

    -- Поиск по ключевым словам (английским или цифрам, чтобы не зависеть от кодировки)
    if text:find("предмет") or text:find("минимум 1") then
        lua_thread.create(function()
            currentStep = currentStep + 1
            wait(1200)
            sampAddChatMessage("{FFD700}[MiningBTC] {FFFFFF}Next card: " .. currentStep, -1)
            sampProcessChatInput("/flashminer")
        end)
    end
end

-- Логика диалогов
function sampev.onShowDialog(id, style, title, button1, button2, text)
    if not active then return end

    -- 1. Выбор дома (ищем по части заголовка)
    if title:find("Выбор") or title:find("дом") then
        lua_thread.create(function()
            wait(600)
            sampSendDialogResponse(id, 1, 0, nil) 
        end)
    end

    -- 2. Окно выбора видеокарты
    if title:find("видеокарт") or title:find("карт") then
        lua_thread.create(function()
            wait(700)
            if currentStep <= #gpu_indexes then
                local targetRow = gpu_indexes[currentStep]
                sampSendDialogResponse(id, 1, targetRow, nil)
            else
                sampAddChatMessage("{00FF00}[MiningBTC] {FFFFFF}Done! All 20 cards checked.", -1)
                active = false
            end
        end)
    end

    -- 3. Меню конкретной карты (Стойка/Полка)
    if title:find("Стойка") or title:find("Полка") then
        lua_thread.create(function()
            wait(500)
            sampSendDialogResponse(id, 1, 1, nil) -- "Забрать прибыль"
        end)
    end

    -- 4. Окно подтверждения
    if title:find("прибыли") or title:find("Вывод") then
        lua_thread.create(function()
            wait(500)
            sampSendDialogResponse(id, 1, 0, nil) -- Кнопка "Вывод"
        end)
    end
end
