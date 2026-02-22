local _, addon = ...
local DBUtils = addon.DBUtils
local SoundSystem = addon.SoundSystem

local trinketUsedAt = {}

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
    local specID, _ = GetArenaOpponentSpec(index)

    if not specID then
        return nil -- sometimes specID is nil, not sure why, seems like a bug
    end
    local _, specName, _, _, _, _, _ = GetSpecializationInfoByID(specID)
    return specName -- Balance
end

local function getUnitClassName(unit)
    local _, _, classID = UnitClass(unit)
    local _, classFile, _ = GetClassInfo(classID)
    return classFile -- DRUID, DEATHKNIGHT, etc.
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
            identity = spec .. "_" .. class -- e.g., "Restoration_Druid"
        else
            -- in some cases spec can be returned nil, as fallback lets return unitClassName
            identity = getUnitClassName(unit)
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

local function getUnitTrinketCD(unit)
    local role = getUnitRole(unit)
    local cdInSeconds = (role == "HEALER") and 90 or 120 --hard coded values due to blizzard api durationMs being secret
    return cdInSeconds
end

local function getArenaTrinketInfo(unit)
    local spellId, startMs, durationMs = C_PvP.GetArenaCrowdControlInfo(unit)
    if not issecretvalue(startMs) or issecrettable(durationMs) then
        -- No secret value means trinket is not on cooldown — nothing to do
        return nil
    end
    return {
        spellId = spellId,
        startTime = GetTime(),
        cdInSeconds = getUnitTrinketCD(unit),
    }
end

local function isUnitTrinketUsed(unit)
    if not trinketUsedAt[unit] then
        return false
    end
    local cdInSeconds = getUnitTrinketCD(unit)
    return GetTime() - trinketUsedAt[unit] < cdInSeconds
end

local function OnArenaTrinketUpdate(unit)
    local trinketInfo = getArenaTrinketInfo(unit)

    if not trinketInfo then
        return -- trinket not on CD
    end

    if isUnitTrinketUsed(unit) then
        return
    end

    trinketUsedAt[unit] = trinketInfo.startTime
    local selectedType, identity = getTypeAndUnitIdentity(unit)
    SoundSystem.playTrinketSound(selectedType, identity)
    if trinketInfo.spellId then
        local spellInfo = C_Spell.GetSpellInfo(trinketInfo.spellId)
        print('Spell Name:', spellInfo and spellInfo.name or 'Unknown', 'Unit:',
            unit, 'Spell ID:', trinketInfo.spellId)
    end
end



-- EVENTS --
local function RequestAll()
    for i = 1, GetNumArenaOpponentSpecs() do
        local unit = "arena" .. i
        if ArenaUtil.UnitExists(unit) then
            C_PvP.RequestCrowdControlSpell(unit)
        end
    end
end

local function RefreshAll()
    for i = 1, GetNumArenaOpponentSpecs() do
        local unit = "arena" .. i
        if ArenaUtil.UnitExists(unit) then
            OnArenaTrinketUpdate(unit)
        end
    end
end

local arenaTrinketTracker = CreateFrame("Frame", "ArenaTrinketSoundFrame")
arenaTrinketTracker:SetScript("OnEvent", function(_, _, unit)
    if not unit or unit == "" then
        RefreshAll()
        return
    end
    if strmatch(unit, "^arena%d$") and ArenaUtil.UnitExists(unit) then
        OnArenaTrinketUpdate(unit)
    end
end)

-- Listen for zone change to enable/disable tracking
local function syncTrinketTracker()
    if C_PvP.IsMatchConsideredArena() then
        arenaTrinketTracker:RegisterEvent("ARENA_COOLDOWNS_UPDATE")
    else
        arenaTrinketTracker:UnregisterEvent("ARENA_COOLDOWNS_UPDATE")
        wipe(trinketUsedAt)
    end
end

local ZoneWatcher = CreateFrame("Frame")
ZoneWatcher:RegisterEvent("PLAYER_ENTERING_WORLD")
ZoneWatcher:RegisterEvent("PVP_MATCH_STATE_CHANGED")
ZoneWatcher:RegisterEvent("ARENA_PREP_OPPONENT_SPECIALIZATIONS")

ZoneWatcher:SetScript("OnEvent", function(_, event)
    if event == "ARENA_PREP_OPPONENT_SPECIALIZATIONS" then
        wipe(trinketUsedAt)
    elseif event == "PVP_MATCH_STATE_CHANGED" then
        local matchState = C_PvP.GetActiveMatchState()
        if matchState == Enum.PvPMatchState.StartUp then
            -- Pre-match lobby: gates not open, no trinkets used yet — clean slate
            wipe(trinketUsedAt)
        elseif matchState == Enum.PvPMatchState.Engaged then
            -- Gates just opened — seed initial state in case trinket was used in prep
            RequestAll()
            RefreshAll()
        end
        syncTrinketTracker()
    elseif event == "PLAYER_ENTERING_WORLD" then
        syncTrinketTracker()
        if C_PvP.IsMatchConsideredArena() then
            -- Reconnect/reload mid-arena — seed current state immediately
            RequestAll()
            RefreshAll()
        end
    end
end)

DBUtils.initSavedVars()
