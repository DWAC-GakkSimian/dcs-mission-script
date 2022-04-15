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

-- ##########################
-- Properties
-- ##########################

-- Unit types capable of FAC-A that will receive the F10 menu option
dwac_faca.facCapableUnits = {
    "SA342M",
    "SA342L",
    "SA342Mistral",
    "SA342Minigun"
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

local function addFACMenuFeatures(groupId)
    missionCommands.removeItemForGroup(groupId, {"FAC-A"}) -- clears menu at root for this feature
    local _facPath = missionCommands.addSubMenuForGroup(groupId, "FAC-A")

    -- Laser Codes
    missionCommands.addCommandForGroup(groupId, "Set laser code", _facPath, dwac_faca.setLaserCode, groupId)

    -- Smoke Color
    local _smokePath = missionCommands.addSubMenuForGroup(groupId, "Set smoke color", _facPath)
    missionCommands.addCommandForGroup(groupId, "Red", _smokePath, dwac_faca.setFACSmokeColor, "red")
    missionCommands.addCommandForGroup(groupId, "Orange", _smokePath, dwac_faca.setFACSmokeColor, "orange")
    missionCommands.addCommandForGroup(groupId, "White", _smokePath, dwac_faca.setFACSmokeColor, "white")
end
dwac_faca.addFACMenuFeatures = addFACMenuFeatures

local function setLaserCode(groupId)
    trigger.action.outTextForGroup(groupId, "Set laser code for group " .. groupId, 5, false)
end
dwac_faca.setLaserCode = setLaserCode

local function setFACSmokeColor(groupId, color)
    if color == "red" then
        trigger.action.outTextForGroup(groupId, "Smoke set to " .. color, 5, false)
    elseif color == "orange" then
        trigger.action.outTextForGroup(groupId, "Smoke set to " .. color, 5, false)
    elseif color == "white" then
        trigger.action.outTextForGroup(groupId, "Smoke set to " .. color, 5, false)
    end
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
local function getCurrentFACUnits()
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
dwac_faca.getCurrentFACUnits = getCurrentFACUnits


local function doFoo()
    trigger.action.outText("DWAC_FACA loaded", 5, false)
end
dwac_faca.doFoo = doFoo

return dwac_faca