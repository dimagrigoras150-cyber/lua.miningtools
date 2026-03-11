local sampev = require 'lib.samp.events'
local encoding = require 'encoding'
encoding.default = 'CP1251'
local u8 = encoding.UTF8_to_CP1251

-- Настройки очереди
local active = false
local currentStep = 1 
-- Твои проверенные индексы строк видеокарт (от 0 до 28)
local gpu_indexes = {1, 2, 3, 4, 7, 8, 9, 10, 13, 14, 15, 16, 19, 20, 21, 22, 25, 26, 27, 28}

function main()
    while not isSampAvailable() do wait(100) end
    
    sampAddChatMessage(u8("{FFD700}[MiningBTC] {FFFFFF}Помощник загружен! Включите: {00FF00}/fmf"), -1)

    sampRegisterChatCommand("fmf", function()
        active = not active
        currentStep = 1 -- Сброс на 1-ю карту при включении
        local status = active and u8("{00FF00}ВКЛЮЧЕН") or u8("{FF0000}ВЫКЛЮЧЕН")
        sampAddChatMessage(u8("{FFD700}[MiningBTC] ") .. status, -1)
        
        -- Если включили, сразу запускаем процесс
        if active then
            sampProcessChatInput("/flashminer")
        end
    end)
    wait(-1)
end

-- Ловим события в чате (Успех или Ошибка "1 коин")
function sampev.onServerMessage(color, text)
    if not active then return end

    -- Входящий текст от сервера уже в CP1251, ищем по ключевым словам
    if text:find("Вам был добавлен предмет") or text:find(u8("минимум 1 целый коин")) then
        lua_thread.create(function()
            currentStep = currentStep + 1 -- Переходим к следующей карте
            wait(1200) -- Пауза для стабильности
            sampAddChatMessage(u8("{FFD700}[MiningBTC] {FFFFFF}Иду к карте №") .. currentStep, -1)
            sampProcessChatInput("/flashminer") -- "Прыжок" назад в меню
        end)
    end
end

-- Ловим Диалоги
function sampev.onShowDialog(id, style, title, button1, button2, text)
    if not active then return end

    -- 1. Окно выбора дома
    if title:find(u8("Выбор дома")) then
        lua_thread.create(function()
            wait(600)
            sampSendDialogResponse(id, 1, 0, nil) -- Всегда первый дом
        end)
    end

    -- 2. Окно выбора видеокарты (29 строк)
    if title:find(u8("Выберите видеокарту")) then
        lua_thread.create(function()
            wait(700)
            if currentStep <= #gpu_indexes then
                local targetRow = gpu_indexes[currentStep]
                sampSendDialogResponse(id, 1, targetRow, nil)
            else
                sampAddChatMessage(u8("{00FF00}[MiningBTC] {FFFFFF}Все 20 карт обработаны! Скрипт спит."), -1)
                active = false
            end
        end)
    end

    -- 3. Меню конкретной карты (Стойка №...)
    if title:find(u8("Стойка №")) then
        lua_thread.create(function()
            wait(500)
            -- Нажимаем на "Забрать прибыль" (индекс 1)
            sampSendDialogResponse(id, 1, 1, nil)
        end)
    end

    -- 4. Окно подтверждения (Вывод прибыли)
    if title:find(u8("Вывод прибыли")) then
        lua_thread.create(function()
            wait(500)
            -- Нажимаем кнопку "Вывод" (ID 1)
            sampSendDialogResponse(id, 1, 0, nil) 
        end)
    end
end
