TekagiUI = TekagiUI or {}
TekagiUI.Modules = TekagiUI.Modules or {}
TekagiUI.Modules.UnitColors = {}

local M = TekagiUI.Modules.UnitColors

local UnitMap = {
	player = {
		label = "Class Colored Player Frame",
		bar = function()
			return PlayerFrame.PlayerFrameContent.PlayerFrameContentMain.HealthBarsContainer.HealthBar
		end,
	},
	target = {
		label = "Class Colored Target Frame",
		bar = function()
			return TargetFrame.TargetFrameContent.TargetFrameContentMain.HealthBarsContainer.HealthBar
		end,
	},
	focus = {
		label = "Class Colored Focus Frame",
		bar = function()
			return FocusFrame.TargetFrameContent.TargetFrameContentMain.HealthBarsContainer.HealthBar
		end,
	},
	targettarget = {
		label = "Class Colored Target-of-Target",
		bar = function()
			return TargetFrameToT.HealthBar
		end,
	},
}

M.defaults = {
	player = true,
	target = true,
	focus = true,
	targettarget = true,
}

local function GetUnitColor(unit)
	if not UnitExists(unit) then
		return CreateColor(0.5, 0.5, 0.5)
	end

	local color
	if UnitIsPlayer(unit) then
		color = GetPlayerColor(unit)
	else
		color = GetReactionColor(unit)
	end

	return color or CreateColor(0.5, 0.5, 0.5)
end

local function ApplyColor(unit)
	if not TekagiUIDB or not TekagiUIDB.UnitColors then
		return
	end

	local data = UnitMap[unit]
	local statusBar = data.bar()
	if not statusBar then
		return
	end

	local texture = statusBar:GetStatusBarTexture()
	if not texture then
		return
	end

	if TekagiUIDB.UnitColors[unit] then
		local color = GetUnitColor(unit)
		statusBar:SetStatusBarDesaturated(true)
		texture:SetGradient("HORIZONTAL", color, color)
	else
		statusBar:SetStatusBarDesaturated(false)
		texture:SetGradient("HORIZONTAL", CreateColor(1, 1, 1), CreateColor(1, 1, 1))

		if statusBar.UpdateColor then
			statusBar:UpdateColor()
		end
	end
end

M.settings = {
	name = "Unit Frames",
	settings = {},
}

for unit, data in pairs(UnitMap) do
	M.settings.settings[unit] = {
		label = data.label,
		callback = function(value)
			if TekagiUIDB.UnitColors then
				TekagiUIDB.UnitColors[unit] = value
			end
			ApplyColor(unit)
		end,
	}
end

local frame = CreateFrame("Frame")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:RegisterEvent("PLAYER_TARGET_CHANGED")
frame:RegisterEvent("PLAYER_FOCUS_CHANGED")
frame:RegisterEvent("UNIT_TARGET")
frame:RegisterEvent("UNIT_FACTION")

frame:SetScript("OnEvent", function(self, event, unit)
	if unit and UnitMap[unit] then
		ApplyColor(unit)
	else
		for u, _ in pairs(UnitMap) do
			ApplyColor(u)
		end
	end
end)
