TekagiUI = TekagiUI or {}
TekagiUI.Modules = TekagiUI.Modules or {}
TekagiUI.Modules.CooldownCentering = {}

local M = TekagiUI.Modules.CooldownCentering

M.defaults = {
    centerCooldowns = true,
    centerBuffs = false,
}

M.settings = {
    name = "Cooldown Manager",
    settings = {
        centerCooldowns = {
            label = "Center Cooldowns",
            callback = function(value)
                if not TekagiUIDB then return end
                TekagiUIDB.CooldownCentering = TekagiUIDB.CooldownCentering or {}
                TekagiUIDB.CooldownCentering.centerCooldowns = value
                if value then M.ApplyAll() end
            end
        },
        centerBuffs = {
            label = "Center Buffs",
            callback = function(value)
                if not TekagiUIDB then return end
                TekagiUIDB.CooldownCentering = TekagiUIDB.CooldownCentering or {}
                TekagiUIDB.CooldownCentering.centerBuffs = value
                if value then M.ApplyAll() end
            end
        },
    }
}

local function IsEnabled(key)
    return TekagiUIDB
        and TekagiUIDB.CooldownCentering
        and TekagiUIDB.CooldownCentering[key]
end

local GRID_VIEWERS = {
    "EssentialCooldownViewer",
    "UtilityCooldownViewer",
}

local isCentering = false

------------------------------------------------------------
-- Buff centering
------------------------------------------------------------
local function CenterBuffIcons(viewer)
    if not viewer or isCentering then return end

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
    local iconH = icons[1]:GetHeight()
    if not iconW or iconW == 0 then return end

    local isVertical = (viewer.isHorizontal == false) or (viewer.isVertical == true)

    local spacing = viewer.childXPadding or viewer.childYPadding or 4
    local count = #icons

    isCentering = true

    if isVertical then
        local totalHeight = (count * iconH) + ((count - 1) * spacing)
        local startY = (totalHeight / 2) - (iconH / 2)

        for i = 1, count do
            local icon = icons[i]
            if icon then
                local y = startY - (i - 1) * (iconH + spacing)
                icon:ClearAllPoints()
                icon:SetPoint("LEFT", viewer, "LEFT", 0, y)
            end
        end
    else
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

    isCentering = false
end

------------------------------------------------------------
-- Cooldown centering
------------------------------------------------------------

local function CenterViewer(viewer)
    if not viewer or isCentering then return end

    local icons = {}
    for _, child in ipairs({ viewer:GetChildren() }) do
        if child and child:IsShown() and child.Icon then
            icons[#icons + 1] = child
        end
    end

    if #icons == 0 then 
        viewer.realGridWidth = 0
        return 
    end

    table.sort(icons, function(a, b)
        return (a.layoutIndex or 0) < (b.layoutIndex or 0)
    end)

    local limit = viewer.iconLimit or 8
    local iconW = icons[1]:GetWidth()
    if not iconW or iconW == 0 then return end

    local spacing = viewer.childXPadding or 4
    local rowIndex = 0
    local maxCalculatedWidth = 0

    isCentering = true

    for i = 1, #icons, limit do
        local start = i
        local finish = math.min(i + limit - 1, #icons)
        local count = finish - start + 1

        local rowWidth = (count * iconW) + ((count - 1) * spacing)
        if rowWidth > maxCalculatedWidth then
            maxCalculatedWidth = rowWidth
        end
        
        local startX = -(rowWidth / 2) + (iconW / 2)
        local rowYOffset = -rowIndex * (iconW + spacing)

        local firstInRow = icons[start]
        if firstInRow then
            firstInRow:ClearAllPoints()
            firstInRow:SetPoint("TOP", viewer, "TOP", startX, rowYOffset)
        end

        for j = start + 1, finish do
            local icon = icons[j]
            if icon then
                icon:ClearAllPoints()
                icon:SetPoint("LEFT", icons[j - 1], "RIGHT", spacing, 0)
            end
        end

        rowIndex = rowIndex + 1
    end

    isCentering = false

    viewer.realGridWidth = maxCalculatedWidth

    if viewer:GetName() == "EssentialCooldownViewer" and TekagiUI.Modules.PersonalResource and TekagiUI.Modules.PersonalResource.UpdateLayout then
        TekagiUI.Modules.PersonalResource.UpdateLayout()
    end
end

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
        hooksecurefunc(viewer, "Layout", ApplyAll)
    end
    viewer:HookScript("OnShow", ApplyAll)
end

frame:SetScript("OnEvent", function()
    for _, name in ipairs(GRID_VIEWERS) do
        HookViewer(name)
    end

    local buffViewer = _G["BuffIconCooldownViewer"]
    if buffViewer and not buffViewer._tekagiHooked then
        buffViewer._tekagiHooked = true
        buffViewer:HookScript("OnShow", ApplyAll)
        
        if buffViewer.Layout then
            hooksecurefunc(buffViewer, "Layout", ApplyAll)
        end
    end

    ApplyAll()
end)

buffFrame:SetScript("OnEvent", function(_, event, unit)
    if not IsEnabled("centerBuffs") then return end
    if event == "UNIT_AURA" and unit and unit ~= "player" then return end
    
    ApplyAll()
end)

M.ApplyAll = ApplyAll