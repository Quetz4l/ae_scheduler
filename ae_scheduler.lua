local component = require "component"
local meController = component.me_controller
local term = require("term")
local sides = require("sides")
local serialization = require("serialization")

--Settings
local red = component.proxy("dedf2c14-e0fe-4ef8-8947-f62b34c2e6bf") -- адресс редстоун приёмника
local sleepTime = 30 -- перерыв между новым сканом мэ (в секундах)
local wait_request = 6 -- чем дольше время, тем более большие рецепты может заказывать
local min_FreeCPU = 1 -- минимальное кол-во свободных CPU в МЭ
local redstoneSide = sides.top -- сторона приёмника, с которой он читает редстоун-сигнал

--[[
Пример / Example
 
redstoneSide = sides.top 
или
redstoneSide = [1,3]
или 
redstoneSide = "all"   (тогда будет обнаруживать с любой стороны)

bottom, Number: 0
top, Number: 1
north, Number: 2
south, Number: 3
west, Number: 4
east, Number: 5
--]]




_G.craftingJobs = {}
if _G.valuesUpdater then
    event.cancel(_G.valuesUpdater)
    _G.valuesUpdater = nil
end

local function getFreeCpus()
    local cpus = meController.getCpus()
    local freeCpus = 0
    for _, c in ipairs(cpus) do
        if not c.busy then
            freeCpus = freeCpus + 1
        end
    end
    return freeCpus
end

local function is_requested(me_label)
	local job = _G.craftingJobs[me_label]
  if job then
    if  job.isDone() or job.isCanceled() then 
      _G.craftingJobs[me_label] = nil
      return false
    else  
      return true 
    end
  else
    return false
  end
end


local function request_item(me_craft, me_label, count_to_craft)
    while true do
		if _G.craftingJobs[me_label] ~= nil then return -1 end 
        if getFreeCpus() <= min_FreeCPU then os.sleep(10) return end

        job = me_craft[1].request(count_to_craft) --Заказ
        os.sleep(wait_request)

        if is_requested(me_label) then
            _G.craftingJobs[me_label] = job
            return count_to_craft
        elseif count_to_craft <= 0 then
            return -1
        end

        if count_to_craft > 10 then
            count_to_craft = math.floor(count_to_craft - count_to_craft * 0.5)
        elseif count_to_craft > 5 then
            count_to_craft = count_to_craft - 5
        elseif count_to_craft > 0 then
            count_to_craft = count_to_craft - 1
        end

        if count_to_craft <= 0 then
            return -1
        end
    end
end

local function check_task(tasks, task_type)
    local freeCpus = getFreeCpus()

    for _, task in ipairs(tasks) do
        if freeCpus <= min_FreeCPU then
            break
        end

        local me_label = task.label .. ":" .. task.damage .. "->" .. tostring(task.fluid_name)
        local me_request
        if task.fluid_name ~= nil then
            --me_request = {label = task.label, damage = task.damage, fluid_name = task.fluid_name}
            me_request = {label = task.label, damage = task.damage}
        else
            me_request = {label = task.label, damage = task.damage}
        end
	
        if not _G.craftingJobs[me_label] then
            local me_craft = meController.getCraftables(me_request)

            if me_craft.n == 1 then -- предмет найден в мэ и не имеет аналогов (разрные nbt)
                local count_to_craft = 1000 -- кол-во предметов в режиме "бесконечный заказ"
                if task_type == "by count" then
                    count_to_craft = task.count - meController.getItemsInNetwork(me_request)[1].size
                end

                if count_to_craft > 0 then
                    requested_items = request_item(me_craft, me_label, count_to_craft) -- заказ предметов
                    requested_items = math.ceil(requested_items | 0)

                    if requested_items > 0 then
                        freeCpus = freeCpus - 1
                        print(" Заказано: " .. requested_items .. " -> " .. task.display_name)
                    elseif requested_items == 0 then
                        print(
                            " Не хватает ресурсов на: " .. math.ceil(count_to_craft | 0) .. " -> " .. task.display_name
                        )
                    end
                end
            elseif me_craft.n > 1 then
                print(" Имеет больше 1 рецепта: " .. task.display_name)
            else
                print(" Нет рецепта: " .. task.display_name)
            end
        end
    end
end

local function getRed()
    red_signal = red.getInput()
    if redstoneSide ~= nil then -- если сигналов много
        if type(redstoneSide) == "table" then
            for side in pairs(redsoneSide) do
                if red_signal[side] == 0 then
                    return false
                end
            end
        else
            if red_signal[redstoneSide] == 0 then
                return false
            end
        end
    end
    return true
end

local function get_file()
    local f = io.open("task_list", "r")
    if f ~= nil then
        local text = f:read()
        f:close()
        return serialization.unserialize(text)
    else
        term.write(" Отсутствует файл с задачами!")
        return nil
    end
end

local function sort(task_list)
    local sorted_data = {[1] = {}, [2] = {}, [3] = {}, [4] = {}}

    for key, task in pairs(task_list) do
        table.insert(sorted_data[task.priority], task)
    end

    return sorted_data
end



local function main()
    term.clear()
    term.write(" Запущен прекрафт:\n\n")

    local task_list = get_file()
    if task_list == nil then
        return
    end

    task_list = sort(task_list)

    while true do
        if getRed() then
            check_task(task_list[1], "by count")
            check_task(task_list[3], "infinity")
        end

        check_task(task_list[2], "by count")
        check_task(task_list[4], "infinity")
        os.sleep(sleepTime)
    end
end

main()
