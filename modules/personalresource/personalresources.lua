TekagiUI = TekagiUI or {}
TekagiUI.Modules = TekagiUI.Modules or {}
TekagiUI.Modules.PersonalResource = {}

local M = TekagiUI.Modules.PersonalResource

------------------------------------------------------------
-- Defaults
------------------------------------------------------------

M.defaults = {
    anchorToEssentials = false,
    matchWidthToEssentials = false,
}

------------------------------------------------------------
-- Settings
------------------------------------------------------------

M.settings = {
    name = "Personal Resource Display",
    settings = {
        anchorToEssentials = {
            label = "Anchor to Essential Cooldowns",
            callback = function(value)
                if not TekagiUIDB then return end
                TekagiUIDB.PersonalResource = TekagiUIDB.PersonalResource or {}
                TekagiUIDB.PersonalResource.anchorToEssentials = value
                M.UpdateLayout()
            end
        },
        matchWidthToEssentials = {
            label = "Match Width to Essential Cooldowns",
            callback = function(value)
                if not TekagiUIDB then return end
                TekagiUIDB.PersonalResource = TekagiUIDB.PersonalResource or {}
                TekagiUIDB.PersonalResource.matchWidthToEssentials = value
                M.UpdateLayout()
            end
        },
    }
}

------------------------------------------------------------
-- Helper
------------------------------------------------------------

local function IsEnabled(key)
    return TekagiUIDB
        and TekagiUIDB.PersonalResource
        and TekagiUIDB.PersonalResource[key]
end

------------------------------------------------------------
-- Layout Logic
------------------------------------------------------------

local function UpdateLayout()
    local prd = _G["PersonalResourceDisplayFrame"]
    local cooldowns = _G["EssentialCooldownViewer"]

    if not prd or not cooldowns or InCombatLockdown() then return end

    -- Skip completely if user is rearranging in Edit Mode
    if prd.isInEditMode or (EditModeManagerFrame and EditModeManagerFrame:IsEditModeActive()) then 
        return 
    end

    local shouldAnchor = IsEnabled("anchorToEssentials")
    local shouldMatchWidth = IsEnabled("matchWidthToEssentials")

    if not shouldAnchor and not shouldMatchWidth then return end

    local icons = {}
    for _, child in ipairs({ cooldowns:GetChildren() }) do
        if child and child:IsShown() and child.Icon then
            table.insert(icons, child)
        end
    end

    if #icons > 0 then
        table.sort(icons, function(a, b)
            return (a.layoutIndex or 0) < (b.layoutIndex or 0)
        end)

        local firstIcon = icons[1]
        local lastIcon = icons[#icons]

        if firstIcon and lastIcon then
            
            --------------------------------------------------------
            -- Option 1: Anchor Positioning
            --------------------------------------------------------
            if shouldAnchor then
                prd:ClearAllPoints()
                if shouldMatchWidth then
                    -- Pin edges to the outer boundaries of the row
                    prd:SetPoint("LEFT", firstIcon, "LEFT", 0, 0)
                    prd:SetPoint("RIGHT", lastIcon, "RIGHT", 0, 0)
                    prd:SetPoint("BOTTOM", firstIcon, "TOP", 0, 6)
                else
                    -- Center it above the middle of the whole Cooldown frame container
                    prd:SetPoint("BOTTOM", cooldowns, "TOP", 0, 6)
                end
            end

            --------------------------------------------------------
            -- Option 2: Sizing / Width Matching
            --------------------------------------------------------
            if shouldMatchWidth then
                -- Lock the health container frame to the icon row boundaries
                if prd.HealthBarsContainer then
                    prd.HealthBarsContainer:ClearAllPoints()
                    prd.HealthBarsContainer:SetPoint("LEFT", firstIcon, "LEFT", 0, 0)
                    prd.HealthBarsContainer:SetPoint("RIGHT", lastIcon, "RIGHT", 0, 0)
                    prd.HealthBarsContainer:SetPoint("TOP", prd, "TOP", 0, 0)
                    
                    if prd.HealthBarsContainer.healthBar then
                        prd.HealthBarsContainer.healthBar:ClearAllPoints()
                        prd.HealthBarsContainer.healthBar:SetAllPoints(prd.HealthBarsContainer)
                    end
                end
                
                -- Lock the power bar frame to the icon row boundaries
                if prd.PowerBar then
                    prd.PowerBar:ClearAllPoints()
                    prd.PowerBar:SetPoint("LEFT", firstIcon, "LEFT", 0, 0)
                    prd.PowerBar:SetPoint("RIGHT", lastIcon, "RIGHT", 0, 0)
                    prd.PowerBar:SetPoint("BOTTOM", prd, "BOTTOM", 0, 0)
                end
            else
                -- Reset sub-bars to follow Blizzard's native scaling width rules
                if prd.HealthBarsContainer then
                    prd.HealthBarsContainer:ClearAllPoints()
                    prd.HealthBarsContainer:SetPoint("TOPLEFT", prd, "TOPLEFT", 0, 0)
                    prd.HealthBarsContainer:SetPoint("BOTTOMRIGHT", prd, "BOTTOMRIGHT", 0, 0)
                    if prd.HealthBarsContainer.healthBar then
                        prd.HealthBarsContainer.healthBar:ClearAllPoints()
                        prd.HealthBarsContainer.healthBar:SetAllPoints(prd.HealthBarsContainer)
                    end
                end
                if prd.PowerBar then
                    prd.PowerBar:ClearAllPoints()
                    prd.PowerBar:SetPoint("BOTTOMLEFT", prd, "BOTTOMLEFT", 0, 0)
                    prd.PowerBar:SetPoint("BOTTOMRIGHT", prd, "BOTTOMRIGHT", 0, 0)
                end
            end

        end
    end
end

------------------------------------------------------------
-- Hook Setup
------------------------------------------------------------

local frame = CreateFrame("Frame")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")

frame:SetScript("OnEvent", function()
    local cooldowns = _G["EssentialCooldownViewer"]

    if cooldowns and not cooldowns._tekagiPRDHooked then
        cooldowns._tekagiPRDHooked = true
        
        cooldowns:HookScript("OnShow", function()
            UpdateLayout()
        end)
        
        if cooldowns.Layout then
            hooksecurefunc(cooldowns, "Layout", function()
                UpdateLayout()
            end)
        end
    end

    -- EDIT MODE FIX: Reapply layout rules when Edit Mode closes.
    if EditModeManagerFrame and not EditModeManagerFrame._tekagiPRDHooked then
        EditModeManagerFrame._tekagiPRDHooked = true
        EditModeManagerFrame:HookScript("OnHide", function()
            C_Timer.After(0, function()
                UpdateLayout()
            end)
        end)
    end

    UpdateLayout()
end)

M.UpdateLayout = UpdateLayout