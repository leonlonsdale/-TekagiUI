function GetPlayerColor(unit)
    if not UnitIsPlayer(unit) then return end
    local _, class = UnitClass(unit)
    local c = RAID_CLASS_COLORS[class]
    if c then
        return CreateColor(c.r, c.g, c.b)
    end
end

function GetReactionColor(unit)
    if UnitIsPlayer(unit) then return end
    local reaction = UnitReaction(unit, "player")
    if reaction then
        if reaction >= 5 then
            return CreateColor(0, 1, 0) -- Friendly (Green)
        elseif reaction == 4 then
            return CreateColor(1, 1, 0) -- Neutral (Yellow)
        else
            return CreateColor(1, 0, 0) -- Hostile (Red)
        end
    end
end