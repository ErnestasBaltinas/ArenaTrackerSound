local ADDON_NAME = ...

local SOUND_PATH = "Interface\\AddOns\\" .. ADDON_NAME .. "\\sounds\\"
local lastTrinketStartTimes = {}

local function isInPvPInstance()
    local _, instanceType = IsInInstance()
    return instanceType == "arena"
end

local function getUnitRole(unit)
    -- Check group-assigned role first
    local role = UnitGroupRolesAssigned(unit)
    if role ~= "NONE" then
        return role
    end

    -- Fallback to specialization-based role
    local specID = GetSpecialization(nil, nil, nil, unit)
    if specID then
        local _, _, _, role = GetSpecializationInfoByID(specID)
        return role
    end

    -- Fallback to class-based default role
    local _, class = UnitClass(unit)
    return GetDefaultRoleForClass(class)
end

local function getSoundPath(unit)
	
	local soundFileName = 'trinket.ogg'
	local role = getUnitRole(unit) -- "TANK", "HEALER", "DAMAGER", or "NONE"
	if role == "HEALER" then
		-- do nothing
	elseif role == "DAMAGER" then
		soundFileName = 'trinket2.ogg'
	else
		-- do nothing
	end

	return SOUND_PATH .. soundFileName;
end

local function OnArenaTrinketUpdate(unit)
    local spellId, startMs, durationMs = C_PvP.GetArenaCrowdControlInfo(unit)
    local start = startMs and startMs / 1000 or 0
    local duration = durationMs and durationMs / 1000 or 0

	if start == 0 then return end

    --print('now - start: ', (now - start) < 10)

    if duration > 0  and (not lastTrinketStartTimes[unit] or lastTrinketStartTimes[unit] ~= start) then
		-- Trinket just used
        --print(unit .. "(".. spellId ..")" .. " used their PvP trinket! " )
		PlaySoundFile(getSoundPath(unit), "Master")

        -- Mark as announced
        lastTrinketStartTimes[unit] = start
    end
end

local arenaTrinketTracker = CreateFrame("Frame", "ArenaTrinketSoundFrame")

arenaTrinketTracker:SetScript("OnEvent", function(_, event, unit)
	if unit and strmatch(unit, "^arena%d$") and ArenaUtil.UnitExists(unit) then
		OnArenaTrinketUpdate(unit)
	end
end)

-- Listen for zone change to enable/disable tracking
local ZoneWatcher = CreateFrame("Frame")
ZoneWatcher:RegisterEvent("PLAYER_ENTERING_WORLD")
ZoneWatcher:RegisterEvent("PVP_MATCH_ACTIVE")
ZoneWatcher:RegisterEvent("PVP_MATCH_COMPLETE")
ZoneWatcher:RegisterEvent("ARENA_PREP_OPPONENT_SPECIALIZATIONS")

ZoneWatcher:SetScript("OnEvent", function(_, event, ...)

	if event == "ARENA_PREP_OPPONENT_SPECIALIZATIONS" then
        wipe(lastTrinketStartTimes)
        return
    end
	
    if C_PvP.IsMatchConsideredArena() then
        -- Entered arena → register arena events
        arenaTrinketTracker:RegisterEvent("ARENA_CROWD_CONTROL_SPELL_UPDATE")
        arenaTrinketTracker:RegisterEvent("ARENA_COOLDOWNS_UPDATE")
    else
        -- Left arena → unregister events
        arenaTrinketTracker:UnregisterEvent("ARENA_CROWD_CONTROL_SPELL_UPDATE")
        arenaTrinketTracker:UnregisterEvent("ARENA_COOLDOWNS_UPDATE")
        -- Reset the table so next arena is fresh
        wipe(lastTrinketStartTimes)
    end
end)