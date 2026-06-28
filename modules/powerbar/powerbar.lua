TekagiUI = TekagiUI or {}
TekagiUI.Modules = TekagiUI.Modules or {}

------------------------------------------------------------
-- BORDER
------------------------------------------------------------

local function AddBorder(f)
	local border = CreateFrame("Frame", nil, f, "BackdropTemplate")

	border:SetPoint("TOPLEFT", -1, 1)
	border:SetPoint("BOTTOMRIGHT", 1, -1)

	border:SetBackdrop({
		edgeFile = "Interface\\Buttons\\WHITE8X8",
		edgeSize = 1,
	})

	border:SetBackdropBorderColor(0, 0, 0, 1)
end

------------------------------------------------------------
-- MAIN POWER BAR
------------------------------------------------------------

TekagiUI.Modules.PowerBar = {}

local M = TekagiUI.Modules.PowerBar

local bar = CreateFrame("StatusBar", "TekagiPowerBar", UIParent)

bar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")

bar.bg = bar:CreateTexture(nil, "BACKGROUND")
bar.bg:SetAllPoints()
bar.bg:SetColorTexture(0, 0, 0, 0.5)

bar.text = bar:CreateFontString(nil, "OVERLAY")
bar.text:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
bar.text:SetPoint("CENTER")

AddBorder(bar)

------------------------------------------------------------
-- SECONDARY POWER BAR
------------------------------------------------------------

TekagiUI.Modules.SecondaryPower = {}

local S = TekagiUI.Modules.SecondaryPower

local SecondaryPowerColours = {

	PALADIN = {
		1.00,
		0.85,
		0.00,
		1,
	},

	WARLOCK = {
		0.58,
		0.00,
		1.00,
		1,
	},

	MONK = {
		0.00,
		1.00,
		0.59,
		1,
	},

	PRIEST = {
		0.40,
		0.00,
		1.00,
		1,
	},

	EVOKER = {
		0.00,
		0.80,
		1.00,
		1,
	},

	DRUID = {
		1.00,
		0.49,
		0.00,
		1,
	},
}

local secContainer = CreateFrame("Frame", "TekagiSecondaryContainer", UIParent)

local segments = {}

------------------------------------------------------------
-- UPDATE SEGMENTS
------------------------------------------------------------

local function UpdateSegments(current, max)
	if not max or max <= 0 then
		return
	end

	local width = secContainer:GetWidth()
	local spacing = 2

	local segmentWidth = (width - ((max - 1) * spacing)) / max

	local _, class = UnitClass("player")

	local colour = SecondaryPowerColours[class] or {
		1,
		1,
		1,
		1,
	}

	for i = 1, max do
		if not segments[i] then
			segments[i] = CreateFrame("Frame", nil, secContainer, "BackdropTemplate")

			segments[i]:SetBackdrop({
				edgeFile = "Interface\\Buttons\\WHITE8X8",
				edgeSize = 1,
			})

			segments[i]:SetBackdropBorderColor(0, 0, 0, 1)

			segments[i].bg = segments[i]:CreateTexture(nil, "BACKGROUND")
			segments[i].bg:SetAllPoints()
			segments[i].bg:SetColorTexture(0, 0, 0, 0.5)

			segments[i].tex = segments[i]:CreateTexture(nil, "ARTWORK")

			segments[i].tex:SetPoint("TOPLEFT", 2, -2)
			segments[i].tex:SetPoint("BOTTOMRIGHT", -2, 2)
		end

		segments[i].tex:SetColorTexture(colour[1], colour[2], colour[3], colour[4])

		segments[i]:SetSize(segmentWidth, secContainer:GetHeight())

		segments[i]:ClearAllPoints()

		if i == 1 then
			segments[i]:SetPoint("LEFT", secContainer, "LEFT")
		else
			segments[i]:SetPoint("LEFT", segments[i - 1], "RIGHT", spacing, 0)
		end

		segments[i].tex:SetShown(i <= current)

		segments[i]:Show()
	end

	for i = max + 1, #segments do
		segments[i]:Hide()
	end
end

------------------------------------------------------------
-- POSITIONING
------------------------------------------------------------

local function AnchorBars()
	local cooldownViewer = _G["EssentialCooldownViewer"]

	if cooldownViewer and cooldownViewer:IsVisible() then
		bar:ClearAllPoints()

		bar:SetPoint("BOTTOM", cooldownViewer, "TOP", 0, 5)

		bar:SetWidth(cooldownViewer:GetWidth())
	end

	secContainer:ClearAllPoints()

	secContainer:SetPoint("BOTTOM", bar, "TOP", 0, 5)

	secContainer:SetSize(bar:GetWidth(), TekagiUIDB.SecondaryPower.height or 10)
