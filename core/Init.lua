TekagiUI = TekagiUI or {}
TekagiUI.Modules = TekagiUI.Modules or {}

local function CopyDefaults(src, dest)
	if not src then
		return
	end
	if not dest then
		dest = {}
	end
	for k, v in pairs(src) do
		if type(v) == "table" then
			dest[k] = CopyDefaults(v, dest[k])
		elseif dest[k] == nil then
			dest[k] = v
		end
	end
	return dest
end

local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:SetScript("OnEvent", function(self, event, addonName)
	if addonName == "TekagiUI" then
		if not TekagiUIDB then
			TekagiUIDB = {}
		end

		for moduleName, module in pairs(TekagiUI.Modules) do
			if module.defaults then
				TekagiUIDB[moduleName] = CopyDefaults(module.defaults, TekagiUIDB[moduleName])
			end
		end

		print("|cffffff00TekagiUI|r Loaded")

		self:UnregisterEvent("ADDON_LOADED")
	end
end)
