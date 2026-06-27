local frame = CreateFrame("Frame")
frame:RegisterEvent("PLAYER_LOGIN")

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
                        return TekagiUIDB
                            and TekagiUIDB[moduleName]
                            and TekagiUIDB[moduleName][key]
                    end

                    local function SetValue(value)
                        TekagiUIDB = TekagiUIDB or {}
                        TekagiUIDB[moduleName] = TekagiUIDB[moduleName] or {}
                        TekagiUIDB[moduleName][key] = value

                        if setting.callback then
                            setting.callback(value)
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

frame:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_LOGIN" then
        BuildSettingsUI()
        print("|cffffff00TekagiUI|r Loaded")
    end
end)