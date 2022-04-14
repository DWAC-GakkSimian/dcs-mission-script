--[[
    Selectable mission features
        - SMOKE: Map targeted (Idea stolen from Tupper of Rotorheads)
            Usage: On the F10 map, place a comment circle with text of "-smoke;<color>" (red|orange|green|white|blue) and minimize
        - ILLUMINATION: Map targeted
            Usage: On the F10 map, place a comment circle with text of "-flare" and minimize


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

io                      = require "io"
lfs                     = require "lfs" -- lfs.writedir() provided by DCS and points to the DCS 'SavedGames' folder

local dwac = {}
local baseName = "DWAC"

env.info(baseName .. " starting")
-- ##########################
-- CONFIGURATION PROPERTIES - Tie them to this table so calling scopes can reference
-- ##########################
dwac.enableLogging = true

-- To enable/disable features set their state here
dwac.enableMapSmoke = true
dwac.enableMapIllumination = true
dwac.mapIlluminationAltitude = 700 -- Altitude(meters) the illumination bomb appears determines duration (300sec max)/effectiveness
dwac.illuminationPower = 1000000 -- 1 to 1000000 brightness

-- ##########################
-- Properties
-- ##########################
if dwac.enableLogging then
    dwac.logger = io.open(lfs.writedir() .. "Logs/" .. baseName .. ".log", "a+")
end
dwac.messageDuration = 20 -- seconds
dwac.f10MenuUpdateFrequency = 4 -- F10 menu refresh rate

-- Unit types capable of FAC-A that will receive the F10 menu option
dwac.facUnits = {
    "SA342M",
    "SA342L",
    "SA342Mistral",
    "SA342Minigun"
}

dwac.MapRequest = {SMOKE = 1, ILLUMINATION = 2}

-- ##########################
-- Methods
-- ##########################
-- *** Logging ***
local function writeDebug(debugLog)
    if dwac.enableLogging then
        dwac.logger:write(dwac.getLogTimeStamp() .. debugLog .. "\n")
    end
end
dwac.writeDebug = writeDebug

local function getMarkerRequest(requestText)
    isSmokeRequest = requestText:match("^-smoke")
    if isSmokeRequest then
        return dwac.MapRequest.SMOKE
    end

    isIllumination = requestText:match("^-flare%s*$")
    if isIllumination then
        return dwac.MapRequest.ILLUMINATION
    end
end
dwac.getMarkerRequest = getMarkerRequest

local function setMapSmoke(requestText, vector)
    smokeColor = requestText:match("^-smoke;(%a+)")
    local lat, lon, alt = coord.LOtoLL(vector)
    if smokeColor then
        dwac.writeDebug("Smoke color requested: " .. smokeColor .. " -> Lat: " .. lat .. " Lon: " .. lon .. " Alt: " .. alt)
        color = string.lower(smokeColor)
        if color == "green" then
            trigger.action.smoke(vector, trigger.smokeColor.Green)
        elseif color == "red" then
            trigger.action.smoke(vector, trigger.smokeColor.Red)
        elseif color == "white" then
            trigger.action.smoke(vector, trigger.smokeColor.White)
        elseif color == "orange" then
            trigger.action.smoke(vector, trigger.smokeColor.Orange)
        elseif color == "blue" then
            trigger.action.smoke(vector, trigger.smokeColor.Blue)
        end
    end
end
dwac.setMapSmoke = setMapSmoke

local function setMapIllumination(vector)
    if vector then
        local lat, lon, alt = coord.LOtoLL(vector)
        dwac.writeDebug("Illumination requested: Lat: " .. lat .. " Lon: " .. lon .. " Alt: " .. alt)
        trigger.action.illuminationBomb(vector, dwac.illuminationPower)
    end
end
dwac.setMapIllumination = setMapIllumination

local function getLogTimeStamp()
    return os.date("%H:%M:%S") .. " - " .. baseName .. ": "
end
dwac.getLogTimeStamp = getLogTimeStamp

local function isFACUnit(_unit)
    dwac.writeDebug("IsFACUnit() \n" .. _unit:getTypeName())
    if _unit ~= nil then
        for _, _unitName in pairs(dwac.facUnits) do
            if _unit:getTypeName() == _unitName then
                dwac.writeDebug("_unit.id: " .. _unit:getID() .. " is FAC capable")
                return true
            end
        end
    end
    return false
end
dwac.isFACUnit = isFACUnit

local function getGroupId(_unit)
    if _unit then
        local _group = _unit:getGroup()
        return _group:getID()
    end
end
dwac.getGroupId = getGroupId

local function addFACFeatures(_unit)
    dwac.writeDebug("Adding FAC-A features")
    local _groupId = getGroupId(_unit)
    missionCommands.removeItemForGroup(_groupId, {"FAC-A"}) -- clears menu at root for this feature
    local _facPath = missionCommands.addSubMenuForGroup(_groupId, "FAC-A")

    -- Laser Codes
    missionCommands.addCommandForGroup(_groupId, "Set laser code", _facPath, dwac.setLaserCode, _unit)

    -- Smoke Color
    local _smokePath = missionCommands.addSubMenuForGroup(_groupId, "Set smoke color", _facPath)
    missionCommands.addCommandForGroup(_groupId, "Red", _smokePath, dwac.setFACSmokeColor, "red")
    missionCommands.addCommandForGroup(_groupId, "Orange", _smokePath, dwac.setFACSmokeColor, "orange")
    missionCommands.addCommandForGroup(_groupId, "White", _smokePath, dwac.setFACSmokeColor, "white")
end
dwac.addFACFeatures = addFACFeatures

local function setLaserCode(_unit)
    dwac.writeDebug("setLaserCode() for unit: " .. _unit:getID())
    local _groupId = dwac.getGroupId(_unit)
    trigger.action.outTextForGroup(_groupId, "Set laser code for " .. _unit:getPlayerName(), dwac.messageDuration, false)
end
dwac.setLaserCode = setLaserCode

local function setFACSmokeColor(color)
    if color == "red" then
        trigger.action.outTextForGroup(_groupId, "Smoke set to " .. color, dwac.messageDuration, false)
    elseif color == "orange" then
        trigger.action.outTextForGroup(_groupId, "Smoke set to " .. color, dwac.messageDuration, false)
    elseif color == "white" then
        trigger.action.outTextForGroup(_groupId, "Smoke set to " .. color, dwac.messageDuration, false)
    end
end
dwac.setFACSmokeColor = setFACSmokeColor

-- highest level DWAC F10 menu addition
--   add calls to functions which add specific menu features here to keep it clean
--   REMEMBER to add clean-up to removeF10MenuOptions()
local function addF10MenuOptions()
    timer.scheduleFunction(dwac.addF10MenuOptions, nil, timer.getTime() + dwac.f10MenuUpdateFrequency)

    for _coalition = coalition.side.RED, coalition.side.BLUE do
        local _players = coalition.getPlayers(_coalition) -- returns array of units run by players
        if _players ~= nil then
            for i = 1, #_players do
                local _unit = _players[i]
                if _unit ~= nil then
                    if dwac.isFACUnit(_unit) then
                        dwac.addFACFeatures(_unit)
                    end
                end
            end
        end
    end
end
dwac.addF10MenuOptions = addF10MenuOptions

local function missionStopHandler(event)    
    dwac.writeDebug("Closing event handlers")
    if mapIlluminationRequestHandler then
        world.removeEventHandler(mapIlluminationRequestHandler)
    end
    if dwac.mapSmokeRequestHandler then
        world.removeEventHandler(mapSmokeRequestHandler)
    end
    if dwac.logger then
        dwac.logger:write(dwac.getLogTimeStamp() .. "Mission End.  Closing logger.\n")
        dwac.logger:flush()
        dwac.logger:close()
        dwac.logger = nil
    end
end
dwac.missionStopHandler = missionStopHandler

-- ##########################
-- EVENT HANDLING
-- ##########################
dwac.dwacEventHandler = {}
function dwac.dwacEventHandler:onEvent(event)    
    -- *** Close Logger on Mission Stop***
    if event.id == world.event.S_EVENT_MISSION_END then
        dwac.missionStopHandler(event)
    end
    
    -- *** Map Request ***
    if event.id == world.event.S_EVENT_MARK_CHANGE then
        local markerPanels = world.getMarkPanels()
        for i,panel in ipairs(markerPanels) do
            if event.idx == panel.idx then
                local markType = dwac.getMarkerRequest(panel.text)
                if dwac.enableMapSmoke and markType == dwac.MapRequest.SMOKE then
                    dwac.setMapSmoke(panel.text, panel.pos)
                    timer.scheduleFunction(trigger.action.removeMark, panel.idx, timer.getTime() + 2)
                    break
                elseif dwac.enableMapIllumination and  markType == dwac.MapRequest.ILLUMINATION then
                    panel.pos.y = dwac.mapIlluminationAltitude
                    dwac.setMapIllumination(panel.pos)
                    timer.scheduleFunction(trigger.action.removeMark, panel.idx, timer.getTime() + 2)
                    break
                end
            end
        end
    end
end
world.addEventHandler(dwac.dwacEventHandler)

-- useful for debugging
local function dump(o)
   if type(o) == 'table' then
      local s = '{ '
      for k,v in pairs(o) do
         if type(k) ~= 'number' then k = '"'..k..'"' end
         s = s .. '['..k..'] = ' .. dump(v) .. ','
      end
      return s .. '} '
   else
      return tostring(o)
   end
end
dwac.dump = dump

--timer.scheduleFunction(dwac.addF10MenuOptions, nil, timer.getTime() + 5)
dwac.addF10MenuOptions()

dwac.writeDebug("DWAC Active")
return dwac