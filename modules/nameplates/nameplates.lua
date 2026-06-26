TekagiUI = TekagiUI or {}
TekagiUI.Modules = TekagiUI.Modules or {}
TekagiUI.Modules.Nameplates = {}

local M = TekagiUI.Modules.Nameplates
local state = { referenceLevel = UnitLevel("player") }

------------------------------------------------------------
-- Settings
------------------------------------------------------------
M.name = "Nameplates"
M.settings = {
    enabled = { 
        label = "Enable Nameplate Coloring", 
        type = "toggle", 
        default = true,
        callback = function(value) 
            TekagiUIDB.Nameplates = TekagiUIDB.Nameplates or {}
            TekagiUIDB.Nameplates.enabled = value 
        end 
    },
    tankMode = { 
        label = "Enable Tank Threat Colors", 
        type = "toggle", 
        default = true,
        callback = function(value) 
            TekagiUIDB.Nameplates = TekagiUIDB.Nameplates or {}
            TekagiUIDB.Nameplates.tankMode = value 
        end 
    }
}

------------------------------------------------------------
-- Logic
------------------------------------------------------------
local function GetColor(role)
    local defaults = {
        caster = { r = 0.2, g = 0.6, b = 1.0 },
        miniboss = { r = 0.6, g = 0.2, b = 0.8 },
        melee = { r = 0.5, g = 0.5, b = 0.5 },
        trivial = { r = 0.3, g = 0.3, b = 0.3 },
        boss = { r = 1.0, g = 0.0, b = 0.0 },
        tank_safe = { r = 0.0, g = 1.0, b = 0.0 },
        tank_warn = { r = 1.0, g = 0.5, b = 0.0 }
    }
    -- Force numeric values even if the DB is corrupted
    local db = (TekagiUIDB and TekagiUIDB.Nameplates and TekagiUIDB.Nameplates.colors) or {}
    local c = db[role]
    if type(c) == "table" and type(c.r) == "number" and type(c.g) == "number" and type(c.b) == "number" then
        return c
    end
    return defaults[role] or defaults.melee
end

local function GetRole(unit)
    local isTankModeEnabled = (TekagiUIDB and TekagiUIDB.Nameplates and TekagiUIDB.Nameplates.tankMode ~= false)
    local isTank = (PlayerUtil and type(PlayerUtil.IsPlayerEffectivelyTank) == "function" and PlayerUtil.IsPlayerEffectivelyTank()) or false
    if isTankModeEnabled and isTank and UnitAffectingCombat("player") then
        local status = UnitThreatSituation("player", unit)
        if type(status) == "number" then
            if status == 3 then return "tank_safe" end
            if status > 0 then return "tank_warn" end
        end
    end
    local classification = UnitClassification(unit)
    local level = UnitLevel(unit)
    local _, powerToken = UnitPowerType(unit)
    local isBoss = (level == -1) or (classification == "worldboss") or (level >= (state.referenceLevel + 2))
    if isBoss then return "boss" end
    if (classification == "elite" or classification == "rare" or classification == "rareelite") and level >= (state.referenceLevel + 1) then return "miniboss" end
    if powerToken == "MANA" then return "caster" end
    if classification == "minus" or classification == "trivial" then return "trivial" end
    return "melee"
end

function ApplyColor(unit)
    if not unit or not unit:find("nameplate") then return end
    local namePlate = C_NamePlate.GetNamePlateForUnit(unit)
    if not namePlate or not namePlate.UnitFrame or not namePlate.UnitFrame.healthBar then return end
    
    local healthBar = namePlate.UnitFrame.healthBar
    local isEnabled = (TekagiUIDB and TekagiUIDB.Nameplates and TekagiUIDB.Nameplates.enabled ~= false)
    
    if isEnabled then
        local c = GetColor(GetRole(unit))
        
        -- Bypass the object-passing and use the standard, direct numeric API
        -- If this still fails, it means the frame is truly "locked" by the driver
        healthBar:SetStatusBarColor(c.r, c.g, c.b, 1)
        
        local tex = healthBar:GetStatusBarTexture()
        if tex then 
            tex:SetVertexColor(c.r, c.g, c.b) 
        end
    else
        healthBar:SetStatusBarColor(1, 1, 1, 1)
    end
end

------------------------------------------------------------
-- Init
------------------------------------------------------------
local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_LEVEL_UP")
f:RegisterEvent("NAME_PLATE_UNIT_ADDED")
f:RegisterEvent("UNIT_THREAT_LIST_UPDATE")
f:RegisterEvent("UNIT_HEALTH")
f:SetScript("OnEvent", function(_, event, unit)
    if event == "PLAYER_LEVEL_UP" then state.referenceLevel = UnitLevel("player")
    elseif unit and unit:find("nameplate") then
        C_Timer.After(0, function() ApplyColor(unit) end)
    end
end)

if TekagiUI.RegisterModule then TekagiUI:RegisterModule("Nameplates", M) end