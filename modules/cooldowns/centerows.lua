TekagiUI = TekagiUI or {}
TekagiUI.Modules = TekagiUI.Modules or {}
TekagiUI.Modules.CooldownCentering = {}

local M = TekagiUI.Modules.CooldownCentering

------------------------------------------------------------
-- Defaults
------------------------------------------------------------

M.defaults = {
    centerCooldowns = true,
    centerBuffs = false,
}

------------------------------------------------------------
-- Settings
------------------------------------------------------------

M.settings = {
    name = "Cooldown Manager",
    settings = {
        centerCooldowns = {
            label = "Center Cooldowns",
            callback = function(value)
                if not TekagiUIDB then return end

                TekagiUIDB.CooldownCentering = TekagiUIDB.CooldownCentering or {}
                TekagiUIDB.CooldownCentering.centerCooldowns = value

                if value then
                    M.ApplyAll()
                end
            end
        },

        centerBuffs = {
            label = "Center Buffs",
            callback = function(value)
                if not TekagiUIDB then return end

                TekagiUIDB.CooldownCentering = TekagiUIDB.CooldownCentering or {}
                TekagiUIDB.CooldownCentering.centerBuffs = value

                if value then
                    M.ApplyAll()
                end
            end
        },
    }
}

------------------------------------------------------------
-- Helpers
------------------------------------------------------------

local function IsEnabled(key)
    return TekagiUIDB
        and TekagiUIDB.CooldownCentering
        and TekagiUIDB.CooldownCentering[key]
end

------------------------------------------------------------
-- Grid viewers
------------------------------------------------------------

local GRID_VIEWERS = {
    "EssentialCooldownViewer",
    "UtilityCooldownViewer",
}

------------------------------------------------------------
-- Buff centering
------------------------------------------------------------

local function CenterBuffIcons(viewer)
    if not viewer then return end

    local icons = {}

    for _, child in ipairs({ viewer:GetChildren() }) do
        if child and child:IsShown() and child.Icon then
            icons[#icons + 1] = child
        end
    end

    if #icons == 0 then return end

    table.sort(icons, function(a, b)
        return (a.layoutIndex or 0) < (b.layoutIndex or 0)
    end)

    local iconW = icons[1]:GetWidth()
    if not iconW or iconW == 0 then return end

    local spacing = viewer.childXPadding or 4

    local count = #icons
    local totalWidth = (count * iconW) + ((count - 1) * spacing)

    local startX = -(totalWidth / 2) + (iconW / 2)

    for i = 1, count do
        local icon = icons[i]
        if icon then
            local x = startX + (i - 1) * (iconW + spacing)

            icon:ClearAllPoints()
            icon:SetPoint("TOP", viewer, "TOP", x, 0)
        end
    end
end

------------------------------------------------------------
-- Cooldown centering
------------------------------------------------------------

local function CenterViewer(viewer)
    if not viewer then return end

    local icons = {}

    for _, child in ipairs({ viewer:GetChildren() }) do
        if child and child:IsShown() and child.Icon then
            icons[#icons + 1] = child
        end
    end

    if #icons == 0 then return end

    table.sort(icons, function(a, b)
        return (a.layoutIndex or 0) < (b.layoutIndex or 0)
    end)

    local limit = viewer.iconLimit or 8

    local iconW = icons[1]:GetWidth()
    if not iconW or iconW == 0 then return end

    local spacing = viewer.childXPadding or 4

    local viewerWidth = viewer:GetWidth()
    local centerX = viewerWidth / 2

    local rowIndex = 0

    for i = 1, #icons, limit do
        local start = i
        local finish = math.min(i + limit - 1, #icons)

        local count = finish - start + 1

        local rowWidth = count * iconW + (count - 1) * spacing
        local startX = centerX - (rowWidth / 2)

        for j = start, finish do
            local icon = icons[j]
            if icon then
                local col = j - start
                local x = startX + col * (iconW + spacing)

                icon:ClearAllPoints()
                icon:SetPoint(
                    "TOPLEFT",
                    viewer,
                    "TOPLEFT",
                    x,
                    -rowIndex * (iconW + spacing)
                )
            end
        end

        rowIndex = rowIndex + 1
    end
end

------------------------------------------------------------
-- Apply
------------------------------------------------------------

local function ApplyAll()
    if not TekagiUIDB or not TekagiUIDB.CooldownCentering then return end

    local db = TekagiUIDB.CooldownCentering

    if db.centerCooldowns then
        for _, name in ipairs(GRID_VIEWERS) do
            CenterViewer(_G[name])
        end
    end

    if db.centerBuffs then
        CenterBuffIcons(_G["BuffIconCooldownViewer"])
    end
end

------------------------------------------------------------
-- Cooldown request (FIXED gating)
------------------------------------------------------------

local pending = false

local function RequestApply()
    if not IsEnabled("centerCooldowns") then return end

    if pending then return end
    pending = true

    C_Timer.After(0, function()
        pending = false
        ApplyAll()
    end)
end

------------------------------------------------------------
-- Buff request (separate gating)
------------------------------------------------------------

local function RequestBuffApply()
    if not IsEnabled("centerBuffs") then return end

    local viewer = _G["BuffIconCooldownViewer"]
    if not viewer then return end

    C_Timer.After(0, function()
        CenterBuffIcons(viewer)
    end)
end

------------------------------------------------------------
-- Hooks
------------------------------------------------------------

local frame = CreateFrame("Frame")
local buffFrame = CreateFrame("Frame")

frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:RegisterEvent("UI_SCALE_CHANGED")

buffFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
buffFrame:RegisterEvent("UNIT_AURA")

local function HookViewer(name)
    local viewer = _G[name]
    if not viewer or viewer._tekagiHooked then return end

    viewer._tekagiHooked = true

    if viewer.Layout then
        hooksecurefunc(viewer, "Layout", RequestApply)
    end

    viewer:HookScript("OnShow", RequestApply)
end

frame:SetScript("OnEvent", function()
    for _, name in ipairs(GRID_VIEWERS) do
        HookViewer(name)
    end

    local buffViewer = _G["BuffIconCooldownViewer"]
    if buffViewer and not buffViewer._tekagiHooked then
        buffViewer._tekagiHooked = true

        buffViewer:HookScript("OnShow", RequestApply)

        if buffViewer.Layout then
            hooksecurefunc(buffViewer, "Layout", RequestApply)
        end
    end

    C_Timer.After(0, ApplyAll)
end)

buffFrame:SetScript("OnEvent", function(_, event, unit)
    if not IsEnabled("centerBuffs") then return end

    if event == "UNIT_AURA" and unit and unit ~= "player" then
        return
    end

    RequestBuffApply()
end)

------------------------------------------------------------
-- Public API
------------------------------------------------------------

M.ApplyAll = ApplyAll