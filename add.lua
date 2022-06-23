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

-- fullename = item.name..':'..item.damage
is_cell = {
     ["gregtech:gt.metaitem.013240:5.0"] = true, 
     ["gregtech:gt.metaitem.013240:6.0"] = true, 
     ["gregtech:gt.metaitem.013240:7.0"] = true, 
     ["gregtech:gt.metaitem.013240:8.0"] = true, 
     ["gregtech:gt.metaitem.013240:9.0"] = true, 
     ["gregtech:gt.metaitem.013240:10.0"] = true, 
     ["gregtech:gt.metaitem.013240:11.0"] = true, 
     ["gregtech:gt.metaitem.013240:12.0"] = true, 
     ["gregtech:gt.metaitem.013240:13.0"] = true, 
     ["gregtech:gt.Volumetric_Flask:0.0"] = true, 
}


function getItemsFromInventory()
    local items = {}  

    for slotIndex = 1, controller.getInventorySize(chest_side) do
        local item = controller.getStackInSlot(chest_side, slotIndex)
        
        if item then
            local exists = false
      local fullename = item.name..':'..item.damage
      
            if not is_cell[fullename] then
                for slotIndexB, stack in pairs(items) do
                    if controller.compareStacks(chest_side, slotIndex, slotIndexB)  then
                        stack.size = stack.size + item.size
                        exists = true
                        break
                    end
                end
            end
            if not exists then
                items[slotIndex] = item
            end
            term.write(".")
        end
    end
    return items
end
  
local function question(text, answer_type)
  term.write(text)
  
  while true do
    local answer = io.read()
    if answer_type == "boolean" and (answer == 'Y' or answer == 'y' or answer == "") then
      return true
    elseif answer_type == "boolean" and (answer == 'N' or answer == 'n')  then
      return false
    elseif answer_type == "integer" and (nil ~= tonumber(answer) and tonumber(answer) > 0 ) then
      return tonumber(answer) 
    else
      local _, row = term.getCursor()
      term.setCursor(1, row - 1)
      term.clearLine()
      term.write(text)
    end
  end
end

local function add_to_file(display_name, item, count)
  local item_key = ""
  
  if item.fluid_name == nil then
    item_key = item.name..":"..item.damage
  else
    item_key = item.name..":"..item.damage.."->"..item.fluid_name
  end
  
  local new_item = {
    display_name= display_name, 
      name= item.name, 
    damage= item.damage, 
    count= count, 
    fluid_name= item.fluid
  }

  local text = "Добавлено :)"
  local _file = io.open('ae_list', 'r')
  

  if _file == nil then
      ae_list = {}
    ae_list[item_key] = new_item  
  else
    ae_list = _file:read()
    _file:close()
    if ae_list[item_key] ~= nil then
      text = "Обновлено :Р"
    end
    
    ae_list = serialization.unserialize(ae_list)
    ae_list[item_key] = new_item    
  end
  
  out = serialization.serialize(ae_list)
  
  local _file = io.open('ae_list', 'w')
    _file:write(out)
    _file:close()
  term.write(text..'\n')
  
end

local function main() 

    term.clear()
    term.write("Скрипт добавления предметов в планировщик\n")
  
  items = getItemsFromInventory()
  
  for slotIndex, item in pairs(items) do

    term.write("\nОставить это имя? -> '"..item.label.."' : ")
    local display_name = io.read()
    if display_name == "" then
      display_name = item.label
    end

    count = question("Укажите кол-во: ", "integer")
    add_to_file(display_name, item, count)

    end
end

main()
