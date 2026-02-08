BetterRollsDB = BetterRollsDB or { winnerRoll = 69, position = {} }

ROLLS = {}
DISPLAY_LINES = {}
TEST_MODE = false

local UpdateDisplay

local frame = CreateFrame("Frame", "BetterRollsFrame", UIParent, "BackdropTemplate")
frame:SetSize(250, 300)
frame:SetPoint("CENTER")
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
frame:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    local point, _, relativePoint, xOfs, yOfs = self:GetPoint()
    BetterRollsDB.position = {point, relativePoint, xOfs, yOfs}
end)
frame:SetClampedToScreen(true)
frame:Hide()

if BetterRollsDB.position and #BetterRollsDB.position == 4 then
    frame:ClearAllPoints()
    frame:SetPoint(BetterRollsDB.position[1], UIParent, BetterRollsDB.position[2],
                   BetterRollsDB.position[3], BetterRollsDB.position[4])
end

local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
title:SetPoint("TOP", 0, -15)
title:SetText("Nice! ("..BetterRollsDB.winnerRoll..")")

local closeButton = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
closeButton:SetPoint("TOPRIGHT", -5, -5)
closeButton:SetScript("OnClick", function()
    ROLLS = {}
    UpdateDisplay()
    frame:Hide()
end)

local scrollFrame = CreateFrame("ScrollFrame", "BetterRollScrollFrame", frame, "UIPanelScrollFrameTemplate")
scrollFrame:SetPoint("TOPLEFT", 15, -40)
scrollFrame:SetPoint("BOTTOMRIGHT", -30, 40)

local scrollChild = CreateFrame("Frame", nil, scrollFrame)
scrollChild:SetSize(210, 1)
scrollFrame:SetScrollChild(scrollChild)

local clearButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
clearButton:SetSize(100, 25)
clearButton:SetPoint("BOTTOM", 0, 10)
clearButton:SetText("Clear List")
clearButton:SetScript("OnClick", function()
    ROLLS = {}
    UpdateDisplay()
    frame:Hide()
end)

UpdateDisplay = function()
    for i, fontString in ipairs(DISPLAY_LINES) do
        fontString:Hide()
        fontString:SetText("")
    end

    local sortedRolls = {}
    for playerName, data in pairs(ROLLS) do
        table.insert(sortedRolls, {name = playerName, time = data.time, count = data.count})
    end
    table.sort(sortedRolls, function(a, b) return a.time > b.time end)

    local yOffset = 0
    for i, rollData in ipairs(sortedRolls) do
        if not DISPLAY_LINES[i] then
            DISPLAY_LINES[i] = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            DISPLAY_LINES[i]:SetPoint("TOPLEFT", 5, 0)
        end

        local fs = DISPLAY_LINES[i]
        fs:SetPoint("TOPLEFT", 5, -yOffset)

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

local function AddRoll(playerName)
    if not playerName or playerName == "" then return end

    if ROLLS[playerName] then
        ROLLS[playerName].count = ROLLS[playerName].count + 1
        ROLLS[playerName].time = time()
    else
        ROLLS[playerName] = {
            count = 1,
            time = time()
        }
    end

    PlaySound(SOUNDKIT.RAID_WARNING)

    UpdateDisplay()

    if not frame:IsShown() then
        frame:Show()
    end
end

local function IsRaidLeader()
    if not IsInRaid() then return false end

    local playerName = UnitName("player")
    for i = 1, GetNumGroupMembers() do
        local name, rank = GetRaidRosterInfo(i)
        if name == playerName then
            return rank == 2
        end
    end

    return false
end

local function AnnounceRoll(message)
    if IsRaidLeader() then
        SendChatMessage(message, "RAID")
    end

    print("|cffff0000BetterRolls:|r "..message)
end

frame:RegisterEvent("CHAT_MSG_SYSTEM")
frame:SetScript("OnEvent", function(self, event, message)
    if event == "CHAT_MSG_SYSTEM" and not issecretvalue(message) then
        local playerName, roll, minRoll, maxRoll = message:match("^(.+) rolls (%d+) %((%d+)%-(%d+)%)$")

        if playerName and roll then
            roll = tonumber(roll)
            minRoll = tonumber(minRoll)
            maxRoll = tonumber(maxRoll)

            local message = ""

            if roll == BetterRollsDB.winnerRoll then
                if not TEST_MODE and (minRoll == BetterRollsDB.winnerRoll or maxRoll == BetterRollsDB.winnerRoll) then
                    message = playerName.." was naughty and faked a "..tostring(BetterRollsDB.winnerRoll).." roll!"
                else
                    message = playerName.." rolled "..tostring(BetterRollsDB.winnerRoll).."!"

                    AddRoll(playerName)
                end

                AnnounceRoll(message)
            end
        end
    end
end)


SLASH_BetterRolls1 = "/brolls"

SlashCmdList["BetterRolls"] = function(msg)
    msg = string.lower(msg or "")

    if msg == "show" then
        frame:Show()
    elseif msg == "hide" then
        frame:Hide()
    elseif msg == "clear" then
        ROLLS = {}
        UpdateDisplay()
        frame:Hide()
        print("|cffff0000BetterRolls:|r List cleared and frame hidden")
    elseif msg == "reset" then
        BetterRollsDB.position = {}
        frame:ClearAllPoints()
        frame:SetPoint("CENTER")
    elseif msg == "set" then
        BetterRollsDB.winnerRoll = tonumber(msg)
    elseif msg == "test" then
        TEST_MODE = (not TEST_MODE)

        print("|cffff0000BetterRolls:|r Test mode "..(TEST_MODE and "enabled" or "disabled"))
    else
        print("|cffff0000BetterRolls:|r Commands:")
        print("/brolls show - Show the tracker frame")
        print("/brolls hide - Hide the tracker frame")
        print("/brolls toggle - Toggle the tracker frame")
        print("/brolls clear - Clear the roll list and hide frame")
        print("/brolls reset - Reset frame position to center")
        print("/brolls set <value> - Set the winner roll value")
        print("/brolls test - Enables/disables test mode (then do /roll "..BetterRollsDB.winnerRoll.."-"..BetterRollsDB.winnerRoll..")")
    end
end