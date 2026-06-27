TekagiUI = TekagiUI or {}
TekagiUI.Modules = TekagiUI.Modules or {}
TekagiUI.Modules.General = {}

local M = TekagiUI.Modules.General

M.defaults = {
	autoScale = true,
}

local function GetScale()
	local _, height = GetPhysicalScreenSize()
	local scale = 768 / height
	return scale
end

local function ApplyScale(enabled)
	if enabled then
		UIParent:SetScale(GetScale())
	else
		UIParent:SetScale(1)
	end
end

M.settings = {
	name = "General",
	settings = {
		autoScale = {
			label = "Auto UI Scale",
			callback = ApplyScale,
		},
	},
}

local frame = CreateFrame("Frame")
frame:RegisterEvent("PLAYER_LOGIN")
frame:SetScript("OnEvent", function(self, event)
	if event == "PLAYER_LOGIN" then
		if TekagiUIDB and TekagiUIDB.General and TekagiUIDB.General.autoScale then
			UIParent:SetScale(GetScale())
		end
	end
end)
