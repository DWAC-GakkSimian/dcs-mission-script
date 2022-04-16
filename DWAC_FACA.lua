--[[
    FAC-A Features


    The MIT License (MIT)
    Copyright © 2022 gakksimian@gmail.com
    Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the “Software”), 
    to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, 
    and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
    The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
    THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, 
    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER 
    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS 
    IN THE SOFTWARE.
]]

local dwac_faca = {}

local dwac_util = _G.require "DWAC_UTIL"

-- ##########################
-- Meta Classes
-- ##########################
FacUnit = {}
function FacUnit:new (baseUnit, smokeColor, laserCode)
    local o = {}
    setmetatable(o, self)
    self.__index = self
    if baseUnit == nil then
        error("Nil Unit provided to FacUnit constructor")
    end
    o.base = baseUnit
    o.smokeColor = smokeColor or dwac_faca.smokeColors[trigger.smokeColor.Red]
    o.laserCode = laserCode or dwac_faca.laserCodes.One
    return o
end


-- ##########################
-- Properties
-- ##########################

dwac_faca.messageDuration = 5

-- Unit types capable of FAC-A that will receive the F10 menu option
dwac_faca.facCapableUnits = {
    "SA342M",
    "SA342L",
    "SA342Mistral",
    "SA342Minigun"
}

-- reverse of trigger.smokeColor
dwac_faca.smokeColors = {
    [0] = "Green",
    [1] = "Red",
    [2] = "White",
    [3] = "Orange",
    [4] = "Blue"
}

dwac_faca.laserCodes = {
    One = 1688,
    Two = 1588,
    Three = 1488,
    Four = 1337
}

-- collection of FAC-A capable units operating in-game
dwac_faca.facUnits = {}
-- add method of removing fac units no longer in use by a player
local function pruneFACUnits()
    local _facPlayers = dwac_faca.getCurrentFACUnits()
    local _newFacUnits = {}
    for _, _facPlayer in _facPlayers do
        for _, _facUnit in dwac_faca.facUnits do
            if _facPlayer:getUnitID() == _facUnit:getUnitID() then
                table.insert(_newFacUnits, _facUnit)
                break
            end
        end
    end
    dwac_faca.facUnits = _newFacUnits
end
dwac_faca.pruneFACUnits = pruneFACUnits


-- ##########################
-- Methods
-- ##########################

local function addFACMenuFeatures(_unit)
    dwac_faca.writeDebug("addFACMenuFeatures()_unit: " .. dwac_util.dump(_unit))
    -- Add the unit for tracking if needed
    local _facUnit = FacUnit:new(_unit)
    local _existing = dwac_faca.getFACUnit(_facUnit)
    if not _existing then
        dwac_faca.addFACUnit(_facUnit)
        local _groupId = dwac_util.getGroupId(_facUnit.base)
        --missionCommands.removeItemForGroup(_groupId, {"FAC-A"}) -- clears menu at root for this feature
        local _facPath = missionCommands.addSubMenuForGroup(_groupId, "FAC-A")

        -- Laser Codes
        local _laserPath = missionCommands.addSubMenuForGroup(_groupId, "Set laser code", _facPath)
        missionCommands.addCommandForGroup(_groupId, dwac_faca.laserCodes.One, _laserPath, dwac_faca.setLaserCode, {_facUnit, dwac_faca.laserCodes.One})
        missionCommands.addCommandForGroup(_groupId, dwac_faca.laserCodes.Two, _laserPath, dwac_faca.setLaserCode, {_facUnit, dwac_faca.laserCodes.Two})
        missionCommands.addCommandForGroup(_groupId, dwac_faca.laserCodes.Three, _laserPath, dwac_faca.setLaserCode, {_facUnit, dwac_faca.laserCodes.Three})
        missionCommands.addCommandForGroup(_groupId, dwac_faca.laserCodes.Four, _laserPath, dwac_faca.setLaserCode, {_facUnit, dwac_faca.laserCodes.Four})

        -- Smoke Color
        local _smokePath = missionCommands.addSubMenuForGroup(_groupId, "Set smoke color", _facPath)
        missionCommands.addCommandForGroup(_groupId, "Red", _smokePath, dwac_faca.setFACSmokeColor, {_facUnit, dwac_faca.smokeColors[trigger.smokeColor.Red]})
        missionCommands.addCommandForGroup(_groupId, "Orange", _smokePath, dwac_faca.setFACSmokeColor, {_facUnit, dwac_faca.smokeColors[trigger.smokeColor.Orange]})
        missionCommands.addCommandForGroup(_groupId, "White", _smokePath, dwac_faca.setFACSmokeColor, {_facUnit, dwac_faca.smokeColors[trigger.smokeColor.White]})

        -- Current Settings
        local _settings = missionCommands.addCommandForGroup(_groupId, "Current settings", _facPath, dwac_faca.getCurrentSettings, {_facUnit})
    end
