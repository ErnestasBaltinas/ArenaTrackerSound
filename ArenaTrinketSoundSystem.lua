local addonName, addon = ...
local DBUtils = addon.DBUtils

addon.SoundSystem = {}
local SoundSystem = addon.SoundSystem
local SOUND_PATH = "Interface\\AddOns\\" .. addonName .. "\\sounds\\"
local DEFAULT_SOUND_PATH = SOUND_PATH .. "default\\trinket_default.ogg"

SoundSystem.SOUND_TYPE = {
    ROLES   = "roles",
    SPECS   = "specs",
    CLASSES = "classes",
    DEFAULT = "default",
}

SoundSystem.AVAILABLE_SOUND_TYPES = {
    { "Default", SoundSystem.SOUND_TYPE.DEFAULT },
    { "Roles",   SoundSystem.SOUND_TYPE.ROLES },
    { "Specs",   SoundSystem.SOUND_TYPE.SPECS },
    { "Classes", SoundSystem.SOUND_TYPE.CLASSES },
}

SoundSystem.SOUND_CHANNEL = {
    MASTER   = "Master",
    MUSIC    = "Music",
    SFX      = "SFX",
    AMBIENCE = "Ambience",
    DIALOG   = "Dialog",
}

SoundSystem.AVAILABLE_SOUND_CHANNELS = {
    { "Master",   SoundSystem.SOUND_CHANNEL.MASTER },
    { "Music",    SoundSystem.SOUND_CHANNEL.MUSIC },
    { "SFX (Effects)", SoundSystem.SOUND_CHANNEL.SFX },
    { "Ambience", SoundSystem.SOUND_CHANNEL.AMBIENCE },
    { "Dialog",   SoundSystem.SOUND_CHANNEL.DIALOG },
}

SoundSystem.ROLES_SOUND_MAP = {
    TANK   = "tank",
    HEALER = "healer",
    DAMAGER = "dps",
}

SoundSystem.CLASS_SOUND_MAP = {
    WARRIOR      = "warrior",
    PALADIN      = "paladin",
    HUNTER       = "hunter",
    ROGUE        = "rogue",
    PRIEST       = "priest",
    DEATHKNIGHT  = "deathknight",
    SHAMAN       = "shaman",
    MAGE         = "mage",
    WARLOCK      = "warlock",
    MONK         = "monk",
    DRUID        = "druid",
    DEMONHUNTER  = "demonhunter",
    EVOKER       = "evoker",
}
SoundSystem.SPECS_SOUND_MAP = {

    -- Death Knight
    BLOOD_DEATHKNIGHT     = "blood_deathknight",
    FROST_DEATHKNIGHT     = "frost_deathknight",
    UNHOLY_DEATHKNIGHT    = "unholy_deathknight",

    -- Demon Hunter
    HAVOC_DEMONHUNTER     = "havoc_demonhunter",
    VENGEANCE_DEMONHUNTER = "vengeance_demonhunter",
    DEVOURER_DEMONHUNTER  = "devourer_demonhunter",

    -- Druid
    BALANCE_DRUID         = "balance_druid",
    FERAL_DRUID           = "feral_druid",
    GUARDIAN_DRUID        = "guardian_druid",
    RESTORATION_DRUID     = "restoration_druid",

    -- Evoker
    AUGMENTATION_EVOKER   = "augmentation_evoker",
    DEVASTATION_EVOKER    = "devastation_evoker",
    PRESERVATION_EVOKER   = "preservation_evoker",

    -- Hunter
    BEASTMASTERY_HUNTER   = "beastmastery_hunter",
    MARKSMANSHIP_HUNTER   = "marksmanship_hunter",
    SURVIVAL_HUNTER       = "survival_hunter",

    -- Mage
    ARCANE_MAGE           = "arcane_mage",
    FIRE_MAGE             = "fire_mage",
    FROST_MAGE            = "frost_mage",

    -- Monk
    BREWMASTER_MONK       = "brewmaster_monk",
    MISTWEAVER_MONK       = "mistweaver_monk",
    WINDWALKER_MONK       = "windwalker_monk",

    -- Paladin
    HOLY_PALADIN          = "holy_paladin",
    PROTECTION_PALADIN    = "protection_paladin",
    RETRIBUTION_PALADIN   = "retribution_paladin",

    -- Priest
    DISCIPLINE_PRIEST     = "discipline_priest",
    HOLY_PRIEST           = "holy_priest",
    SHADOW_PRIEST         = "shadow_priest",

    -- Rogue
    ASSASSINATION_ROGUE   = "assassination_rogue",
    OUTLAW_ROGUE          = "outlaw_rogue",
    SUBTLETY_ROGUE        = "subtlety_rogue",

    -- Shaman
    ELEMENTAL_SHAMAN      = "elemental_shaman",
    ENHANCEMENT_SHAMAN    = "enhancement_shaman",
    RESTORATION_SHAMAN    = "restoration_shaman",

    -- Warlock
    AFFLICTION_WARLOCK    = "affliction_warlock",
    DEMONOLOGY_WARLOCK    = "demonology_warlock",
    DESTRUCTION_WARLOCK   = "destruction_warlock",

    -- Warrior
    ARMS_WARRIOR          = "arms_warrior",
    FURY_WARRIOR          = "fury_warrior",
    PROTECTION_WARRIOR    = "protection_warrior",
}

