local frame = CreateFrame("Frame")
frame:RegisterEvent("PLAYER_LOGIN")

local function BuildSettingsUI()
    -- Create the top-level "TekagiUI" parent category
    local mainCat = Settings.RegisterVerticalLayoutCategory("TekagiUI")
    Settings.RegisterAddOnCategory(mainCat)

    if not TekagiUI or not TekagiUI.Modules then return end

    for moduleName, module in pairs(TekagiUI.Modules) do
        if module.settings then

            local subCatName = module.settings.name or moduleName
            local subCat = Settings.RegisterVerticalLayoutSubcategory(mainCat, subCatName)

            if module.settings.settings then
                for key, setting in pairs(module.settings.settings) do
                    
                    local function GetValue()
                        return TekagiUIDB and TekagiUIDB[moduleName] and TekagiUIDB[moduleName][key]
                    end

                    local function SetValue(value)
                        if not TekagiUIDB then TekagiUIDB = {} end
                        if not TekagiUIDB[moduleName] then TekagiUIDB[moduleName] = {} end
                        TekagiUIDB[moduleName][key] = value

                        if setting.callback then
                            setting.callback(value)
                        end
                    end

                    local settingID = "TekagiUI_" .. moduleName .. "_" .. key
                    local settingObj = Settings.RegisterProxySetting(
                        subCat,
                        settingID,
                        Settings.VarType.Boolean,
                        setting.label,
                        false,
                        GetValue,
                        SetValue
                    )

                    Settings.CreateCheckbox(subCat, settingObj, setting.label)
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