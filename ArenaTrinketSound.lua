local ADDON_NAME, addon = ...
local DBUtils = addon.DBUtils
local SoundSystem = addon.SoundSystem


local lastTrinketStartTimes = {}


-- utils --

local function getArenaIndex(unit)
    return tonumber(string.match(unit, "^arena(%d+)$"))
end


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
    local index = getArenaIndex(unit)
    local specID, _ = GetArenaOpponentSpec(index)
    if specID then
        local _, _, _, role = GetSpecializationInfoByID(specID)
        return role
    end
    return "NONE"
end

local function getUnitSpecName(unit)
    local index = getArenaIndex(unit)
    local specId, _ = GetArenaOpponentSpec(index)
    local _, specName, _, _, _, _, _ = GetSpecializationInfoByID(specId)
    return specName -- Balance
end

local function getUnitClassName(unit)
    local _, _, classID = UnitClass(unit)
    local _, classFile, _ = GetClassInfo(classID)
    return classFile -- DRUID, DEAHTKNIGHT, etc.
end


local function getTypeAndUnitIdentity(unit)

    local selectedType = DBUtils.getOptionValue("selectedSoundType")
    local identity = nil

    if selectedType == SoundSystem.SOUND_TYPE.ROLES then
        identity = getUnitRole(unit)
    elseif selectedType == SoundSystem.SOUND_TYPE.SPECS then
        local spec = getUnitSpecName(unit)   -- e.g., "Restoration"
        local class = getUnitClassName(unit) -- e.g., "Druid"

        if spec and class then
            identity = spec .. "_" .. class  -- e.g., "Restoration_Druid"
        end
    elseif selectedType == SoundSystem.SOUND_TYPE.CLASSES then
        identity = getUnitClassName(unit)
    end

    -- Normalize once here
    if identity then
        identity = string.upper(identity)
    end

    return selectedType, identity
end


-- logic --
local function OnArenaTrinketUpdate(unit)
    local spellId, startMs, durationMs = C_PvP.GetArenaCrowdControlInfo(unit)
    local start = startMs and startMs / 1000 or 0
    local duration = durationMs and durationMs / 1000 or 0

	if start == 0 then return end

    if duration > 0  and (not lastTrinketStartTimes[unit] or lastTrinketStartTimes[unit] ~= start) then
		-- Trinket just used
        local selectedType, identity = getTypeAndUnitIdentity(unit)
        --print('Trinket used by ', unit, selectedType, identity)
		SoundSystem.playTrinketSound(selectedType, identity)

        -- Mark as announced
        lastTrinketStartTimes[unit] = start
    end
end


-- EVENTS --
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

ZoneWatcher:SetScript("OnEvent", function(_, event, a, b)
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

DBUtils.initSavedVars()