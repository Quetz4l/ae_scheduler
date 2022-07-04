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

local function save_file(item, task_list)
    local new_item = {
        display_name = item.display_name,
        label = item.label,
        damage = item.damage,
        count = item.count,
        fluid_name = item.fluid_name,
        priority = item.priority
    }

    task_list[item.item_key] = new_item
    out = serialization.serialize(task_list)

    local _file = io.open("task_list", "w")
    _file:write(out)
    _file:close()
end

local function load_file()
    local _file = io.open("task_list", "r")
    local task_list

    if _file == nil then
        task_list = {}
    else
        task_list = serialization.unserialize(_file:read())
        _file:close()
    end
    return task_list
end

local function delete_from_file(item_key, task_list)
    task_list[item_key] = nil
    out = serialization.serialize(task_list)

    local _file = io.open("task_list", "w")
    _file:write(out)
    _file:close()
end

local function question(text, answer_type, _start, _end)
    term.write(text)
    if _start == nil then
        _start = 1
    end
    if _end == nil then
        _end = 9999999
    end

    while true do
        local answer = io.read()
        if answer_type == "boolean" and (answer == "Y" or answer == "y" or answer == "") then
            return true
        elseif answer_type == "boolean" and (answer == "N" or answer == "n") then
            return false
        elseif
            answer_type == "integer" and
                (nil ~= tonumber(answer) and tonumber(answer) >= _start and tonumber(answer) <= _end)
         then
            return tonumber(answer)
        else
            local _, row = term.getCursor()

            delete_lines = select(2, string.gsub(text, "\n", "")) + 1
            for i = 0, delete_lines do
                term.setCursor(1, row - i)
                term.clearLine()
            end
            term.write(text)
        end
    end
end

local function item_in_task_list(item, task_list)
    item["display_name"] = task_list[item.item_key].display_name
    item["count"] = task_list[item.item_key].count
    item["priority"] = task_list[item.item_key].priority

    local what_do =
        question(
        " #" ..
            item.slot ..
                " Предмет уже есть в списке: " ..
                    item.display_name ..
                        "( " .. item.count .. "шт. )" .. "\n  #1-> Изменить\n  #2-> Удалить\n  #3-> Пропустить\n  ->",
        "integer"
    )
    if what_do == 2 then
        delete_from_file(item.item_key, task_list)
        return
    elseif what_do == 3 then
        return
    end

    term.write("\n #" .. item.slot .. " Оставить это имя? -> '" .. item["display_name"] .. "' : ")
    item["display_name"] = io.read()
    if item["display_name"] == "" then
        item["display_name"] = item["display_name"]
    end

    item["count"] = question(" Укажите кол-во (было " .. item["count"] .. "): ", "integer")

    item["priority"] =
        question(
        " Какой приоритет? (Был " ..
            item["priority"] ..
                ")\n #1-> Запуск если есть редстоун сигнал\n #2-> Игнорировать редстоун сигнал\n #3-> Беcконечно, но с редстоун сигналом\n #4-> Беcконечно и игнорировать редстоун сигнал\n #5-> Высокий приоритет с сигналом\n #6-> Высокий приоритет без сигнала\n ->",
        "integer",
        1,
        6
    )
    save_file(item, task_list)
    print("Изменено :Р")
    return
end

local function add_to_file(item)
    local task_list = load_file()

    item["item_key"] = item.name .. ":" .. item.damage .. "->" .. tostring(item.fluid_name)

    --check in task_list
    if task_list[item["item_key"]] ~= nil then
        item_in_task_list(item, task_list)
        return
    end

    term.write("\n #" .. item.slot .. " Оставить это имя? -> '" .. item.label .. "' : ")
    item["display_name"] = io.read()
    if item["display_name"] == "" then
        item["display_name"] = item.label
    end
    item["count"] = question(" Укажите кол-во: ", "integer")
    item["priority"] =
        question(
        " Какой приоритет?\n #1-> Запуск если есть редстоун сигнал\n #2-> Игнорировать редстоун сигнал\n #3-> Беcконечно, но с редстоун сигналом\n #4-> Беcконечно и игнорировать редстоун сигнал\n #5-> Высокий приоритет с сигналом\n #6-> Высокий приоритет без сигнала\n ->",
        "integer",
        1,
        6
    )

    save_file(item, task_list)
    print("Добавлено :)")
end

local function main()
    term.clear()
    term.write("Скрипт добавления предметов в планировщик\n")

    local items = controller.getAllStacks(chest_side).getAll()

    for slot, item in pairs(items) do
        item["slot"] = slot + 1
        if item.damage ~= nil then
            add_to_file(item)
        end
    end
end

main()
