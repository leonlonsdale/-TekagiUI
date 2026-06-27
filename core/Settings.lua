local frame = CreateFrame("Frame")
frame:RegisterEvent("PLAYER_LOGIN")

------------------------------------------------------------
-- Global settings change notification
------------------------------------------------------------

TekagiUI = TekagiUI or {}
TekagiUI.Modules = TekagiUI.Modules or {}

TekagiUI.SettingsChanged = function(moduleName, key, value)
	local module = TekagiUI.Modules and TekagiUI.Modules[moduleName]

	if module and module.Refresh then
		C_Timer.After(0, function()
			module:Refresh()
		end)
	end
end

------------------------------------------------------------
-- Build Settings UI
------------------------------------------------------------

local function BuildSettingsUI()
	local mainCat = Settings.RegisterVerticalLayoutCategory("TekagiUI")

	Settings.RegisterAddOnCategory(mainCat)

	if not TekagiUI or not TekagiUI.Modules then
		return
	end

	for moduleName, module in pairs(TekagiUI.Modules) do
		if module.settings then
			local subCatName = module.settings.name or moduleName

			local subCat = Settings.RegisterVerticalLayoutSubcategory(mainCat, subCatName)

			if module.settings.settings then
				for key, setting in pairs(module.settings.settings) do
					local function GetValue()
						if TekagiUIDB and TekagiUIDB[moduleName] and TekagiUIDB[moduleName][key] ~= nil then
							return TekagiUIDB[moduleName][key]
						end

						return setting.default or false
					end

					local function SetValue(value)
						TekagiUIDB = TekagiUIDB or {}

						TekagiUIDB[moduleName] = TekagiUIDB[moduleName] or {}

						TekagiUIDB[moduleName][key] = value

						if setting.callback then
							setting.callback(value)
						end

						if TekagiUI.SettingsChanged then
							TekagiUI.SettingsChanged(moduleName, key, value)
						end
					end

					local settingID = "TekagiUI_" .. moduleName .. "_" .. key

					local varType = Settings.VarType.Boolean

					if setting.type == "slider" then
						varType = Settings.VarType.Number
					end

					local settingObj = Settings.RegisterProxySetting(
						subCat,
						settingID,
						varType,
						setting.label,
						setting.default or false,
						GetValue,
						SetValue
					)

					if setting.type == "slider" then
						Settings.CreateSlider(subCat, settingObj, {
							minValue = setting.min,
							maxValue = setting.max,
							steps = (setting.max - setting.min) / (setting.step or 1),
						})
					else
						Settings.CreateCheckbox(subCat, settingObj, setting.label)
					end
				end
			end
		end
	end
end

------------------------------------------------------------
-- Initialise
------------------------------------------------------------

frame:SetScript("OnEvent", function(self, event)
	if event == "PLAYER_LOGIN" then
		BuildSettingsUI()

		print("|cffffff00TekagiUI|r Loaded")
	end
end)
