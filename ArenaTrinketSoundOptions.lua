-- =========================================
-- ArenaTrinketSoundOptions
-- =========================================

local addonName, addon = ...
local loader = CreateFrame("Frame")
local xOffset = 7
local addonCategoryId = nil
local DBUtils = addon.DBUtils
local SoundSystem = addon.SoundSystem



-- =============================
-- Dropdown helper
-- =============================
local function createDropdown(parent, labelText)
    local dropdown = CreateFrame("DropdownButton", nil, parent, "WowStyle1DropdownTemplate")
    dropdown:SetWidth(200)

    local label = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    label:SetPoint("BOTTOMLEFT", dropdown, "TOPLEFT", 0, 2)
    label:SetText(labelText)

    return dropdown
end

-- =============================
-- Options Frame
-- =============================
local function initOptionsFrame()
    local optionsFrame = CreateFrame("FRAME", addonName)
    optionsFrame.name = addonName
    local category = Settings.RegisterCanvasLayoutCategory(optionsFrame, addonName)
    Settings.RegisterAddOnCategory(category)
    addonCategoryId = category:GetID()

    -- Header
    local header = optionsFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalHuge")
    header:SetPoint("TOPLEFT", xOffset, -20)
    header:SetText(addonName)
    header:SetTextColor(1, 1, 1, 1)

    -- Separator
    local separator = optionsFrame:CreateTexture(nil, "ARTWORK")
    separator:SetAtlas("Options_HorizontalDivider", true)
    separator:SetPoint("TOP", 0, -50)

    -- Sound Type Dropdown
    local soundTypeDropdown = createDropdown(optionsFrame, "Sound Type:")
    soundTypeDropdown:SetPoint("TOPLEFT", xOffset, -75)
        
    if MenuUtil and MenuUtil.CreateRadioMenu then
        MenuUtil.CreateRadioMenu(
            soundTypeDropdown,
            function(value) return value == DBUtils.getOptionValue("selectedSoundType") end,
            function(value) DBUtils.setOptionValue("selectedSoundType", value) end,
            unpack(SoundSystem.AVAILABLE_SOUND_TYPES)
        )
    end
  
    -- Channel Dropdown
    local channelDropdown = createDropdown(optionsFrame, "Sound Channel:")
    channelDropdown:SetPoint("LEFT", soundTypeDropdown, "RIGHT", 5, 0)
            
    -- error message for disabled channels
    local errorMessage = optionsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    errorMessage:SetPoint("TOPLEFT", channelDropdown, "BOTTOMLEFT", 0, -5)
    errorMessage:SetTextColor(1, 0.2, 0.2, 1) -- red color
    errorMessage:SetText("Channel is disabled")
    errorMessage:Hide()  -- hide initially

    if MenuUtil and MenuUtil.CreateRadioMenu then
        MenuUtil.CreateRadioMenu(
            channelDropdown,
            function(value) return value == DBUtils.getOptionValue("selectedSoundChannel") end,
            function(value)
                DBUtils.setOptionValue("selectedSoundChannel", value)
                if not SoundSystem.isChannelEnabled(value) then
                    errorMessage:Show()
                else
                    errorMessage:Hide()
                end
             end,
            unpack(SoundSystem.AVAILABLE_SOUND_CHANNELS)
        )
    end



    -- Preview Button
    local previewButton = CreateFrame("Button", nil, optionsFrame, "UIPanelButtonTemplate")
    previewButton:SetSize(150, 25)
    previewButton:SetPoint("LEFT", channelDropdown, "RIGHT", 5, 0)
    previewButton:SetText("Preview")
    previewButton:SetScript("OnClick", function()
        SoundSystem.playPreviewSound()
    end)

end

-- =============================
-- Open options helper
-- =============================
function OpenArenaTrinketSoundOptionsPanel()
    if UnitAffectingCombat("player") then
        print('|cffff0000ArenaTrinketSound:|r You can’t open options in combat.')
        return
    end
    Settings.OpenToCategory(addonCategoryId)
end

-- =============================
-- ADDON_LOADED
-- =============================
loader:SetScript("OnEvent", function(self, event, name)
    if event == "ADDON_LOADED" and name == addonName then
        initOptionsFrame()
        loader:UnregisterEvent("ADDON_LOADED")
    end
end)
loader:RegisterEvent("ADDON_LOADED")

-- =============================
-- Slash Commands
-- =============================
SLASH_ARENATRINKETSOUND1 = "/ats"
SLASH_ARENATRINKETSOUND2 = "/arenatrinketsound"
SlashCmdList["ARENATRINKETSOUND"] = function()
    OpenArenaTrinketSoundOptionsPanel()
end
