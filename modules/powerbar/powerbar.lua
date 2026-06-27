TekagiUI = TekagiUI or {}
TekagiUI.Modules = TekagiUI.Modules or {}

local function AddBorder(f)
    local border = CreateFrame("Frame", nil, f, "BackdropTemplate")
    border:SetPoint("TOPLEFT", -1, 1); border:SetPoint("BOTTOMRIGHT", 1, -1)
    border:SetBackdrop({edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1})
    border:SetBackdropBorderColor(0, 0, 0, 1)
end

-- --- MAIN POWER BAR ---
TekagiUI.Modules.PowerBar = {}
local M = TekagiUI.Modules.PowerBar
local bar = CreateFrame("StatusBar", "TekagiPowerBar", UIParent)
bar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
bar.bg = bar:CreateTexture(nil, "BACKGROUND"); bar.bg:SetAllPoints(true); bar.bg:SetColorTexture(0, 0, 0, 0.5)
bar.text = bar:CreateFontString(nil, "OVERLAY"); bar.text:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE"); bar.text:SetPoint("CENTER")
AddBorder(bar)

-- --- SECONDARY POWER BAR (SEGMENTED) ---
TekagiUI.Modules.SecondaryPower = {}
local S = TekagiUI.Modules.SecondaryPower
local secContainer = CreateFrame("Frame", "TekagiSecondaryContainer", UIParent)
local segments = {}

local function UpdateSegments(current, max)
    local containerWidth = bar:GetWidth()
    local spacing = 2
    local segmentWidth = (containerWidth - (max - 1) * spacing) / max
    for i = 1, max do
        if not segments[i] then
            segments[i] = CreateFrame("Frame", nil, secContainer, "BackdropTemplate")
            segments[i]:SetBackdrop({edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1})
            segments[i]:SetBackdropBorderColor(0, 0, 0, 1)
            segments[i].tex = segments[i]:CreateTexture(nil, "ARTWORK")
            segments[i].tex:SetPoint("TOPLEFT", 1, -1); segments[i].tex:SetPoint("BOTTOMRIGHT", -1, 1)
            segments[i].tex:SetColorTexture(0.5, 0, 0.5)
        end
        segments[i]:SetSize(segmentWidth, secContainer:GetHeight())
        segments[i]:ClearAllPoints()
        if i == 1 then segments[i]:SetPoint("LEFT", secContainer, "LEFT")
        else segments[i]:SetPoint("LEFT", segments[i-1], "RIGHT", spacing, 0) end
        segments[i].tex:SetShown(i <= current)
        segments[i]:Show()
    end
    for i = max + 1, #segments do segments[i]:Hide() end
end

-- --- LOGIC ---
local function AnchorBars()
    if _G["EssentialCooldownViewer"] and _G["EssentialCooldownViewer"]:IsVisible() then
        bar:ClearAllPoints()
        bar:SetPoint("BOTTOM", _G["EssentialCooldownViewer"], "TOP", 0, 5)
        bar:SetWidth(_G["EssentialCooldownViewer"]:GetWidth())
    end
    secContainer:ClearAllPoints()
    secContainer:SetPoint("BOTTOM", bar, "TOP", 0, 5)
    secContainer:SetSize(bar:GetWidth(), tonumber(TekagiUIDB.SecondaryPower.height) or 10)
end

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:RegisterUnitEvent("UNIT_POWER_UPDATE", "player")
eventFrame:RegisterUnitEvent("UNIT_MAXPOWER", "player")

eventFrame:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_ENTERING_WORLD" then
        TekagiUIDB = TekagiUIDB or {}; TekagiUIDB.PowerBar = TekagiUIDB.PowerBar or {enabled=true, height=10}
        TekagiUIDB.SecondaryPower = TekagiUIDB.SecondaryPower or {enabled=true, height=10}
        bar:SetHeight(TekagiUIDB.PowerBar.height); secContainer:SetHeight(TekagiUIDB.SecondaryPower.height)
        C_Timer.After(1, AnchorBars)
    end
    local cur, max = UnitPower("player"), UnitPowerMax("player")
    bar:SetMinMaxValues(0, max); bar:SetValue(cur); bar.text:SetText(cur .. " / " .. max)
    local pType = UnitPowerType("player")
    local color = PowerBarColor[pType] or {r=1, g=1, b=1}
    bar:SetStatusBarColor(color.r, color.g, color.b)
    
    local _, class = UnitClass("player")
    local isSecondary = (class == "PALADIN" or class == "WARLOCK" or class == "MONK" or class == "PRIEST" or class == "EVOKER" or class == "DRUID")
    local sType = Enum.PowerType.HolyPower
    if class == "WARLOCK" then sType = Enum.PowerType.SoulShards elseif class == "MONK" then sType = Enum.PowerType.Chi end
    local sCur, sMax = UnitPower("player", sType), UnitPowerMax("player", sType)
    
    if isSecondary and sMax > 0 and TekagiUIDB.SecondaryPower.enabled then
        secContainer:Show()
        UpdateSegments(sCur, sMax)
    else
        secContainer:Hide()
    end
end)

if _G["EssentialCooldownViewer"] then _G["EssentialCooldownViewer"]:HookScript("OnSizeChanged", AnchorBars) end

M.settings = { name = "Power Bar", settings = {
    enabled = { label = "Enable Power Bar", type = "toggle", default = true, callback = function(v) bar:SetShown(v) end },
    height = { label = "Bar Height", type = "slider", min = 5, max = 50, step = 1, default = 10, callback = function(v) bar:SetHeight(v); AnchorBars() end }
}}
S.settings = { name = "Secondary Power", settings = {
    enabled = { label = "Enable Secondary Bar", type = "toggle", default = true, callback = function(v) secContainer:SetShown(v) end },
    height = { label = "Secondary Height", type = "slider", min = 5, max = 50, step = 1, default = 10, callback = function(v) secContainer:SetHeight(v); AnchorBars() end }
}}