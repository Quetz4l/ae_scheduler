local component = require("component")
local computer = require("computer")
local sides = require("sides")
local controller = component.inventory_controller
local term = require("term")
local serialization = require("serialization")

local chest_side = sides.north

if not controller then
    print("Не найден inventory controller")
    os.exit()
end


local function save_file(task_list)
    out = serialization.serialize(task_list)

    local _file = io.open("task_list", "w")
    _file:write(out)
    _file:close()
end

local function getItemsFromInventory()
    local items = {}

    for _, item in pairs(controller.getAllStacks(chest_side).getAll()) do
		if item.name~=nil then
			local fullename = item.name .. ":" .. item.damage .. "->"..tostring(item.fluid_name)
			items[fullename] = item
			term.write(".")
		end
    end
	
    return items
end

local function question(text, answer_type)
    term.write(text)

    while true do
        local answer = io.read()
        if answer_type == "boolean" and (answer == "Y" or answer == "y" or answer == "") then
            return true
        elseif answer_type == "boolean" and (answer == "N" or answer == "n") then
            return false
        elseif answer_type == "integer" and (nil ~= tonumber(answer) and tonumber(answer) > 0) then
            return tonumber(answer)
        else
            local _, row = term.getCursor()
            term.setCursor(1, row - 1)
            term.clearLine()
            term.write(text)
        end
    end
end

local function add_to_file(item)

	local _file = io.open("task_list", "r")
	local is_was_in_file = false
	
	if _file == nil then
		task_list = {}
	else
		task_list = serialization.unserialize(_file:read())
		_file:close()
	end
	
	local item_key = ""
    if item.fluid_name == nil then
        item_key = item.name .. ":" .. item.damage
    else
        item_key = item.name .. ":" .. item.damage .. "->" .. item.fluid_name
    end
	
	if task_list[item_key] ~= nil then
		is_was_in_file = true
		local what_do = question(" Предмет уже есть в списке: ".. task_list[item_key]['display_name'] .. "\n  #1-> Изменить\n  #2-> Удалить\n  #3-> Пропустить\n  ->", "integer")
		if what_do == 2 then
			table.remove(task_list, item_key)
			save_file(task_list)
			return
		elseif what_do == 3 then 
			return
		end
	end
	
	if is_was_in_file then
		term.write("\n Оставить это имя? -> '" .. task_list[item_key]['display_name'] .. "' : ")
		local display_name = io.read()
		if display_name == "" then
			display_name = task_list[item_key]['display_name']		
		end
		local count = question(" Укажите кол-во (было "..task_list[item_key]['count'].."): ", "integer")
			priority =
		question(
		" Какой приоритет? (Был "..task_list[item_key]['priority']..")\n #1-> Запуск если есть редстоун сигнал\n #2-> Игнорировать редстоун сигнал\n #3-> Беcконечно, но с редстоун сигналом\n #4-> Беcконечно и игнорировать редстоун сигнал\n ->",
		"integer"
	)
	else
		term.write("\n Оставить это имя? -> '" .. item.label .. "' : ")
		local display_name = io.read()
		if display_name == "" then
			display_name = item.label
		end
		local count = question(" Укажите кол-во: ", "integer")
			priority =
		question(
		" Какой приоритет?\n #1-> Запуск если есть редстоун сигнал\n #2-> Игнорировать редстоун сигнал\n #3-> Беcконечно, но с редстоун сигналом\n #4-> Беcконечно и игнорировать редстоун сигнал\n ->",
		"integer"
	)
	end
	
    local new_item = {
        display_name = display_name,
        label = item.label,
        damage = item.damage,
        count = count,
        fluid_name = item.fluid_name,
        priority = priority
    }

	task_list[item_key] = new_item
	save_file(task_list)
	
    if is_was_in_file then       
		print("Изменено :Р")
    else      
		print("Добавлено :)")
    end

end

local function main()
    term.clear()
    term.write("Скрипт добавления предметов в планировщик\n")

	
    items = getItemsFromInventory()

    for slotIndex, item in pairs(items) do
		add_to_file(item)
    end
end

main()
