script_version('12.01.2023')
script_author("Lucifer_Heaven (KitGov4e)") -- Тема blasthk www.blast.hk/threads/98943
require "lib.moonloader"
local hook = require 'samp.events'
local inicfg = require "inicfg"

local version = script.this.version

local miningtool = true -- Выключить главный код скрипта
local automining_status = false
local usefullfill = false
local automining_getbtc = 0
local automining_startall = 0
local automining_fillall = 0
local automining_fillall_ASC = 0
local tablestatuscount = 0
local tablefillcount = 0

local chosenhouse = 0
local fillall_pressed = false -- Защита от повторного наполнения

local oxladtime = 224 -- Часы, на сколько хватит охлада

local MiningMainIni = inicfg.load({
  dialogs =
  {
    FlashDialogID = 25182, -- ID Диалога главного (флешка)
	MainDialogID = 25244, -- ID Диалога главного
    CardDialogID = 25245, -- ID Диалога с действиями для видеокарты
	CardConfirmID = 25246, -- ID Диалога с подтверждением для снятия битков
	FillTypeID = 25271, -- ID Диалога с выбором типа жидкости
	HouseChoseID = 7238, -- ID Диалога с выбором дома
	MaxFill = 49, -- Уровень % охлада, выше которого скрипт заливать больше не будет
	mtwait = 750, -- Время задержки в действиях (В мсек)
	mtupd = true -- Функция автообновления диалога
  }
}, "MiningTool.ini")

if not doesFileExist('moonloader/config/MiningTool.ini') then inicfg.save(MiningMainIni, 'MiningTool.ini') end -- Нет конфига = создать его

local INFO = { 
    0.029999,
    0.059999,
    0.09,
    0.11999,
    0.15,
    0.18,
	0.209999,
	0.239999,
	0.27,
	0.3
} -- Прибыль в час по лвл (от 1 до 10)

local dtext = {} -- Таблица для текста всего главного диалога.
local tablestatus = {} -- Таблица для ID строк работающих видеокарт, на которые надо нажать.
local tablebtc = {} -- Таблица для ID строк видеокарт с 1+ BTC, на которые надо нажать.
local tablefill = {} -- Таблица для ID строк видеокарт с уровнем охлада меньше, чем MaxFill и на которые надо нажать.
local tablefill_ASC = {} -- Таблица для ID строк видеокарт типа ASC с уровнем охлада меньше, чем MaxFill и на которые надо нажать.

local MainDialogID = MiningMainIni.dialogs.MainDialogID
local CardDialogID = MiningMainIni.dialogs.CardDialogID
local CardConfirmID = MiningMainIni.dialogs.CardConfirmID
local FlashDialogID = MiningMainIni.dialogs.FlashDialogID
local FillTypeID = MiningMainIni.dialogs.FillTypeID
local HouseChoseID = MiningMainIni.dialogs.HouseChoseID
local MaxFill = MiningMainIni.dialogs.MaxFill -- Выше этого порога заливать не будет.
local mtwait = MiningMainIni.dialogs.mtwait -- Время задержки в действиях (В мсек).
local mtupd = MiningMainIni.dialogs.mtupd -- Функция автообновления диалога
 
function main()
	while not isSampAvailable() do wait(0) end
		sampRegisterChatCommand("miningtool", function() -- Команда для перезапуска скрипта и загрузки конфига по новой.
		    sampAddChatMessage('[MiningTool] {FFFFFF}Скрипт перезапущен! Конфиг перезагружен!', 0xFF6060)
			thisScript():reload()
		end)
		sampRegisterChatCommand('mtwait', function(num)
            if type(tonumber(num)) == 'number' and tonumber(num) > 99 and tonumber(num) < 5001 then
			    num = tonumber(num)
				mtwait = num
				MiningMainIni.dialogs.mtwait = mtwait
				if inicfg.save(MiningMainIni, 'MiningTool.ini') then
					sampAddChatMessage('[MiningTool] {FFFFFF}Установлена задержка действий в {BEF781}'..mtwait..' мсек {FFFFFF}| По умолчанию - 500 мсек', 0xFF6060)
				end				
			else
				sampAddChatMessage('[MiningTool] {FFFFFF}Ошибка! Используйте число от 100 до 5000 (Миллисекунд)', 0xFF6060)
			end
		end)
		sampRegisterChatCommand('mtmaxfill', function(num)
            if type(tonumber(num)) == 'number' and tonumber(num) > 0 and tonumber(num) < 100 then
			    num = tonumber(num)
				MaxFill = num
				MiningMainIni.dialogs.MaxFill = MaxFill
				if inicfg.save(MiningMainIni, 'MiningTool.ini') then
					sampAddChatMessage('[MiningTool] {FFFFFF}Скрипт не будет заливать охлаждение, если в видеокарте его больше {BEF781}'..MaxFill..'%%%%', 0xFF6060)
				end				
			else
				sampAddChatMessage('[MiningTool] {FFFFFF}Ошибка! Используйте число от 1 до 99', 0xFF6060)
			end
		end)
		sampRegisterChatCommand('mtupd', function() 
				mtupd = not mtupd
				sampAddChatMessage(mtupd and '[MiningTool] Автообновление диалогов включено!' or '[MiningTool] Автообновление диалогов выключено!', 0xFF6060)
				MiningMainIni.dialogs.mtupd = mtupd
				inicfg.save(MiningMainIni, 'MiningTool.ini')		
		end)		
		
		sampAddChatMessage('[MiningTool (От '..version..')] {FFFFFF}Готов к работе. ', 0xFF6060)
	wait(-1)