end

------------------------------------------------------------
-- UPDATE POWER BARS
------------------------------------------------------------

local function UpdatePowerBars()
	if not TekagiUIDB.PowerBar.enabled then
		bar:Hide()
	else
		bar:Show()
	end

	local current = UnitPower("player")
	local max = UnitPowerMax("player")

	bar:SetMinMaxValues(0, max)
	bar:SetValue(current)

	bar.text:SetText(current .. " / " .. max)

	local powerType = UnitPowerType("player")

	local colour = PowerBarColor[powerType] or {
		r = 1,
		g = 1,
		b = 1,
	}

	bar:SetStatusBarColor(colour.r, colour.g, colour.b)
	------------------------------------------------------------
	-- SECONDARY POWER
	------------------------------------------------------------

	local _, class = UnitClass("player")

	local secondary

	if class == "PALADIN" then
		secondary = Enum.PowerType.HolyPower
	elseif class == "WARLOCK" then
		secondary = Enum.PowerType.SoulShards
	elseif class == "MONK" then
		secondary = Enum.PowerType.Chi
	elseif class == "PRIEST" then
		secondary = Enum.PowerType.Insanity
	elseif class == "EVOKER" then
		secondary = Enum.PowerType.Essence
	elseif class == "DRUID" then
		secondary = Enum.PowerType.ComboPoints
	end

	if secondary then
		local cur = UnitPower("player", secondary)

		local maxPower = UnitPowerMax("player", secondary)

		if maxPower > 0 and TekagiUIDB.SecondaryPower.enabled then
			secContainer:Show()

			UpdateSegments(cur, maxPower)
		else
			secContainer:Hide()
		end
	else
		secContainer:Hide()
	end
end

------------------------------------------------------------
-- EVENTS
------------------------------------------------------------

local eventFrame = CreateFrame("Frame")

eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")

eventFrame:RegisterUnitEvent("UNIT_POWER_UPDATE", "player")

eventFrame:RegisterUnitEvent("UNIT_MAXPOWER", "player")

eventFrame:SetScript("OnEvent", function(_, event)
	if event == "PLAYER_ENTERING_WORLD" then
		TekagiUIDB = TekagiUIDB or {}

		TekagiUIDB.PowerBar = TekagiUIDB.PowerBar or {

			enabled = true,

			height = 10,
		}

		TekagiUIDB.SecondaryPower = TekagiUIDB.SecondaryPower or {

			enabled = true,

			height = 10,
		}

		bar:SetHeight(TekagiUIDB.PowerBar.height)

		bar:SetShown(TekagiUIDB.PowerBar.enabled)

		secContainer:SetHeight(TekagiUIDB.SecondaryPower.height)

		secContainer:SetShown(TekagiUIDB.SecondaryPower.enabled)

		C_Timer.After(1, function()
			AnchorBars()

			UpdatePowerBars()
		end)
	else
		UpdatePowerBars()
	end
end)

if _G["EssentialCooldownViewer"] then
	_G["EssentialCooldownViewer"]:HookScript("OnSizeChanged", function()
		AnchorBars()

		UpdatePowerBars()
	end)
end

------------------------------------------------------------
-- SETTINGS
------------------------------------------------------------

M.settings = {

	name = "Power Bar",

	settings = {

		enabled = {

			label = "Enable Power Bar",

			type = "toggle",

			default = true,

			callback = function(v)
				TekagiUIDB.PowerBar.enabled = v

				bar:SetShown(v)

				AnchorBars()

				UpdatePowerBars()
			end,
		},

		height = {

			label = "Bar Height",

			type = "slider",

			min = 5,

			max = 50,

			step = 1,

			default = 10,

			callback = function(v)
				TekagiUIDB.PowerBar.height = v

				bar:SetHeight(v)

				AnchorBars()

				UpdatePowerBars()
			end,
		},
	},
}

S.settings = {

	name = "Secondary Power",

	settings = {

		enabled = {

			label = "Enable Secondary Bar",

			type = "toggle",

			default = true,

			callback = function(v)
				TekagiUIDB.SecondaryPower.enabled = v

				secContainer:SetShown(v)

				UpdatePowerBars()
			end,
		},

		height = {

			label = "Secondary Height",

			type = "slider",

			min = 5,

			max = 50,

			step = 1,

			default = 10,

			callback = function(v)
				TekagiUIDB.SecondaryPower.height = v

				secContainer:SetHeight(v)

				AnchorBars()

				UpdatePowerBars()
			end,
		},
	},
}
