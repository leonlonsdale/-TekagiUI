TekagiUI = TekagiUI or {}
TekagiUI.Modules = TekagiUI.Modules or {}
TekagiUI.Modules.PowerBar = {}

local M = TekagiUI.Modules.PowerBar

-- Ensure DB has defaults
local function InitDB()
    TekagiUIDB = TekagiUIDB or {}
    if not TekagiUIDB.PowerBar then 
        TekagiUIDB.PowerBar = { enabled = true, height = "10" } 
    end
end

local function CreatePowerBar()
    local f = CreateFrame("StatusBar", "TekagiPowerBar", UIParent)
    f:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
    
    f.bg = f:CreateTexture(nil, "BACKGROUND")
    f.bg:SetAllPoints(true)
    f.bg:SetColorTexture(0, 0, 0, 0.5)
    
    f.text = f:CreateFontString(nil, "OVERLAY")
    f.text:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
    f.text:SetPoint("CENTER", f, "CENTER", 0, 0)
    
    return f
end

local bar = CreatePowerBar()

-- Anchor logic
local function AnchorPowerBar()
    if _G["EssentialCooldownViewer"] and _G["EssentialCooldownViewer"]:IsVisible() then
        bar:ClearAllPoints()
        bar:SetPoint("BOTTOM", _G["EssentialCooldownViewer"], "TOP", 0, 5)
        bar:SetWidth(_G["EssentialCooldownViewer"]:GetWidth())
    end
end

-- Apply settings state
local function ApplySettings()
    InitDB()
    local db = TekagiUIDB.PowerBar
    
    if db.enabled then bar:Show() else bar:Hide() end
    bar:SetHeight(tonumber(db.height) or 10)
    
    C_Timer.After(1, AnchorPowerBar)
end

-- Events
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:RegisterEvent("UNIT_POWER_UPDATE")
eventFrame:RegisterEvent("UNIT_MAXPOWER")

eventFrame:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_ENTERING_WORLD" then ApplySettings() end
    
    local current, max = UnitPower("player"), UnitPowerMax("player")
    bar:SetMinMaxValues(0, max)
    bar:SetValue(current)
    local type = UnitPowerType("player")
    local color = PowerBarColor[type] or {r=1, g=1, b=1}
    bar:SetStatusBarColor(color.r, color.g, color.b)
    bar.text:SetText(current .. " / " .. max)
end)

if _G["EssentialCooldownViewer"] then
    _G["EssentialCooldownViewer"]:HookScript("OnSizeChanged", AnchorPowerBar)
end

-- Settings Table
M.settings = {
    name = "Power Bar",
    settings = {
        enabled = {
            label = "Enable Power Bar",
            type = "toggle",
            default = true,
            callback = function(value)
                if value then bar:Show() else bar:Hide() end
            end
        },
height = {
    label = "Bar Height",
    type = "slider",
    min = 5,
    max = 50,
    step = 1,
    default = 10,
    callback = function(value)
        bar:SetHeight(value)
        -- ... rest of your re-anchoring logic
    end
}
    }
}