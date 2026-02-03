local addonName, addon = ...

-- Session-only data (cleared when frame closes)
addon.rolls = {}

-- Create the main frame
local frame = CreateFrame("Frame", "Nice69TrackerFrame", UIParent, "BackdropTemplate")
frame:SetSize(250, 300)
frame:SetPoint("LEFT")
frame:SetBackdrop({
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    tile = true,
    tileSize = 32,
    edgeSize = 32,
    insets = { left = 8, right = 8, top = 8, bottom = 8 }
})
frame:SetBackdropColor(0, 0, 0, 0.8)
frame:EnableMouse(true)
frame:SetMovable(true)
frame:RegisterForDrag("LeftButton")
frame:SetScript("OnDragStart", frame.StartMoving)
frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
frame:SetClampedToScreen(true)

-- Create title text
local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
title:SetPoint("TOP", 0, -15)
title:SetText("Nice! (69)")

-- Create close button
local closeButton = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
closeButton:SetPoint("TOPRIGHT", -5, -5)
closeButton:SetScript("OnClick", function()
    addon.rolls = {}
    addon:UpdateDisplay()
    frame:Hide()
end)

-- Create scroll frame
local scrollFrame = CreateFrame("ScrollFrame", "Nice69ScrollFrame", frame, "UIPanelScrollFrameTemplate")
scrollFrame:SetPoint("TOPLEFT", 15, -40)
scrollFrame:SetPoint("BOTTOMRIGHT", -30, 40)

-- Create scroll child (content holder)
local scrollChild = CreateFrame("Frame", nil, scrollFrame)
scrollChild:SetSize(210, 1)
scrollFrame:SetScrollChild(scrollChild)

-- Create clear button
local clearButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
clearButton:SetSize(100, 25)
clearButton:SetPoint("BOTTOM", 0, 10)
clearButton:SetText("Clear List")
clearButton:SetScript("OnClick", function()
    addon.rolls = {}
    addon:UpdateDisplay()
    frame:Hide()
end)

-- Store font strings for display
addon.displayLines = {}

-- Function to update the display
function addon:UpdateDisplay()
    -- Clear existing font strings
    for i, fontString in ipairs(self.displayLines) do
        fontString:Hide()
        fontString:SetText("")
    end

    -- Sort rolls by timestamp (most recent first)
    local sortedRolls = {}
    for playerName, data in pairs(self.rolls) do
        table.insert(sortedRolls, {name = playerName, time = data.time, count = data.count})
    end
    table.sort(sortedRolls, function(a, b) return a.time > b.time end)

    -- Display rolls
    local yOffset = 0
    for i, rollData in ipairs(sortedRolls) do
        if not self.displayLines[i] then
            self.displayLines[i] = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            self.displayLines[i]:SetPoint("TOPLEFT", 5, 0)
        end

        local fs = self.displayLines[i]
        fs:SetPoint("TOPLEFT", 5, -yOffset)

        -- Color the player name by class if possible
        local classColor = "|cFFFFFFFF"
        local _, class = UnitClass(rollData.name)
        if class then
            local color = RAID_CLASS_COLORS[class]
            if color then
                classColor = string.format("|cFF%02x%02x%02x", color.r * 255, color.g * 255, color.b * 255)
            end
        end

        local countText = rollData.count > 1 and string.format(" (x%d)", rollData.count) or ""
        fs:SetText(classColor .. rollData.name .. "|r" .. countText)
        fs:Show()

        yOffset = yOffset + 20
    end

    scrollChild:SetHeight(math.max(yOffset, 1))
end

-- Function to add a 69 roll
function addon:AddRoll(playerName)
    if not playerName or playerName == "" then return end

    -- Initialize or update the roll count
    if self.rolls[playerName] then
        self.rolls[playerName].count = self.rolls[playerName].count + 1
        self.rolls[playerName].time = time()
    else
        self.rolls[playerName] = {
            count = 1,
            time = time()
        }
    end

    -- Play a sound
    PlaySound(SOUNDKIT.RAID_WARNING)

    -- Update the display
    self:UpdateDisplay()

    -- Show the frame if it's hidden
    if not frame:IsShown() then
        frame:Show()
    end
end

-- Event handler
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("CHAT_MSG_SYSTEM")
eventFrame:SetScript("OnEvent", function(self, event, message)
    if event == "CHAT_MSG_SYSTEM" then
        -- Pattern for roll messages
        -- Example: "PlayerName rolls 69 (1-100)"
        local playerName, roll, minRoll, maxRoll = message:match("^(.+) rolls (%d+) %((%d+)%-(%d+)%)$")

        if playerName and roll then
            roll = tonumber(roll)
            if roll == 69 then
                addon:AddRoll(playerName)
            end
        end
    end
end)

-- Slash commands
SLASH_NICE69TRACKER1 = "/nice69"
SLASH_NICE69TRACKER2 = "/69tracker"

SlashCmdList["NICE69TRACKER"] = function(msg)
    msg = string.lower(msg or "")

    if msg == "show" then
        frame:Show()
        print("Nice 69 Tracker: Frame shown")
    elseif msg == "hide" then
        frame:Hide()
        print("Nice 69 Tracker: Frame hidden")
    elseif msg == "toggle" then
        if frame:IsShown() then
            frame:Hide()
        else
            frame:Show()
        end
    elseif msg == "clear" then
        addon.rolls = {}
        addon:UpdateDisplay()
        frame:Hide()
        print("Nice 69 Tracker: List cleared and frame hidden")
    else
        print("Nice 69 Tracker Commands:")
        print("/nice69 show - Show the tracker frame")
        print("/nice69 hide - Hide the tracker frame")
        print("/nice69 toggle - Toggle the tracker frame")
        print("/nice69 clear - Clear the roll list and hide frame")
    end
end

-- Initialize on addon loaded
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:SetScript("OnEvent", function(self, event, loadedAddon)
    if event == "ADDON_LOADED" and loadedAddon == addonName then
        addon:UpdateDisplay()
        print("Nice 69 Tracker loaded! Type /nice69 for commands")
        self:UnregisterEvent("ADDON_LOADED")
    end
end)
