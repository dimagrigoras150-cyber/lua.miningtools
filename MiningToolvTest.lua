script_name('MiningBTC Helper v3.0 Beta')
local imgui = require('mimgui')
local encoding = require('encoding')
local sampev = require("lib.samp.events")
local vkeys = require('vkeys')
encoding.default = 'CP1251'
local u8 = encoding.UTF8

-- [[ НАСТРОЙКИ И СОСТОЯНИЕ ]]
local active = false
local currentStep = 1
local currentHouse = 0
local totalBTC = 0 
local maxHouses = 15
local targetTime = nil
local isWaiting = false
local gpu_indexes = {1, 2, 3, 4, 7, 8, 9, 10, 13, 14, 15, 16, 19, 20, 21, 22, 25, 26, 27, 28}

-- Переменные MIMGUI
local showMenu = imgui.new.bool(false)
-- [[ ЗАГРУЗКА ШРИФТА (ТОЛЬКО ОДИН РАЗ) ]]
local imgui_font = nil
imgui.OnInitialize(function()
    local config = imgui.ImFontConfig()
    config.GlyphRanges = imgui.GetIO().Fonts:GetGlyphRangesCyrillic()
    
    -- Путь к шрифту (убедись, что agora.ttf лежит в папке moonloader)
    local fontPath = getWorkingDirectory() .. '\\agora.ttf' 
    
    if doesFileExist(fontPath) then
        -- ВОТ ЗДЕСЬ МЕНЯЕМ РАЗМЕР НА 18
        imgui_font = imgui.GetIO().Fonts:AddFontFromFileTTF(fontPath, 18, config) 
        imgui.GetIO().Fonts:Build()
    else
        sampAddChatMessage("{FF0000}[MiningBTC] ОШИБКА: agora.ttf не найден!", -1)
    end
end)

imgui.OnFrame(function() return showMenu end, function(player)
    -- 1. Подключаем шрифт (надеюсь, он у нас 18-20 размера для такого стиля)
    if imgui_font then imgui.PushFont(imgui_font) end 

    imgui.SetNextWindowPos(imgui.ImVec2(20, 350), imgui.Cond.FirstUseEver)
    -- Увеличим ширину до 400, чтобы выглядело солидно
    imgui.SetNextWindowSize(imgui.ImVec2(400, 0), imgui.Cond.Always)

    -- [[ СТИЛИ ДЛЯ КРАСИВОГО ОКНА ]]
    local style = imgui.GetStyle()
    style.WindowRounding = 12.0     -- Более мягкие углы
    style.WindowBorderSize = 1.5    -- Чуть заметнее рамка
    style.WindowPadding = imgui.ImVec2(20, 20) -- Больше "воздуха" внутри

    imgui.PushStyleColor(imgui.Col.WindowBg, imgui.ImVec4(0.06, 0.06, 0.06, 0.96)) -- Глубокий черный
    imgui.PushStyleColor(imgui.Col.Border, imgui.ImVec4(1.0, 0.7, 0.0, 0.5))    -- Золотая рамка

    imgui.Begin("Mining Helper v3.0 Beta", showMenu, imgui.WindowFlags.NoDecoration)
        
        -- [[ ЗАГОЛОВОК ]]
        imgui.TextColored(imgui.ImVec4(1.0, 0.8, 0.0, 1.0), "Mining Helper v3.0 Beta")
        
        -- [[ ТА САМАЯ ЗОЛОТАЯ ПОЛОСКА (ГРАДИЕНТ) ]]
        local draw = imgui.GetWindowDrawList()
        local p = imgui.GetCursorScreenPos()
        local w = imgui.GetWindowWidth()
        -- Рисуем линию от золотого к прозрачному
        draw:AddRectFilledMultiColor(imgui.ImVec2(p.x, p.y + 5), imgui.ImVec2(p.x + w - 40, p.y + 7), 
            0xFF00AAFF, 0x0000AAFF, 0x0000AAFF, 0xFF00AAFF) -- Золотистый градиент
        
        imgui.Dummy(imgui.ImVec2(0, 15)) -- Отступ после линии

        -- [[ КОНТЕНТ (УВЕЛИЧЕННЫЙ) ]]
        imgui.Text(u8"Статус: ") imgui.SameLine()
        if active then imgui.TextColored(imgui.ImVec4(0.0, 1.0, 0.0, 1.0), "RUNNING")
        else imgui.TextColored(imgui.ImVec4(1.0, 0.2, 0.2, 1.0), "PAUSED") end
        
        imgui.Spacing()
        
        imgui.Text(u8(string.format("Дом: %d/%d | Карта: %d/20", currentHouse, maxHouses, currentStep)))
        imgui.Text(u8"Собрано за сессию: ") imgui.SameLine()
        imgui.TextColored(imgui.ImVec4(1.0, 0.8, 0.0, 1.0), tostring(totalBTC) .. " BTC")

        imgui.Dummy(imgui.ImVec2(0, 10))
        -- [[ ВОЗВРАЩАЕМ ТАЙМЕР ]]
        imgui.Spacing()
        if targetTime and not active then
            local remaining = targetTime - os.time()
            if remaining > 0 then
                local h, m, s = math.floor(remaining / 3600), math.floor((remaining % 3600) / 60), remaining % 60
                -- Сделаем его ярко-зеленым, чтобы бросался в глаза
                imgui.TextColored(imgui.ImVec4(0.0, 1.0, 0.5, 1.0), u8(string.format("Отложенный старт: %02d:%02d:%02d", h, m, s)))
            else 
                targetTime = nil 
            end
        else
            -- Вместо пустоты или надписи "Готов" сделаем серую заглушку
            imgui.PushStyleColor(imgui.Col.Text, imgui.ImVec4(0.4, 0.4, 0.4, 1.0))
            imgui.Text(u8"Таймер не запущен")
            imgui.PopStyleColor()
        end
        imgui.Separator()
        imgui.Spacing()

        -- Подсказки внизу
        imgui.PushStyleColor(imgui.Col.Text, imgui.ImVec4(0.5, 0.5, 0.5, 1.0))
        imgui.Text(u8"'F3' - Пауза/Старт | /freset - Сброс")
        imgui.PopStyleColor()

    imgui.End()
    imgui.PopStyleColor(2)
    if imgui_font then imgui.PopFont() end 
end)