end
dwac_faca.addFACMenuFeatures = addFACMenuFeatures

local function getCurrentSettings(args)
    dwac_faca.writeDebug("getCurrentSettings()")
    local _facUnit = args[1]
    dwac_faca.writeDebug("getCurrentSettings()_facUnit: " .. dwac_util.dump(_facUnit))
    --local _facUnit = dwac_faca.getFACUnit(_facUnit)
    local _groupId = dwac_util.getGroupId(_facUnit.base)
    trigger.action.outTextForGroup(_groupId, "Laser code: " .. _facUnit.laserCode .. ", Smoke Color: " .. _facUnit.smokeColor, dwac_faca.messageDuration, true)
end
dwac_faca.getCurrentSettings = getCurrentSettings

local function setLaserCode(args) -- args: {facUnit, code}
    dwac_faca.writeDebug("setLaserCode()")
    args[1].laserCode = args[2]
    --dwac_faca.writeDebug("setLaserCode()_facUnit: " .. dwac_util.dump(args[1]))
    dwac_faca.updateFACUnit(args[1])
end
dwac_faca.setLaserCode = setLaserCode


local function setFACSmokeColor(args) -- args: {facUnit, color}
    dwac_faca.writeDebug("setFACSmokeColor()")
    local _facUnit = args[1]
    local color = args[2]
    _facUnit.smokeColor = args[2]
    dwac_faca.updateFACUnit(_facUnit)
    --local _groupId = dwac_util.getGroupId(_facUnit.base)

    -- if color.lower() == "red" then
    --     trigger.action.outTextForGroup(_groupId, "Smoke set to " .. color, dwac_faca.messageDuration, false)
    -- elseif color == "orange" then
    --     trigger.action.outTextForGroup(_groupId, "Smoke set to " .. color, dwac_faca.messageDuration, false)
    -- elseif color == "white" then
    --     trigger.action.outTextForGroup(_groupId, "Smoke set to " .. color, dwac_faca.messageDuration, false)
    -- end
end
dwac_faca.setFACSmokeColor = setFACSmokeColor

local function isFACUnit(_unit)
    if _unit ~= nil then
        for _, _unitName in pairs(dwac_faca.facCapableUnits) do
            if _unit:getTypeName() == _unitName then
                return true
            end
        end
    end
    return false
end
dwac_faca.isFACUnit = isFACUnit

-- Extracts all current player units that are FAC-A capable
local function getCurrentFACCapableUnits()
    local reply = {}
    for _coalition = coalition.side.RED, coalition.side.BLUE do
        local _players = coalition.getPlayers(_coalition) -- returns array of units run by players
        if _players ~= nil then
            for i = 1, #_players do
                local _unit = _players[i]
                if _unit ~= nil then
                    if dwac_faca.isFACUnit(_unit) then
                        table.insert(reply, _unit)
                    end
                end
            end
        end
    end
    return reply
end
dwac_faca.getCurrentFACCapableUnits = getCurrentFACCapableUnits

local function addFACUnit(_facUnit)
   -- dwac_faca.writeDebug("addFACUnit()")
    if _facUnit then
        local existingFacUnit = dwac_faca.getFACUnit(_facUnit)
        if existingFacUnit == nil then
            table.insert(dwac_faca.facUnits, _facUnit)
        end
    end
end
dwac_faca.addFACUnit = addFACUnit

local function updateFACUnit(_facUnit)
    dwac_faca.writeDebug("updateFACUnit()")
    -- dwac_faca.writeDebug("_facUnit: " .. dwac_util.dump(_facUnit))
    for i, _value in ipairs(dwac_faca.facUnits) do
        local valId = _value.base:getID()
        local facId = _facUnit.base:getID()
        -- dwac_faca.writeDebug("updateFACUnit()._value.base:getID(): " .. valId)
        -- dwac_faca.writeDebug("updateFACUnit()._facUnit.base:getID(): " .. facId)
        if valId == facId then
            table.insert(dwac_faca.facUnits, i, _facUnit)
            break
        end
    end
end
dwac_faca.updateFACUnit = updateFACUnit

local function getFACUnit(_newFacUnit)
    --dwac_faca.writeDebug("getFACUnit()")
    for _, _facUnit in pairs(dwac_faca.facUnits) do
        if _facUnit then
            if _facUnit.base:getID() == _newFacUnit.base:getID() then
                return _facUnit
            end
        end
    end    
end
dwac_faca.getFACUnit = getFACUnit

local function doFoo()
    trigger.action.outText("DWAC_FACA loaded", dwac_faca.messageDuration, false)
    --dwac_util.doFoo()
end
dwac_faca.doFoo = doFoo

return dwac_faca