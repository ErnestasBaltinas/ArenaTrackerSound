local _, addon = ...
local DBUtils = addon.DBUtils
local SoundSystem = addon.SoundSystem

local trinketUsedAt = {}

-- Build specID → classFile lookup at load time from static game data.
-- Avoids calling UnitClass/UnitGroupRolesAssigned on arena units, which return
-- secret values in 12.1 when the unit's identity is secret.
local specToClassFile = {}
for classIndex = 1, GetNumClasses() do
    local _, classFile, classID = GetClassInfo(classIndex)
    for specIndex = 1, GetNumSpecializationsForClassID(classID) do
        local specID = GetSpecializationInfoForClassID(classID, specIndex)
        specToClassFile[specID] = classFile
    end
end

-- utils --

local function getArenaIndex(unit)
    return tonumber(string.match(unit, "^arena(%d+)$"))
end

local function getUnitRole(unit)
    local index = getArenaIndex(unit)
    local specID = GetArenaOpponentSpec(index)
    if specID then
        local _, _, _, role = GetSpecializationInfoByID(specID)
        return role or "NONE"
    end
    return "NONE"
end

local function getUnitSpecName(unit)
    local index = getArenaIndex(unit)
    local specID = GetArenaOpponentSpec(index)
    if not specID then
        return nil
    end
    local _, specName = GetSpecializationInfoByID(specID)
    return specName -- Balance
end

local function getUnitClassName(unit)
    local index = getArenaIndex(unit)
    local specID = GetArenaOpponentSpec(index)
    return specID and specToClassFile[specID] -- DRUID, DEATHKNIGHT, etc.
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


-- debug --

local function atsPrefix()
    return "|cFFFFD700[ATS " .. date("%H:%M:%S") .. "]|r"
end

local function printTrinketUsed(unit, identity)
    local label = identity and (tostring(identity) .. " (" .. unit .. ")") or unit
    print(atsPrefix() ..
        " |cFFFF0000" .. label .. "|r |cFF00FF00Trinketed!|r |T1322720:16:16|t")
end


-- logic --

local function getUnitTrinketCD(unit)
    local role = getUnitRole(unit)
    local cdInSeconds = (role == "HEALER") and 90 or 120 --hard coded values due to blizzard api durationMs being secret
    return cdInSeconds
end

local function isTrinketOnCD(unit)
    return trinketUsedAt[unit] ~= nil
end

local function markTrinketUsed(unit)
    trinketUsedAt[unit] = GetTime()
end

local function clearTrinketCD(unit)
    trinketUsedAt[unit] = nil
end

local function resetAllTrinkets()
    wipe(trinketUsedAt)
end

local function OnArenaTrinketUsed(unit)
    markTrinketUsed(unit)
    local selectedType, identity = getTypeAndUnitIdentity(unit)
    printTrinketUsed(unit, identity)
    SoundSystem.playTrinketSound(selectedType, identity)
end


-- HOOKS --

local hookedSlots = {}

local function setupTrinketHooks()
    for i = 1, 5 do
        if not hookedSlots[i] then
            local arenaFrame = _G["CompactArenaFrameMember" .. i]
            if arenaFrame and arenaFrame.CcRemoverFrame and arenaFrame.CcRemoverFrame.Cooldown then
                local unit = "arena" .. i
                hooksecurefunc(arenaFrame.CcRemoverFrame.Cooldown, "SetCooldown", function(_, start, duration)
                    if isTrinketOnCD(unit) then return end
                    OnArenaTrinketUsed(unit)
                end)
                arenaFrame.CcRemoverFrame.Cooldown:HookScript("OnCooldownDone", function()
                    clearTrinketCD(unit)
                end)
                hookedSlots[i] = true
            end
        end
    end
end


-- EVENTS --

local ZoneWatcher = CreateFrame("Frame")
ZoneWatcher:RegisterEvent("PLAYER_ENTERING_WORLD")
ZoneWatcher:RegisterEvent("PVP_MATCH_STATE_CHANGED")
ZoneWatcher:RegisterEvent("ARENA_PREP_OPPONENT_SPECIALIZATIONS")

ZoneWatcher:SetScript("OnEvent", function(_, event)
    if event == "ARENA_PREP_OPPONENT_SPECIALIZATIONS" then
        resetAllTrinkets()
        setupTrinketHooks()
    elseif event == "PVP_MATCH_STATE_CHANGED" then
        local matchState = C_PvP.GetActiveMatchState()
        if matchState == Enum.PvPMatchState.StartUp then
            -- Pre-match lobby: gates not open, no trinkets used yet — clean slate
            resetAllTrinkets()
        elseif matchState == Enum.PvPMatchState.Engaged then
            -- Gates just opened
            setupTrinketHooks()
        end
    elseif event == "PLAYER_ENTERING_WORLD" then
        if C_PvP.IsMatchConsideredArena() then
            -- Reconnect/reload mid-arena
            setupTrinketHooks()
        end
    end
end)

DBUtils.initSavedVars()