function main()
    while not isSampAvailable() do wait(100) end
    
    -- Выводим строго 4 строки
    sampAddChatMessage("{FFD700}[MiningBTC] {FFFFFF}Скрипт v3.0 Beta загружен!", -1)
    sampAddChatMessage("{00FF00}F2 {FFFFFF}- скрыть меню | {00FF00}F3 {FFFFFF}- пауза/старт", -1)
    sampAddChatMessage("{00FF00}/fwait [часы] {FFFFFF}- запустить таймер", -1)
    sampAddChatMessage("{00FF00}/freset {FFFFFF}- сбросить прогресс и таймер", -1)

    sampRegisterChatCommand("fwait", startTimer)
    sampRegisterChatCommand("freset", function()
        currentStep, currentHouse, totalBTC, active, targetTime = 1, 0, 0, false, nil
        sampAddChatMessage("{FFD700}[MiningBTC] {FFFFFF}Прогресс и таймер сброшены.", -1)
    end)

    while true do
        wait(0)
        if isKeyJustPressed(vkeys.VK_F2) then showMenu[0] = not showMenu[0] end
        if isKeyJustPressed(vkeys.VK_F3) then toggleMining() end
    end
end

function toggleMining()
    active = not active
    isWaiting = false
    if active then 
        sampAddChatMessage("{FFD700}[MiningBTC] {00FF00}Старт!", -1)
        sampProcessChatInput("/flashminer") 
    else
        sampAddChatMessage("{FFD700}[MiningBTC] {FF4444}Пауза.", -1)
    end
end

function startTimer(arg)
    local hours = tonumber(arg)
    if hours then
        targetTime = os.time() + (hours * 3600)
        lua_thread.create(function()
            wait(hours * 3600 * 1000)
            if not active then targetTime = nil toggleMining() end
        end)
    end
end

function processNextStep()
    lua_thread.create(function()
        isWaiting = true
        currentStep = currentStep + 1
        wait(200)
        if active then sampProcessChatInput("/flashminer") end
        wait(300)
        isWaiting = false
    end)
end

-- [[ ЛОГИКА ЧАТА - БЕЗ u8:decode ]]
function sampev.onServerMessage(color, text)
    if not active then return end
    local cleanText = text:gsub('{......}', ''):lower()
    
    if cleanText:find("Выберите дом с майнинг") or 
       cleanText:find("минимум 1") or 
       cleanText:find("целыми частями") or
       cleanText:find("Вам был добавлен предмет") then
        
        if (cleanText:find("минимум 1") or cleanText:find("целыми частями")) and not isWaiting then
            processNextStep()
        end
        return false 
    end
end

-- [[ ЛОГИКА ДИАЛОГОВ - БЕЗ u8:decode ]]
function sampev.onShowDialog(id, style, title, button1, button2, text)
    if not active then return end
    local cleanTitle = title:gsub('{......}', '')

    if cleanTitle:find("Выбор") and not cleanTitle:find("видеокарт") then
        lua_thread.create(function() wait(200) sampSendDialogResponse(id, 1, currentHouse, "") end)
        return false 
    end

    if cleanTitle:find("видеокарт") then
        lua_thread.create(function()
            wait(250)
            if currentStep <= #gpu_indexes then
                sampSendDialogResponse(id, 1, gpu_indexes[currentStep], "")
            else
                currentHouse, currentStep = currentHouse + 1, 1
                if currentHouse < maxHouses then 
                    wait(250) 
                    sampProcessChatInput("/flashminer")
                else 
                    active = false 
                    sampAddChatMessage("{00FF00}[MiningBTC] Все дома обработаны! Работа завершена.", -1)
                end
            end
        end)
        return false 
    end

    if cleanTitle:find("Стойка №") then
        local btcVal = text:match("%(([%d%.]+)%s+BTC%)")
        lua_thread.create(function() 
            wait(200) 
            if btcVal and tonumber(btcVal) >= 1.0 then
                totalBTC = totalBTC + math.floor(tonumber(btcVal))
            end
            sampSendDialogResponse(id, 1, 1, "") 
        end)
        return false 
    end

    if cleanTitle:find("прибыли") then
        lua_thread.create(function() wait(125) sampSendDialogResponse(id, 1, 0, "") end)
        return false 
    end
end