local SOUND_CHANNEL_CVAR = {
    Master   = "Sound_EnableAllSound",
    SFX      = "Sound_EnableSFX",
    Music    = "Sound_EnableMusic",
    Ambience = "Sound_EnableAmbience",
    Dialog   = "Sound_EnableDialog",
}

local function getSoundFileName(type, identity)
    if type == SoundSystem.SOUND_TYPE.DEFAULT then
        return "trinket_default"
    elseif type == SoundSystem.SOUND_TYPE.ROLES then
         return SoundSystem.ROLES_SOUND_MAP[identity]
    elseif type == SoundSystem.SOUND_TYPE.SPECS then
         return SoundSystem.SPECS_SOUND_MAP[identity]
    elseif type == SoundSystem.SOUND_TYPE.CLASSES then
        return SoundSystem.CLASS_SOUND_MAP[identity]
    end
    return nil

end

-- type: "roles" | "specs" | "classes"
local function getSoundPath(type, soundFileName)
    if not type or not soundFileName then
        return nil
    end

    -- Build the path dynamically
    local path = SOUND_PATH .. type .. "\\" .. soundFileName .. ".ogg"

    return path or nil
end


function SoundSystem.playTrinketSound(type, identity)

    local selectedSoundChannel = DBUtils.getOptionValue("selectedSoundChannel")

    local soundFileName = getSoundFileName(type, identity)
    local soundPath = getSoundPath(type, soundFileName)

    -- If mapping failed, use default
    if not soundPath then
        PlaySoundFile(DEFAULT_SOUND_PATH, selectedSoundChannel)
        return
    end

    -- Try playing requested sound
    local willPlay = PlaySoundFile(soundPath, selectedSoundChannel)

    -- If WoW fails to play it (file missing), fallback
    if not willPlay then
        PlaySoundFile(DEFAULT_SOUND_PATH, selectedSoundChannel)
    end
end

-- global preview function
function SoundSystem.playPreviewSound()
    local selectedType = DBUtils.getOptionValue("selectedSoundType")
    if not selectedType then return end

    -- Default type has no per-identity variation
    if selectedType == SoundSystem.SOUND_TYPE.DEFAULT then
        SoundSystem.playTrinketSound(selectedType, nil)
        return
    end

    -- select the appropriate mapping table
    local mapping = nil
    if selectedType == SoundSystem.SOUND_TYPE.ROLES then
        mapping = SoundSystem.ROLES_SOUND_MAP
    elseif selectedType == SoundSystem.SOUND_TYPE.SPECS then
        mapping = SoundSystem.SPECS_SOUND_MAP
    elseif selectedType == SoundSystem.SOUND_TYPE.CLASSES then
        mapping = SoundSystem.CLASS_SOUND_MAP
    end

    if not mapping then return end

    -- convert mapping keys to array for random selection
    local identities = {}
    for identity, _ in pairs(mapping) do
        table.insert(identities, identity)
    end

    if #identities == 0 then return end

    -- pick a random identity
    local randomIndex = math.random(1, #identities)
    local randomIdentity = identities[randomIndex]

    SoundSystem.playTrinketSound(selectedType, randomIdentity)
end


function SoundSystem.isChannelEnabled(channelToken)
    local cvar = SOUND_CHANNEL_CVAR[channelToken]
    if not cvar then return false end
    return GetCVarBool(cvar)
end