end



function hook.onShowDialog(dialogId, dialogStyle, dialogTitle, okButtonText, cancelButtonText, dialogText)
    if miningtool then
		if mtupd == true then
		mtupd_text_paceholder = '[MiningTool] (/mtupd для отключения функции) {FFFFFF}Обнаружены изменения в ID диалога. Обновление...'
			if dialogTitle:find('Выберите видеокарту') then
				if dialogTitle:find('дом') then
					if dialogId ~= FlashDialogID then
						sampAddChatMessage(mtupd_text_paceholder, 0xFF6060)
						dialogupdate(5, dialogId)
					end
				else
					if dialogId ~= MainDialogID then
						sampAddChatMessage(mtupd_text_paceholder, 0xFF6060)
						dialogupdate(1, dialogId)
					end
				end
			end
			if dialogTitle:find('Стойка') and dialogTitle:find('Полка') then
				if dialogId ~= CardDialogID then
					sampAddChatMessage(mtupd_text_paceholder, 0xFF6060)
					dialogupdate(2, dialogId)
				end
			end	
			if dialogTitle:find('Вывод прибыли видеокарты') then
				if dialogId ~= CardConfirmID then
					sampAddChatMessage(mtupd_text_paceholder, 0xFF6060)
					dialogupdate(3, dialogId)
				end
			end
			if dialogTitle:find('Выберите тип жидкости') then
				if dialogId ~= FillTypeID then
					sampAddChatMessage(mtupd_text_paceholder, 0xFF6060)
					dialogupdate(4, dialogId)
				end
			end	
			if dialogTitle:find('Выбор дома') then
				if dialogId ~= HouseChoseID then
					sampAddChatMessage(mtupd_text_paceholder, 0xFF6060)
					dialogupdate(6, dialogId)
				end
			end			
		end

	    if dialogId == MainDialogID or dialogId == FlashDialogID or dialogId == 0 and dialogTitle:find('Обзор всех видеокарт') or dialogTitle:find('Выберите видеокарту') then
			local automining_btcoverall = 0
			local automining_btcoverallph = 0
			local automining_btcamountoverall = 0
			local automining_videocards = 0
			local automining_videocardswork = 0
			-- ASC обявление переменных
			local automining_ASCoverall = 0
			local automining_ASCoverallph = 0
			local automining_ASCamountoverall = 0
			--
			for line in dialogText:gmatch("[^\n]+") do
                dtext[#dtext+1] = line			
            end
			
			if dtext[1]:find('%(коин%)') then
			    dtext[1] = dtext[1]:gsub('%(коин%)', '%1 | До 9 | До 15 коинов')
			end
			
			for d = 1, #dtext do
				if dtext[d]:find('Полка%s+№%d+%s+|%s+%{BEF781%}%W+%s+%d+%p%d+%s+%a+%s+%d+%s+уровень%s+%d+%p%d+%%') then	-- Статус, работает или нет					
					automining_status = 1
					automining_statustext = '{BEF781}'
				else
					automining_status = 0
					automining_statustext = '{F78181}'
				end
				local automining_lvl = tonumber(dtext[d]:match('Полка%s+№%d+%s+|%s+%{......%}%W+%s+%d+%p%d+%s+%a+%s+(%d+)%s+уровень%s+%d+%p%d+%%')) -- Уровень видюхи
				local automining_fillstatus = tonumber(dtext[d]:match('Полка%s+№%d+%s+|%s+%{......%}%W+%s+%d+%p%d+%s+%a+%s+%d+%s+уровень%s+(%d+%p%d+)%%')) -- Залито охлада в процентах
                local automining_fillstatus_thisisASC = dtext[d]:find('Полка%s+№%d+%s+|%s+%{......%}%W+%s+%d+%p%d+%s+ASC%s+%d+%s+уровень%s+%d+%p%d+%%') -- Это ASC карта
				local automining_btcamount = tonumber(dtext[d]:match('Полка%s+№%d+%s+|%s+%{......%}%W+%s+(%d+%p%d+)%s+%a+%s+%d+%s+уровень%s+%d+%p%d+%%')) -- Число битков сейчас в видюхе              						
					if automining_lvl ~= nil and automining_lvl ~= 0 and automining_fillstatus ~= nil and automining_btcamount ~= nil then					    												
						automining_videocards = automining_videocards + 1
						automining_btctimetofull = math.ceil((9 - automining_btcamount) / INFO[automining_lvl])
						automining_btctimetofull_15 = math.ceil((15 - automining_btcamount) / INFO[automining_lvl])					
						if automining_status == 1 then 
							automining_videocardswork = automining_videocardswork + 1
						elseif automining_status == 0 and automining_btcamount ~= 9 and automining_fillstatus > 0 then
							idd = d - 2
							tablestatus[#tablestatus+1] = idd
						end
						if automining_btcamount >= 1 then 
							automining_btcamountinfo = true
							idd2 = d - 2
							tablebtc[#tablebtc+1] = idd2				
						else 
							automining_btcamountinfo = false 
						end
						
						if automining_fillstatus_thisisASC ~= nil then
							if automining_fillstatus < MaxFill then
								idd3 = d - 2
								tablefill_ASC[#tablefill_ASC+1] = idd3
							end
						elseif automining_fillstatus < MaxFill then
							idd3 = d - 2
							tablefill[#tablefill+1] = idd3
						end
						
						if tablefill ~= nil then
							tablefilltopress = tablefill[1]
						else
							tablefilltopress = nil
						end
						
						if tablefill_ASC ~= nil then
							tablefilltopress_ASC = tablefill_ASC[1]
						else
							tablefilltopress_ASC = nil
						end
						
						if tablebtc ~= nil then
							tablebtctopress = tablebtc[1]
						else
							tablebtctopress = nil
						end
						
						if tablestatus ~= nil then
							tablestatustopress = tablestatus[1]
						else
							tablestatustopress = nil
						end					
												
						automining_fillstatushours = math.ceil(oxladtime * (automining_fillstatus / 100)) -- На сколько часов охлада
						automining_fillstatusbtc = automining_fillstatushours * INFO[automining_lvl] -- Сколько видюха еще даст BTC
												
						if automining_fillstatus_thisisASC ~= nil then
							automining_ASCamountoverall = automining_ASCamountoverall + math.floor(automining_btcamount) -- Подсчет сколько ASC доступно для снятия
							automining_ASCoverall = automining_ASCoverall + automining_fillstatusbtc -- Подсчет сколько всего ASC дадут все видюхи
						else
							automining_btcamountoverall = automining_btcamountoverall + math.floor(automining_btcamount) -- Подсчет сколько доступно для снятия
							automining_btcoverall = automining_btcoverall + automining_fillstatusbtc -- Подсчет сколько всего дадут все видюхи
						end
						
						if automining_fillstatus > 0 and automining_status == 1 then
							if automining_fillstatus_thisisASC ~= nil then
								automining_ASCoverallph = automining_ASCoverallph + INFO[automining_lvl]
							else
								automining_btcoverallph = automining_btcoverallph + INFO[automining_lvl]
							end
						end
						if dialogId ~= FlashDialogID then 
							dtext[d] = dtext[d]:gsub('Полка%s+№%d+%s+|%s+%{......%}%W+%s+%d+%p%d+%s+%a+%s+'..automining_lvl..'%s+уровень', '%1 | '..automining_statustext..INFO[automining_lvl]..'/Час')
						end
						if automining_fillstatus > 0 then
							if dialogId ~= FlashDialogID then 
								dtext[d] = dtext[d]:gsub('Полка%s+№%d+%s+|%s+%{......%}%W+%s+%d+%p%d+%s+%a+%s+%d+%s+уровень%s+|%s+%{......%}%d+%p%d+/Час%s+'..automining_fillstatus..'%A+', '%1 '..tostring(automining_status and '{BEF781}' or '{F78181}')..'- [~'..automining_fillstatushours..'ч] {FFFFFF}|{81DAF5} [~'..string.format("%.1f", automining_fillstatusbtc)..' Coins]')
						    else
								dtext[d] = dtext[d]:gsub('Полка%s+№%d+%s+|%s+%{......%}%W+%s+%d+%p%d+%s+%a+%s+%d+%s+уровень%s+'..automining_fillstatus..'%A+', '%1 '..tostring(automining_status and '{BEF781}' or '{F78181}')..'- [~'..automining_fillstatushours..'ч]')
							end
						else
						    if dialogId ~= FlashDialogID then
								dtext[d] = dtext[d]:gsub('Полка%s+№%d+%s+|%s+%{......%}%W+%s+%d+%p%d+%s+%a+%s+%d+%s+уровень%s+|%s+%{......%}%d+%p%d+/Час%s+'..automining_fillstatus..'%A+', '%1 {F78181}(!)')
							else
								dtext[d] = dtext[d]:gsub('Полка%s+№%d+%s+|%s+%{......%}%W+%s+%d+%p%d+%s+%a+%s+%d+%s+уровень%s+'..automining_fillstatus..'%A+', '%1 {F78181}(!)')
							end
						end
						
						dtext[d] = dtext[d]:gsub('Полка%s+№%d+%s+|%s+%{......%}%W+%s+%d+%p%d+%s+%a+', '%1 '..tostring(automining_btcamountinfo and '{BEF781}•' or '{F78181}•')..' {ffffff}| '..automining_statustext..'~'..automining_btctimetofull..'ч {ffffff}| '..automining_statustext..'~'..automining_btctimetofull_15..'ч')
					
					elseif automining_lvl ~= nil and automining_lvl == 0 then
						dtext[d] = dtext[d]:gsub('Полка%s+№%d+%s+|%s+%{......%}%W+%s+%d+%p%d+%s+%a+%s+%d+%s+уровень', '%1 |{F78181} Ошибка!')
					end				
			end
			
		if dialogId == MainDialogID or dialogId == FlashDialogID then		
			
		    local automining_fillstatus1 = tonumber(dialogText:match('Полка №1 |%s+%{......%}%W+%s+%d+%p%d+%s+%a+%s+%d+%s+уровень%s+(%d+%p%d+)%A'))
			local automining_fillstatus2 = tonumber(dialogText:match('Полка №2 |%s+%{......%}%W+%s+%d+%p%d+%s+%a+%s+%d+%s+уровень%s+(%d+%p%d+)%A'))
			local automining_fillstatus3 = tonumber(dialogText:match('Полка №3 |%s+%{......%}%W+%s+%d+%p%d+%s+%a+%s+%d+%s+уровень%s+(%d+%p%d+)%A'))
			local automining_fillstatus4 = tonumber(dialogText:match('Полка №4 |%s+%{......%}%W+%s+%d+%p%d+%s+%a+%s+%d+%s+уровень%s+(%d+%p%d+)%A'))
			
			local automining_getbtcstatus1 = tonumber(dialogText:match('Полка №1 |%s+%{......%}%W+%s+(%d+)%p%d+%s+%a+%s+%d+%s+уровень%s+%d+.'))
			local automining_getbtcstatus2 = tonumber(dialogText:match('Полка №2 |%s+%{......%}%W+%s+(%d+)%p%d+%s+%a+%s+%d+%s+уровень%s+%d+.'))
			local automining_getbtcstatus3 = tonumber(dialogText:match('Полка №3 |%s+%{......%}%W+%s+(%d+)%p%d+%s+%a+%s+%d+%s+уровень%s+%d+.'))
			local automining_getbtcstatus4 = tonumber(dialogText:match('Полка №4 |%s+%{......%}%W+%s+(%d+)%p%d+%s+%a+%s+%d+%s+уровень%s+%d+.'))				
			
			for i = 1, 4 do
			    local automining_lvl = tonumber(dialogText:match('Полка №'..i..' |%s+%{......%}%W+%s+%d+%p%d+%s+%a+%s+(%d+)%s+уровень%s+%d+.'))
				local automining_fillstatus = tonumber(dialogText:match('Полка №'..i..' |%s+%{......%}%W+%s+%d+%p%d+%s+%a+%s+%d+%s+уровень%s+(%d+%p%d+)%A'))
			    if automining_fillstatus ~= nil then
					if automining_fillstatus > 0 and automining_lvl ~= nil then
						automining_fillstatushours =  math.ceil(224 * (automining_fillstatus / 100))
						dialogText = dialogText:gsub('Полка №'..i..' |%s+%{......%}%W+%s+%d+%p%d+%s+%a+%s+%d+%s+уровень%s+%d+%p%d+%A', '%1 {BEF781}- [~'..automining_fillstatushours..'ч]')	
					end				
					if automining_lvl > 0 then
						dialogText = dialogText:gsub('Полка №'..i..' |%s+%{......%}%W+%s+%d+%p%d+%s+%a+%s+%d+%s+уровень', '%1 | '..INFO[automining_lvl]..'/Час')
					end
                end				
			end					
				
			if automining_getbtc == 1 then
			    if #tablebtc ~= 0 and tablebtc ~= nil then
					for fg = 1, #tablebtc do
					    if dialogId == MainDialogID or dialogId == FlashDialogID then
							sampSendDialogResponse(dialogId,1,tablebtc[fg],nil)
							break
					    end				
					end
				else
				    sampAddChatMessage('[MiningTool] {FFFFFF}Сбор завершен.', 0xFF6060)
					automining_getbtc = 2 -- Выключить забор битков
					thisScript():reload()
				end
			tablebtc = {}
			end			
			
			if automining_startall == 1 then
			    if #tablestatus ~= 0 and tablestatus ~= nil then
					for f = 1, #tablestatus do					   
					    if dialogId == MainDialogID or dialogId == FlashDialogID then
							sampSendDialogResponse(dialogId,1,tablestatus[f],nil)
							break
					    end						
					end
				else
				    sampAddChatMessage('[MiningTool] {FFFFFF}Запуск завершен.', 0xFF6060)
					automining_startall = 2 -- Выключить старт всех
					thisScript():reload()
				end
			tablestatus = {}
			end
			
            if automining_fillall == 1 then
				fillall_pressed = false
				fillall_pressed2 = false
			    if #tablefill ~= 0 and tablefill ~= nil then
					for fl = 1, #tablefill do					   
					    if dialogId == MainDialogID then
							sampSendDialogResponse(dialogId,1,tablefill[fl],nil)
							break
					    end						
					end
				else
				    sampAddChatMessage('[MiningTool] {FFFFFF}Заливка завершена.', 0xFF6060)
					automining_fillall = 2 -- Выключить залив
					thisScript():reload()
				end
			tablefill = {}
			end
            -- Заливка в Arizona Card
            if automining_fillall_ASC == 1 then
				fillall_pressed = false
				fillall_pressed2 = false
			    if #tablefill_ASC ~= 0 and tablefill_ASC ~= nil then
					for fl = 1, #tablefill_ASC do					   
					    if dialogId == MainDialogID then
							sampSendDialogResponse(dialogId,1,tablefill_ASC[fl],nil)
							break
					    end						
					end
				else
				    sampAddChatMessage('[MiningTool] {FFFFFF}Заливка завершена.', 0xFF6060)
					automining_fillall_ASC = 2 -- Выключить залив
					thisScript():reload()
				end
			tablefill_ASC = {}
			end
			--
		end
		
		dialogText = table.concat(dtext,'\n')
        dtext = {}
		tablestatuscount = #tablestatus
		tablefillcount = #tablefill
		tablefillcount_ASC = #tablefill_ASC
		tablestatus = {}
		tablebtc = {}
		tablefill = {}
		tablefill_ASC = {}
        dialogText = dialogText .. '\n' .. ' '
		dialogText = dialogText .. '\n' .. '{ffff00}Информация\t{ffff00}Доступно снять\t{ffff00}Прибыль в час\t{ffff00}Прибыль прогнозируемая'
		if dialogText:find('ASC') and dialogText:find('BTC') then
		    dialogText = dialogText .. '\n' .. '{FFFFFF}Всего: '..automining_videocards..' | {BEF781}Работают '..automining_videocardswork..'\t{FFFFFF}'..string.format("%.0f", automining_btcamountoverall)..' BTC | {9966FF}'..string.format("%.0f", automining_ASCamountoverall)..' ASC\t{BEF781}'..automining_btcoverallph..' {FFFFFF}BTC | {BEF781}'..automining_ASCoverallph..' {9966FF}ASC\t{81DAF5}'..string.format("%.1f", automining_btcoverall)..' {FFFFFF}BTC | {81DAF5}'..string.format("%.1f", automining_ASCoverall)..' {9966FF}ASC'
		elseif dialogText:find('BTC') then
			dialogText = dialogText .. '\n' .. '{FFFFFF}Всего: '..automining_videocards..' | {BEF781}Работают '..automining_videocardswork..'\t{FFFFFF}'..string.format("%.0f", automining_btcamountoverall)..' BTC\t{BEF781}'..automining_btcoverallph..' {FFFFFF}BTC\t{81DAF5}'..string.format("%.1f", automining_btcoverall)..' {FFFFFF}BTC'
		elseif dialogText:find('ASC') then
			dialogText = dialogText .. '\n' .. '{FFFFFF}Всего: '..automining_videocards..' | {BEF781}Работают '..automining_videocardswork..'\t{9966FF}'..string.format("%.0f", automining_ASCamountoverall)..' ASC\t{BEF781}'..automining_ASCoverallph..' {9966FF}ASC\t{81DAF5}'..string.format("%.1f", automining_ASCoverall)..' {9966FF}ASC'
		else
			dialogText = dialogText .. '\n' .. ' '
		end	
			if dialogTitle:find('Выберите видеокарту') then	
				if dialogText:find('Полка №1 | Свободна') and dialogText:find('Полка №2 | Свободна') and dialogText:find('Полка №3 | Свободна') and dialogText:find('Полка №4 | Свободна') and dialogId ~= FlashDialogID then
					dialogText = dialogText .. '\n' .. ' '
					dialogText = dialogText .. '\n' .. '{FF6060}- Забрать всю прибыль (Полки пусты!)'
					dialogText = dialogText .. '\n' .. '{FF6060}- Запустить все видеокарты (Полки пусты!)'
					if dialogId ~= FlashDialogID then
						dialogText = dialogText .. '\n' .. '{FF6060}- Залить жидкость (Полки пусты!)'
					end					
				else
					dialogText = dialogText .. '\n' .. ' '
					if dialogText:find('ASC') and dialogText:find('BTC') then 
						dialogText = dialogText .. '\n' .. '{99FF99}- Забрать всю прибыль\t{99FF99}'..string.format("%.0f", automining_btcamountoverall)..' BTC + {9966FF}'..string.format("%.0f", automining_ASCamountoverall)..' ASC'
					elseif dialogText:find('BTC') then
						dialogText = dialogText .. '\n' .. '{99FF99}- Забрать всю прибыль\t{99FF99}'..string.format("%.0f", automining_btcamountoverall)..' BTC'
					elseif dialogText:find('ASC') then
						dialogText = dialogText .. '\n' .. '{99FF99}- Забрать всю прибыль\t{9966FF}'..string.format("%.0f", automining_ASCamountoverall)..' ASC'
					end
					dialogText = dialogText .. '\n' .. '{22FF00}- Запустить все видеокарты\t{22FF00}'..tablestatuscount..' из '..automining_videocards..' Штук'
					if dialogId ~= FlashDialogID then
						if dialogText:find('BTC') then
							dialogText = dialogText .. '\n' .. '{00FF55}- Залить жидкость (По 50%)\t{00FF55}В '..tablefillcount..' из '..automining_videocards..' Видеокарт'
							dialogText = dialogText .. '\n' .. '{99FFFF}- Залить жидкость (По 100%)\t{99FFFF}В '..tablefillcount..' из '..automining_videocards..' Видеокарт'
						else
							dialogText = dialogText .. '\n' .. '{c0c0c0}- Залить жидкость (По 50%)\t{c0c0c0}Недоступно'
							dialogText = dialogText .. '\n' .. '{c0c0c0}- Залить жидкость (По 100%)\t{c0c0c0}Недоступно'							
						end
						if dialogText:find('ASC') then
							dialogText = dialogText .. '\n' .. '{9966FF}- Залить жидкость (Для Arizona Cards)\t{9966FF}В '..tablefillcount_ASC..' из '..automining_videocards..' Видеокарт'
						end
					end
				end
			end
		automining_btcoverall = 0
	    automining_btcoverallph = 0
		automining_ASCoverall = 0
	    automining_ASCoverallph = 0
		tablestatuscount = 0
		tablefillcount = 0	
		return {dialogId, dialogStyle, dialogTitle, okButtonText, cancelButtonText, dialogText}
		end
		
		if dialogId == CardDialogID then
		
		    if automining_getbtc == 1 then
				if dialogText:find('Забрать прибыль') and dialogTitle:find('Стойка №%d+%s+') then
				    local automining_btcamount = tonumber(dialogText:match('Забрать прибыль %((%d+).%d+ '))
				    if automining_btcamount ~= 0 then
						sampSendDialogResponse(CardDialogID,1,1,nil)							
					else
						lua_thread.create(function()
							wait(mtwait)
							sampSendDialogResponse(CardDialogID,0,0,nil)
							return
						end)
					end
				else
				    sampSendDialogResponse(CardDialogID,0,0,nil)
				end
			end		    
			
			if automining_startall == 1 then
				if dialogText:find('Запустить видеокарту') and dialogTitle:find('Стойка №%d+%s+') then
				    lua_thread.create(function()
					    wait(mtwait)
						sampSendDialogResponse(CardDialogID,1,0,nil)
						return
					end)
				else
					sampSendDialogResponse(CardDialogID,0,0,nil)
				end
			end

		    if automining_fillall == 1 then
				if dialogTitle:find('Стойка №%d+%s+| Полка №') and not fillall_pressed then
					sampSendDialogResponse(CardDialogID,1,2,nil)
					fillall_pressed = true
				elseif fillall_pressed then
				    sampSendDialogResponse(CardDialogID,0,0,nil)
				end
			end
			
			-- Заливка в Arizona Card
		    if automining_fillall_ASC == 1 then
				if dialogTitle:find('Стойка №%d+%s+| Полка №') and not fillall_pressed then
					sampSendDialogResponse(CardDialogID,1,2,nil)
					fillall_pressed = true
				elseif fillall_pressed then
				    sampSendDialogResponse(CardDialogID,0,0,nil)
				end
			end
			--			
	    end
		
	    if dialogId == CardConfirmID and dialogTitle:find('Вывод прибыли видеокарты') then
     		if automining_getbtc == 1 then
				lua_thread.create(function()
					wait(mtwait)
					sampSendDialogResponse(CardConfirmID,1,nil,nil) -- Да
				return false
				end)
			end
	    end			
	    
		if dialogId == FillTypeID then
		    if automining_fillall == 1 then
				if not fillall_pressed2 then
					if usefullfill then
						if dialogText:find('%{......%}Супер охлаждающая жидкость для видеокарты\t%{......%}%[ 0 %]') then
							automining_fillall = 2
							sampAddChatMessage('[MiningTool] {FFFFFF}У вас закончилась супер охлаждающая жидкость!', 0xFF6060)
						else
							lua_thread.create(function()
							    fillall_pressed2 = true
								wait(mtwait*2)
								sampSendDialogResponse(FillTypeID,1,1,nil)
							return false
							end)
						end
					else
						if dialogText:find('%{......%}Охлаждающая жидкость для видеокарты\t%{......%}%[ 0 %]') then
							automining_fillall = 2
							sampAddChatMessage('[MiningTool] {FFFFFF}У вас закончилась охлаждающая жидкость!', 0xFF6060)
						else
							lua_thread.create(function()
							    fillall_pressed2 = true
								wait(mtwait*2)
								sampSendDialogResponse(FillTypeID,1,0,nil)
							return false
							end)
						end
					end
				else
					sampSendDialogResponse(FillTypeID,0,1,nil)
				end
			end
				
			if automining_fillall_ASC == 1 then
				if not fillall_pressed2 then
					if dialogText:find('%{......%}Охлаждающая жидкость для Arizona Video Card\t%{......%}%[ 0 %]') then
						automining_fillall = 2
						sampAddChatMessage('[MiningTool] {FFFFFF}У вас закончилась жидкость для Arizona Video Card!', 0xFF6060)
					else
						lua_thread.create(function()
							fillall_pressed2 = true
							wait(mtwait*2)
							sampSendDialogResponse(FillTypeID,1,2,nil)
						return false
						end)
					end
				else
					sampSendDialogResponse(FillTypeID,0,2,nil)
				end
			end			
		end
	end
end

function hook.onSendDialogResponse(DialogId, DialogButton, DialogList, DialogInput)
    if DialogId == MainDialogID and DialogList == 8 and DialogButton == 1 then
	    automining_getbtc = 1
		if tablebtctopress ~= nil then
			sampSendDialogResponse(MainDialogID,1,tablebtctopress,nil)
			sampAddChatMessage('[MiningTool] {FFFFFF}Забираем прибыль... Не открывайте другие диалоги во время этого!', 0xFF6060)
		else
			automining_getbtc = 2
			sampAddChatMessage('[MiningTool] {FFFFFF}Забирать больше нечего.', 0xFF6060)
			sampSendDialogResponse(MainDialogID,0,0,nil)
		end
	elseif DialogId == MainDialogID and DialogList == 8 and DialogButton == 0 then
	    sampSendDialogResponse(MainDialogID,0,0,nil)
	end
	
	if DialogId == MainDialogID and DialogList == 9 and DialogButton == 1 then
	    automining_startall = 1
		if tablestatustopress ~= nil then
			sampSendDialogResponse(MainDialogID,1,tablestatustopress,nil)
			sampAddChatMessage('[MiningTool] {FFFFFF}Запускаем все видеокарты... Не открывайте другие диалоги во время этого!', 0xFF6060)
		else
			automining_startall = 2
			sampAddChatMessage('[MiningTool] {FFFFFF}Запускать больше нечего.', 0xFF6060)
			sampSendDialogResponse(MainDialogID,0,0,nil)
		end
	elseif DialogId == MainDialogID and DialogList == 9 and DialogButton == 0 then
	    sampSendDialogResponse(MainDialogID,0,0,nil)	
	end
	
	if DialogId == MainDialogID and DialogList == 10 and DialogButton == 1 then
		automining_fillall = 1
		usefullfill = false
		if tablefilltopress ~= nil then
			sampSendDialogResponse(MainDialogID,1,tablefilltopress,nil)
			sampAddChatMessage('[MiningTool] {FFFFFF}Заливаем жидкость (По 50%)... Не открывайте другие диалоги во время этого!', 0xFF6060)
		else
		    automining_fillall = 2
			sampAddChatMessage('[MiningTool] {FFFFFF}Заливать некуда или уровень охлаждения у всех выше {BEF781}'..MaxFill..'%%%%', 0xFF6060)
			sampAddChatMessage('[MiningTool] {FFFFFF}Настроить уровень {BEF781}MaxFill {FFFFFF}- /mtmaxfill [1-99]', 0xFF6060)
			sampSendDialogResponse(MainDialogID,0,0,nil)
		end
	elseif DialogId == MainDialogID and DialogList == 10 and DialogButton == 0 then
	    sampSendDialogResponse(MainDialogID,0,0,nil)
	end	
	
	if DialogId == MainDialogID and DialogList == 11 and DialogButton == 1 then
		automining_fillall = 1
		usefullfill = true
		if tablefilltopress ~= nil then
			sampSendDialogResponse(MainDialogID,1,tablefilltopress,nil)
			sampAddChatMessage('[MiningTool] {FFFFFF}Заливаем жидкость (По 100%)... Не открывайте другие диалоги во время этого!', 0xFF6060)
		else
		    automining_fillall = 2
			sampAddChatMessage('[MiningTool] {FFFFFF}Заливать некуда или уровень охлаждения у всех выше {BEF781}'..MaxFill..'%%%%', 0xFF6060)
			sampAddChatMessage('[MiningTool] {FFFFFF}Настроить уровень {BEF781}MaxFill {FFFFFF}- /mtmaxfill [1-99]', 0xFF6060)
			sampSendDialogResponse(MainDialogID,0,0,nil)
		end
	elseif DialogId == MainDialogID and DialogList == 11 and DialogButton == 0 then
	    sampSendDialogResponse(MainDialogID,0,0,nil)
	end	
	
	if DialogId == MainDialogID and DialogList == 12 and DialogButton == 1 then -- Система для заливки ASC
		automining_fillall_ASC = 1
		if tablefilltopress_ASC ~= nil then
			sampSendDialogResponse(MainDialogID,1,tablefilltopress_ASC,nil)
			sampAddChatMessage('[MiningTool] {FFFFFF}Заливаем жидкость для Arizona Video Card... Не открывайте другие диалоги во время этого!', 0xFF6060)
		else
		    automining_fillall_ASC = 2
			sampAddChatMessage('[MiningTool] {FFFFFF}Заливать некуда или уровень охлаждения у всех выше {BEF781}'..MaxFill..'%%%%', 0xFF6060)
			sampAddChatMessage('[MiningTool] {FFFFFF}Настроить уровень {BEF781}MaxFill {FFFFFF}- /mtmaxfill [1-99]', 0xFF6060)
			sampSendDialogResponse(MainDialogID,0,0,nil)
		end
	elseif DialogId == MainDialogID and DialogList == 12 and DialogButton == 0 then
	    sampSendDialogResponse(MainDialogID,0,0,nil)
	end	
	
	--[Флешка]
	if DialogId == FlashDialogID and DialogList == 33 and DialogButton == 1 then
	    automining_getbtc = 1
		if tablebtctopress ~= nil then
			sampSendDialogResponse(FlashDialogID,1,tablebtctopress,nil)
			sampAddChatMessage('[MiningTool: Флешка] {FFFFFF}Забираем прибыль... Не открывайте другие диалоги во время этого!', 0xFF6060)
		else
			automining_getbtc = 2
			sampAddChatMessage('[MiningTool: Флешка] {FFFFFF}Забирать тут больше нечего.', 0xFF6060)
			sampSendDialogResponse(FlashDialogID,0,0,nil)
		end
    elseif DialogId == FlashDialogID and DialogList == 33 and DialogButton == 0 then
		sampSendDialogResponse(FlashDialogID,0,0,nil)
	end
	
	if DialogId == FlashDialogID and DialogList == 34 and DialogButton == 1 then
	    automining_startall = 1
		if tablestatustopress ~= nil then
			sampSendDialogResponse(FlashDialogID,1,tablestatustopress,nil)
			sampAddChatMessage('[MiningTool: Флешка] {FFFFFF}Запускаем все видеокарты... Не открывайте другие диалоги во время этого!', 0xFF6060)
		else
			automining_startall = 2
			sampAddChatMessage('[MiningTool: Флешка] {FFFFFF}Запускать тут больше нечего.', 0xFF6060)
			sampSendDialogResponse(FlashDialogID,0,0,nil)
		end				
	elseif DialogId == FlashDialogID and DialogList == 34 and DialogButton == 0 then
		sampSendDialogResponse(FlashDialogID,0,0,nil)
	end
	
	if DialogId == HouseChoseID then
		for i = 0, 20 do
			if DialogList == i and DialogButton == 1 then
				chosenhouse = i
			end
		end
		if automining_startall == 1 or automining_getbtc == 1 then
			sampSendDialogResponse(DialogId,chosenhouse,1,nil)
		end
	end
end

function dialogupdate (dialogId_configname, dialogId_new)
	if dialogId_configname == 1 then
		MiningMainIni.dialogs.MainDialogID = dialogId_new
		dialogId_new_info = 'Основного'
	elseif dialogId_configname == 2 then
		MiningMainIni.dialogs.CardDialogID = dialogId_new
		dialogId_new_info = 'Видеокарты'
	elseif dialogId_configname == 3 then
		MiningMainIni.dialogs.CardConfirmID = dialogId_new
		dialogId_new_info = 'Подтверждения'
	elseif dialogId_configname == 4 then
		MiningMainIni.dialogs.FillTypeID = dialogId_new
		dialogId_new_info = 'Выбора жидкости'
	elseif dialogId_configname == 5 then
		MiningMainIni.dialogs.FlashDialogID = dialogId_new
		dialogId_new_info = 'Флешки'
	elseif dialogId_configname == 6 then
		MiningMainIni.dialogs.HouseChoseID = dialogId_new
		dialogId_new_info = 'Выбора дома'		
	end
	if inicfg.save(MiningMainIni, 'MiningTool.ini') then
		sampAddChatMessage('[MiningTool] {FFFFFF}ID Диалога {BEF781}'..dialogId_new_info..'{FFFFFF} обновлен. Новый ID = '..dialogId_new, 0xFF6060)
		thisScript():reload()
	end
end
