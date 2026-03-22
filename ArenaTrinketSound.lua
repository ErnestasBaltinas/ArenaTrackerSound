local _, addon = ...
local DBUtils = addon.DBUtils
local SoundSystem = addon.SoundSystem

local trinketUsedAt = {}

-- utils --

local function getArenaIndex(unit)
    return tonumber(string.match(unit, "^arena(%d+)$"))
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


-- debug --

local function atsPrefix()
    return "|cFFFFD700[ATS " .. date("%H:%M:%S") .. "]|r"
end

local function printTrinketUsed(unit, identity)
    print(atsPrefix() .. " |cFFFF0000" .. tostring(identity) .. " (" .. unit .. ")|r |cFF00FF00Trinketed!|r |T1322720:16:16|t")
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
