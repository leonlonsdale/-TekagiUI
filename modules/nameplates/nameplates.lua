TekagiUI = TekagiUI or {}
TekagiUI.Modules = TekagiUI.Modules or {}
TekagiUI.Modules.Nameplates = {}

local M = TekagiUI.Modules.Nameplates

local state = {
	referenceLevel = UnitLevel("player"),
}

local activeNameplates = {}

------------------------------------------------------------
-- Colours
------------------------------------------------------------

local defaults = {

	caster = {
		r = 0.2,
		g = 0.6,
		b = 1.0,
	},

	miniboss = {
		r = 0.6,
		g = 0.2,
		b = 0.8,
	},

	melee = {
		r = 0.5,
		g = 0.5,
		b = 0.5,
	},

	trivial = {
		r = 0.3,
		g = 0.3,
		b = 0.3,
	},

	boss = {
		r = 1.0,
		g = 0.0,
		b = 0.0,
	},

	tank_safe = {
		r = 0.0,
		g = 1.0,
		b = 0.0,
	},

	tank_warn = {
		r = 1.0,
		g = 0.5,
		b = 0.0,
	},
}

local function GetColor(role)
	local saved = TekagiUIDB
		and TekagiUIDB.Nameplates
		and TekagiUIDB.Nameplates.colors
		and TekagiUIDB.Nameplates.colors[role]

	if
		type(saved) == "table"
		and type(saved.r) == "number"
		and type(saved.g) == "number"
		and type(saved.b) == "number"
	then
		return saved
	end

	return defaults[role] or defaults.melee
end

------------------------------------------------------------
-- Settings
------------------------------------------------------------

M.settings = {

	name = "Nameplates",

	settings = {

		enabled = {

			label = "Enable Nameplate Coloring",
			type = "toggle",
			default = true,

			callback = function(value)
				TekagiUIDB.Nameplates = TekagiUIDB.Nameplates or {}

				TekagiUIDB.Nameplates.enabled = value
			end,
		},

		tankMode = {

			label = "Enable Tank Threat Colors",
			type = "toggle",
			default = true,

			callback = function(value)
				TekagiUIDB.Nameplates = TekagiUIDB.Nameplates or {}

				TekagiUIDB.Nameplates.tankMode = value
			end,
		},
	},
}

------------------------------------------------------------
-- Role detection
------------------------------------------------------------

local function GetRole(unit)
	local db = TekagiUIDB and TekagiUIDB.Nameplates

	local tankMode = not db or db.tankMode ~= false

	if
		tankMode
		and PlayerUtil
		and PlayerUtil.IsPlayerEffectivelyTank
		and PlayerUtil.IsPlayerEffectivelyTank()
		and UnitAffectingCombat("player")
	then
		local threat = UnitThreatSituation("player", unit)

		if threat == 3 then
			return "tank_safe"
		elseif threat and threat > 0 then
			return "tank_warn"
		end
	end

	local classification = UnitClassification(unit)

	local level = UnitLevel(unit)

	local _, power = UnitPowerType(unit)

	if level == -1 or classification == "worldboss" or level >= state.referenceLevel + 2 then
		return "boss"
	end

	if
		(classification == "elite" or classification == "rare" or classification == "rareelite")
		and level >= state.referenceLevel + 1
	then
		return "miniboss"
	end

	if power == "MANA" then
		return "caster"
	end

	if classification == "minus" or classification == "trivial" then
		return "trivial"
	end

	return "melee"
end

------------------------------------------------------------
-- Restore Blizzard-like colours
------------------------------------------------------------

local reactionColours = {

	[1] = { 1, 0, 0 },
	[2] = { 1, 0, 0 },
	[3] = { 1, 0, 0 },
	[4] = { 1, 1, 0 },
	[5] = { 1, 1, 0 },
	[6] = { 0, 1, 0 },
	[7] = { 0, 1, 0 },
	[8] = { 0, 1, 0 },
}

local function RestoreDefault(unit, healthBar)
	local reaction = UnitReaction("player", unit)

	local c = reactionColours[reaction]

	if c then
		healthBar:SetStatusBarColor(c[1], c[2], c[3], 1)

		local tex = healthBar:GetStatusBarTexture()

		if tex then
			tex:SetVertexColor(c[1], c[2], c[3], 1)
		end
	else
		-- fallback if reaction is unavailable
		healthBar:SetStatusBarColor(1, 1, 1, 1)

		local tex = healthBar:GetStatusBarTexture()

		if tex then
			tex:SetVertexColor(1, 1, 1, 1)
		end
	end
end

------------------------------------------------------------
-- Apply colour
------------------------------------------------------------

local function ApplyColor(unit)
	if not unit or not unit:find("nameplate") then
		return
	end

	if UnitIsFriend("player", unit) then
		return
	end

	local plate = C_NamePlate.GetNamePlateForUnit(unit)

	if not plate or not plate.UnitFrame or not plate.UnitFrame.healthBar then
		return
	end

	local healthBar = plate.UnitFrame.healthBar

	local enabled = TekagiUIDB and TekagiUIDB.Nameplates and TekagiUIDB.Nameplates.enabled ~= false

	if enabled then
		local c = GetColor(GetRole(unit))

		healthBar:SetStatusBarColor(c.r, c.g, c.b, 1)

		local tex = healthBar:GetStatusBarTexture()

		if tex then
			tex:SetVertexColor(c.r, c.g, c.b)
		end
	else
		RestoreDefault(unit, healthBar)
	end
end

------------------------------------------------------------
-- Refresh active plates
------------------------------------------------------------

function M:Refresh()
	for unit in pairs(activeNameplates) do
		if UnitExists(unit) then
			ApplyColor(unit)
		else
			activeNameplates[unit] = nil
		end
	end
end

------------------------------------------------------------
-- Events
------------------------------------------------------------

local frame = CreateFrame("Frame")

frame:RegisterEvent("PLAYER_LEVEL_UP")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:RegisterEvent("NAME_PLATE_UNIT_ADDED")
frame:RegisterEvent("NAME_PLATE_UNIT_REMOVED")
frame:RegisterEvent("UNIT_THREAT_LIST_UPDATE")
frame:RegisterEvent("UNIT_HEALTH")

frame:SetScript("OnEvent", function(_, event, unit)
	if event == "PLAYER_LEVEL_UP" then
		state.referenceLevel = UnitLevel("player")
	elseif event == "NAME_PLATE_UNIT_ADDED" then
		activeNameplates[unit] = true

		C_Timer.After(0, function()
			ApplyColor(unit)
		end)
	elseif event == "NAME_PLATE_UNIT_REMOVED" then
		activeNameplates[unit] = nil
	elseif unit and unit:find("nameplate") then
		C_Timer.After(0, function()
			ApplyColor(unit)
		end)
	end
end)

------------------------------------------------------------
-- Register
------------------------------------------------------------

if TekagiUI.RegisterModule then
	TekagiUI:RegisterModule("Nameplates", M)
end
