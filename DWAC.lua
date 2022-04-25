--[[
    Selectable mission features
        - SMOKE: Map targeted (Idea stolen from Tupper of Rotorheads)
            Usage: On the F10 map, place a comment circle with text of "-smoke;<color>" (red|orange|green|white|blue) and minimize
        - ILLUMINATION: Map targeted
            Usage: On the F10 map, place a comment circle with text of "-flare" and minimize
        - VERSION: Map activated
            Usage: On the F10 map, place a comment circle with text of "-version" to see the current version of DWAC

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
os = require "os"
io = require "io"
lfs = require "lfs" -- lfs.writedir() provided by DCS and points to the DCS 'SavedGames' folder

local dwac = {}
local baseName = "DWAC"
local version = "0.1.8"

--#region Configuration

-- ##########################
-- CONFIGURATION PROPERTIES - Tie them to this table so calling scopes can reference
-- ##########################
dwac.enableLogging = true

-- To enable/disable features set their state here
dwac.enableMapSmoke = true
dwac.enableMapIllumination = true
dwac.mapIlluminationAltitude = 700 -- Altitude(meters) the illumination bomb appears determines duration (300sec max)/effectiveness
dwac.illuminationPower = 1000000 -- 1 to 1000000 brightness
dwac.messageDuration = 20 -- seconds
dwac.f10MenuUpdateFrequency = 1 -- F10 menu refresh rate

dwac.MapRequest = {SMOKE = 1, ILLUMINATION = 2, VERSION = 3}

dwac.facEnableSmokeTarget = true    -- allows FAC-A smoking of targets
dwac.facEnableLazeTarget = false    -- allows FAC-A to laze a target
dwac.facEnableArtilleryStrike = false   -- allows FAC-A to call arty on target

--#endregion


--#region UTIL
local function getGroupId(_unit)
    if _unit then
        local _group = _unit:getGroup()
        return _group:getID()
    end
end
dwac.getGroupId = getGroupId

--get distance in meters assuming a Flat world (DSMC)
local function getDistance(_point1, _point2)

    local xUnit = _point1.x
    local yUnit = _point1.z
    local xZone = _point2.x
    local yZone = _point2.z

    local xDiff = xUnit - xZone
    local yDiff = yUnit - yZone

    return math.sqrt(xDiff * xDiff + yDiff * yDiff)
end
dwac.getDistance = getDistance

-- DSMC based
local function deepCopy(object)
    local lookup_table = {}
	local function _copy(object)
		if type(object) ~= "table" then
			return object
		elseif lookup_table[object] then
			return lookup_table[object]
		end
		local new_table = {}
		lookup_table[object] = new_table
		for index, value in pairs(object) do
			new_table[_copy(index)] = _copy(value)
		end
		return setmetatable(new_table, getmetatable(object))
	end
	return _copy(object)
end
dwac.deepCopy = deepCopy

-- DSMC based
local function getNorthCorrection(gPoint)	--gets the correction needed for true north
	local point = dwac.deepCopy(gPoint)
	if not point.z then --Vec2; convert to Vec3
		point.z = point.y
		point.y = 0
	end
	local lat, lon = coord.LOtoLL(point)
	local north_posit = coord.LLtoLO(lat + 1, lon)
	return math.atan2(north_posit.z - point.z, north_posit.x - point.x)
end
dwac.getNorthCorrection = getNorthCorrection

-- DSMC based
local function getHeading(unit, rawHeading)
	local unitpos = unit:getPosition()
	if unitpos then
		local Heading = math.atan2(unitpos.x.z, unitpos.x.x)
		if not rawHeading then
			Heading = Heading + dwac.getNorthCorrection(unitpos.p)
		end
		if Heading < 0 then
			Heading = Heading + 2*math.pi	-- put heading in range of 0 to 2*pi
		end
		return Heading
	end
end
dwac.getHeading = getHeading

-- DSMC based
local function vecsub(vec1, vec2)
	return {x = vec1.x - vec2.x, y = vec1.y - vec2.y, z = vec1.z - vec2.z}
end
dwac.vecsub = vecsub

-- DSMC based
function vecdp(vec1, vec2)
	return vec1.x*vec2.x + vec1.y*vec2.y + vec1.z*vec2.z
end
dwac.vecdp = vecdp

-- DSMC based
local function getClockDirection(_unit, _obj)
    -- Source: Helicopter Script - Thanks!
    local _position = _obj:getPosition().p -- get position of _obj
    local _playerPosition = _unit:getPosition().p -- get position of _unit
    local _relativePosition = dwac.vecsub(_position, _playerPosition)
    local _playerHeading = dwac.getHeading(_unit) -- the rest of the code determines the 'o'clock' bearing of the missile relative to the helicopter

    local _headingVector = { x = math.cos(_playerHeading), y = 0, z = math.sin(_playerHeading) }

    local _headingVectorPerpendicular = { x = math.cos(_playerHeading + math.pi / 2), y = 0, z = math.sin(_playerHeading + math.pi / 2) }

    local _forwardDistance = dwac.vecdp(_relativePosition, _headingVector)

    local _rightDistance = dwac.vecdp(_relativePosition, _headingVectorPerpendicular)

    local _angle = math.atan2(_rightDistance, _forwardDistance) * 180 / math.pi

    if _angle < 0 then
        _angle = 360 + _angle
    end
    _angle = math.floor(_angle * 12 / 360 + 0.5)
    if _angle == 0 then
        _angle = 12
    end

    return _angle
end
dwac.getClockDirection = getClockDirection

local function smokePoint(vector, smokeColor)
    vector.y = vector.y + 2.0
    local lat, lon, alt = coord.LOtoLL(vector)
    pcall(function()
        dwac.writeDebug(
            "Smoke color requested: " .. smokeColor .. " -> Lat: " .. lat .. " Lon: " .. lon .. " Alt: " .. alt
        )
        color = string.lower(smokeColor)
        if color == "green" then
            trigger.action.smoke(vector, trigger.smokeColor.Green)
            return true
        elseif color == "red" then
            trigger.action.smoke(vector, trigger.smokeColor.Red)
            return true
        elseif color == "white" then
            trigger.action.smoke(vector, trigger.smokeColor.White)
            return true
        elseif color == "orange" then
            trigger.action.smoke(vector, trigger.smokeColor.Orange)
            return true
        elseif color == "blue" then
            trigger.action.smoke(vector, trigger.smokeColor.Blue)
            return true
        end
        return false
    end)
    return false
end
dwac.smokePoint = smokePoint

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
--#endregion


--#region FAC-A

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
    o.smokeColor = smokeColor or dwac.smokeColors[trigger.smokeColor.Red]
    o.laserCode = laserCode or dwac.laserCodes.One
    o.onStation = false
    o.menuStable = true
    o.currentTarget = nil
    o.targets = {}
    o.responses = {
        noTargetText = "No target selected",
        outOfRange = "Target out of range"
    }

    return o
end
function FacUnit:goOnStation()
    self.onStation = true
    dwac.updateFACUnit(self)
    local coalition = self.base:getCoalition()
    local pilot = self.base:getPlayerName()
    trigger.action.outTextForCoalition(coalition, pilot .. " FAC-A is ON station", dwac.messageDuration, false)
end
function FacUnit:goOffStation()
    self.onStation = false
    dwac.updateFACUnit(self)
    local coalition = self.base:getCoalition()
    local pilot = self.base:getPlayerName()
    trigger.action.outTextForCoalition(coalition, pilot .. " FAC-A is OFF station", dwac.messageDuration, false)
end
function FacUnit:smokeTarget()
    if not dwac.facEnableSmokeTarget then
        return
    end
    dwac.writeDebug("Smoke Target: ")
    if self.currentTarget then
        local inRange = self:targetInRange()
        
        dwac.writeDebug("target in range: " .. tostring(inRange))
        if inRange then
            dwac.smokePoint(self.currentTarget.unit:getPosition().p, self.smokeColor)
        end
    else
        local groupId = dwac.getGroupId(self.base)
        trigger.action.outTextForGroup(groupId, self.responses["noTargetText"], dwac.messageDuration, false)
    end
end
function FacUnit:lazeTarget()
    if not dwac.facEnableLazeTarget then
        return
    end
    dwac.writeDebug("Laze Target: ")
    if self.currentTarget then
    else
        local groupId = dwac.getGroupId(self.base)
        trigger.action.outTextForGroup(groupId, self.responses["noTargetText"], dwac.messageDuration, false)
    end
end
function FacUnit:callArty()
    if not dwac.facEnableArtilleryStrike then
        return
    end
    dwac.writeDebug("Pound Target: ")
    if self.currentTarget then
    else
        local groupId = dwac.getGroupId(self.base)
        trigger.action.outTextForGroup(groupId, self.responses["noTargetText"], dwac.messageDuration, false)
    end
end
function FacUnit:targetInRange()
    dwac.writeDebug("Ranging target")
    dwac.writeDebug("target dist: " .. self.currentTarget.dist .. " max range: " .. dwac.facMaxEngagmentRange)
    if self.currentTarget then
        dwac.writeDebug("target dist: " .. self.currentTarget.dist .. " max range: " .. dwac.facMaxEngagmentRange)
        return self.currentTarget.dist < dwac.facMaxEngagmentRange
    end
    return false
end
function FacUnit:setCurrentTarget(arg)
    if arg then
        if not self.menuStable then
            return
        end
        local _target = nil
        for _, _tgt in pairs(self.targets) do
            if _tgt.id == arg[1] then
                _target = _tgt
                break
            end
        end
        dwac.writeDebug("setCurrentTarget() _target: " .. dwac.dump(_target))
        self.currentTarget = _target
    end
end
function FacUnit:currentTargetInList()
    if self.currentTarget == nil then
        return true -- though not in list, no current target should not generate a "target lost" message
    end
    if self.currentTarget.unit:isExist() then
        local _currentId = self.currentTarget.unit:getID()
        for _, _target in pairs(self.targets) do
            if _currentId == self.currentTarget.unit:getID() then
                self:currentTargetPosition()
                return true
            end
        end
        self:setCurrentTarget({nil})
    else
        self:setCurrentTarget({nil})
    end
    return false
end
function FacUnit:currentTargetPosition()
    if self.currentTarget == nil then
        return
    end
    local _groupId = dwac.getGroupId(self.base)
    local _bearing = dwac.getClockDirection(self.base, self.currentTarget.unit)
    local _msg = "Contact: " .. self.currentTarget.type .. "; " .. _bearing .. " o'clock for " .. math.floor(self.currentTarget.dist) .. " meters"
    dwac.writeDebug(_msg)
    trigger.action.outTextForGroup(_groupId, _msg, 1, true)
end


-- ##########################
-- Properties
-- ##########################

dwac.messageDuration = 5
dwac.facMaxEngagmentRange = 4300 -- meters
dwac.facMaxDetectionRange = 6000
dwac.maxTargetTracking = 5
dwac.scanForTargetFrequency = 5

-- Unit types capable of FAC-A that will receive the F10 menu option
dwac.facCapableUnits = {
    "SA342M",
    "SA342L",
    "SA342Mistral",
    "SA342Minigun"
}

-- reverse of trigger.smokeColor
dwac.smokeColors = {
    [0] = "Green",
    [1] = "Red",
    [2] = "White",
    [3] = "Orange",
    [4] = "Blue"
}

dwac.laserCodes = {
    One = 1688,
    Two = 1588,
    Three = 1488,
    Four = 1337
}

-- collection of FAC-A capable units operating in-game
dwac.facUnits = {}
-- add method of removing fac units no longer in use by a player
local function pruneFACUnits()
    local _facPlayers = dwac.getCurrentFACUnits()
    local _newFacUnits = {}
    for _, _facPlayer in pairs(_facPlayers) do
        for _, _facUnit in pairs(dwac.facUnits) do
            if _facPlayer:getUnitID() == _facUnit:getUnitID() then
                table.insert(_newFacUnits, _facUnit)
                break
            end
        end
    end
    dwac.facUnits = _newFacUnits
end
dwac.pruneFACUnits = pruneFACUnits

dwac.facMenuDB = {}

-- ##########################
-- Methods
-- ##########################

local function addFACMenuFeatures(_unit)
    -- Add the unit for tracking if needed
    if not _unit then
        return
    end
    local _unitId = _unit:getID()
    if not dwac.facUnits[_unitId] then
        dwac.facUnits[_unitId] = FacUnit:new(_unit)
    end
    dwac.facUnits[_unitId].menuStable = false

    local _groupId = dwac.getGroupId(dwac.facUnits[_unitId].base)
    if not dwac.facMenuDB[_groupId] then
        dwac.facMenuDB[_groupId] = {}
    end

    local _FACA = "FAC-A"
    local _onStation = "Go ON Station"
    local _offStation = "Go OFF Station"
    local _facPath = "FacPath"
    local _stationPath = "StationPath"
    local _listTargetPath = "ListTargetPath"
    local _smokeTargetPath = "SmokeTargetPath"
    local _lazeTargetPath = "LazeTargetPath"
    local _artyTargetPath = "ArtyTargetPath"

    if dwac.facMenuDB[_groupId][_stationPath] then
        -- Remove dynamic menu items for refresh
        missionCommands.removeItemForGroup(_groupId, dwac.facMenuDB[_groupId][_stationPath])

        -- Handle being On-Station
        if dwac.facUnits[_unitId].onStation then
            dwac.facMenuDB[_groupId][_stationPath] = missionCommands.addCommandForGroup(_groupId, _offStation, dwac.facMenuDB[_groupId][_facPath], dwac.facUnits[_unitId].goOffStation, dwac.facUnits[_unitId])
            
            dwac.facUnits[_unitId]:currentTargetInList()
            
            -- Recreate the detected targets on each cycle
            if dwac.facMenuDB[_groupId][_listTargetPath] then
                missionCommands.removeItemForGroup(_groupId, dwac.facMenuDB[_groupId][_listTargetPath])
            end
            dwac.facMenuDB[_groupId][_listTargetPath] = missionCommands.addSubMenuForGroup(_groupId, "List targets",  dwac.facMenuDB[_groupId][_facPath])

            dwac.sortTargets(dwac.facUnits[_unitId])
            dwac.limitTargets(dwac.facUnits[_unitId]) -- limit list to dwac.maxTargetsTracked
            for _, _target in pairs(dwac.facUnits[_unitId].targets) do
                missionCommands.addCommandForGroup(_groupId, _target.type, dwac.facMenuDB[_groupId][_listTargetPath], dwac.facUnits[_unitId].setCurrentTarget, dwac.facUnits[_unitId], {_target.id})
            end

            if dwac.facEnableSmokeTarget and dwac.facUnits[_unitId].currentTarget and not dwac.facMenuDB[_groupId][_smokeTargetPath] then
                dwac.facMenuDB[_groupId][_smokeTargetPath] = missionCommands.addCommandForGroup(_groupId, "Smoke target",  dwac.facMenuDB[_groupId][_facPath], dwac.facUnits[_unitId].smokeTarget, dwac.facUnits[_unitId])
            end
            if dwac.facEnableLazeTarget and dwac.facUnits[_unitId].currentTarget and not dwac.facMenuDB[_groupId][_lazeTargetPath] then
                dwac.facMenuDB[_groupId][_lazeTargetPath] = missionCommands.addCommandForGroup(_groupId, "Laze target",  dwac.facMenuDB[_groupId][_facPath], dwac.facUnits[_unitId].lazeTarget, dwac.facUnits[_unitId])
            end
            if dwac.facEnableArtilleryStrike and dwac.facUnits[_unitId].currentTarget and not dwac.facMenuDB[_groupId][_artyTargetPath] then
                dwac.facMenuDB[_groupId][_artyTargetPath] = missionCommands.addCommandForGroup(_groupId, "Call artillery",  dwac.facMenuDB[_groupId][_facPath], dwac.facUnits[_unitId].callArty, dwac.facUnits[_unitId])
            end
        else 
            if dwac.facMenuDB[_groupId][_listTargetPath] then
                missionCommands.removeItemForGroup(_groupId, dwac.facMenuDB[_groupId][_listTargetPath])
                dwac.facMenuDB[_groupId][_listTargetPath] = nil
            end
            if dwac.facMenuDB[_groupId][_smokeTargetPath] then
                missionCommands.removeItemForGroup(_groupId, dwac.facMenuDB[_groupId][_smokeTargetPath])
                dwac.facMenuDB[_groupId][_smokeTargetPath] = nil
            end
            if dwac.facMenuDB[_groupId][_lazeTargetPath] then
                missionCommands.removeItemForGroup(_groupId, dwac.facMenuDB[_groupId][_lazeTargetPath])
                dwac.facMenuDB[_groupId][_lazeTargetPath] = nil
            end
            if dwac.facMenuDB[_groupId][_artyTargetPath] then
                missionCommands.removeItemForGroup(_groupId, dwac.facMenuDB[_groupId][_artyTargetPath])
                dwac.facMenuDB[_groupId][_artyTargetPath] = nil
            end
            dwac.facMenuDB[_groupId][_stationPath] = missionCommands.addCommandForGroup(_groupId, _onStation,  dwac.facMenuDB[_groupId][_facPath], dwac.facUnits[_unitId].goOnStation, dwac.facUnits[_unitId])
        end
    else
        dwac.facMenuDB[_groupId][_facPath] = missionCommands.addSubMenuForGroup(_groupId, "FAC-A")

        -- Laser Codes
        local _laserPath = missionCommands.addSubMenuForGroup(_groupId, "Set laser code", dwac.facMenuDB[_groupId][_facPath])
        missionCommands.addCommandForGroup(_groupId, dwac.laserCodes.One, _laserPath, dwac.setLaserCode, {dwac.facUnits[_unitId], dwac.laserCodes.One})
        missionCommands.addCommandForGroup(_groupId, dwac.laserCodes.Two, _laserPath, dwac.setLaserCode, {dwac.facUnits[_unitId], dwac.laserCodes.Two})
        missionCommands.addCommandForGroup(_groupId, dwac.laserCodes.Three, _laserPath, dwac.setLaserCode, {dwac.facUnits[_unitId], dwac.laserCodes.Three})
        missionCommands.addCommandForGroup(_groupId, dwac.laserCodes.Four, _laserPath, dwac.setLaserCode, {dwac.facUnits[_unitId], dwac.laserCodes.Four})

        -- Smoke Color
        local _smokePath = missionCommands.addSubMenuForGroup(_groupId, "Set smoke color", dwac.facMenuDB[_groupId][_facPath])
        missionCommands.addCommandForGroup(_groupId, "Red", _smokePath, dwac.setFACSmokeColor, {dwac.facUnits[_unitId], dwac.smokeColors[trigger.smokeColor.Red]})
        missionCommands.addCommandForGroup(_groupId, "Orange", _smokePath, dwac.setFACSmokeColor, {dwac.facUnits[_unitId], dwac.smokeColors[trigger.smokeColor.Orange]})
        missionCommands.addCommandForGroup(_groupId, "White", _smokePath, dwac.setFACSmokeColor, {dwac.facUnits[_unitId], dwac.smokeColors[trigger.smokeColor.White]})

        -- Current Settings
        local _settings = missionCommands.addCommandForGroup(_groupId, "Current settings", dwac.facMenuDB[_groupId][_facPath], dwac.getCurrentSettings, {dwac.facUnits[_unitId]})

        -- Station
        dwac.facMenuDB[_groupId][_stationPath] = missionCommands.addCommandForGroup(_groupId, _onStation, dwac.facMenuDB[_groupId][_facPath], dwac.facUnits[_unitId].goOnStation, dwac.facUnits[_unitId])
        dwac.writeDebug("FAC User: " .. _unit:getPlayerName() .. ". Menu: " .. dwac.dump(dwac.facMenuDB[_groupId]))
    end
    dwac.facUnits[_unitId].menuStable = true
end
dwac.addFACMenuFeatures = addFACMenuFeatures

local function processSearchResults(_unit, args)
    local _facUnit = args[1]
    local _coalition = _facUnit.base:getCoalition()
    local _facUnitPoint = _facUnit.base:getPosition().p
    local _offsetFACAPos = { x = _facUnitPoint.x, y = _facUnitPoint.y, z = _facUnitPoint.z }

    -- DSMC based
    pcall(function()
        if _unit ~= nil
        and _unit:getLife() > 0
        and _unit:isActive()
        and _unit:getCoalition() ~= _coalition
        and not _unit:inAir() then
            local _tempPoint = _unit:getPoint()
            local _offsetEnemyPos = { x = _tempPoint.x, y = _tempPoint.y + 2.0, z = _tempPoint.z } -- slightly above ground level
            local landVisible = land.isVisible(_facUnitPoint,_offsetEnemyPos )
            if land.isVisible(_offsetFACAPos,_offsetEnemyPos ) then
                local _dist = dwac.getDistance(_facUnitPoint, _offsetEnemyPos)

                if _dist < dwac.facMaxDetectionRange then
                    table.insert(_facUnit.targets,{ id = _unit:getID(), unit=_unit, dist=_dist, type=_unit:getTypeName()})
                end
            end
        end
    end)
end
dwac.processSearchResults = processSearchResults

local function scanForTargets(_unit)
    timer.scheduleFunction(dwac.scanForTargets, nil, timer.getTime() + dwac.scanForTargetFrequency)
    -- Add the unit for tracking if needed
    if not _unit then
        return
    end
    local _unitId = _unit:getID()
     -- Handle targets
    local _searchVolume = {
        id = world.VolumeType.SPHERE,
        params = {
            point = dwac.facUnits[_unitId].base:getPoint(),
            radius = dwac.facMaxDetectionRange
        }
    }
    dwac.facUnits[_unitId].targets = {} -- reset list of tracked targets
    -- world.searchObjects returns the number of items found
    world.searchObjects(Object.Category.UNIT, _searchVolume, dwac.processSearchResults, {dwac.facUnits[_unitId]})
end
dwac.scanForTargets = scanForTargets

local function sortTargets(_facUnit, _asc)    
    if _asc or _asc == nil then -- default ascending
        table.sort(_facUnit.targets, function(unit1, unit2) return unit1.dist < unit2.dist end)
    else
        table.sort(_facUnit.targets, function(unit1, unit2) return unit1.dist > unit2.dist end)
    end
end
dwac.sortTargets = sortTargets

local function limitTargets(_facUnit)
    local _targets = {}
    local _limit = 0
    if #_facUnit.targets < dwac.maxTargetTracking then
        _limit = #_facUnit.targets
    else
        _limit = dwac.maxTargetTracking
    end
    for i=1, _limit do
        table.insert(_targets, _facUnit.targets[i])
    end
    _facUnit.targets = _targets
end
dwac.limitTargets = limitTargets

local function getCurrentSettings(args)
    local _facUnit = args[1]
    local _groupId = dwac.getGroupId(_facUnit.base)
    trigger.action.outTextForGroup(_groupId, "Laser code: " .. _facUnit.laserCode .. ", Smoke Color: " .. _facUnit.smokeColor, dwac.messageDuration, true)
end
dwac.getCurrentSettings = getCurrentSettings

local function setLaserCode(args) -- args: {facUnit, code}
    args[1].laserCode = args[2]
    dwac.updateFACUnit(args[1])
end
dwac.setLaserCode = setLaserCode


local function setFACSmokeColor(args) -- args: {facUnit, color}
    args[1].smokeColor = args[2]
    dwac.updateFACUnit(args[1])
end
dwac.setFACSmokeColor = setFACSmokeColor

local function isFACCapable(_unit)
    if _unit ~= nil then
        for _, _unitName in pairs(dwac.facCapableUnits) do
            if _unit:getTypeName() == _unitName then
                return true
            end
        end
    end
    return false
end
dwac.isFACCapable = isFACCapable

-- Extracts all current player units that are FAC-A capable
local function getCurrentFACCapableUnits()
    local reply = {}
    for _coalition = coalition.side.RED, coalition.side.BLUE do
        local _players = coalition.getPlayers(_coalition) -- returns array of units run by players
        if _players ~= nil then
            for i = 1, #_players do
                local _unit = _players[i]
                if _unit ~= nil then
                    if dwac.isFACCapable(_unit) then
                        table.insert(reply, _unit)
                    end
                end
            end
        end
    end
    return reply
end
dwac.getCurrentFACCapableUnits = getCurrentFACCapableUnits

local function updateFACUnit(_facUnit)
    if _facUnit then
        if _facUnit.base then
            dwac.facUnits[_facUnit.base:getID()] = _facUnit
        end
    end
end
dwac.updateFACUnit = updateFACUnit

local function doFoo()
    trigger.action.outText("DWAC loaded", dwac.messageDuration, false)
end
dwac.doFoo = doFoo

--#endregion


--#region DWAC

-- ##########################
-- Properties
-- ##########################
if dwac.enableLogging then
    local _date = os.date("*t")
    dwac.logger =
        io.open(
        lfs.writedir() .. "Logs/" .. baseName .. "_" .. _date.year .. "_" .. _date.month .. "_" .. _date.day .. ".log",
        "a+"
    )
end


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
    local isSmokeRequest = requestText:match("^-smoke")
    if isSmokeRequest then
        return dwac.MapRequest.SMOKE
    end

    local isIllumination = requestText:match("^-flare%s*$")
    if isIllumination then
        return dwac.MapRequest.ILLUMINATION
    end

    local isVersionRequest = requestText:match("^-version")
    if isVersionRequest then
        return dwac.MapRequest.VERSION
    end
end
dwac.getMarkerRequest = getMarkerRequest

local function setMapSmoke(requestText, vector)
    smokeColor = requestText:match("^-smoke;(%a+)")
    local lat, lon, alt = coord.LOtoLL(vector)
    return dwac.smokePoint(vector, smokeColor)
end
dwac.setMapSmoke = setMapSmoke

local function setMapIllumination(vector)
    if vector then
        local lat, lon, alt = coord.LOtoLL(vector)
        dwac.writeDebug("Illumination requested: Lat: " .. lat .. " Lon: " .. lon .. " Alt: " .. alt)
        trigger.action.illuminationBomb(vector, dwac.illuminationPower)
        return true
    end
    return false
end
dwac.setMapIllumination = setMapIllumination

local function showVersion()
    trigger.action.outText(baseName .. " version: " .. version, dwac.messageDuration, false)
end
dwac.showVersion = showVersion

local function getLogTimeStamp()
    return os.date("%H:%M:%S") .. " - " .. baseName .. ": "
end
dwac.getLogTimeStamp = getLogTimeStamp

-- highest level DWAC F10 menu addition
--   add calls to functions which add specific menu features here to keep it clean
--   REMEMBER to add clean-up to removeF10MenuOptions()
local function addF10MenuOptions()
    timer.scheduleFunction(dwac.addF10MenuOptions, nil, timer.getTime() + dwac.f10MenuUpdateFrequency)
    -- FAC-A
    local _units = dwac.getCurrentFACCapableUnits()
    if _units then
        for _, _unit in pairs(_units) do
            dwac.addFACMenuFeatures(_unit)
            dwac.scanForTargets(_unit)
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
        for i, panel in ipairs(markerPanels) do
            if event.idx == panel.idx then
                local markType = dwac.getMarkerRequest(panel.text)
                if dwac.enableMapSmoke and markType == dwac.MapRequest.SMOKE then
                    if dwac.setMapSmoke(panel.text, panel.pos) then
                        timer.scheduleFunction(trigger.action.removeMark, panel.idx, timer.getTime() + 2)
                    end
                    break
                elseif dwac.enableMapIllumination and markType == dwac.MapRequest.ILLUMINATION then
                    panel.pos.y = dwac.mapIlluminationAltitude
                    if dwac.setMapIllumination(panel.pos) then
                        timer.scheduleFunction(trigger.action.removeMark, panel.idx, timer.getTime() + 2)
                    end
                    break
                elseif markType == dwac.MapRequest.VERSION then
                    dwac.showVersion()
                    timer.scheduleFunction(trigger.action.removeMark, panel.idx, timer.getTime() + 2)
                    break
                end
            end
        end
    end
end
world.addEventHandler(dwac.dwacEventHandler)

trigger.action.outText(baseName .. " version: " .. version, dwac.messageDuration, false)
dwac.addF10MenuOptions()

--#endregion

dwac.writeDebug("DWAC Active")
return dwac
