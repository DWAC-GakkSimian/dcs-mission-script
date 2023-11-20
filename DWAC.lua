--[[
    Selectable mission features
        - SMOKE: Map targeted (Idea stolen from Tupper of Rotorheads)
            Usage: On the F10 map, place a comment circle with text of "-smoke;<color>" (red|orange|green|white|blue) and minimize
			
        - ILLUMINATION: Map targeted
            Usage: On the F10 map, place a comment circle with text of "-flare" and minimize
			
        - FAC-A: (Currently limited to SA-342 Gazelles)
            - Smoke target
            - Laze target
            - Arty target
			
        - UAV: Map targeted
            Usage: On the F10 map, place a comment circle with text of "-uav" and minimize.  Limit one(1) Optional MQ-9 Reaper in flight.
			
        - REPAIR: Map targeted
            Usage: On the F10 map, place a comment circle with text of "-repair" and minimize.  Limit one(1) Optional CH-47D in flight.

        - DESTROY: 'explode' and then remove all vehicles within x radius of comment circle with text "-destroy".  Limited to players listed
            in dwac.authorizedDestroyers.  Used to reduce the polygon count in areas cleared of threats.
			
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

if _DATABASE == nil then
  local _text = "MOOSE is required for the DWAC script "
  trigger.action.outText( _text, 10, false)
  env.error( _text, false)
  return
end

dwac = {}
dwac.version = "0.6.0"

-- To enable/disable features set their state here
dwac.enableMapSmoke = true
dwac.enableMapIllumination = true
dwac.enableMapUAV = true
dwac.enableMapREPAIR = true
dwac.enableMapDEBUG = true
dwac.listHeloClientsInLog = false   	-- writes out all flyable helos to be compared with CTLD pilotname list

-- General / Common Settings
dwac.messageDuration = 20 				-- seconds
dwac.spawnAir = 1						-- UNDER CONSTRUCTION Spawn units in air (1) or on airfield (0)
dwac.aiSkill = "Excellent"          	-- Random (Random), Excellent (Ace)
dwac.alt_Type = "RADIO"					-- BARO (Sea Level) RADIO (Ground Level)

-- UAV
dwac.uavmessageDuration = 180 			-- seconds
dwac.uavAltitude = 914.4           	 	-- limits opfor units visible to the uav, on Sea level (meter)
dwac.uavType = "MQ-9 Reaper"        	-- "MQ-9 Reaper" or "RQ-1A Predator"
dwac.uavNum = "113"              		-- Support number
dwac.uavLivery = "'camo' scheme"      	-- Livery
dwac.uavInvisible = false				-- false, unit can be seen by Enemy AI CURRENTLY NOT WORKING 24-4-2023
dwac.uavLimit = false               	-- Limit UAV once (true) unlimited (false)

-- UNDER CONSTRUCTION
dwac.uavAlt = 600      		      	 	-- limits opfor units visible to the uav, on Sea level (meter)
dwac.uavSpeed = 111.000					-- 111 x 3,6 is 400km/h
dwac.uavPilot = "GRIM"					-- ? Group name
dwac.uavCallsign = "Pontiac11"   		-- Call sign shown as
dwac.uavGroup = "UAV"        			-- Group name

-- Repair
dwac.repairLimit = false            	-- Limit Repair once (true) unlimited (false)
-- UNDER CONSTRUCTION
dwac.repairAltitude = 762	          	-- On Sea level (meter)
dwac.repairSpeed = 74.000            	-- meters/second (speed is x 3.6 to get km/h) 74 is approx 266,4 km/h
dwac.repairType = "CH-47D"          	-- CH-47D
dwac.repairPilot = "Lightyear"			-- ? Group name
dwac.repairCallsign = "Pontiac12"   	-- Call sign shown as 
dwac.repairGroup = "Support"       		-- Group name
dwac.repairNum = "112"            	  	-- Support number
dwac.repairLivery = "ch-47_green neth"  -- Livery
dwac.repairmessageDuration = 270 		-- seconds

-- Illumination
dwac.mapIlluminationAltitude = 700  	-- Altitude(meters AGL) the illumination bomb appears determines duration (300sec max)/effectiveness
dwac.illuminationPower = 1000000    	-- 1 to 1000000(max) brightness
dwac.illuminationUnits = 3          	-- number of illum bombs deployed in a star pattern
dwac.illuminationRadius = 500       	-- units deployed in meters from target point

-- Destroy
dwac.authorizedDestroyers = { "[GR] Gakk Simian", "DWAC 1-2 |Buz" }
dwac.destroyRadius = 2000               -- meters

-- FAC
dwac.facEnableSmokeTarget = true    	-- allows FAC-A smoking of targets
dwac.facEnableLazeTarget = true    		-- allows FAC-A to laze a target (controls appearance in F10 menu)
dwac.facEnableInfraRedTarget = true 	-- allows FAC-A to put an NVG visible infrared beam on target (with laser).  Not recommended for PvP I suppose.


dwac.facMaxEngagmentRange = 4300    	-- meters
dwac.facMaxDetectionRange = 6000
dwac.maxTargetTracking = 7
dwac.scanForTargetFrequency = 15    	-- longer period reduces the chance of failed target selection due to menu update collision
dwac.displayCurrentTargetFrequency = 5

dwac.MapRequest = { SMOKE = 1, ILLUMINATION = 2, VERSION = 3, UAV = 4, REPAIR = 5, DEBUG = 6, DESTROY = 7 }
dwac.messageDuration = 20 				-- seconds

dwac.facAMenuTexts = {
  baseMenu = "FAC-A",
  smokeTarget = "Smoke target",
  laseTarget = "Lase target",
  currentSettings = "Current settings",
  setLaserCode = "Set laser code",
  setSmokeColor = "Set smoke color",
  targets = "Targets"
}

-- Unit types capable of FAC-A
dwac.facUnits = {
    "SA342M",
    "SA342L",
    "SA342Mistral",
    "SA342Minigun"
}
dwac.facLaserCodes = {
  "1688",
  "1588",
  "1488",
  "1337"
}
dwac.facSmokeColors = {
  "Green",
  "Red",
  "White",
  "Orange",
  "Blue"
}

-- ########################################################################################################################
-- ##########################################   UAV  - In AIR #  options in spawn area ####################################
-- ########################################################################################################################
dwac.uav = {
    ["modulation"] = 0,
    ["tasks"] = 
    {
    }, -- end of ["tasks"]
    ["radioSet"] = false,
    ["task"] = "Reconnaissance",
    ["uncontrolled"] = false,
    ["route"] = 
    {
        ["points"] = 
        {
            [1] = 
            {
                ["alt"] = 914.4,
                ["action"] = "Turning Point",
                ["alt_type"] = "BARO",
                ["speed"] = 111,
                ["task"] = 
                {
                    ["id"] = "ComboTask",
                    ["params"] = 
                    {
                        ["tasks"] = 
                        {
                            [1] = 
                            {
                                ["enabled"] = true,
                                ["auto"] = true,
                                ["id"] = "WrappedAction",
                                ["number"] = 1,
                                ["params"] = 
                                {
                                    ["action"] = 
                                    {
                                        ["id"] = "EPLRS",
                                        ["params"] = 
                                        {
                                            ["value"] = true,
                                            ["groupId"] = 1,
                                        }, -- end of ["params"]
                                    }, -- end of ["action"]
                                }, -- end of ["params"]
                            }, -- end of [1]
                            [2] = 
                            {
                                ["enabled"] = true,
                                ["auto"] = false,
                                ["id"] = "WrappedAction",
                                ["number"] = 2,
                                ["params"] = 
                                {
                                    ["action"] = 
                                    {
                                        ["id"] = "SetInvisible",
                                        ["params"] = 
                                        {
                                            ["value"] = true,
                                        }, -- end of ["params"]
                                    }, -- end of ["action"]
                                }, -- end of ["params"]
                            }, -- end of [2]
                        }, -- end of ["tasks"]
                    }, -- end of ["params"]
                }, -- end of ["task"]
                ["type"] = "Turning Point",
                ["ETA"] = 0,
                ["ETA_locked"] = true,
                ["y"] = 74498.046875,
                ["x"] = 8875.3984375,
                ["formation_template"] = "",
                ["speed_locked"] = true,
            }, -- end of [1]
            [2] = 
            {
                ["alt"] = 914.4,
                ["action"] = "Turning Point",
                ["alt_type"] = "BARO",
                ["speed"] = 56.013888888889,
                ["task"] = 
                {
                    ["id"] = "ComboTask",
                    ["params"] = 
                    {
                        ["tasks"] = 
                        {
                            [1] = 
                            {
                                ["enabled"] = true,
                                ["auto"] = false,
                                ["id"] = "Orbit",
                                ["number"] = 1,
                                ["params"] = 
                                {
                                    ["altitude"] = 914.4,
                                    ["pattern"] = "Circle",
                                    ["speed"] = 55.555555555556,
                                }, -- end of ["params"]
                            }, -- end of [1]
                            [2] = 
                            {
                                ["enabled"] = true,
                                ["auto"] = false,
                                ["id"] = "WrappedAction",
                                ["number"] = 2,
                                ["params"] = 
                                {
                                    ["action"] = 
                                    {
                                        ["id"] = "Option",
                                        ["params"] = 
                                        {
                                            ["value"] = true,
                                            ["name"] = 6,
                                        }, -- end of ["params"]
                                    }, -- end of ["action"]
                                }, -- end of ["params"]
                            }, -- end of [2]
                        }, -- end of ["tasks"]
                    }, -- end of ["params"]
                }, -- end of ["task"]
                ["type"] = "Turning Point",
                ["ETA"] = 241.60473223726,
                ["ETA_locked"] = false,
                ["y"] = 82376.916415147,
                ["x"] = -2127.8499599822,
                ["formation_template"] = "",
                ["speed_locked"] = true,
            }, -- end of [2]
        }, -- end of ["points"]
    }, -- end of ["route"]
    ["groupId"] = 1,
    ["hidden"] = false,
    ["units"] = 
    {
        [1] = 
        {
            ["alt"] = 914.4,
            ["alt_type"] = "BARO",
            ["livery_id"] = "'camo' scheme",
            ["skill"] = "High",
            ["speed"] = 111,
            ["type"] = "MQ-9 Reaper",
            ["unitId"] = 1,
            ["psi"] = -2.5201762879326,
            ["y"] = 74498.046875,
            ["x"] = 8875.3984375,
            ["name"] = "Grim-1-1",
            ["payload"] = 
            {
                ["pylons"] = 
                {
                }, -- end of ["pylons"]
                ["fuel"] = 100,
                ["flare"] = 0,
                ["chaff"] = 0,
                ["gun"] = 100,
            }, -- end of ["payload"]
            ["heading"] = 2.5201762879326,
            ["callsign"] = 
            {
                [1] = 8,
                [2] = 1,
                [3] = 1,
                ["name"] = "Pontiac11",
            }, -- end of ["callsign"]
            ["onboard_num"] = "112",
        }, -- end of [1]
    }, -- end of ["units"]
    ["y"] = 74498.046875,
    ["x"] = 8875.3984375,
    ["name"] = "Grim-1",
    ["communication"] = true,
    ["start_time"] = 0,
    ["frequency"] = 251,
}
dwac.uavInFlight = {
    [coalition.side.RED] = false,
    [coalition.side.BLUE] = false,
}


-- ########################################################################################################################
-- ########################################   UAV  - From Airfield #  options in spawn area ###############################
-- ########################################################################################################################
dwac.uavAirfield = {
    ["modulation"] = 0,
    ["tasks"] = 
    {
    }, -- end of ["tasks"]
    ["radioSet"] = false,
    ["task"] = "Reconnaissance",
    ["uncontrolled"] = false,
    ["route"] = 
    {
        ["points"] = 
        {
            [1] = 
            {
                ["alt"] = 300,
                ["action"] = "From Parking Area Hot",
                ["alt_type"] = "BARO",
                ["speed"] = 111.11111111111,
                ["task"] = 
                {
                    ["id"] = "ComboTask",
                    ["params"] = 
                    {
                        ["tasks"] = 
                        {
                            [1] = 
                            {
                                ["number"] = 1,
                                ["auto"] = true,
                                ["id"] = "WrappedAction",
                                ["enabled"] = true,
                                ["params"] = 
                                {
                                    ["action"] = 
                                    {
                                        ["id"] = "EPLRS",
                                        ["params"] = 
                                        {
                                            ["value"] = true,
                                            ["groupId"] = 1,
                                        }, -- end of ["params"]
                                    }, -- end of ["action"]
                                }, -- end of ["params"]
                            }, -- end of [1]
                            [2] = 
                            {
                                ["number"] = 2,
                                ["auto"] = false,
                                ["id"] = "WrappedAction",
                                ["enabled"] = true,
                                ["params"] = 
                                {
                                    ["action"] = 
                                    {
                                        ["id"] = "SetInvisible",
                                        ["params"] = 
                                        {
                                            ["value"] = true,
                                        }, -- end of ["params"]
                                    }, -- end of ["action"]
                                }, -- end of ["params"]
                            }, -- end of [2]
                            [3] = 
                            {
                                ["enabled"] = true,
                                ["auto"] = false,
                                ["id"] = "WrappedAction",
                                ["number"] = 3,
                                ["params"] = 
                                {
                                    ["action"] = 
                                    {
                                        ["id"] = "Option",
                                        ["params"] = 
                                        {
                                            ["value"] = true,
                                            ["name"] = 6,
                                        }, -- end of ["params"]
                                    }, -- end of ["action"]
                                }, -- end of ["params"]
                            }, -- end of [3]
                        }, -- end of ["tasks"]
                    }, -- end of ["params"]
                }, -- end of ["task"]
                ["type"] = "TakeOffParkingHot",
                ["ETA"] = 0,
                ["ETA_locked"] = true,
                ["y"] = 74498.046875,
                ["x"] = 8875.3984375,
                ["formation_template"] = "",
                ["airdromeId"] = 14,
                ["speed_locked"] = true,
            }, -- end of [1]
            [2] = 
            {
                ["alt"] = 300,
                ["action"] = "Turning Point",
                ["alt_type"] = "BARO",
                ["speed"] = 111.11111111111,
                ["task"] = 
                {
                    ["id"] = "ComboTask",
                    ["params"] = 
                    {
                        ["tasks"] = 
                        {
                            [1] = 
                            {
                                ["number"] = 1,
                                ["auto"] = false,
                                ["id"] = "Orbit",
                                ["enabled"] = true,
                                ["params"] = 
                                {
                                    ["altitude"] = 914.4, -- meter
                                    ["pattern"] = "Circle",
                                    ["speed"] = 55.555555555556,
                                }, -- end of ["params"]
                            }, -- end of [1]
                        }, -- end of ["tasks"]
                    }, -- end of ["params"]
                }, -- end of ["task"]
                ["type"] = "Turning Point",
                ["ETA"] = 105.92256447724,
                ["ETA_locked"] = false,
                ["y"] = 81559.663450253,
                ["x"] = -539.85641851914,
                ["formation_template"] = "",
                ["speed_locked"] = true,
            }, -- end of [2]
        }, -- end of ["points"]
    }, -- end of ["route"]
    ["groupId"] = 1,
    ["hidden"] = false,
    ["units"] = 
    {
        [1] = 
        {
            ["alt"] = 300,
            ["alt_type"] = "BARO",
            ["livery_id"] = "'camo' scheme",
            ["skill"] = "High",
            ["parking"] = "30",
            ["speed"] = 111.11111111111,
            ["type"] = "MQ-9 Reaper",
            ["unitId"] = 1,
            ["psi"] = -2.4980796198651,
            ["parking_id"] = "24",
            ["x"] = 8875.3984375,
            ["name"] = "Grim-1-1",
            ["payload"] = 
            {
                ["pylons"] = 
                {
                }, -- end of ["pylons"]
                ["fuel"] = 100,
                ["flare"] = 0,
                ["chaff"] = 0,
                ["gun"] = 100,
            }, -- end of ["payload"]
            ["y"] = 74498.046875,
            ["heading"] = 2.4163455909405,
            ["callsign"] = 
            {
                [1] = 8,
                [2] = 1,
                [3] = 1,
                ["name"] = "Pontiac11",
            }, -- end of ["callsign"]
            ["onboard_num"] = "112",
        }, -- end of [1]
    }, -- end of ["units"]
    ["y"] = 74498.046875,
    ["x"] = 8875.3984375,
    ["name"] = "Grim-1",
    ["communication"] = true,
    ["start_time"] = 0,
    ["frequency"] = 251,
}
dwac.uavInFlight = {
    [coalition.side.RED] = false,
    [coalition.side.BLUE] = false,
}

-- ########################################################################################################################
-- ######################################################   REPAIR   ######################################################
-- ########################################################################################################################
dwac.repair = {
    ["modulation"] = 0,
    ["tasks"] = 
    {
    }, -- end of ["tasks"]
    ["radioSet"] = false,
    ["task"] = "Transport",
    ["uncontrolled"] = false,
    ["route"] = 
    {
        ["points"] = 
        {
            [1] = 
            {
                ["alt"] = 300,
                ["action"] = "From Parking Area Hot",
                ["alt_type"] = "RADIO",
                ["speed"] = 41.666666666667,
                ["task"] = 
                {
                    ["id"] = "ComboTask",
                    ["params"] = 
                    {
                        ["tasks"] = 
                        {
                            [1] = 
                            {
                                ["number"] = 1,
                                ["auto"] = false,
                                ["id"] = "Land",
                                ["enabled"] = true,
                                ["params"] = 
                                {
                                    ["y"] = 72902.272574181,
                                    ["x"] = 7809.66246567,
                                    ["duration"] = 300,
                                    ["durationFlag"] = false,
                                }, -- end of ["params"]
                            }, -- end of [1]
                        }, -- end of ["tasks"]
                    }, -- end of ["params"]
                }, -- end of ["task"]
                ["type"] = "TakeOffParkingHot",
                ["ETA"] = 0,
                ["ETA_locked"] = true,
                ["y"] = 74368.84375,
                ["x"] = 8878.3486328125,
                ["formation_template"] = "",
                ["airdromeId"] = 14,
                ["speed_locked"] = true,
            }, -- end of [1]
        }, -- end of ["points"]
    }, -- end of ["route"]
    ["groupId"] = 1,
    ["hidden"] = false,
    ["units"] = 
    {
        [1] = 
        {
            ["alt"] = 300,
            ["alt_type"] = "RADIO",
            ["livery_id"] = "ch-47_green neth",
            ["skill"] = "Excellent",
            ["parking"] = "15",
            ["ropeLength"] = 15,
            ["speed"] = 41.666666666667,
            ["type"] = "CH-47D",
            ["unitId"] = 1,
            ["psi"] = 0,
            ["parking_id"] = "23",
            ["x"] = 8878.3486328125,
            ["name"] = "Lightyear-1-1",
            ["payload"] = 
            {
                ["pylons"] = 
                {
                }, -- end of ["pylons"]
                ["fuel"] = "3600",
                ["flare"] = 120,
                ["chaff"] = 120,
                ["gun"] = 100,
            }, -- end of ["payload"]
            ["y"] = 74368.84375,
            ["heading"] = 2.6241508410591,
            ["callsign"] = 
            {
                [1] = 8,
                [2] = 2,
                [3] = 1,
                ["name"] = "Pontiac21",
            }, -- end of ["callsign"]
            ["onboard_num"] = "113",
        }, -- end of [1]
    }, -- end of ["units"]
    ["y"] = 74368.84375,
    ["x"] = 8878.3486328125,
    ["name"] = "Lightyear",
    ["communication"] = true,
    ["start_time"] = 0,
    ["frequency"] = 127.5,
}
dwac.repairInFlight = {
    [coalition.side.RED] = false,
    [coalition.side.BLUE] = false,
}

dwac.farpAmmo = {
    ["category"] = "Fortifications",
    ["shape_name"] = "SetkaKP",
    ["type"] = "FARP Ammo Dump Coating",
    ["unitId"] = 4,
    ["rate"] = 50,
    ["y"] = 78836.311026623,
    ["x"] = 8449.6071372688,
    ["name"] = "DWAC_AMMO",
    ["heading"] = 1.1693705988362,
}

dwac.farpHeliports = {
    ["category"] = "Heliports",
    ["shape_name"] = "invisiblefarp",
    ["type"] = "Invisible FARP",
    ["unitId"] = 1,
    ["heliport_callsign_id"] = 3,
    ["heliport_modulation"] = 0,
    ["rate"] = 100,
    ["y"] = 78840.621464855,
    ["x"] = 8433.3601008565,
    ["name"] = "DWAC_FARP",
    ["heliport_frequency"] = 127.5,
    ["heading"] = 0,
}

-- ##########################
-- Methods
-- ##########################

local function setUpFacA( _client )
    _DATABASE:I( "FAC-A client started: " .. _client:GetName() )
    _client.CurrentTarget = nil
    _client.Targets = {}      
    _client.CurrentLaserCode = "disabled"
    _client.CurrentSmokeColor = "disabled"
    _client.FacAMenu = nil
    _client.SpotterDetectionAngles = { 1, 2, 12, 11, 10, 9, 8, 7, 6 } -- co-pilot visibility
    
    if dwac.facEnableLazeTarget then
      _client.CurrentLaserCode = dwac.facLaserCodes[1] -- 1688
    end
    
    if dwac.facEnableSmokeTarget then
      _client.CurrentSmokeColor = dwac.facSmokeColors[2] -- red
    end
    
    dwac.SetupBaseFacAMenu( _client )
    
    -- Start target detection
    local _targetScanObject = SCHEDULER:New( _client )
    _targetScanObject:Schedule( _client, dwac.ScanForTargets, { _client }, 1, dwac.scanForTargetFrequency, 0.2 ) -- 20% variation on repeat timer
    
    -- Start Menu Refresh
    local _masterObject = SCHEDULER:New( _client )
    _masterObject:Schedule( _client, dwac.RefreshFacATargetList, { _client }, 1, 10 )
    
    -- Display of current target
    local _currentTargetObject = SCHEDULER:New( _client )
    _currentTargetObject:Schedule( _client, dwac.DisplayCurrentTarget, { _client }, 1, dwac.displayCurrentTargetFrequency )
end
dwac.setUpFacA = setUpFacA

-- Function FAC Unit
local function IsFacAUnit( _type )
  for _, _name in pairs( dwac.facUnits ) do
    if _type ~= nil then
      env.info( "Check isFacAUnit: " .. _type )
    end
    if _name:gsub( "%s+", "" ) == _type then 
      return true
    end
  end
  return false
end
dwac.IsFacAUnit = IsFacAUnit

-- Function FAC Base
local function SetupBaseFacAMenu( _client )
  local _group = GROUP:FindByName( _client:GetClientGroupName() )
  _client.FacAMenu = MENU_GROUP:New( _group, dwac.facAMenuTexts.baseMenu )
  
  -- Show Current Settings
  local _facSettingsMenu = MENU_GROUP_COMMAND:New( _group, dwac.facAMenuTexts.currentSettings, _client.FacAMenu, dwac.ShowCurrentFacASettings, _client)
  
  -- Set Laser Codes
  if dwac.facEnableLazeTarget then
    local _laserMenu = MENU_GROUP:New( _group, dwac.facAMenuTexts.setLaserCode, _client.FacAMenu )
    for _, _code in pairs( dwac.facLaserCodes ) do
      MENU_GROUP_COMMAND:New( _group, _code, _laserMenu, dwac.SetFacALaserCode, _client, _code )
    end
  end
  
  -- Set Smoke Color
  if dwac.facEnableSmokeTarget then
    local _smokeMenu = MENU_GROUP:New( _group, dwac.facAMenuTexts.setSmokeColor , _client.FacAMenu )
    for _, _color in pairs( dwac.facSmokeColors ) do
      MENU_GROUP_COMMAND:New( _group, _color, _smokeMenu, dwac.SetFacASmokeColor , _client, _color )
    end
  end
  
  -- Targets
  MENU_GROUP:New( _group, dwac.facAMenuTexts.targets, _client.FacAMenu )
end
dwac.SetupBaseFacAMenu = SetupBaseFacAMenu

local function SetFacALaserCode( _client, _code )
  _client.CurrentLaserCode = _code
end
dwac.SetFacALaserCode = SetFacALaserCode

local function SetFacASmokeColor( _client, _color )
  _client.CurrentSmokeColor = _color
end
dwac.SetFacASmokeColor = SetFacASmokeColor

local function ShowCurrentFacASettings( _client )
  MESSAGE:New( "Laser: " .. _client.CurrentLaserCode .. "\nSmoke: " .. _client.CurrentSmokeColor ):ToClient( _client )
end
dwac.ShowCurrentFacASettings = ShowCurrentFacASettings

local function RefreshFacATargetList( _client )
  local _targetMenu = _client.FacAMenu:GetMenu( dwac.facAMenuTexts.targets )
  local _group = GROUP:FindByName( _client:GetClientGroupName() )
  _targetMenu:RemoveSubMenus()
  local _sortedTargets = dwac.sortTargets( _client.Targets )
  local _limitedTargets = dwac.limitTargets( _sortedTargets )

  local _currentTargetStillInRange = false
  if #_limitedTargets > 0 then
    for _index,_target in ipairs( _limitedTargets ) do
      if _client.CurrentTarget ~= nil and _target.id == _client.CurrentTarget.id then
        dwac.SetCurrentFacATarget( _client, _target )
        _currentTargetStillInRange = true
      end
      MENU_GROUP_COMMAND:New( _group, "(" .. _index .. ")" .. _target.type, _targetMenu, dwac.SetCurrentFacATarget, _client, _target )
    end
    
    if _client.CurrentTarget ~= nil and _currentTargetStillInRange == false then
      MESSAGE:New( _client.CurrentTarget.type .. ": Target lost", 3, "Current target: ", true ):ToClient( _client )
      dwac.SetCurrentFacATarget( _client, nil )
    end
  end
end
dwac.RefreshFacATargetList = RefreshFacATargetList

local function RemoveCurrentTarget( _client )
  
end
dwac.RemoveCurrentTarget = RemoveCurrentTarget

local function SetCurrentFacATarget( _client, _target )
  _client.CurrentTarget = _target
  if _target == nil then
    local _smokeTargetMenu = _client.FacAMenu:GetMenu( dwac.facAMenuTexts.smokeTarget )
    if _smokeTargetMenu ~= nil then
      _smokeTargetMenu:Remove( _smokeTargetMenu.MenuStamp, _smokeTargetMenu.MenuTag )
    end
    
    local _laseTargetMenu = _client.FacAMenu:GetMenu( dwac.facAMenuTexts.laseTarget )
    if _laseTargetMenu ~= nil then
      _laseTargetMenu:Remove( _laseTargetMenu.MenuStamp, _laseTargetMenu.MenuTag )
    end
    dwac.LaseTarget( _client ) -- turn off laser
  else
    local _group = GROUP:FindByName( _client:GetClientGroupName() )
    _client.CurrentTarget.dist = dwac.getDistance( _client:GetCoordinate(), _target.unit:GetCoordinate() )
    MENU_GROUP_COMMAND:New( _group, dwac.facAMenuTexts.smokeTarget, _client.FacAMenu, dwac.SmokeTarget,  _client )
    MENU_GROUP_COMMAND:New( _group, dwac.facAMenuTexts.laseTarget, _client.FacAMenu, dwac.LaseTarget,  _client )
  end
end
dwac.SetCurrentFacATarget = SetCurrentFacATarget

local function DisplayCurrentTarget( _client )
  if _client.CurrentTarget ~= nil then
    local _target = _client.CurrentTarget.unit:GetDCSObject()
    if _target ~= nil then
      local _vector = dwac.getClockDirection( _client,  _target)
      MESSAGE:New( _client.CurrentTarget.type .. " at " .. _vector .. " o'clock - " .. math.floor( _client.CurrentTarget.dist ) .. "m", 3, "Current target: ", true ):ToClient( _client )
    end
  end
end
dwac.DisplayCurrentTarget = DisplayCurrentTarget

local function LaseTarget( _client )
  _client:LaseOff()
  if _client.CurrentTarget ~= nil then
    local _laserCode = tonumber( _client.CurrentLaserCode )
    _client:LaseUnit( _client.CurrentTarget.unit, _laserCode, 600 )
  end
end
dwac.LaseTarget = LaseTarget

local function SmokeTarget( _client )
  if _client.CurrentTarget ~= nil then
    local _dist = dwac.getDistance( _client:GetCoordinate(), _client.CurrentTarget.unit:GetCoordinate() )
    local _color = nil
    if _dist <= dwac.facMaxEngagmentRange then
      if _client.CurrentSmokeColor == "Green" then
        _color = SMOKECOLOR.Green
      elseif _client.CurrentSmokeColor == "Red" then
        _color = SMOKECOLOR.Red
      elseif _client.CurrentSmokeColor == "White" then
        _color = SMOKECOLOR.White
      elseif _client.CurrentSmokeColor == "Orange" then
        _color = SMOKECOLOR.Orange
      elseif _client.CurrentSmokeColor == "Blue" then
        _color = SMOKECOLOR.Blue
      end
      _client.CurrentTarget.unit:Smoke( _color, 50, 0 )
    end
  end
end
dwac.SmokeTarget = SmokeTarget

local function ScanForTargets( _client )
  local _unit = _client:GetClientGroupUnit()
  if _unit ~= nil then
    local _pos = _unit:GetCoordinate()
    local _searchVolume = {
      id = world.VolumeType.SPHERE,
      params = {
        point = _pos,
        radius = dwac.facMaxDetectionRange
      }
    }
    
  
    _client.Targets = {}
    
    world.searchObjects( Object.Category.UNIT, _searchVolume, dwac.ProcessFacAScanResults, _client)
  end
end
dwac.ScanForTargets = ScanForTargets

--- Populates the CLIENT.Targets array with all detected ground units 
-- @param DCS#UNIT detected DCS unit found within the search volume
-- @param Wrapper#CLIENT client unit
local function ProcessFacAScanResults( _detectedUnit, _client )
  local _facACoalition = _client:GetCoalition()
  local _pos = _client:GetCoordinate()
  local _detectedCoalition = _detectedUnit:getCoalition()
  pcall(function()
    if _detectedUnit ~= nil
    and _detectedUnit:getLife() > 0
    and _detectedUnit:isActive()
    and _detectedUnit:getCoalition() ~= _facACoalition
    and not _detectedUnit:inAir() then
      local _tempPoint = _detectedUnit:getPoint()
      local _offsetEnemyPos = { x = _tempPoint.x, y = _tempPoint.y + 2.0, z = _tempPoint.z } -- slightly above ground level        
      if land.isVisible(_pos,_offsetEnemyPos ) then
        local _dist = dwac.getDistance(_pos, _offsetEnemyPos)
        if dwac.IsSpotterVisible( _client, _detectedUnit ) and _dist < dwac.facMaxDetectionRange then
          local _unit = UNIT:Find( _detectedUnit )
          table.insert(_client.Targets,{ id = _detectedUnit:getID(), unit=_unit, dist=_dist, type=_detectedUnit:getTypeName()})
        end
      end
    end
  end)
end
dwac.ProcessFacAScanResults = ProcessFacAScanResults

--get distance in meters assuming a Flat world (DSMC)
local function getDistance(_point1, _point2)
    if _point1 ~= nil and _point2 ~= nil then
        local xUnit = _point1.x
        local yUnit = _point1.z
        local xZone = _point2.x
        local yZone = _point2.z

        local xDiff = xUnit - xZone
        local yDiff = yUnit - yZone

        return math.sqrt(xDiff * xDiff + yDiff * yDiff)
    end
    return 100000
end
dwac.getDistance = getDistance

-- DSMC based
local function getNorthCorrection(gPoint) --gets the correction needed for true north
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
local function getHeading( _client, rawHeading)
  local unitpos = _client:GetPosition()
  if unitpos then
    local Heading = math.atan2(unitpos.x.z, unitpos.x.x)
    if not rawHeading then
      Heading = Heading + dwac.getNorthCorrection(unitpos.p)
    end
    if Heading < 0 then
      Heading = Heading + 2*math.pi -- put heading in range of 0 to 2*pi
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
local function getClockDirection( _client, _obj)
    -- Source: Helicopter Script - Thanks!
    local _position = _obj:getPosition().p -- get position of _obj
    local _playerPosition = _client:GetCoordinate() -- get position of _client
    local _relativePosition = dwac.vecsub( _position, _playerPosition )
    local _playerHeading = dwac.getHeading( _client ) -- the rest of the code determines the 'o'clock' bearing of the missile relative to the helicopter

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

local function sortTargets( _targets, _asc )    
  local _results = dwac.deepCopy( _targets )
  if _asc or _asc == nil then -- default ascending
      table.sort( _results, function(unit1, unit2) return unit1.dist < unit2.dist end )
  else
      table.sort( _results, function(unit1, unit2) return unit1.dist > unit2.dist end )
  end
  return _results
end
dwac.sortTargets = sortTargets

local function limitTargets( _targets )
  local _results = {} --dwac.deepCopy( _targets )
  local _limit = 0
  if #_targets < dwac.maxTargetTracking then
      _limit = #_targets
  else
      _limit = dwac.maxTargetTracking
  end
  for i=1, _limit do
      table.insert( _results, _targets[i])
  end
  return _results
end
dwac.limitTargets = limitTargets

function IsSpotterVisible( _client, _target )
    if _target ~= nil then
        local _targetBearing = dwac.getClockDirection( _client, _target)
        for _, _clockDirection in pairs( _client.SpotterDetectionAngles ) do
            if _targetBearing == _clockDirection then
                return true
            end
        end        
    end
    return false
end
dwac.IsSpotterVisible = IsSpotterVisible


-- Read markers F10 map
local function getMarkerRequest(requestText)
    local lowerText = string.lower(requestText)
    local isSmokeRequest = lowerText:match("^%s*-smoke;%a+%s*$")
    if isSmokeRequest then
        return dwac.MapRequest.SMOKE
    end

    local isIllumination = lowerText:match("^%s*-flare%s*$")
    if isIllumination then
        return dwac.MapRequest.ILLUMINATION
    end

    local isUAVrequest = lowerText:match("^%s*-uav%s*$")
    if isUAVrequest then
        return dwac.MapRequest.UAV
    end

    local isREPAIRrequest = lowerText:match("^%s*-repair%s*$")
    if isREPAIRrequest then
        return dwac.MapRequest.REPAIR
    end

	local isDEBUGrequest = lowerText:match("^%s*-debug%s*$")
    if isDEBUGrequest then
        return dwac.MapRequest.DEBUG
    end
	
    local isVersionRequest = lowerText:match("^-version%s*$")
    if isVersionRequest then
        return dwac.MapRequest.VERSION
    end
	
    local isVersionRequest = lowerText:match("^-destroy%s*$")
    if isVersionRequest then
        return dwac.MapRequest.DESTROY
    end
end
dwac.getMarkerRequest = getMarkerRequest

local function setMapSmoke(requestText, vector)
    local lowerText = string.lower(requestText)
    smokeColor = lowerText:match("^-smoke;(%a+)")
    return dwac.smokePoint(vector, smokeColor)
end
dwac.setMapSmoke = setMapSmoke

-- Function Illumination
local function setMapIllumination(vector)
    if dwac.illuminationUnits == nil or dwac.illuminationUnits < 0 then
        _DATABASE:E( "dwac.illuminationUnits is nil or negative" )
        return false
    end

    if vector then
        -- Calculate AGL
        local _aglVector = {x = vector.x, y = land.getHeight({x = vector.x, y = vector.z}) + dwac.mapIlluminationAltitude, z = vector.z}

        local lat, lon, alt = coord.LOtoLL(_aglVector)
        _DATABASE:E( "Illumination requested: Lat: " .. lat .. " Lon: " .. lon .. " Alt: " .. alt)
        if dwac.illuminationUnits == 1 then
            trigger.action.illuminationBomb(_aglVector, dwac.illuminationPower)
        else
            local points = dwac.getRadialPoints(_aglVector, dwac.illuminationRadius, dwac.illuminationUnits)
            for _, _point in pairs(points) do
                trigger.action.illuminationBomb(_point, dwac.illuminationPower)
            end
        end
        return true
    end
    return false
end
dwac.setMapIllumination = setMapIllumination

local function requestDestroy( panel )
    BASE:I( "Panel destroy command issued by: "..panel.author )
    for _,_auth in pairs( dwac.authorizedDestroyers ) do
        if _auth == panel.author then
            local _vol = {
                id = world.VolumeType.SPHERE,
                params = {
                    point = panel.pos,
                    radius = dwac.destroyRadius
                }
            }
            if dwac.uavInFlight[panel.coalition] then
                return true -- return without doing anything, but clear the marker
            end
            world.searchObjects( Object.Category.UNIT, _vol, dwac.destroyUnit )
            break
        end
    end
end
dwac.requestDestroy = requestDestroy

local function destroyUnit( unit )
    local _unit = UNIT:Find( unit )
    BASE:I( "Unit found: ".._unit:Name() )
    local _isAlive = _unit:IsAlive()
    if _isAlive == true then
        _unit:Destroy( true ) -- generate crash or dead event based on unit type
    else
        _unit:Destroy( false ) -- no event generated
    end
end
dwac.destroyUnit = destroyUnit

-- Function UAV active or not
local function uavSearch(_unit, args)
    if _unit:getTypeName() == dwac.uavType and
        _unit:getCoalition() == args[1] and
        _unit:inAir() then
        dwac.uavInFlight[args[1]] = true -- Probably a problem.  Coalition collision?
    end
end
dwac.uavSearch = uavSearch

-- Function UAV Spawn
local function setMapUAV(panel)
    -- BASE:I( "setMapUAV()")
    -- BASE:I( panel.pos )
    local vector = panel.pos
    local _author = panel.author
    local _playerUnit = nil
    for _, _group in pairs(coalition.getGroups(panel.coalition)) do
        for _, _unit in pairs(_group:getUnits()) do
            if _unit:getPlayerName() == _author then
                _playerUnit = _unit
                break
            end
        end
        if _playerUnit ~= nil then
            break
        end
    end
    if _playerUnit == nil then
        return false
    end
    local _country = _playerUnit:getCountry()
    local _vol = {
        id = world.VolumeType.SPHERE,
        params = {
            point = vector,
            radius = 150000 -- 150 kilometer radius
        }
    }
    if dwac.uavInFlight[panel.coalition] then
        return true -- return without doing anything, but clear the marker
    end
    world.searchObjects(Object.Category.UNIT, _vol, dwac.uavSearch, {panel.coalition})

    -- delay to let DCS locate a UAV or not
    timer.scheduleFunction(function()
        if not dwac.uavInFlight[panel.coalition] then
            -- get nearest airfield to vector
            local nearestAirfield = dwac.getNearestAirfield(vector, panel.coalition)
            local nearestAirfieldPoint = nearestAirfield:getPoint()

			local nearestAirfieldID = nearestAirfield:getID()
			dwac.uavnearestAirfieldID = nearestAirfieldID -- Set airport ID

            -- spawn UAV at altitude with directions to fly to vector and begin orbit.
            -- Set UAV position
            dwac.uav.x = nearestAirfieldPoint.x
            dwac.uav.y = nearestAirfieldPoint.z  -- don't ask me why
            dwac.uav["units"][1].x = nearestAirfieldPoint.x 																				-- determine player location
            dwac.uav["units"][1].y = nearestAirfieldPoint.z 																				-- determine player location
            dwac.uav["units"][1].skill = dwac.aiSkill																						-- AI Skill
            dwac.uav["units"][1].livery_id = dwac.uavLivery																					-- UAV Livery
            dwac.uav["units"][1].type = dwac.uavType																						-- UAV Type
            dwac.uav["units"][1].onboard_num = dwac.uavNum																					-- UAV Number
            dwac.uav["route"]["points"][2].x = vector.x																						-- F10 Waypoint location
            dwac.uav["route"]["points"][2].y = vector.z																						-- F10 Waypoint location
            dwac.uav["route"]["points"][2].alt = dwac.uavAltitude																			-- Waypoint Altitude
            dwac.uav["route"]["points"][2].alt_type = dwac.alt_Type																			-- Altitude MGL / SL
            dwac.uav["route"]["points"][2]["task"]["params"]["tasks"][1]["params"].altitude = dwac.uavAltitude								-- Waypoint Altitude
            dwac.uav["route"]["points"][1].alt = dwac.uavAltitude																			-- Waypoint Altitude
            dwac.uav["route"]["points"][1].alt_type = dwac.alt_Type																			-- Altitude MGL / SL
            dwac.uav["route"]["points"][1]["task"]["params"]["tasks"][2]["params"]["action"]["params"].value = dwac.uavInvisible			-- Unit invisible or not

			if(dwac.spawnAir == 0)
				then
				-- Take off FROM airfield, so spawnAir == 0
					dwac.uavAirfield["route"]["points"][1].airdromeId = dwac.uavnearestAirfieldID 											-- Sets AirfieldID for Repair unit to start from.
					
					trigger.action.outTextForCoalition(panel.coalition, "CAUTION: Launching an UAV from " .. nearestAirfield:getName(), dwac.uavmessageDuration, false)
					coalition.addGroup(_country, Group.Category.AIRPLANE, dwac.uavAirfield)
				else
				-- Take off IN air, so spawnAir == 1
					dwac.uav["route"]["points"][1].x = vector.x																				-- Starting Coordinates
					dwac.uav["route"]["points"][1].y = vector.z																				-- Starting Coordinates

					trigger.action.outTextForCoalition(panel.coalition, "CAUTION: UAV departing from " .. nearestAirfield:getName(), dwac.messageDuration, false)
					coalition.addGroup(_country, Group.Category.AIRPLANE, dwac.uav)
				end



            local lat, lon, alt = coord.LOtoLL(vector)
            _DATABASE:E( "User " .. _playerUnit:getPlayerName() .. " requested UAV for Lat: " .. lat .. " Lon: " .. lon )
            dwac.uavInFlight[panel.coalition] = dwac.uavLimit
		else
					trigger.action.outTextForCoalition(panel.coalition, "UAV allready airborn", dwac.messageDuration, false)	-- Message UAV allready in the AIR
						-- UNDER CONSTRUCTION Needs to be inserted to UAV Coordinates
						--dwac.uav["route"]["points"][2].x = vector.x																			-- New F10 Waypoint location
						--dwac.uav["route"]["points"][2].y = vector.z																			-- New F10 Waypoint location
					dwac.uavInFlight[panel.coalition] = dwac.uavLimit
        end
    end, nil, timer.getTime() + 5)
    return true
end
dwac.setMapUAV = setMapUAV
-- End Function UAV

-- Function REPAIR active or not
local function repairSearch(_unit, args)
    if _unit:getTypeName() == dwac.repairType and
        _unit:getCoalition() == args[1] and
        _unit:inAir() then
        dwac.repairInFlight[args[1]] = true -- Probably a problem.  Coalition collision?
    end
end
dwac.repairSearch = repairSearch

-- Function REPAIR Spawn
local function setMapREPAIR(panel)
    local vector = panel.pos
    local _author = panel.author
    local _playerUnit = nil
    for _, _group in pairs(coalition.getGroups(panel.coalition)) do
        for _, _unit in pairs(_group:getUnits()) do
            if _unit:getPlayerName() == _author then
                _playerUnit = _unit
                break
            end
        end
        if _playerUnit ~= nil then
            break
        end
    end
    if _playerUnit == nil then
        return false
    end
    local _country = _playerUnit:getCountry()
    local _vol = {
        id = world.VolumeType.SPHERE,
        params = {
            point = vector,
            radius = 150000 -- 150 kilometer radius
        }
    }
    if dwac.repairInFlight[panel.coalition] then
        return true -- return without doing anything, but clear the marker
    end
    world.searchObjects(Object.Category.UNIT, _vol, dwac.repairSearch, {panel.coalition})

    -- delay to let DCS locate a REPAIR or not
    timer.scheduleFunction(function()
        if not dwac.repairInFlight[panel.coalition] then
            -- get nearest airfield to vector
            local nearestAirfield = dwac.getNearestAirfield(vector, panel.coalition)
            local nearestAirfieldPoint = nearestAirfield:getPoint()

			local nearestAirfieldID = nearestAirfield:getID()
			dwac.repairnearestAirfieldID = nearestAirfieldID -- Set airport ID

            -- spawn REPAIR with directions to fly to vector and Land.
            -- Get best REPAIR position
            dwac.repair.x = nearestAirfieldPoint.x
            dwac.repair.y = nearestAirfieldPoint.z  -- don't ask me why
					-- For Spawn in AIR
            --dwac.repair["units"][1].x = nearestAirfieldPoint.x	-- Coordinates to start from
            --dwac.repair["units"][1].y = nearestAirfieldPoint.z	-- Coordinates to start from
			
					-- or For Spawn on AIRFIELD
			dwac.repair["route"]["points"][1].airdromeId = dwac.repairnearestAirfieldID 				-- Sets AirfieldID for Repair unit to start from.
			
					-- Waypoint
			dwac.repair["route"]["points"][1]["task"]["params"]["tasks"][1]["params"].x = vector.x		-- Waypoint
            dwac.repair["route"]["points"][1]["task"]["params"]["tasks"][1]["params"].y = vector.z + 20	-- Waypoint (added 20 offset)

            coalition.addGroup(_country, Group.Category.HELICOPTER, dwac.repair)
			
			dwac.farpAmmo.x = vector.x + 20		-- Coordinates for Ammo (added 20 offset)
            dwac.farpAmmo.y = vector.z			-- Coordinates for Ammo

			dwac.farpHeliports.x = vector.x		-- Coordinates for Heliport
            dwac.farpHeliports.y = vector.z		-- Coordinates for Heliport
			
			--[[
			dwac.farpMarker.mapX = vector.x		-- Coordinates for Marker
			dwac.farpMarker.mapY = vector.z		-- Coordinates for Marker
			--]]
            coalition.addStaticObject(_country, dwac.farpAmmo)
            coalition.addStaticObject(_country, dwac.farpHeliports)

            --coalition.markToCoalition(_country, dwac.farpMarker)	
			
			--coalition.addStaticObject(country.id.USA, staticObj)
			--coalition.addGroup(country.id.USA, Group.Category.GROUND, groupData)			
		--trigger.action.outTextForCoalition(panel.coalition, "DEBUG: airfieldID : " .. dwac.repairnearestAirfieldID, dwac.messageDuration, false)
            trigger.action.outTextForCoalition(panel.coalition, "Launching support from " .. nearestAirfield:getName(), dwac.messageDuration, false)

            local lat, lon, alt = coord.LOtoLL(vector)
            _DATABASE:E( "User " .. _playerUnit:getPlayerName() .. " requested REPAIRS for Lat: " .. lat .. " Lon: " .. lon )
            dwac.repairInFlight[panel.coalition] = dwac.repairLimit
        end
    end, nil, timer.getTime() + 5)
    return true
end
dwac.setMapREPAIR = setMapREPAIR
-- End Function REPAIR

-- Function Version
local function showVersion()
    MESSAGE:New( "Version: " .. dwac.version, 5, "DWAC Load" ):ToAll()
end
dwac.showVersion = showVersion

-- Function DEBUG
local function showDebug()
--unitFuel(Lightyear)
MESSAGE:New( " : dwac.spawnAir      = " .. dwac.spawnAir, 5, "DEBUG" ):ToAll() -- Debugging flags example
--MESSAGE:New( " : dwac.uavInvisible  = " .. dwac.uavInvisible, 5, "DEBUG" ):ToAll() -- Debugging flags example
--MESSAGE:New( " : dwac.fuelLevel = " .. dwac.fuelLevel, 5, "DEBUG" ):ToAll()
end
dwac.showDebug = showDebug

local function missionStopHandler(event)
    _DATABASE:E( "DWAC: Closing event handlers")
    if mapIlluminationRequestHandler then
        world.removeEventHandler(mapIlluminationRequestHandler)
    end
    if dwac.mapSmokeRequestHandler then
        world.removeEventHandler(mapSmokeRequestHandler)
    end
end
dwac.missionStopHandler = missionStopHandler

-- Function Smoke
local function smokePoint(vector, smokeColor)
    vector.y = vector.y + 2.0
    local lat, lon, alt = coord.LOtoLL(vector)
    return pcall(function()
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
        else
            return false
        end
    end)
end
dwac.smokePoint = smokePoint

-- returns the nearest coalition airbase for a given point
local function getNearestAirfield(_point, _coalition)
    local nearestAirfield = nil
    local currentABDistance = 0
    local airbases = coalition.getAirbases(_coalition)
    for _, _airbase in pairs(airbases) do
        local abPoint = _airbase:getPoint()
        local distance = dwac.getDistance(_point, abPoint)
        local desc = _airbase:getDesc()
        -- No helipad or destroyed AB
        local abNotHelipad = desc["category"] ~= Airbase.Category.HELIPAD and desc["life"] > 0
        if abNotHelipad and (distance < currentABDistance or currentABDistance == 0) then
            currentABDistance = distance
            nearestAirfield = _airbase
        end
    end
    return nearestAirfield
end
dwac.getNearestAirfield = getNearestAirfield

local function getRadialPoints(_sourceVec, _radius, _count)
    -- https://math.stackexchange.com/questions/1030655/how-do-we-find-points-on-a-circle-equidistant-from-each-other
    local points = {}
    for i=0, _count do
        local _vec3 = {}
        _vec3.y = _sourceVec.y -- same altitude
        _vec3.x = _sourceVec.x + _radius * math.cos(2 * math.pi * i / _count)
        _vec3.z = _sourceVec.z + _radius * math.sin(2 * math.pi * i / _count)
        table.insert(points, _vec3)
    end
    return points
end
dwac.getRadialPoints = getRadialPoints

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
                    BASE:I( "ILLUMINATE" )
                    BASE:I( panel )
                    panel.pos.y = dwac.mapIlluminationAltitude
                    if dwac.setMapIllumination(panel.pos) then
                        timer.scheduleFunction(trigger.action.removeMark, panel.idx, timer.getTime() + 2)
                    end
                    break
                elseif dwac.enableMapUAV and markType == dwac.MapRequest.UAV then
                    if dwac.setMapUAV(panel) then
                        timer.scheduleFunction(trigger.action.removeMark, panel.idx, timer.getTime() + 2)
                    end
                    break
				elseif dwac.enableMapREPAIR and markType == dwac.MapRequest.REPAIR then
                    if dwac.setMapREPAIR(panel) then
                        timer.scheduleFunction(trigger.action.removeMark, panel.idx, timer.getTime() + 2)
                    end
                    break
				elseif dwac.enableMapDEBUG and markType == dwac.MapRequest.DEBUG then
                    dwac.showDebug()
						timer.scheduleFunction(trigger.action.removeMark, panel.idx, timer.getTime() + 2)
                    break
                elseif markType == dwac.MapRequest.VERSION then
                    dwac.showVersion()
						timer.scheduleFunction(trigger.action.removeMark, panel.idx, timer.getTime() + 2)
                    break
                elseif markType == dwac.MapRequest.DESTROY then
                    dwac.requestDestroy( panel )
                    timer.scheduleFunction(trigger.action.removeMark, panel.idx, timer.getTime() + 2)
                end
            end
        end
    end
end
world.addEventHandler(dwac.dwacEventHandler)

dwac.showDebug()
dwac.showVersion()

-- Handle Player entrances
dwac.ClientSelectHandler = EVENTHANDLER:New()
dwac.ClientSelectHandler:HandleEvent( EVENTS.PlayerEnterAircraft )

function dwac.ClientSelectHandler:OnEventPlayerEnterAircraft( eventData )
  _DATABASE:I( "OnPlayerEnterAircraft" )
  _DATABASE:I( eventData )
  local _client = CLIENT:FindByName( eventData.IniDCSUnitName )
  local _type = eventData.IniTypeName

  _DATABASE:I( "InitFacA.Client.Type: " .. _type )
  if dwac.IsFacAUnit( _type ) then
    dwac.setUpFacA( _client )
  end
end

if dwac.listHeloClientsInLog then
  for _,_client in pairs( _DATABASE.CLIENTS ) do
    BASE:I( _client.ClientName )
  end
end