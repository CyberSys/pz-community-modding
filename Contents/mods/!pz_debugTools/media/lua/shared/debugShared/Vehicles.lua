local debug = require "!!!communityPatchDebugTools - shared"

local Vehicles = {}

function Vehicles.add(scriptName,square,direction,skinIndex)
    scriptName = scriptName or "Base.CarLightsPolice"
    square = square or getPlayer():getSquare()
    direction = direction or IsoDirections.S
    --skinIndex = nil--skinIndex or 0

    local vehicle = addVehicleDebug(scriptName,direction,skinIndex,square)

    return vehicle
end

function Vehicles.remove(vehicle)
    local vehicleId
    if type(vehicle) == "number" then vehicleId = vehicle
    elseif instanceof(vehicle, "BaseVehicle") then vehicleId = vehicle:getId()
    elseif type(vehicle) == "string" then vehicleId = tonumber(vehicle)
    end
    if not vehicleId then print("Vehicles: attempted to remove ",vehicle) return end

    if isClient then
        sendClientCommand("vehicle","remove",{vehicle=vehicleId})
    else
        triggerEvent("OnClientCommand","vehicle","remove",nil,{vehicle = vehicleId})
    end
end

--returns the most recent vehicle matching the scriptName
function Vehicles.getLast(scriptName)
    local allVehicles = getCell():getVehicles()
    local test
    for i = allVehicles:size() - 1, 0, -1 do
        test = allVehicles:get(i)
        if scriptName == test:getScriptName() then
            return test
        end
    end
end

function Vehicles.reload(scriptName)
    local vehicle = Vehicles.getLast(scriptName)

    reloadVehicles()
    reloadVehicleTextures(scriptName)

    if vehicle then vehicle:scriptReloaded() end
    --if vehicle then Vehicles.remove(vehicle) end
    --Vehicles.add(scriptName)
end

function Vehicles.removeAll(scriptName)
    if isClient() then sendClientCommand("ceDebug","Vehicles.removeAll",{scriptName}) return end
    local vehicles = getCell():getVehicles()
    for i = vehicles:size() - 1, 0, -1 do
        local vehicle = vehicles:get(i)
        if not scriptName or scriptName == vehicle:getScriptName() then
            vehicle:permanentlyRemove()
        end
    end
end
debug.serverCommands["Vehicles.removeAll"] = function(player,args) Vehicles.removeAll(args[1]) end

function Vehicles.unlock(vehicle)
    for seat=1,vehicle:getMaxPassengers() do
        local part = vehicle:getPassengerDoor(seat-1)
        if part then
            if isClient() then
                sendClientCommand('vehicle', 'setDoorLocked', { vehicle = vehicle:getId(), part = part:getId(), locked = false })
            else
                part:getDoor():setLocked(false)
            end
        end
    end
end

--example to test all parts
function Vehicles.testAllParts(v,test)
    if not v then return end
    local vehicle
    if instanceof(v,"BaseVehicle") then vehicle = v
    elseif type(v) == "string" then vehicle = Vehicles.getLast(v)
    end
    if not vehicle then return end

    if not (test and type(test) == "function") then
        test = function(i,part)
            if part ~= nil then
                return string.format("\nid:%d | %s | condition: %d", i, part:getId(), part:getCondition())
            else
                return string.format("\nid:%d | no part", i)
            end
        end
    end

    local printTable = {[1]=string.format("\n/*** %s Parts ***/",vehicle:getScriptName() or "")}
    for i = 0, vehicle:getPartCount() - 1 do
        printTable[i+2] = test(i,vehicle:getPartByIndex(i))
    end
    print(table.concat(printTable))
end

function Vehicles.patchISSpawnVehicleUI(ISSpawnVehicleUI)
    local function removeAll() Vehicles.removeAll() end
    local function reload(ui,button) Vehicles.reload(ui:getVehicle()) end
    local function addButton(ui,x,y,w,h,text,target,fn)
        local button = ISButton:new(x,y,w,h,text,target,fn)
        button.anchorTop = false
        button.anchorBottom = true
        button.borderColor = {r=1, g=1, b=1, a=0.1}
        button:initialise()
        ui:addChild(button)
        return button
    end

    local initialise = ISSpawnVehicleUI.initialise
    ISSpawnVehicleUI.initialise = function(self)
        initialise(self)

        local height = self:getHeight()

        self:setHeight(height+35)
        for i,v in ipairs({ self.getKey,self.repair }) do --self.spawn,self.close
            v:setY(v:getY()-35)
        end

        local x,y,w,h = 10,height - 65,80,25
        local x1 = 110
        self.zxReload = addButton(self, x, y, w, h, getText("Reload"), self, reload)
        self.zxRemoveAll = addButton(self,x1, y, w, h, getText("Remove All"), self, removeAll)

    end
end

debug.Vehicles = Vehicles
return Vehicles
