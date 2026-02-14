BetterRollsDB = BetterRollsDB or { winnerRoll = 69, position = {} }


RollsFrameMixin = {}

function RollsFrameMixin:OnLoad()
    self.rolls = {}
    self.displayLines = {}
    self.testMode = false

    self.title:SetText("Nice! ("..BetterRollsDB.winnerRoll..")")

    if BetterRollsDB.position and #BetterRollsDB.position == 4 then
        self:ClearAllPoints()
        self:SetPoint(BetterRollsDB.position[1], UIParent, BetterRollsDB.position[2],
                      BetterRollsDB.position[3], BetterRollsDB.position[4])
    end

    local backdrop_header = {
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true,
        tileSize = 32,
        edgeSize = 32,
        insets = { left = 8, right = 8, top = 8, bottom = 8 }
    }
    self:SetBackdrop(backdrop_header)
    self:SetBackdropColor(0, 0, 0, 0.8)
    self:EnableMouse(true)
    self:SetMovable(true)
    self:RegisterForDrag("LeftButton")
    self:SetClampedToScreen(true)
    self:Hide()

    local frame = self
    self.closeButton:SetScript("OnClick", function()
        frame:Clear()
    end)

    self.clearButton:SetScript("OnClick", function()
        frame:Clear()
    end)

    self:RegisterEvent("CHAT_MSG_SYSTEM")
end

function RollsFrameMixin:Clear()
    self.rolls = {}
    self:UpdateDisplay()
    self:Hide()
end

function RollsFrameMixin:OnDragStop()
    self:StopMovingOrSizing()
    local point, _, relativePoint, xOfs, yOfs = self:GetPoint()
    BetterRollsDB.position = {point, relativePoint, xOfs, yOfs}
end

function RollsFrameMixin:GetClassColor(class)
    local classColor = "|cFFFFFFFF"
    if class then
        local color = RAID_CLASS_COLORS[class]
        if color then
            classColor = string.format("|cFF%02x%02x%02x", color.r * 255, color.g * 255, color.b * 255)
        end
    end

    return classColor
end

function RollsFrameMixin:UpdateDisplay()
    for i, fontString in ipairs(self.displayLines) do
        fontString:Hide()
        fontString:SetText("")
    end

    local sortedRolls = {}
    for playerName, data in pairs(self.rolls) do
        table.insert(sortedRolls, {name = playerName, time = data.time, count = data.count, class = data.class})
    end
    table.sort(sortedRolls, function(a, b) return a.time > b.time end)

    local scrollChild = self.scrollFrame:GetScrollChild()
    local yOffset = 0
    for i, rollData in ipairs(sortedRolls) do
        if not self.displayLines[i] then
            self.displayLines[i] = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            self.displayLines[i]:SetPoint("TOPLEFT", 5, 0)
        end

        local fs = self.displayLines[i]
        fs:SetPoint("TOPLEFT", 5, -yOffset)

        local classColor = self:GetClassColor(rollData.class)
        local countText = rollData.count > 1 and string.format(" (x%d)", rollData.count) or ""
        fs:SetText(classColor..rollData.name.."|r"..countText)
        fs:Show()

        yOffset = yOffset + 20
    end

    scrollChild:SetHeight(math.max(yOffset, 1))
end

function RollsFrameMixin:AddRoll(playerName)
    if not playerName or playerName == "" then return end

    local currentTime = time()

    local _, class = UnitClass(playerName)

    if self.rolls[playerName] then
        self.rolls[playerName].count = self.rolls[playerName].count + 1
        self.rolls[playerName].time = currentTime
    else
        self.rolls[playerName] = {
            count = 1,
            time = currentTime,
            class = class
        }
    end

    PlaySound(SOUNDKIT.RAID_WARNING)

    self:UpdateDisplay()

    if not self:IsShown() then
        self:Show()
    end
end

function RollsFrameMixin:IsRaidLeader()
    if not IsInRaid() then return false end

    local playerName = UnitName("player")
    for i = 1, GetNumGroupMembers() do
        local name, rank = GetRaidRosterInfo(i)
        if name and name == playerName then
            return rank == 2
        end
    end

    return false
end

function RollsFrameMixin:AnnounceRoll(message)
    if self:IsRaidLeader() then
        SendChatMessage(message, "RAID")
    end

    print("|cffB0C4DE[BetterRolls]|r "..message)
end

function RollsFrameMixin:OnEvent(event, message)
    if message and not issecretvalue(message) then
        local playerName, roll, minRoll, maxRoll = message:match("^(.+) rolls (%d+) %((%d+)%-(%d+)%)$")

        if playerName and roll then
            roll = tonumber(roll)
            minRoll = tonumber(minRoll)
            maxRoll = tonumber(maxRoll)

            local announceMsg = ""

            if roll == BetterRollsDB.winnerRoll then
                if not self.testMode and (minRoll == BetterRollsDB.winnerRoll or maxRoll == BetterRollsDB.winnerRoll) then
                    announceMsg = playerName.." was naughty and faked a "..tostring(BetterRollsDB.winnerRoll).." roll!"
                else
                    announceMsg = playerName.." rolled "..tostring(BetterRollsDB.winnerRoll).."!"
                    self:AddRoll(playerName)
                end

                self:AnnounceRoll(announceMsg)
            end
        end
    end
end


SLASH_BetterRolls1 = "/brolls"

SlashCmdList["BetterRolls"] = function(arg)
    local msg = string.lower(arg or "")

    if msg == "show" then
        RollsFrame:Show()
    elseif msg == "hide" then
        RollsFrame:Hide()
    elseif msg == "clear" then
        RollsFrame:Clear()
        print("|cffB0C4DE[BetterRolls]|r List cleared and frame hidden")
    elseif msg == "reset" then
        BetterRollsDB.position = {}
        RollsFrame:ClearAllPoints()
        RollsFrame:SetPoint("CENTER")
        print("|cffB0C4DE[BetterRolls]|r Position reset to center")
    elseif msg:match("^set%s+%d+$") then
        local value = tonumber(msg:match("^set%s+(%d+)$"))
        if value and value >= 1 and value <= 100 then
            BetterRollsDB.winnerRoll = value
            RollsFrame.title:SetText("Nice! ("..value..")")
            print("|cffB0C4DE[BetterRolls]|r Winner roll set to "..value)
        else
            print("|cffB0C4DE[BetterRolls]|r Invalid value. Must be 1-100.")
        end
    elseif msg == "test" then
        RollsFrame.testMode = not RollsFrame.testMode
        print("|cffB0C4DE[BetterRolls]|r Test mode "..(RollsFrame.testMode and "enabled" or "disabled"))
    else
        print("|cffB0C4DE[BetterRolls]|r Commands:")
        print("  /brolls show - Show the tracker frame")
        print("  /brolls hide - Hide the tracker frame")
        print("  /brolls clear - Clear the roll list and hide frame")
        print("  /brolls reset - Reset frame position to center")
        print("  /brolls set <value> - Set the winner roll value (1-100)")
        print("  /brolls test - Toggle test mode (then do /roll "..BetterRollsDB.winnerRoll.."-"..BetterRollsDB.winnerRoll..")")
    end
end